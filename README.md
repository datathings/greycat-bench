# GreyCat performance information

Each performance test of GreyCat is located in a dedicated sub-directory.

As always, performance comparisons are to be taken with a grain of salt.

When comparisons are made with other software, we welcome any improvement to our implementation in that software!

Some notes on the development differences between Neo4j's Cypher and GgreyCat language are [here](https://github.com/datathings/greycat-bench/tree/main/simple-nested#neo4j-code-explanation).

| test | description |
| :--- | :--- |
| [simple nested](./simple-nested) | Neo4j / GreyCat comparison on, up-to 10M, 4-level-deep records. |
| [simple index](./simple-index) | Neo4j / GreyCat comparison on, up-to 20M, flat records with single relation. |

