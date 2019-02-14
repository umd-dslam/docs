# Quantitative Analysis

The purpose of this session is to find the memory bottleneck by quantifying the memory footprint of various data structures in HDFS. Data structures that are not bottlenecks will remain in the Namenode's memory, but the bottleneck part needs to be transferred to the distributed deterministic database to improve the overall scalability of HDFS.

> Here we only make a rough estimate of the size of different objects. Optimizatins like reordering object properties and memory layout of super/subclasses in JVM heap allocation were not considered. But this does not affect the final result.

## Java Object Size

One way to get an estimate of an object's size in Java is to use `getObjectSize(Object)` method of the [Instrumentation interface](https://docs.oracle.com/javase/7/docs/api/java/lang/instrument/Instrumentation.html) introduced in Java. We provide the [InstrumentationAgent](https://github.com/DSL-UMD/hadoop-calvin/pull/1/files#diff-5cbfd1caf17137e9459de168b90ef12e) is based on that.

> However, this approach **only supports** size estimation of the considered object itself and not the sizes of objects it references. To estimate a total size of the object, we have to go over those references and calculate the estimated size.

### Primitives

We know the size of each primitive from the Java specification. What isn't stated in the specification is how much heap space they use. It seems to be JVM implementation dependent.
Below is a table that shows each primitive's size and how much heap it may use on my JVM.
Be aware because of `8 byte alignment` and `padding` that a primitive such as a byte or boolean, can be packed together to take up less memory, and this table only shows the maximum space it can use.

```bash
$ java -version

openjdk version "1.8.0_191"
OpenJDK Runtime Environment (build 1.8.0_191-8u191-b12-0ubuntu0.16.04.1-b12)
OpenJDK 64-Bit Server VM (build 25.191-b12, mixed mode)
```

| Primitives | Size (bytes) | Max Heap Usage (bytes) |
|:----------:|:------------:|:----------------------:|
| boolean    | 1            | 8                      |
| byte       | 1            | 8                      |
| short      | 2            | 8                      |
| int        | 4            | 8                      |
| long       | 8            | 8                      |
| float      | 4            | 8                      |
| double     | 8            | 8                      |
| char       | 2            | 8                      |


### Object References

