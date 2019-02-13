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
| char       | 16           | 16                     |


### Object References

References have a typical size of 4 bytes on 32-bit platforms and on 64-bits platforms with heap boundary less than 32GB, and 8 bytes for this boundary above 32GB. We are working with large heaps and need to assume that all references are 8 bytes (You can disable it through **-XX:-UseCompressedOops**, [UseCompressedOops](https://www.oracle.com/technetwork/java/javase/tech/vmoptions-jsp-140102.html) is on by default).

### Object Header

In a modern 64-bit JDK, an object has a 12-byte header, padded to a multiple of 8 bytes, so the minimum object size is 16 bytes in the following form:

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

All arrays have an extra integer `length` field stored in their header, which means that an array's header uses 24 bytes even if it has no data - 16 bytes for header, 4 bytes for integer length, and 4 bytes for padding. JVM will allocate a block of memory, 8 byte aligned, to contain all the elements and only padding after the end of the last element. The layout looks like this:

|     Field    | Type |   Size (bytes)  |
|:------------:|:----:|:---------------:|
| Header       |      | 16              |
| Length       | int  | 4               |
| Padding      |      | 4               |
| Memory Block |      | size            |
| Padding      |      | pad             |
| Total        |      | 24 + size + pad |

[ArrayList](https://docs.oracle.com/javase/8/docs/api/java/util/ArrayList.html) is a resizable-array implementation of the `List` interface. It has more default fields than an array such as type and capacity.

ArrayList's internal structure looks like below:

```bash
ArrayList
├── default
│
└── Object[]
    ├── entry
    ├── entry
    ├── entry
    └── entry
```

> The cost of ArrayList is 40 bytes fixed + 8 bytes/entry. However, getObjectSize(Object) can only get 40 bytes (no reference sizes).

### Example

Consider the following examples, let's calculate their memory usage:

1. Class Object

```java
class Person {
  String name;
  int age;
  boolean female;
}
```

16 bytes (object header) + 8 bytes (1 reference) + 4 bytes (int) + 1 byte (boolean) + 3 bytes (padding) = 32 bytes.

2. Arrays of Primitives/Objects

    - int[100]: 16 bytes (object header) + 4 bytes (length) + 400 bytes (100 ints) + 4 (padding) = 424 bytes.
    - String[10]: 16 bytes (object header) + 4 bytes (length) + 80 bytes (10 references) + 4 (padding) = 104 bytes.

## File and Directory

Namenode maintains a directory tree for HDFS and a mapping of file blocks to datanodes where the data is stored. Similar to the traditional stand-alone file system, the directory structure of HDFS is also a tree structure. HDFS Namespace stores all the attributes of each directory/file node in the directory tree, including: name, number (id), user, group, permission, modification time, access time, subdirectory/file (children) and other information which exist in the Namenode's memory at runtime. You can find more details in [Section 3.1](https://dsl-umd.github.io/docs/metadata/namespace/index.html).

The memory usage of each attribute in inode is shown in the table.


## Data Block


## Datanode Storage


## Conclusion

## References

1. [How to Get the Size of an Object in Java](https://www.baeldung.com/java-size-of-object)
2. [Java Object Size Calculations in 64-bit](http://btoddb-java-sizing.blogspot.com/)
3. [Java objects memory size](http://iryndin.net/post/java_objects_memory_size/)
4. Nick Mitchell, Gary Sevitsky, [Building Memory-efficient Java Applications: Practices and Challenges](http://www.iro.umontreal.ca/~dufour/cours/ift3912/docs/12-memory-efficient-java.pdf) 