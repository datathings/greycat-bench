
match (t:Tran)-[:T]->(to:Person {id: 1})-->(c:Currency {name: 'JPY'})
with distinct t as dt
return count(dt), sum(dt.val);

