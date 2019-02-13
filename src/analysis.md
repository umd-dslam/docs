# Quantitative Analysis

The purpose of this session is to find the memory bottleneck by quantifying the memory footprint of various data structures in HDFS. Data structures that are not bottlenecks will remain in the Namenode's memory, but the bottleneck part needs to be transferred to the distributed deterministic database to improve the overall scalability of HDFS.

> Note: Here we only make a rough estimate of the size of different objects. Optimizatins like reordering object properties and memory layout of super/subclasses in JVM heap allocation were not considered. But this does not affect the final result.

## Java Object Size

One way to get an estimate of an object's size in Java is to use `getObjectSize(Object)` method of the [Instrumentation interface](https://docs.oracle.com/javase/7/docs/api/java/lang/instrument/Instrumentation.html) introduced in Java. We provide the [InstrumentationAgent](https://github.com/DSL-UMD/hadoop-calvin/pull/1/files#diff-5cbfd1caf17137e9459de168b90ef12e) is based on that.
However, this approach **only supports** size estimation of the considered object itself and not the sizes of objects it references. To estimate a total size of the object, we have to go over those references and calculate the estimated size.

### Primitives

We know the size of each primitive from the Java specification. What isn't stated in the specification is how much heap space they use. It seems to be JVM implementation dependent.
Below is a table that shows each primitive's size and how much heap it may use on my JVM.
Be aware because of "8 byte alignment" and "padding" that a primitive such as a byte or boolean, can be packed together to take up less memory, and this table only shows the maximum space it can use.

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

References have a typical size of 4 bytes on 32-bit platforms and on 64-bits platforms with heap boundary less than 32GB, and 8 bytes for this boundary above 32GB. We are working with large heaps and need to assume that all references are 8 bytes ([UseCompressedOops](https://www.oracle.com/technetwork/java/javase/tech/vmoptions-jsp-140102.html) is false).

### Object Header

In a modern 64-bit JDK, an object has a 12-byte header, padded to a multiple of 8 bytes, so the minimum object size is 16 bytes.


## File and Directory

Namenode maintains a directory tree for HDFS and a mapping of file blocks to datanodes where the data is stored. Similar to the traditional stand-alone file system, the directory structure of HDFS is also a tree structure. HDFS Namespace stores all the attributes of each directory/file node in the directory tree, including: name, number (id), user, group, permission, modification time, access time, subdirectory/file (children) and other information which exist in the Namenode's memory at runtime. You can find more details in [Section 3.1](https://dsl-umd.github.io/docs/metadata/namespace/index.html).

The memory usage of each attribute in inode is shown in the table.


## Data Block


## Datanode Storage


## Conclusion

## References

1. How to Get the Size of an Object in Java: https://www.baeldung.com/java-size-of-object
2. Java Object Size Calculations in 64-bit: http://btoddb-java-sizing.blogspot.com/