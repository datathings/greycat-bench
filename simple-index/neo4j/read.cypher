
# for 20m relationships

match (r:Id)-[:Ref]->(p:Part)
where r.id = 10000011
return p.pid;

