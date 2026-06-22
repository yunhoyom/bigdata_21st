create table products (
	id	serial primary key,
	name	text not null,
	price	integer not null
);

insert into products(name, price) values
('keyboard', 30000),
('mouse', 15000);