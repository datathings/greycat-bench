

unwind range(1,100000) as i
with i
match (r:Id)-[:Ref]->(p:Part)
where r.id = toInteger(rand() * 20000000) 
return p.pid;

