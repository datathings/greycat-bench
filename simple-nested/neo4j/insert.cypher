
create 
 (eur:Currency {id: 0, base: "USD", name: "EUR", rate: 0.9}),
 (jpy:Currency {id: 1, base: "USD", name: "JPY", rate: 0.007}),
 (a:Person {id: 0, name: "alice"}),
 (b:Person {id: 1, name: "byron"}),
 (c:Person {id: 2, name: "charles"}),
 (d:Person {id: 3, name: "deirdre"}),
 (e:Person {id: 4, name: "edmond"}),
 (f:Person {id: 5, name: "francis"}),
 (g:Person {id: 6, name: "gwen"}),
 (h:Person {id: 7, name: "helen"})
;

unwind range(1, 10000000) as i
call {
	with i
	match (to:Person {id: i % 8}), (from:Person {id: (i + 4) % 8}), (c:Currency {id: i % 2})
	create (:Tran {id: i, val: 12.4 + i * 0.2})-[:T]->(to)-[:F]->(from)-[:C]->(c)
} in transactions of 10000 rows;

create index for (p:Person) on (p.id);
call db.awaitIndexes;

