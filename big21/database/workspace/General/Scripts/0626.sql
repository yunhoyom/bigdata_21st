-- FK : 데이터 무결성 확보, 관계(부모-자식)가 생긴다.
select * from emp;

-- 현재 우리 회사에는 개발, 총무, 기획팀 3개 팀이 있다.
select * from depart;

-- 신입사원 : 둘리 ->  insert into emp
insert into emp(empid, empname, salary, departid)
values (104, '둘리', 700, 30);
-- departid 50은 없는 번호..
-- 막아야..

-- 희동이, 둘리 삭제(fk 선언 위해)
--delete from emp 
--where empid in (103, 104);

-- FK 설정
-- 1. depart table departid 먼저 pk(제약조건) 추가 선언해야 함.
-- FK 참조할 때 중복되면 안 된다.
-- 현재 상태 : 테이블은 다 생성된 상태

alter table depart					-- depart table 변경
add constraint pk_depart			-- add constraint 제약조건명
primary key(departid)				-- primary key(컬럼명) PK가 될 컬럼 지정
;

-- 2. emp table departid 를 fk 선언
alter table emp 					-- emp table 변경해라
add constraint fk_emp_depart		-- departid column을 FK로 지정
foreign key (departid)				-- emp 테이블에 departid 컬럼을 fk로 사용
references depart(departid)			-- 참조
on delete restrict		 			-- 특정 부서를 삭제할 때 소속 사원이 있으면 삭제x
on update cascade					-- 특정 부서번호 변경시 사원 쪽도 자동으로 변경
;

update emp 
set empid = 102
where empname='마이콜'
;

-- 1000개의 상품 평균 가격보다 큰 상품의 개수
select count(*)
  from products p 
 where p.price > (			-- row 추출
 	select avg(p2.price)	-- 1000개 상품의 평균 가격 185,195
 	  from products p2 
 );

-- 카테고리별 가격이 제일 높은 상품 조회: 카테고리번호, 상품명, 가격(1백만 회 반복)
select *
  from products p1								-- p1 1000개 where에 의해 돌아감
 where p1.price = (
 	   select max(p2.price)
  		 from products p2						-- p2 1000개 where에 의해 돌아감  1000*1000=1000000번 돌아야 끝남.
 		where p2.category_id = p1.category_id	
)
order by p1.category_id asc
;

-- 상동(1.4만 번 반복)
select p.category_id, p."name" , p.price 
  from products p 											-- p 1000개
  join (
  	   select p1.category_id, max(p1.price) as max_price
  	     from products p1									-- p1 14개		14000번 돌아야 끝남.
  	    group by p1.category_id			
  )a 
  		   on p.category_id = a.category_id
  		  and p.price = a.max_price
;  		  

--
select count(*) as 주문한_vip
  from customers c
 where c.grade = 'BRONZE'
   and exists (
   	   select 1
   	     from orders o
   	    where o.customer_id = c.customer_id 
   )
;

-- 예제 23
-- 취소, 환불 제외하고 구매한 고객 중 
-- 총 구매 금액이 5,000,000 이상이면 초우량, 2,000,000 이상이면 우량, 이하이면 일반 고객
-- 인원 수 조회
select case when c.amt >= 5000000 then '초우량'
			when c.amt >= 2000000 then '우량'
			else '일반'
		end as 고객군
	 , count(*) as 인원
  from (
	   select o.customer_id, sum(o.total_amount) as amt
	     from orders o 
	    where o.status not in ('취소', '환불')	-- 배송중, 결제완료, 배송완료만 가져오기
		group by o.customer_id 
)c
 group by 1
 order by 인원 desc
;


with spend as (
	   select o.customer_id, sum(o.total_amount) as amt
	     from orders o 
	    where o.status not in ('취소', '환불')	-- 배송중, 결제완료, 배송완료만 가져오기
		group by o.customer_id 
)
select case when amt >= 5000000 then '초우량'
			when amt >= 2000000 then '우량'
			else '일반'
		end as 고객군
	 , count(*) as 인원
  from spend
 group by 1
 order by 인원 desc
;

select distinct o.status from orders o;

-- 예제 24
-- 윈도우 함수 (window function) : 행을 그룹으로 묶되 행을 줄이지 않고 
-- 							   각 행에 집계/순위/분석 값을 추가하는 함수

-- group by 사용
select p.category_id	-- 14개
	 , avg(p.price)		-- 카테고리별 평균 금액
  from products p 			-- 1000개 행
 group by p.category_id 	-- 14개 행으로 압축
;

-- 윈도우 함수
select p."name"
	 , p.category_id 
	 , p.price
	 , avg(p.price) over(partition by category_id) as avg_pdt
  from products p
;
 
-- 윈도우 함수 문법
-- 함수명 (컬럼) over(
--partition by 컬럼 : 그룹핑 할 때 (생략 가능)
--order by 컬럼 : 정렬			(생략 가능)
--rows / range between : 프레임 범위 지정(생략 가능)
--)

-- 함수 : rank() : 순위 구하는 함수
select p."name" 
	 , p.price 
	 , rank() over(order by price desc) as rank
  from products p 
 limit 10
;

-- dense_rank()
select p."name" 
	 , p.price 
	 , dense_rank() over(order by price desc) as rank
  from products p 
 limit 10
;

-- row_number()
select p."name" 
	 , p.price 
	 , row_number() over(order by price desc) as rank
  from products p 
 limit 10
;

-- ntile(n) : n등분
with tiles as (
select name
	 , price
	 , ntile(4) over(order by price desc) as tile
  from products p 
)
select t."name" 
	 , t.price
  from tiles t
 where t.tile = 1	-- 가격 상위 25% 상품 가져오기.
;

-- sum() over(order by) : 현재 행까지 누적 계산
select 
	   p."name" 
	 , p.price 
	 , sum(price) over(order by p.created_at) as 누적합
  from products p 
;