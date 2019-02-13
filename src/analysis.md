# Quantitative Analysis

## Java Object Size

One way to get an estimate of an object's size in Java is to use `getObjectSize(Object)` method of the [Instrumentation interface](https://docs.oracle.com/javase/7/docs/api/java/lang/instrument/Instrumentation.html) introduced in Java. We provide the [InstrumentationAgent](https://github.com/DSL-UMD/hadoop-calvin/pull/1/files#diff-5cbfd1caf17137e9459de168b90ef12e) is based on that.
However, this approach **only supports** size estimation of the considered object itself and not the sizes of objects it references. To estimate a total size of the object, we have to go over those references and calculate the estimated size.



**Note:** In a modern 64-bit JDK, an object has a 12-byte header, padded to a multiple of 8 bytes, so the minimum object size is **16 bytes**. References have a typical size of 4 bytes on 32-bit platforms and on 64-bits platforms with heap boundary less than 32Gb (-Xmx32G), and **8 bytes** for this boundary above 32GB.

## File and Directory

Namenode maintains a directory tree for HDFS and a mapping of file blocks to datanodes where the data is stored. Similar to the traditional stand-alone file system, the directory structure of HDFS is also a tree structure. HDFS Namespace stores all the attributes of each directory/file node in the directory tree, including: name, number (id), user, group, permission, modification time, access time, subdirectory/file (children) and other information which exist in the Namenode's memory at runtime. You can find more details in [Section 3.1](https://dsl-umd.github.io/docs/metadata/namespace/index.html).

The memory usage of each attribute in inode is shown in the table.


## Data Block


## Datanode Storage


## Conclusion

## References

1. How to Get the Size of an Object in Java: https://www.baeldung.com/java-size-of-object