References have a typical size of 4 bytes on 32-bit platforms and on 64-bits platforms with heap boundary less than 32GB, and 8 bytes for this boundary above 32GB. We are working with large heaps and need to assume that all references are **8 bytes** (You can disable it through **-XX:-UseCompressedOops**, [UseCompressedOops](https://www.oracle.com/technetwork/java/javase/tech/vmoptions-jsp-140102.html) is on by default).

### Object Header

In a modern 64-bit JDK, an object has a 12-byte header, padded to a multiple of 8 bytes, so the minimum object size is **16 bytes** in the following form [3]:

```bash
|------------------------------------------------------------------------------------------------------------|--------------------|
|                                            Object Header (128 bits)                                        |        State       |
|------------------------------------------------------------------------------|-----------------------------|--------------------|
|                                  Mark Word (64 bits)                         |    Klass Word (64 bits)     |                    |
|------------------------------------------------------------------------------|-----------------------------|--------------------|
| unused:25 | identity_hashcode:31 | unused:1 | age:4 | biased_lock:1 | lock:2 |    OOP to metadata object   |       Normal       |
|------------------------------------------------------------------------------|-----------------------------|--------------------|
| thread:54 |       epoch:2        | unused:1 | age:4 | biased_lock:1 | lock:2 |    OOP to metadata object   |       Biased       |
|------------------------------------------------------------------------------|-----------------------------|--------------------|
|                       ptr_to_lock_record:62                         | lock:2 |    OOP to metadata object   | Lightweight Locked |
|------------------------------------------------------------------------------|-----------------------------|--------------------|
|                     ptr_to_heavyweight_monitor:62                   | lock:2 |    OOP to metadata object   | Heavyweight Locked |
|------------------------------------------------------------------------------|-----------------------------|--------------------|
|                                                                     | lock:2 |    OOP to metadata object   |    Marked for GC   |
|------------------------------------------------------------------------------|-----------------------------|--------------------|
```

### Array and ArrayList


#### Array

All arrays have an extra integer `length` field stored in their header, which means that an array's header uses 24 bytes even if it has no data - 16 bytes for header, 4 bytes for integer length, and 4 bytes for padding. JVM will allocate a block of memory, 8 byte aligned, to contain all the elements and only padding after the end of the last element. The layout looks like this:

|     Field    | Type |   Size (bytes)  |
|:------------:|:----:|:---------------:|
| Header       |      | 16              |
| Length       | int  | 4               |
| Padding      |      | 4               |
| Memory Block |      | size            |
| Padding      |      | pad             |
| Total        |      | **24+size+pad** |

#### ArrayList

[ArrayList](https://docs.oracle.com/javase/8/docs/api/java/util/ArrayList.html) is a resizable-array implementation of the `List` interface. It has more default fields than an array such as [[AbstractList.java#L348](https://github.com/ZenOfAutumn/jdk8/blob/de6c37469e54d46841838423400144f7b9dc4cf1/java/util/AbstractList.java#L348)] and [[ArrayList.java#L106-L141](https://github.com/ZenOfAutumn/jdk8/blob/de6c37469e54d46841838423400144f7b9dc4cf1/java/util/ArrayList.java#L106-L141)].

```bash
java.util.ArrayList object internals:
 OFFSET  SIZE     TYPE DESCRIPTION                    VALUE
      0     4          (object header)                05 00 00 00 (00000101 00000000 00000000 00000000) (5)
      4     4          (object header)                00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4          (object header)                f0 ad e9 23 (11110000 10101101 11101001 00100011) (602516976)
     12     4          (object header)                02 00 00 00 (00000010 00000000 00000000 00000000) (2)
     16     4      int AbstractList.modCount          0
     20     4          (alignment/padding gap)        N/A
     24     4      int ArrayList.size                 0
     28     4          (alignment/padding gap)        N/A
     32     8 Object[] ArrayList.elementData          []
Instance size: 40 bytes
Space losses: 8 bytes internal + 0 bytes external = 8 bytes total
```

The cost of ArrayList is **40 bytes fixed** + 8 bytes/entry.

|       Field      |     Type     |    Size (bytes)    |
|:----------------:|:------------:|:------------------:|
| Header           |              | 16                 |
| modCount         | int          | 4                  |
| Padding          |              | 4                  |
| size             | int          | 4                  |
| Padding          |              | 4                  |
| elementData      | Object[] Ref | 8                  |
| Total            |              | **40**             |


> The heap space taken by the `elementData` field is only the reference to the Object[], not including the data. `getObjectSize(List)` only returns 40 bytes.

### String Object

To understand how much heap a String object uses, we must look at [String's source code](https://github.com/ZenOfAutumn/jdk8/blob/de6c37469e54d46841838423400144f7b9dc4cf1/java/lang/String.java#L111-L120). The following table shows the properties and their sizes:

The cost of String is **32 bytes fixed** + 2 bytes/entry.

|  Field  |    Type    | Size (bytes) |
|:-------:|:----------:|:------------:|
| Header  |            | 16           |
| value   | char[] Ref | 8            |
| hash    | int        | 4            |
| Padding |            | 4            |
| Total   |            | **32**       |

> In Java JDK 7.0, String also included `int offset` and `int count`. The heap space taken by the `value` field is only the reference to the char[], not including the data. `getObjectSize(String)` only returns 32 bytes.

### Example

Consider the following example (the complete code is in [bench](https://github.com/DSL-UMD/hadoop-calvin/tree/calvin/bench) directory):

```java
class Person {
    String name;
    int age;
    long phone;
    boolean female;
    byte[] password = {1, 2, 3, 4};
}

Person p = new Person();

int[] a0 = {};
int[] a1 = {1};
int[] a2 = {1, 2};
int[] a3 = new int[100];

String[] b0 = {};
String[] b1 = {"1"};
String[] b2 = {"1", "2"};
String[] b3 = new String[100];

String s0 = "";
String s1 = "hello";

List<Person> al0 = new ArrayList<>(0);
List<Person> al1 = new ArrayList<>(1);
al1.add(new Person());
List<Person> al2 = new ArrayList<>(2);
al2.add(new Person());
al2.add(new Person());
List<Person> al3 = new ArrayList<>(100);
for (int i = 0; i < 100; i++) {
    al3.add(new Person());
}
```

The output of this example:

```bash
$ cd bench
$ javac InstrumentationAgent.java
$ jar cmf MANIFEST.MF InstrumentationAgent.jar InstrumentationAgent.class
$ javac InstrumentationExample.java
$ java -javaagent:InstrumentationAgent.jar -XX:-UseCompressedOops InstrumentationExample

Object type: class InstrumentationExample$1Person, size: 48 bytes
Object type: class [I, size: 24 bytes
Object type: class [I, size: 32 bytes
Object type: class [I, size: 32 bytes
Object type: class [I, size: 424 bytes
Object type: class [Ljava.lang.String;, size: 24 bytes
Object type: class [Ljava.lang.String;, size: 32 bytes
Object type: class [Ljava.lang.String;, size: 40 bytes
Object type: class [Ljava.lang.String;, size: 824 bytes
Object type: class java.util.ArrayList, size: 40 bytes
Object type: class java.util.ArrayList, size: 40 bytes
Object type: class java.util.ArrayList, size: 40 bytes
Object type: class java.util.ArrayList, size: 40 bytes
Object type: class java.lang.String, size: 32 bytes
Object type: class java.lang.String, size: 32 bytes
Object type: class java.lang.String, size: 32 bytes
```

Let's manually analyse and calculate their memory usage:

- **Person p**: 16 bytes (object header) + 8 bytes (string reference) + 4 bytes (int) + 8 bytes (long) + 1 byte (boolean) + 8 bytes (byte reference) + 3 bytes (padding) = 48 bytes. Total size: 48 + (24 + 4 * 8) = 104 bytes (`password`: 24 + size + pad, size = 0, pad = 0).
- **int[] a0 = {}**: output: 24 bytes (size = 0, pad = 0).
- **int[] a1 = {1}**: output: 32 bytes (size = 4, pad = 4).
- **int[] a2 = {1, 2}**: output: 32 bytes (size = 4 * 2, pad = 0).
- **int[] a3 = new int[100]**: output: 424 bytes (size = 4 * 100, pad = 0). 
- **String[] b0 = {}**: output: 24 bytes (size = 0, pad = 0).
- **String[] b1 = {"1"}**: output: 32 bytes (size = 8, pad = 0).
- **String[] b2 = {"1", "2"}**: output: 40 bytes (size = 8 * 2, pad = 0).
- **String[] b3 = new String[100]**: output: 824 bytes (size = 8 * 100, pad = 0).

We assume that all Person references are different in `List<Person>` (40 bytes + 8 bytes/entry):

- **List<Person> al0**: output: 40 bytes, real size = total size = 40 bytes.
- **List<Person> al1**: output: 40 bytes, real size: 40 + 8 = 48 bytes. Total size: 48 + 104 = 152 bytes.
- **List<Person> al2**: output: 40 bytes, real size: 40 + 8 * 2 = 56 bytes. Total size: 56 + 104 * 2 = 264 bytes.
- **List<Person> al3**: output: 40 bytes, real size: 40 + 8 * 100 = 840 bytes. Total size: 840 + 104 * 100 = 11240 bytes.

- **String s0 = ""**: output: 32 bytes, total size = 32 bytes.
- **String s1 = "hello"**: output: 32 bytes, total size = 32 + 2 * 5 + 6 (pad) = 48 bytes.

After studying the size of the Java object, let's estimate the various Java objects in the Namenode.

## File and Directory

Namenode maintains a directory tree for HDFS and a mapping of file blocks to datanodes where the data is stored. Similar to the traditional stand-alone file system, the directory structure of HDFS is also a tree structure. HDFS Namespace stores all the attributes of each directory/file node in the directory tree, including: name, number (id), user, group, permission, modification time, access time, subdirectory/file (children) and other information which exist in the Namenode's memory at runtime. You can find more details in [Section 3.1](https://dsl-umd.github.io/docs/metadata/namespace/index.html).

The memory usage of each attribute in inode is shown in the table.

<table class="tg">
<thead>
  <tr>
    <th class="tg-0lax">Class</th>
    <th class="tg-0lax">Type</th>
    <th class="tg-0lax">Members</th>
    <th class="tg-0lax">Size (bytes)</th>
    <th class="tg-0lax">Total</th>
  </tr></thead>
  <tbody>
  <tr>
    <td class="tg-0lax" rowspan="2">Inode</td>
    <td class="tg-0lax">#</td>
    <td class="tg-0lax">Object header</td>
    <td class="tg-0lax">16</td>
    <td class="tg-0lax" rowspan="2">24</td>
  </tr>
  <tr>
    <td class="tg-0lax">INode ref</td>
    <td class="tg-0lax">parent</td>
    <td class="tg-0lax">8</td>
  </tr>
  <tr>
    <td class="tg-0lax" rowspan="8">INodeWithAdditionalFields</td>
    <td class="tg-0lax">#</td>
    <td class="tg-0lax">Object header</td>
    <td class="tg-0lax">16</td>
    <td class="tg-0lax" rowspan="8">256 (assume num(bytes) = 104, num(feature) = 2)</td>
  </tr>
  <tr>
    <td class="tg-0lax">long</td>
    <td class="tg-0lax">id</td>
    <td class="tg-0lax">8</td>
  </tr>
  <tr>
    <td class="tg-0lax">byte[]</td>
    <td class="tg-0lax">name</td>
    <td class="tg-0lax">8 + 24 + 1*num(bytes) + pad</td>
  </tr>
  <tr>
    <td class="tg-0lax">long</td>
    <td class="tg-0lax">permission</td>
    <td class="tg-0lax">8</td>
  </tr>
  <tr>
    <td class="tg-0lax">long</td>
    <td class="tg-0lax">modificationTime</td>
    <td class="tg-0lax">8</td>
  </tr>
  <tr>
    <td class="tg-0lax">long</td>
    <td class="tg-0lax">accessTime</td>
    <td class="tg-0lax">8</td>
  </tr>
  <tr>
    <td class="tg-0lax">LinkedElement ref</td>
    <td class="tg-0lax">next</td>
    <td class="tg-0lax">8 + 16 = 24</td>
  </tr>
  <tr>
    <td class="tg-0lax">Feature[]</td>
    <td class="tg-0lax">features</td>
    <td class="tg-0lax">8 + 24 + 8*num(feature)</td>
  </tr>
  <tr>
    <td class="tg-0lax" rowspan="3">INodeFile</td>
    <td class="tg-0lax">#</td>
    <td class="tg-0lax">Object header</td>
    <td class="tg-0lax">16</td>
    <td class="tg-0lax" rowspan="3">56+8*num(blocks)</td>
  </tr>
  <tr>
    <td class="tg-0lax">long</td>
    <td class="tg-0lax">header</td>
    <td class="tg-0lax">8</td>
  </tr>
  <tr>
    <td class="tg-0lax">BlockInfo[]</td>
    <td class="tg-0lax">blocks</td>
    <td class="tg-0lax">8 + 24 + 8*num(blocks)</td>
  </tr>
  <tr>
    <td class="tg-0lax" rowspan="2">INodeDirectory</td>
    <td class="tg-0lax">#</td>
    <td class="tg-0lax">Object header</td>
    <td class="tg-0lax">16</td>
    <td class="tg-0lax" rowspan="2">64+8*num(children)</td>
  </tr>
  <tr>
    <td class="tg-0lax">ArrayList</td>
    <td class="tg-0lax">children</td>
    <td class="tg-0lax">8 + 40 + 8*num(children)</td>
  </tr>
  <tr>
    <td class="tg-0lax" rowspan="5">INodeDirectory.withQuotaFeature</td>
    <td class="tg-0lax">#</td>
    <td class="tg-0lax">Object header</td>
    <td class="tg-0lax">16</td>
    <td class="tg-0lax" rowspan="5">48</td>
  </tr>
  <tr>
    <td class="tg-0lax">long</td>
    <td class="tg-0lax">nsQuota</td>
    <td class="tg-0lax">8</td>
  </tr>
  <tr>
    <td class="tg-0lax">long</td>
    <td class="tg-0lax">NameSpace</td>
    <td class="tg-0lax">8</td>
  </tr>
  <tr>
    <td class="tg-0lax">long</td>
    <td class="tg-0lax">ssQuota</td>
    <td class="tg-0lax">8</td>
  </tr>
  <tr>
    <td class="tg-0lax">long</td>
    <td class="tg-0lax">StorageSpace</td>
    <td class="tg-0lax">8</td>
  </tr>
  </tbody>
</table>

In addition to the attributes mentioned in the table, some non-generic attributes like access control lists are not counted. If the cluster has features such as ACL/Snapshot, you need to increase this memory overhead. In most cases, `INodeFile`, `INodeDirectory` and `withQuotaFeature` will suffice. 

`INodeMap` also stores lots of INode references which need to be counted.

<table class="tg">
<thead>
  <tr>
    <th class="tg-0lax">Class</th>
    <th class="tg-0lax">Type</th>
    <th class="tg-0lax">Members</th>
    <th class="tg-0lax">Size (bytes)</th>
    <th class="tg-0lax">Total</th>
  </tr></thead>
  <tbody>
  <tr>
    <td class="tg-0lax" rowspan="6">LightWeightGSet</td>
    <td class="tg-0lax">#</td>
    <td class="tg-0lax">Object header</td>
    <td class="tg-0lax">16</td>
    <td class="tg-0lax" rowspan="6">68 + 8 * num(files)</td>
  </tr>
  <tr>
    <td class="tg-0lax">LinkedElement[]</td>
    <td class="tg-0lax">entries</td>
    <td class="tg-0lax">8+24+8*num(files)</td>
  </tr>
  <tr>
    <td class="tg-0lax">int</td>
    <td class="tg-0lax">hash_mask</td>
    <td class="tg-0lax">4</td>
  </tr>
  <tr>
    <td class="tg-0lax">int</td>
    <td class="tg-0lax">size</td>
    <td class="tg-0lax">4</td>
  </tr>
  <tr>
    <td class="tg-0lax">int</td>
    <td class="tg-0lax">modification</td>
    <td class="tg-0lax">4</td>
  </tr>
  <tr>
    <td class="tg-0lax">interface Collection</td>
    <td class="tg-0lax">values</td>
    <td class="tg-0lax">8</td>
  </tr>
  <tr>
    <td class="tg-0pky" rowspan="2">INodeMap</td>
    <td class="tg-0pky">#</td>
    <td class="tg-0pky">Object header</td>
    <td class="tg-0pky">16</td>
    <td class="tg-0pky" rowspan="2">92 + 8 * num(files)</td>
  </tr>
  <tr>
    <td class="tg-0pky">LightWeightGSet&lt;INode, INodeWithAdditionalFields&gt;</td>
    <td class="tg-0pky">map</td>
    <td class="tg-0pky">8 + 68 + 8 * num(files)</td>
  </tr>
    </tbody>
</table>


An estimating formula for the total size:

```bash
Total(files) = (24 + 256 + 56) * num(files) + 8 * num(blocks)
             = 336 * num(files) + 8 * num(blocks)

Total(directories) = (24 + 256 + 64 + 48) * num(diretories) + 8 * num(children)
                   = 392 * num(diretories) + 8 * num(children)
                   = 400 * num(diretories) + 8 * num(files)

Total(INodeMap) = 92 + 8 * num(files)

Total = Total(files) + Total(directories) + Total(INodeMap)
      = 400 * num(diretories) + 352 * num(files) + 8 * num(blocks) + 92
```

> Note: From the parent-child relationship of the directory tree, **num(children) = num(directories) + num(files)**.


By assuming the number of directories, files, and data blocks, we estimate how much memory these data structures consume.

| # directories | # files     | # blocks    | Total Size |
|---------------|-------------|-------------|------------|
| 10 Million    | 10 Million  | 100 Million | 7.74 GB    |
| 100 Million   | 100 Million | 1 Billion   | 77.48 GB   |
| 1 Billion     | 1 Billion   | 10 Billion  | 774.86 GB  |


The namespace is resident in the JVM heap memory. To ensure the reliability of the data, the Namenode periodically make a checkpoint and materializes the namespace to the external storage device. When data continues to grow exponentially, the number of files/directories will also increase, and eventually, memory will grow linearly proportional to the number of files/directories. The 3nd tuple from the above table shows that the total memory consumed (774.86 GB) has far exceeded the capacity of a typical server.

**From this we can conclude that the bottleneck of HDFS is here!**

## Data Block

HDFS splits a file into multiple data blocks. To ensure data reliability, each block has multiple replicas and are stored on different Datanodes in the cluster. In addition to maintaining the information of the `Block` itself, the Namenode also needs to maintain the correspondence from the data block to Datanodes, which is used to describe the physical location of each replica. The `BlocksMap` structure in the BlockManager is used for the mapping relation between `Block` and `BlockInfo`. You can find more details in [Section 3.2](https://dsl-umd.github.io/docs/metadata/datablock/index.html) we introduced before.

BlocksMap performed multiple refactoring optimizations.  NameNode used a `java.util.HashMap` to store `BlockInfo` objects. When there are many blocks in HDFS, this map uses a lot of memory in the NameNode. They optimized the memory usage by a light weight hash table implementation which is `LightWeightGSet` instead of HashMap. It uses an array for storing the elements and linked lists for collision resolution, which performs better in terms of ease of use, memory footprint and performance. For details on LightWeightGSet, please refer to [HDFS-1114](https://issues.apache.org/jira/browse/HDFS-1114).


> In order to avoid collision conflicts, BlocksMap allocates **2%** of total memory as the index space of `LightWeightGSet` ([BlockManager.java#L464-L466](https://github.com/DSL-UMD/hadoop-calvin/blob/838a740157e153c338056f9ffdbf1c606e3dcd8a/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/blockmanagement/BlockManager.java#L464-L466)).

The memory usage of each attribute in BlocksMap, Block and BlockInfo is shown in the following table.

<table class="tg">
<thead>
  <tr>
    <th class="tg-0lax">Class</th>
    <th class="tg-0lax">Type</th>
    <th class="tg-0lax">Members</th>
    <th class="tg-0lax">Size (bytes)</th>
    <th class="tg-0lax">Total</th>
  </tr></thead>
  <tbody>
  <tr>
    <td class="tg-0lax" rowspan="4">Block</td>
    <td class="tg-0lax">#</td>
    <td class="tg-0lax">Object header</td>
    <td class="tg-0lax">16</td>
    <td class="tg-0lax" rowspan="4">40</td>
  </tr>
  <tr>
    <td class="tg-0lax">long</td>
    <td class="tg-0lax">blockid</td>
    <td class="tg-0lax">8</td>
  </tr>
  <tr>
    <td class="tg-0lax">long</td>
    <td class="tg-0lax">numBytes</td>
    <td class="tg-0lax">8</td>
  </tr>
  <tr>
    <td class="tg-0lax">long</td>
    <td class="tg-0lax">generationStamp</td>
    <td class="tg-0lax">8</td>
  </tr>
  <tr>
    <td class="tg-0lax" rowspan="6">BlockInfo</td>
    <td class="tg-0lax">#</td>
    <td class="tg-0lax">Object header</td>
    <td class="tg-0lax">16</td>
    <td class="tg-0lax" rowspan="6">~90</td>
  </tr>
  <tr>
    <td class="tg-0lax">short</td>
    <td class="tg-0lax">replication</td>
    <td class="tg-0lax">2</td>
  </tr>
  <tr>
    <td class="tg-0lax">long</td>
    <td class="tg-0lax">bcId</td>
    <td class="tg-0lax">8</td>
  </tr>
  <tr>
    <td class="tg-0lax">LinkedElement Ref</td>
    <td class="tg-0lax">nextLinkedElement</td>
    <td class="tg-0lax">8</td>
  </tr>
  <tr>
    <td class="tg-0lax">DatanodeStorageInfo[]</td>
    <td class="tg-0lax">storages</td>
    <td class="tg-0lax">8+24+8*r(3)=56</td>
  </tr>
  <tr>
    <td class="tg-0lax">BlockUnderConstructionFeature</td>
    <td class="tg-0lax">uc</td>
    <td class="tg-0lax">not counted (dynamic)</td>
  </tr>
  <tr>
    <td class="tg-0lax" rowspan="7">LightWeightGSet</td>
    <td class="tg-0lax">#</td>
    <td class="tg-0lax">Object header</td>
    <td class="tg-0lax">16</td>
    <td class="tg-0lax" rowspan="7">68 + 8*num(blocks) + 2%*size(total memory)</td>
  </tr>
  <tr>
    <td class="tg-0lax">LinkedElement[]</td>
    <td class="tg-0lax">entries</td>
    <td class="tg-0lax">8+24+8*num(blocks)</td>
  </tr>
  <tr>
    <td class="tg-0lax">int</td>
    <td class="tg-0lax">hash_mask</td>
    <td class="tg-0lax">4</td>
  </tr>
  <tr>
    <td class="tg-0lax">int</td>
    <td class="tg-0lax">size</td>
    <td class="tg-0lax">4</td>
  </tr>
  <tr>
    <td class="tg-0lax">int</td>
    <td class="tg-0lax">modification</td>
    <td class="tg-0lax">4</td>
  </tr>
  <tr>
    <td class="tg-0lax">interface Collection&lt;E&gt;</td>
    <td class="tg-0lax">values</td>
    <td class="tg-0lax">8</td>
  </tr>
  <tr>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">Index Space</td>
    <td class="tg-0lax">2%*total memory</td>
  </tr>
  <tr>
    <td class="tg-0lax" rowspan="5">BlocksMap</td>
    <td class="tg-0lax">#</td>
    <td class="tg-0lax">Object header</td>
    <td class="tg-0lax">16</td>
    <td class="tg-0lax" rowspan="5">116+8*num(blocks)+2%*total memory</td>
  </tr>
  <tr>
    <td class="tg-0lax">int</td>
    <td class="tg-0lax">capacity</td>
    <td class="tg-0lax">8</td>
  </tr>
  <tr>
    <td class="tg-0lax">LightWeightGSet</td>
    <td class="tg-0lax">blocks</td>
    <td class="tg-0lax">8+68+8*num(blocks)+2%*total memory</td>
  </tr>
  <tr>
    <td class="tg-0lax">LongAdder</td>
    <td class="tg-0lax">totalReplicatedBlocks</td>
    <td class="tg-0lax">8</td>
  </tr>
  <tr>
    <td class="tg-0lax">LongAdder</td>
    <td class="tg-0lax">totalECBlockGroups</td>
    <td class="tg-0lax">8</td>
  </tr>
  </tbody>
</table>

> Note: The hash table elements are required to implement a new interface, called `LinkedElement`, which provides `setNext` and `getNex` to perations. Then, the hash table entries store references to `LinkedElement` objects. These objects are the heads of linked lists. For linked lists, the memory overhead is 8 bytes per element in 64-bit JVMs.

HDFS uses `LightWeightGSet` to optimize memory usage, but `BlocksMap` still occupies a large amount of memory space. Assuming that there are 10 million or 100 million data blocks across the cluster and the total memory of the NameNode is 256GB, the BlocksMap, Block and BlockInfo will take up a lot of memory:

```bash
Total = Total(Block) + Total(BlockInfo) + Total(BlocksMap)
      = (Block + BlockInfo) * num(blocks) + Total(BlocksMap)
      = (40 + 90) * num(blocks) + 116 + 8 * num(blocks)
      = (138 * num(blocks) + 116) / 2^30 (GB)
```

| # blocks   | Total Size |
|------------|------------|
| 10 Million | 1.28 GB    |
| 100 Million| 12.85 GB   |
| 1 Billion  | 128.52 GB  |
| 10 Billion | 1285.23 GB |

In addition to INode, **Block, BlockInfo and BlocksMap are also the scalability bottleneck of HDFS.**

## Datanode Storage


Since Datanode generally mounts multiple different types of storages such as HDD, SSD, RAM, etc.
Each Datanode (`DatanodeDescriptor.storageMap` in the table below) is treated as a collection of storages. A storage in Datanode is represented by `DatanodeStorageInfo`.  More details can be found in [Section 3.3 - Datanode Storage](https://dsl-umd.github.io/docs/metadata/datanode/index.html).

<table class="tg">
<thead>
  <tr>
    <th class="tg-0lax">Class</th>
    <th class="tg-0lax">Type</th>
    <th class="tg-0lax">Members</th>
    <th class="tg-0lax">Size (bytes)</th>
    <th class="tg-0lax">Total</th>
  </tr></thead>
  <tbody>
  <tr>
    <td class="tg-0pky" rowspan="13">DatanodeStorageInfo</td>
    <td class="tg-0pky">#</td>
    <td class="tg-0pky">Object header</td>
    <td class="tg-0pky">16</td>
    <td class="tg-0pky" rowspan="13">177</td>
  </tr>
  <tr>
    <td class="tg-0pky">DatanodeDescriptor</td>
    <td class="tg-0pky">dn</td>
    <td class="tg-0pky">8</td>
  </tr>
  <tr>
    <td class="tg-0pky">String</td>
    <td class="tg-0pky">storageID</td>
    <td class="tg-0pky">8+32+2*32=104</td>
  </tr>
  <tr>
    <td class="tg-0pky">Enum(bool)</td>
    <td class="tg-0pky">storageType</td>
    <td class="tg-0pky">1</td>
  </tr>
  <tr>
    <td class="tg-0pky">Enum(short)</td>
    <td class="tg-0pky">state</td>
    <td class="tg-0pky">2</td>
  </tr>
  <tr>
    <td class="tg-0pky">long</td>
    <td class="tg-0pky">capacity</td>
    <td class="tg-0pky">8</td>
  </tr>
  <tr>
    <td class="tg-0pky">long</td>
    <td class="tg-0pky">dfsUsed</td>
    <td class="tg-0pky">8</td>
  </tr>
  <tr>
    <td class="tg-0pky">long</td>
    <td class="tg-0pky">remaining</td>
    <td class="tg-0pky">8</td>
  </tr>
  <tr>
    <td class="tg-0pky">long</td>
    <td class="tg-0pky">blockPoolUsed</td>
    <td class="tg-0pky">8</td>
  </tr>
  <tr>
    <td class="tg-0pky">FoldedTreeSet ref</td>
    <td class="tg-0pky">blocks</td>
    <td class="tg-0pky">8</td>
  </tr>
  <tr>
    <td class="tg-0pky">int</td>
    <td class="tg-0pky">blockReportCount</td>
    <td class="tg-0pky">4</td>
  </tr>
  <tr>
    <td class="tg-0pky">boolean</td>
    <td class="tg-0pky">heartbeatedSinceFailover</td>
    <td class="tg-0pky">1</td>
  </tr>
  <tr>
    <td class="tg-0pky">boolean</td>
    <td class="tg-0pky">blockContentsStale</td>
    <td class="tg-0pky">1</td>
  </tr>
  <tr>
    <td class="tg-0pky" rowspan="14">DatanodeDescriptor</td>
    <td class="tg-0pky">#</td>
    <td class="tg-0pky">Object header</td>
    <td class="tg-0pky">16</td>
    <td class="tg-0pky" rowspan="14">406</td>
  </tr>
  <tr>
    <td class="tg-0pky">LeavingServiceStatus ref</td>
    <td class="tg-0pky">leavingServiceStatus</td>
    <td class="tg-0pky">8</td>
  </tr>
  <tr>
    <td class="tg-0pky">HashMap&lt;StorageID, DatanodeStorageInfo&gt;</td>
    <td class="tg-0pky">storageMap</td>
    <td class="tg-0pky">8+40+(storageID+8+DatanodeStorageInfo)*3=48+(104+8+177)=337</td>
  </tr>
  <tr>
    <td class="tg-0pky">long</td>
    <td class="tg-0pky">lastCachingDirectiveSentTimeMs</td>
    <td class="tg-0pky">8</td>
  </tr>
  <tr>
    <td class="tg-0pky">boolean</td>
    <td class="tg-0pky">isAlive</td>
    <td class="tg-0pky">1</td>
  </tr>
  <tr>
    <td class="tg-0pky">boolean</td>
    <td class="tg-0pky">needKeyUpdate</td>
    <td class="tg-0pky">1</td>
  </tr>
  <tr>
    <td class="tg-0pky">boolean</td>
    <td class="tg-0pky">forceRegistration</td>
    <td class="tg-0pky">1</td>
  </tr>
  <tr>
    <td class="tg-0pky">long</td>
    <td class="tg-0pky">bandwidth</td>
    <td class="tg-0pky">8</td>
  </tr>
  <tr>
    <td class="tg-0pky">long</td>
    <td class="tg-0pky">lastBlocksScheduledRollTime</td>
    <td class="tg-0pky">8</td>
  </tr>
  <tr>
    <td class="tg-0pky">int</td>
    <td class="tg-0pky">volumeFailures</td>
    <td class="tg-0pky">4</td>
  </tr>
  <tr>
    <td class="tg-0pky">VolumeFailureSummary</td>
    <td class="tg-0pky">volumeFailureSummary</td>
    <td class="tg-0pky">8</td>
  </tr>
  <tr>
    <td class="tg-0pky">boolean</td>
    <td class="tg-0pky">disallowed</td>
    <td class="tg-0pky">1</td>
  </tr>
  <tr>
    <td class="tg-0pky">int</td>
    <td class="tg-0pky">pendingReplicationWithoutTargets</td>
    <td class="tg-0pky">4</td>
  </tr>
  <tr>
    <td class="tg-0pky">boolean</td>
    <td class="tg-0pky">heartbeatedSinceRegistration</td>
    <td class="tg-0pky">1</td>
  </tr>
  <tr>
    <td class="tg-0pky" rowspan="16">DatanodeInfo</td>
    <td class="tg-0pky">#</td>
    <td class="tg-0pky">Object header</td>
    <td class="tg-0pky">16</td>
    <td class="tg-0pky" rowspan="16">556</td>
  </tr>
  <tr>
    <td class="tg-0pky">long</td>
    <td class="tg-0pky">capacity</td>
    <td class="tg-0pky">8</td>
  </tr>
  <tr>
    <td class="tg-0pky">long</td>
    <td class="tg-0pky">dfsUsed</td>
    <td class="tg-0pky">8</td>
  </tr>
  <tr>
    <td class="tg-0pky">long</td>
    <td class="tg-0pky">nonDfsUsed</td>
    <td class="tg-0pky">8</td>
  </tr>
  <tr>
    <td class="tg-0pky">long</td>
    <td class="tg-0pky">remaining</td>
    <td class="tg-0pky">8</td>
  </tr>
  <tr>
    <td class="tg-0pky">long</td>
    <td class="tg-0pky">blockPoolUsed</td>
    <td class="tg-0pky">8</td>
  </tr>
  <tr>
    <td class="tg-0pky">long</td>
    <td class="tg-0pky">cacheCapacity</td>
    <td class="tg-0pky">8</td>
  </tr>
  <tr>
    <td class="tg-0pky">long</td>
    <td class="tg-0pky">cacheUsed</td>
    <td class="tg-0pky">8</td>
  </tr>
  <tr>
    <td class="tg-0pky">long</td>
    <td class="tg-0pky">lastUpdate</td>
    <td class="tg-0pky">8</td>
  </tr>
  <tr>
    <td class="tg-0pky">long</td>
    <td class="tg-0pky">lastUpdateMonotonic</td>
    <td class="tg-0pky">8</td>
  </tr>
  <tr>
    <td class="tg-0pky">int</td>
    <td class="tg-0pky">xceiverCount</td>
    <td class="tg-0pky">4</td>
  </tr>
  <tr>
    <td class="tg-0pky">String</td>
    <td class="tg-0pky">location (network topology)</td>
    <td class="tg-0pky">8+32+2*50=140</td>
  </tr>
  <tr>
    <td class="tg-0pky">String</td>
    <td class="tg-0pky">softwareVersion</td>
    <td class="tg-0pky">8+32+2*8=56</td>
  </tr>
  <tr>
    <td class="tg-0pky">List&lt;String&gt;</td>
    <td class="tg-0pky">dependentHostNames</td>
    <td class="tg-0pky">8+40+(8+32+2*16)*2=192</td>
  </tr>
  <tr>
    <td class="tg-0pky">String</td>
    <td class="tg-0pky">upgradeDomain</td>
    <td class="tg-0pky">8+32+2*16=72</td>
  </tr>
  <tr>
    <td class="tg-0pky">int</td>
    <td class="tg-0pky">numBlocks</td>
    <td class="tg-0pky">4</td>
  </tr>
  <tr>
    <td class="tg-0pky" rowspan="9">DatanodeID</td>
    <td class="tg-0pky">#</td>
    <td class="tg-0pky">Object header</td>
    <td class="tg-0pky">16</td>
    <td class="tg-0pky" rowspan="9">544</td>
  </tr>
  <tr>
    <td class="tg-0pky">String</td>
    <td class="tg-0pky">ipAddr</td>
    <td class="tg-0pky">8+32+2*16=72</td>
  </tr>
  <tr>
    <td class="tg-0pky">String</td>
    <td class="tg-0pky">peerHostName</td>
    <td class="tg-0pky">8+32+2*16=72</td>
  </tr>
  <tr>
    <td class="tg-0pky">int</td>
    <td class="tg-0pky">xferPort</td>
    <td class="tg-0pky">4</td>
  </tr>
  <tr>
    <td class="tg-0pky">int</td>
    <td class="tg-0pky">infoPort</td>
    <td class="tg-0pky">4</td>
  </tr>
  <tr>
    <td class="tg-0pky">int</td>
    <td class="tg-0pky">infoSecurePort</td>
    <td class="tg-0pky">4</td>
  </tr>
  <tr>
    <td class="tg-0pky">int</td>
    <td class="tg-0pky">ipcPort</td>
    <td class="tg-0pky">4</td>
  </tr>
  <tr>
    <td class="tg-0pky">String</td>
    <td class="tg-0pky">xferAddr</td>
    <td class="tg-0pky">8+32+2*16=72</td>
  </tr>
  <tr>
    <td class="tg-0pky">String</td>
    <td class="tg-0pky">datanodeUuid</td>
    <td class="tg-0pky">8+32+2*128=296</td>
  </tr>
  </tbody>
</table>

> Due to many dynamically changing information is not counted, results may have some errors. For example, replicateBlocks, recoverBlocks, and invalidateBlocks in DatanodeDescriptor relate to state transitions of data blocks. pendingCached, cached, and pendingUncached relate to cache.


Based on the previous analysis, let's estimate the total amount of memory that Namenode needs to maintain for this part of the information:

```bash
Total = (406 + 556 + 544) * num(datanodes) / 2^30 (GB)
```

| # datanodes | Total Size |
|-------------|------------|
| 1000        | 1.43MB     |
| 10000       | 14.36MB    |
| 100000      | 143.62MB   |
| 1000000     | 1.40GB     |
| 10000000    | 14.03GB    |

**When the number of Datanodes reaches tens of millions or even hundreds of millions, the metadata of Datanodes in Namenode is not the bottleneck of HDFS. We don't need to put DatanodeDescriptor and DatanodeStorageInfo into the database system!**

## Conclusion

In this section, we quantify the memory usage of various objects. The memory consumption comes mainly from the size of the objects themselves (`INodeFile`, `INodeDirectory`, `Block` and `BlockInfo`) and their references in two hash tables, that is, `INodesMap` and `BlocksMap`.

The metadata of Datanode (`DatanodeStorageInfo` and `DatanodeDescriptor`) is not a bottleneck because the number of horizontal expansion of the Datanode grows very slowly compared to the exponential growth of the data (files and blocks).

    The relation for Datanode metadata can be discarded.

    <S>

    ```sql
    CREATE TABLE datanodeStorageInfo(
        storageID text primary key, storageType int, State int,
        capacity bigint, dfsUsed bigint, nonDfsUsed bigint, remaining bigint,
        blockPoolUsed bigint, blockReportCount int, heartbeatedSinceFailover boolean,
        blockContentsStale boolean, datanodeUuid text
    );

    DROP TABLE IF EXISTS datanodeDescriptor;
    CREATE TABLE datanodeDescriptor(
        datanodeUuid text primary key, datanodeUuidBytes bytea, ipAddr text,
        ipAddrBytes bytea, hostName text, hostNameBytes bytea, peerHostName text,
        xferPort int, infoPort int, infoSecurePort int, ipcPort int, xferAddr text, 
        capacity bigint, dfsUsed bigint, nonDfsUsed bigint, remaining bigint,
        blockPoolUsed bigint, cacheCapacity bigint, cacheUsed bigint, lastUpdate bigint, 
        lastUpdateMonotonic bigint, xceiverCount int, location text, softwareVersion text,
        dependentHostNames text[], upgradeDomain text, numBlocks int, adminState text,
        maintenanceExpireTimeInMS bigint, lastBlockReportTime bigint, lastBlockReportMonotonic bigint,
        lastCachingDirectiveSentTimeMs bigint, isAlive boolean, needKeyUpdate boolean,
        forceRegistration boolean, bandwidth bigint, lastBlocksScheduledRollTime bigint,
        disallowed boolean, pendingReplicationWithoutTargets int, heartbeatedSinceRegistration boolean 
    );
    ```

    </S>

We can solve this problem in two directions:

- Objects: We can remove all attributes of `INodeFile`, `INodeDirectory`, `Block` and `BlockInfo` and put them into the deterministic database system. Their data models are as follows:

```sql
CREATE TABLE inodes(
    id int primary key, parent int, name text,
    accessTime bigint, modificationTime bigint,
    header bigint, permission bigint, blockIds bigint[]
);
```

<table><tr><th>  ID      </th><th> parent   </th><th>  name    </th><th> accesstime  </th><th> modificationtime </th><th>  header  </th><th> permission  </th><th> blockId </th></tr></table>

```sql
CREATE TABLE datablocks(
    blockId bigint primary key, numBytes bigint, generationStamp bigint,
    eplication int, bcId bigint
);
```

<table><tr><th>  blockId </th><th> numBytes   </th><th>  generationStamp    </th><th> eplication  </th><th> bcId </th></tr></table>

- Object References: We might also put serialized key-value into the deterministic database system.
Or, implement a DHT (distributed hash table) to replace `INodesMap` and `BlocksMap`.



## References

1. How to Get the Size of an Object in Java, https://www.baeldung.com/java-size-of-object
2. Java Object Size Calculations in 64-bit, http://btoddb-java-sizing.blogspot.com/
3. Java objects memory size, http://iryndin.net/post/java_objects_memory_size/
4. Nick Mitchell, Gary Sevitsky, Building Memory-efficient Java Applications: Practices and Challenges, http://www.iro.umontreal.ca/~dufour/cours/ift3912/docs/12-memory-efficient-java.pdf