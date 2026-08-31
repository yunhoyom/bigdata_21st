-- 분위 분할: ntile

select t.사분위
	 , count(*) as 상품수
	 , min(t.price)	-- 버킷 안에 있는 최소값
	 , max(t.price)	-- 버킷 안에 있는 최댓값
  from (	-- 인라인뷰는 단독 실행이 되어야 한다.
  	select p.price 
  		 , ntile(4) over(order by p.price asc) as 사분위
  	  from products p
  ) t
group by t.사분위
order by t.사분위
;

-- 문법
-- ntile(버켓수) over(
-- partition by 컬럼 	: 선택
-- order by 컬럼 		: 필수
-- )
-- 상품테이블 상품수가 1000개, 4개로 분할.
-- 동일한 값 처리에 문제 : dense_rank(), width_bucket() 사용 고려.
--					 percent_rank()

-- 집합연산, 차집합 (빼기)
select p.category_id
  from products p
 where p.status = '판매중'		-- 953개
except -- 중복 제거
select p.category_id
  from products p
 where p.status = '단종'			-- 32개
 
-- 차집합 : A 특징 남기기
-- 의미 부여 : 단종된 상품이 없는 판매중인 카테고리 조회
select c.name from categories c where c.category_id in (9, 10);
-- 도서, 가구 카테고리는 단종된 상품 없는 판매 중인 상품만 있는 분류

-- select distinct status from products p
-- 품절
-- 단종
-- 판매중


-- 합집합 : UNION, UNION ALL
(select p."name", p.price, '최고가' as 구분
  from products p
 order by p.price desc, p.product_id 
 limit 1)
union 
(select p.name, p.price, '최저가' as 구분
  from products p
 order by p.price
 		, p.product_id
 limit 1)
;
 
select p.name, min(p.price)
  from products p
 group by p."name"
;