--drop table if exists members;

-- 회원 테이블
create table members(
	  id			integer			generated always as identity primary key
	, name			varchar(50)		not null
	, email			varchar(100)	not null
	, points		integer 		default 0
	, create_at		timestamp 		default now()
);

create table products ( 
	  id		integer		generated always as identity primary key
	, name		varchar(100)	not null
	, category	varchar(100)
	, price		integer not null
	, stock		integer default 0
);

-- create table : DDL
-- insert : DML

-- insert: 데이터 추가
-- 기본 문법: insert into 테이블명 [(컬럼1, 컬럼2, ...)] values (값1, 값2, 값3, ...);

insert into members (name, email)
values ('홍길동','hong@gmail.com');


select * from members m ;	-- 데이터 추출
select * from products;

insert into members (name, email)
values 
('고길동','go@gmail.com'),
('마이콜','my@gmail.com');

insert into products (name, category, price, stock)
values 
('무선 마우스','전자기기',19900,50),
('기계식 키보드','전자기기',89000,20),
('머그컵','주방용품',8900,100),
('노트','문구',3000,200);

select 
	   p.name
	 , p.category
	 , p.price 
--	 , p.stock 
  from products p 
;

select *
  from members m 
;

select 
	   m."name" 
	 , p."name" 
  from members m, products p 
;

--stock 제외 insert
insert into products(name, category, price)
values('텀블러','주방용품',15000);

select *
  from products p 
;

-- returning
insert into members (name, email)
values ('둘리','dol@gmail.com')
returning id
;

select * from members ;

insert into products (name, category, price)
values
('손목 받침대','전자기기',12000),
('USB 허브','전자기기',23000)
returning id, name
;

select * from products p ;

insert into electronics (id, name, price)
select p.id, p."name", p.price 
  from products p 
 where p.category = '전자기기'
;

select * from electronics e ;

select *
  from products p 
 where p.category = '전자기기'
;


-- select 기초
select p."name" 
	 , p.price 
  from products p 
;

select * from products p ;


-- 컬럼 별칭, 테이블 별칭
select p."name" as 상품명
	 , p.price as 가격
  from products p  -- 테이블 별칭
;

-- 전체 데이터 조회 => 테이블 나옴.
select * from products p;


-- 문제 : 가격이 20000원 이상인 상품 조회(where)
select p."name" , p.price , p.stock		-- 3. 필요한 컬럼을 가지고 있는 행 조회
  from products p 						-- 1. 상품 정보가 들어있는 테이블 찾기
 where p.price >= 20000					-- 2. 가격이 20000인 행 추출. >= 비교 연산자
;

-- 주방용품 중에 10000원 이상이 상품 조회
-- 1. 테이블 찾기 : products
-- 2. 조건에 부합하는 컬럼 찾기: category, price
select p."name" as "상품명"
	 , p.category as "상품 분류"	-- 띄어쓰기 있으면 ""에 넣기
  from products p 
 where p.category = '주방용품'
   and p.price >= 10000
;

-- 문제: 종류가 주방용품이거나 문구인 상품 조회(or 또는 in 적용)

select *
  from products p 
 where p.category not in ('주방용품', '문구')
;


-- 문제 : 가격이 5000이상 20000미만인 상품 조회
select *
  from products p 
 where p.price >= 5000
   and p.price < 20000
;

select *
  from products p
 where p.price between 5000 and 19999	-- 5000 <= p.price < 20000
;

-- 문제 : 상품명 중에서 "마우스"가 포함된 상품 추출

select * 
  from products p 
-- where p."name" like '마우스'	-- '마우스'만
-- where p."name" like '%마우스%'	-- 마우스 포함
-- where p."name" like '마우스%'	-- 마우스로 시작
 where p."name" like '%마우스'	-- 마우스로 끝
;