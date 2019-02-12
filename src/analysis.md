# Quantitative Analysis

## Instrumentation Agent

One way to get an estimate of an object's size in Java is to use `getObjectSize(Object)` method of the [Instrumentation interface](https://docs.oracle.com/javase/7/docs/api/java/lang/instrument/Instrumentation.html) introduced in Java.
This approach only supports size estimation of the considered object itself and not the sizes of objects it references. To estimate a total size of the object, we would need a code that would go over those references and calculate the estimated size.

```java
import java.lang.instrument.Instrumentation;

public class InstrumentationAgent {
    private static volatile Instrumentation globalInstrumentation;
    public static void premain(final String agentArgs, final Instrumentation inst) {
        globalInstrumentation = inst;
    }
    public static long getObjectSize(final Object object) {
        if (globalInstrumentation == null) {
            throw new IllegalStateException("Agent not initialized.");
        }
        return globalInstrumentation.getObjectSize(object);
    }
}
```

The following example can be used to estimate the different objects and references.

```java
public class InstrumentationExample {

    public static void printObjectSize(Object object) {
        System.out.println("Object type: " + object.getClass() +
          ", size: " + InstrumentationAgent.getObjectSize(object) + " bytes");
    }

    public static void main(String[] arguments) {
        String emptyString = "";
        String string = "Estimating Object Size Using Instrumentation";
        String[] stringArray = { emptyString, string, "com.baeldung" };
        String[] anotherStringArray = new String[100];
        List<String> stringList = new ArrayList<>();
        long zeroLong = 0L;
        double zeroDouble = 0.0;
        boolean falseBoolean = false;
        Object object = new Object();

        printObjectSize(emptyString);
        printObjectSize(string);
        printObjectSize(stringArray);
        printObjectSize(anotherStringArray);
        printObjectSize(stringList);
        printObjectSize(zeroLong);
        printObjectSize(zeroDouble);
        printObjectSize(falseBoolean);
        printObjectSize(object);
    }
}
```

The output of running `InstrumentationExample` will show us estimated object sizes:

```bash
Object type: class java.lang.String, size: 24 bytes
Object type: class java.lang.String, size: 24 bytes
Object type: class [Ljava.lang.String;, size: 32 bytes
Object type: class [Ljava.lang.String;, size: 416 bytes
Object type: class java.util.ArrayList, size: 24 bytes
Object type: class java.lang.Long, size: 24 bytes
Object type: class java.lang.Double, size: 24 bytes
Object type: class java.lang.Boolean, size: 16 bytes
Object type: class java.lang.Object, size: 16 bytes
```

**Note:** In a modern 64-bit JDK, an object has a 12-byte header, padded to a multiple of 8 bytes, so the minimum object size is **16 bytes**. References have a typical size of 4 bytes on 32-bit platforms and on 64-bits platforms with heap boundary less than 32Gb (-Xmx32G), and **8 bytes** for this boundary above 32GB.

## File and Directory

Namenode maintains a directory tree for HDFS and a mapping of file blocks to datanodes where the data is stored. Similar to the traditional stand-alone file system, the directory structure of HDFS is also a tree structure. HDFS Namespace stores all the attributes of each directory/file node in the directory tree, including: name, number (id), user, group, permission, modification time, access time, subdirectory/file (children) and other information which exist in the Namenode's memory at runtime. You can find more details in [Section 3.1](https://dsl-umd.github.io/docs/metadata/namespace/index.html).

The memory usage of each attribute in inode is shown in the table.


## Data Block


## Datanode Storage


## Conclusion

## References

1. How to Get the Size of an Object in Java: https://www.baeldung.com/java-size-of-object