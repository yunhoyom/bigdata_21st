-- 윈도우 함수
-- 기본 구조
--select 컬럼 자리
--	   윈도우 함수(컬럼) over(
--	   	[partition by 분할할 컬럼]	-- 해당 컬럼으로 그루핑. cf> group by
--	   	[order by 정렬할 컬럼]		-- 해당 컬럼으로 정렬 
--	   	[rows | range 프레임 지정]	-- 범위 지정
--	   )
--  from 테이블명;

-- over()
-- 원래 select는 한 개 행을 가져와 한 개 행을 생성
-- 예 : 10개 행 => sum => 1개 행으로 압축
-- sum(col) over() : 압축 일어나지 않음
select c.customer_id	-- 회원 번호
	 , count(*)	over()	-- 한 개 row로 압축x.
  from customers c;		-- 50000 row
  

select c.customer_id			-- 회원 번호
	 , count(*)	over(			-- counting
	 	partition by c.grade	-- 등급별로 grouping
	 )
  from customers c;				-- 50000 row
  
-- 주요 윈도우 함수
-- 1. 순위 지정 함수 (Ranking)
-- row_number() : 중복 값과 관계 없이 무조건 순차적인 고유 순위 부여(1,2,3,...)
-- rank() : 중복 값이 있으면 동일 순위 부여, 다음 순위 건너 뜀.(1,2,2,4)
-- dense_rank() : 중복 값이 있으면 동일 순위 부여, 다음 순위 연속하여 부여(1,2,2,3)
  
-- 2. 집계 함수(Aggregate)
-- sum, avg, count, min, max : over()와 조합하여 그룹별 누적합이나 이동 평균 계산 : order by, rows

-- 3. 값 참조 함수(Value)
-- LAG(컬럼, 칸 수) : 현재 행 기준으로 이전 행의 값을 가져옴.(select 문이지만 over로 다른 행을 가져옴.)
-- LEAD(컬럼, 칸 수) : 현재 행 기준으로 다음 행의 값을 가져옴.
-- FIRST_VALUE(컬럼) : 파티션(partition by) / 프레임(row|range) 내의 첫 번째 행 값을 가져옴.
-- LAST_VALUE(컬럼) : 파티션(partition by) / 프레임(row|range) 내의 마지막 행 값을 가져옴.
  
-- 회원당 평균 주문 수
select c."name" 
	 , count(*) as cnt
  from orders o 
  join customers c 
    on o.customer_id = c.customer_id
 group by c.customer_id
 
select s.customer_id
	 , count(*) as 주문수
	 , avg(count(*)) over() as 전체회원의주문수평균
  from orders s
 group by s.customer_id
 
-- 등급별 평균 주문 수
select o.customer_id
	 , count(*) as 회원별주문수
	 , avg(count(*)) over(partition by  ) as 등급별평균주문수
  from orders o 
  join customers c
 group by o.customer_id
 
-- 문제
select *
  from orders o
 order by o.order_date desc
 limit 5
;


create table orders_top5 as  
	select *
	  from orders s
	 order by s.order_date desc --최근 주문
	 limit 5
;