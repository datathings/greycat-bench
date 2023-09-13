
# GreyCat, Neo4j relative performance

## Scenario

The test application is artificial, yet attempts to represent a common graph structure.  
The data is loosely inspired from financial transactions, each includes: 

- an amount, 
- a destination (person), 
- an origin (person),
- a currency.

To evaluate graph performance, the transaction components above are modeled ***in depth***:

- the transaction (amount, identification) *links* to a destination person,
- in turn, the destination person *links* to an originator (person),
- in turn again, the originator *links* to a currency (here: EUR or JPY).

Many transactions are created.

The first test measures the insertion speed of the transaction data (generated randomly).  

The second test measures the speed of a graph query (the total amount of transactions in Japanese yens received by a particular person).

The source code for both tests is present in the respective subdirectories: [neo4j](neo4j/), [greycat](greycat/).

## Results

| transactions | insertion | insertion | query    | query    | storage  | storage  |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| (M) | time (s)  | time (s)  | time (s) | time (s) | size(GB) | size(GB) |
|              | Neo4j     | GreyCat   | Neo4j    | GreyCat  | Neo4j*   | GreyCat  |
|       0.1    |     4.2   |     0.06  |     6.0  |    0.043 | 0.26 tra |  0.0035  |
|              |           |           |          |          | 0.001 db |          |
|       1      |    18.8   |     0.45  |   n/a**  |    0.21  | 0.51 tra |  0.035   | 
|              |           |           |          |          | 0.19 db  |          |
|      10      |   160.0   |     4.1   |   n/a**  |    1.8   | 1.7 tra  |  0.34    |
|              |           |           |          |          | 3.3 db   |          |
|  11,000      |    n/a    | 11,105    |   n/a    |  4,847    |  n/a     |  400     |
|              |           | (185m5s)  |          | (80m47s) |          |          |

*: Neo4j disk storage is made of a transaction log (tra), and a database proper (db).  
**: the test failed to complete in a reasonable time (several minutes).

The memory usage is mentioned in the runtime configuration.

## Source code

### Neo4j code explanation

The final Cypher source for both tests is [here](neo4j/).  

While simple, the Neo4j scripts required several refinements.

The initial insert script (below), with default parameters for the server, was not able to complete the 10M records test case, 
and failed with `Currently using 5.4 GiB. dbms.memory.transaction.total.max threshold reached`.
```
create 
 (eur:Currency {id: 0, base: "USD", name: "EUR", rate: 0.9}),
 (jpy:Currency {id: 1, base: "USD", name: "JPY", rate: 0.007}),
 (a:Person {id: 0, name: "alice"}),
 ... (lines omitted)
 (h:Person {id: 7, name: "helen"})
;
unwind range(1, 10000000) as i
call {
	with i
	match (to:Person {id: i % 8}), (from:Person {id: (i + 4) % 8}), (c:Currency {id: i % 2})
	create (:Tran {id: i, val: 12.4 + i * 0.2})-[:T]->(to)-[:F]->(from)-[:C]->(c)
};
```
This was solved with the specification of a transaction split:
```
unwind range(1, 10000000) as i
call {
	with i
	match (to:Person {id: i % 8}), (from:Person {id: (i + 4) % 8}), (c:Currency {id: i % 2})
	create (:Tran {id: i, val: 12.4 + i * 0.2})-[:T]->(to)-[:F]->(from)-[:C]->(c)
} in transactions of 10000 rows;
```
However, the graph query (below) was unable to complete in a reasonable time.
```
match (t:Tran)-[:T]->(to:Person {id: 1})-->(c:Currency {name: 'JPY'})
with distinct t as dt
return count(dt), sum(dt.val);
```
This required reading on query tuning from the Neo4j documentation.
The LOOKUP index, present by default, suggested to specify labels, which was already the case.
Indeed, the `PROFILE` output did show that the column operator was `NodeByLabelScan`, and not `AllNodesScan`.

The Advanced query tuning example pointed to explicit index creation:
```
create index for (p:Person) on (p.id);
call db.awaitIndexes;
```
This allowed the query to complete
(profiling reported a `+DirectedRelationshipTypeScan` column operator).

Finally, the debug.log reported warnings related to the JVM memory configuration.
As suggested, `neo4j-admin memory-recommendation` output was applied to the Neo4j configuration (more in the [runtime configuration](https://github.com/datathings/greycat-perf/blob/main/simple-nested/README.md#runtime-configuration)).

In summary, 

- split of transactions into 10K rows, which otherwise fails with memory allocation errors,
- index on `Person.id`, which does speed up the read query.

This, unfortunately prevents the read query to complete with larger graph sizes.
There are surely ways to improve upon this query, but more time would be needed.

### GreyCat

After [GreyCat download](https://get.greycat.io/), no further setting was needed.

The insert and query functions share the data types, and are grouped in the same [project file](greycat/project.gcl).  
Each function can be invoked separately at the command line, such as:

```
$ rm -rf gcdata  # clear all data
$ greycat run project.gcl insert
$ greycat run project.gcl query
```

In comparison to Neo4j's Cypher language, the GreyCat Language (GCL) is imperative, which makes the code more verbose.

However, no performance tuning was necessary.

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

GreyCat version is 6 (beta).

For 0.1, 1 and 10M transactions, the memory cache is set to 5GB and the maximum disk size to 5GB.  
This totals to about 10GB of RAM allocated (virtual, about 5GB resident).  
Decreasing the cache memory delays the execution a little, yet completes successfully: 
for example: a 500MB cache decreases speed by about 10% for both insert and query.

For 11,000M transactions (11 billions), memory and storage respectively set to 20GB and 500GB (21GB resident).


