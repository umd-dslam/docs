# Data Model

In order to unlock the memory bottleneck of namenode, we propose to replace file metadata in memory with a deterministic distributed system which can improve scalability of the file system, as file metadata can be partitioned across a shared-nothing cluster of independent servers.

Singleton pattern is used to restrict the instance of [DatabaseConnection](https://github.com/DSL-UMD/hadoop-calvin/blob/calvin/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/DatabaseConnection.java) class to one object. This is useful when exactly one object is needed to coordinate actions across the system. The generic metadata storage layer we implemented can easily enable a different database to be plugged into HDFS. In this project, in order to keep it simple, we first integrate **Postgres** into HDFS to demonstrate how it works. Then, deterministic database systems like **Calvin** or **FaunaDB** can be considered as a backend later.

## CRUD Operations

We already replace fields such as **id**, **parent**, **name**, **accessTime**, **modificationTime**, **permission** and **header** with `inodes table` in Postgres. All related get/set inode functions have been modified to support database. For example, 

```java
public long getPermissionLong() {
    return this.permission;
}
private final void setPermission(long permission) {
    this.permission = permission;
}
```

has been changed to

```java
public long getPermissionLong() {
    return DatabaseConnection.getPermission(this.getId());
}
private final void setPermission(long permission) {
    DatabaseConnection.setPermission(this.getId(), permission);
}
```

### Create 

When [DatabaseConnection.getInstance()](https://github.com/DSL-UMD/hadoop-calvin/blob/c337680e23ded375df17c09a878f719102a47773/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/server/namenode/DatabaseConnection.java#L70-L77) is invoked, Object will be initialized by its constructor (only once in the lifetime of the file system), and `inodes` table also will be
created.

```sql
DROP TABLE IF EXISTS inodes;
CREATE TABLE inodes(
    id int primary key, parent int, name text,
    accessTime bigint, modificationTime bigint,
    header bigint, permission bigint
);
```

### Insert

Inserting a new inode into database is tricky. Most of the fields such as **id**, **name**, **accessTime**, **modificationTime**, **permission** are assigned during the initialization of INodeFile and INodeDirectory. However, the rest like **header** and **parent** are updated during the runtime of file operations. Therefore, at least two SQL statements are required in here.

```sql
INSERT INTO inodes(
    id, name, accessTime, modificationTime, permission
) VALUES (?, ?, ?, ?, ?);

UPDATE inodes SET parent = ?, name = ? WHERE id = ?;
```

### Select

To get one child since we have no children lists in the memory, we need both **parent** and **name** to fetch **INODE ID** because two inodes may have the same name under the different directories. 

```sql
SELECT id FROM inodes WHERE parent = ? AND name = ?;
```

Similarly, to get the 1st level children(immediate descendants), we can simply remove **name** from above SQL query:

```sql
SELECT id FROM inodes WHERE parent = ?;
```

### Delete

When working with hierarchical data, for example, remove all descendants(subtree) from one inode recursively, [CTE](https://en.wikipedia.org/wiki/Hierarchical_and_recursive_queries_in_SQL) is useful because CTE can continue to execute until the query returns the entire hierarchy.

```sql
DELETE FROM inodes WHERE id IN (
    WITH RECURSIVE cte AS (
        SELECT id, parent FROM inodes d WHERE id = ?
    UNION ALL
        SELECT d.id, d.parent FROM cte
        JOIN inodes d ON cte.id = d.parent
    )
    SELECT id FROM cte
);
```

After we implemented such functions with database API, we already get the primitives for implementing different directory tree operators. Although some intermediate object may still take some memory, it won't stay persistently in the memory and will finally be garbage collected.


Besides moving the logic and data model into database, we also have to modify the code of saving FSImage file and writing EditLog mentioned in [Section 2.1](https://dsl-umd.github.io/docs/intro/hdfs.html#persistence) to avoid read and serialize those attributes. The steps include simplifying the format of log data and protobuf image (checkpoint) and removing redundant code in saving and loading functions.


## Tables

If client creates the same directory `nnThroughputBenchmark` with 10 files again, all these fields in INode will be stored into database as follows:


|  ID      | parent   |  name                | accesstime    | modificationtime |  header         | permission    |
|----------|----------|----------------------|---------------|------------------|-----------------|---------------|
| 16385    |          |                      | 0000000000000 |    1545267685079 | 000000000000000 | 1099511693805 |
| 16386    |  16385   |nnThroughputBenchmark | 0000000000000 |    1545267685104 | 000000000000000 | 1099511693805 |
| 16389    |  16388   |ThroughputBench0      | 1545267685125 |    1545267685125 | 281474976710672 | 1099511693823 |
| 16390    |  16388   |ThroughputBench1      | 1545267685224 |    1545267685224 | 281474976710672 | 1099511693823 |
| 16391    |  16388   |ThroughputBench2      | 1545267685252 |    1545267685252 | 281474976710672 | 1099511693823 |
| 16392    |  16388   |ThroughputBench3      | 1545267685278 |    1545267685278 | 281474976710672 | 1099511693823 |
| 16388    |  16387   |ThroughputBenchDir0   | 0000000000000 |    1545267685278 | 000000000000000 | 1099511693805 |
| 16394    |  16393   |ThroughputBench4      | 1545267685319 |    1545267685319 | 281474976710672 | 1099511693823 |
| 16395    |  16393   |ThroughputBench5      | 1545267685343 |    1545267685343 | 281474976710672 | 1099511693823 |
| 16396    |  16393   |ThroughputBench6      | 1545267685370 |    1545267685370 | 281474976710672 | 1099511693823 |
| 16397    |  16393   |ThroughputBench7      | 1545267685394 |    1545267685394 | 281474976710672 | 1099511693823 |
| 16393    |  16387   |ThroughputBenchDir1   | 0000000000000 |    1545267685394 | 000000000000000 | 1099511693805 |
| 16387    |  16386   |create                | 0000000000000 |    1545267685416 | 000000000000000 | 1099511693805 |
| 16399    |  16398   |ThroughputBench8      | 1545267685421 |    1545267685421 | 281474976710672 | 1099511693823 |
| 16400    |  16398   |ThroughputBench9      | 1545267685452 |    1545267685452 | 281474976710672 | 1099511693823 |
| 16398    |  16387   |ThroughputBenchDir2   | 0000000000000 |    1545267685452 | 000000000000000 | 1099511693805 |
