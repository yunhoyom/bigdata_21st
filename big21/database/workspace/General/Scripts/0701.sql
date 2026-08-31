select *
  from customers c
 where c.customer_id = 5
;

-- 다중 컬럼 수정
update customers
   set email='user5@gmail.com',
   	   phone='010-1234-1234'
 where customer_id = 5
;

select count(p.*)
  from products p	-- 카테고리명을 알 수 없다.
  join categories c on c.category_id = p.category_id
 where c."name" = '전자제품'
;

select c."name"
  from categories c
;

-- 입고 테이블
create table restock(
	product_id		integer		not null
	, quantity		integer		not null 
);

-- 1번 상품 30개, 3번 상품 50개 입고
insert into restock
values (1, 30), (3, 50);

--1	209
--3	368

--1	239
--3	418

select * from restock r;

-- 상품 테이블에 1, 3번 상품 재고
select p.product_id , p.stock_quantity 
  from products p
 where p.product_id in (1,3)
;

-- 입고 테이블 값을 상품 테이블 재고 수정
update products as p
   set stock_quantity = p.stock_quantity + r.quantity
  from restock as r
 where p.product_id = r.product_id 	-- 1, 3번
;


select p.product_id, p.price 
  from products p
 where p.product_id = 3
;
--3	286090.00

insert into sample_products (product_id, price)
values(2, 500000)
on conflict (product_id)
do update set price=EXCLUDED.price
;

create table sample_products(
	product_id	integer not null primary key,
	price		integer	not null
);

select * from sample_products sp;