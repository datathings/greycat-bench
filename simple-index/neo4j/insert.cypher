
# for 20m relationships

unwind range(1, 20000000) as i
call {
	with i
	create (:Id {id: toInteger(rand() * 20000000)})-[:Ref]->(:Part {pid: i})
} in transactions of 10000 rows;

create index for (p:Id) on (p.id);
create index for (p:Part) on (p.pid);
call db.awaitIndexes;

