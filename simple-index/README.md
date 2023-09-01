
# GreyCat, Neo4j relative performance

## Scenario

The test application is completely artificial.
It models a integer serial number relation to a part object, composed of a single integer attribute.

The first test measures the insertion speed of the transaction data (generated randomly).  

The second test measures the speed of a graph query (finding the part corresponding to a serial number, which is not present).

The source code for both tests is present in the respective subdirectories: [neo4j](neo4j/), [greycat](greycat/).

## Results

| transactions | insertion | insertion | query    | query    | storage  | storage  |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| (M) | time (s)  | time (s)  | time (s) | time (s) | size(GB) | size(GB) |
|              | Neo4j     | GreyCat   | Neo4j    | GreyCat  | Neo4j*   | GreyCat  |
|      10      |   99.0   |     31.0   |   1.011  |    0.020 | 2.6 tra  |  0.26    |
|              |           |           |          |          | 2.0 db   |          |
|      20      |   170.0   |     71.0   |  1.45   |    0.023   | 5.1 tra  |  0.52    |
|              |           |           |          |          | 3.8 db   |          |

*: Neo4j disk storage is made of a transaction log (tra), and a database proper (db).  

The memory usage is mentioned in the runtime configuration.

## Comments on source code

### Neo4j

The Cypher source for both tests is [here](neo4j/).  

It is not tuned (more in the [runtime configuration](https://github.com/datathings/greycat-perf/blob/main/simple-nested/README.md#runtime-configuration)), apart from:

- split of transactions into 10K rows, which otherwise fails with memory allocation errors,
- index on serial number id.

### GreyCat

The insert and query functions share the data types, and are grouped in the same [project file](greycat/project.gcl).  
Each function can be invoked separately at the command line, such as:

```
$ rm -rf gcdata  # clear all data
$ greycat run --cache=5000 --store=5000 project.gcl insert
$ greycat run --cache=5000 --store=5000 project.gcl query
```

## Runtime configuration

### General

The test machine is a 16-core i7 clocked at 5GHz, with 32GB RAM and an NVMe disk.
The OS is Linux.   

The times are reported with the Linux `time` command.  

For Neo4j, the server is running before the test starts, with all data erased.

For GreyCat, the time reported includes the time to start and shutdown the GreyCat instance, including the synchronization of memory to disk.

### Neo4j

Neo4j is version 5.11.0, Community.

The [settings](neo4j/neo4j.conf) are derived from `neo4j-admin server memory-recommendation`.   
The only non-default settings are:
```
server.memory.heap.initial_size=11800m
server.memory.heap.max_size=11800m
server.memory.pagecache.size=12000m
server.jvm.additional=-XX:+ExitOnOutOfMemoryError
```
These memory settings lead to about 24GB of allocated memory (14GB resident).

### GreyCat

GreyCat version is 6 (beta), at time of last commit.

The memory cache is set to 5GB and the maximum disk size to 5GB.  
This totals to about 10GB of RAM allocated (virtual).  
Decreasing the cache memory delays the execution a little, yet completes successfully: 
for example: a 500MB cache decreases speed by about 10% for both insert and query.

