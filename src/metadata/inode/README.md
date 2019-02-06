# INode Metadata

When clients send requests for file operations (mkdir, create, open, rename, delete) through `ClientProtocol`'s RPCs, after Namenode receives requests from clients, it will forward them to the `FSNameSystem` class to proceed.

`FSNameSystem` is a container of both transient and persisted file namespace states, and does all the book-keeping work on a Namenode. Its role is briefly described below: 

- RPC calls that modify or inspect the namespace should get delegated here; 
- anything that touches only blocks (eg. block reports) is delegated to `BlockManager`;
- anything that touches only file information (eg. permissions, mkdirs) is delegated to `FSDirectory`, etc.

`FSDirectory` is a pure in-memory data structure, all of whose operations happen entirely in memory. In contrast, `FSNameSystem` persists the operations to the disk.

**Under Construction**

