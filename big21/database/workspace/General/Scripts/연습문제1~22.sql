--1. 전체 회원 수
select count(*) as cnt
  from customers c 
;

--2. 전체 상품 수
select count(*) as cnt
  from products p 
;

--3. 활성 회원 수
select count(*) as cnt
  from customers c 
 where c.is_active = true
;

--4. 비활성 회원 수
select count(*) as cnt
  from customers c 
 where c.is_active = false
;

--5. 성별이 남성인 회원 수
select count(*) as cnt
  from customers c 
 where c.gender = 'M'
; 

select * from customers c; 
select * from products p;

--6. VIP 등급 회원 수
select count(*) as cnt
  from customers c 
 where grade = 'VIP'
;

--7. 서울 거주 회원 수
select count(*) as cnt
  from customers c 
 where city = '서울'
;

--8. 품절인 상품 수
select count(*) as cnt
  from products p 
 where status = '품절'
;

--9. 단종인 상품 수
select count(*) as cnt
  from products p 
 where p.status = '단종'
;

--10. 가장 비싼 상품 1개 이름과 가격
select p."name", p.price as cnt
  from products p
 order by p.price desc
 limit 1
;

--11. 가장 싼 상품 1개 이름과 가격
select p."name", p.price as cnt
  from products p
 order by p.price asc
 limit 1
;

--12. 이메일 도메인 종류 모두 구하기
select distinct split_part(c.email, '@', 2)
  from customers c 
;

--13. 회원 등급 종류 알파벳순
select c.grade
  from customers c 
 group by c.grade 
 order by c.grade
;

--14. 회원 거주 도시 종류 몇 종류
select count(distinct c.city)
  from customers c
;

--15. 1990-01-01 이후 출생 회원 수
select count(*) as cnt
  from customers c 
 where c.birth_date >= date '1990-01-01'
;

--16. 가격 10만원 이상인 상품 수
select count(*) as cnt
  from products p
 where p.price >= 100000
;

--17. 가격 5만원 이상 10만원 이하 상품 수
select count(*) as cnt
  from products p
 where p.price between 50000 and 100000
 
--18. 이메일이 gmail.com인 회원 수
select count(*) as cnt
  from customers c
 where c.email like '%gmail.com'
;

--19. '김'씨 회원 수
select count(*) as cnt
  from customers c 
 where c."name" like '김%'
;

--20. 재고 0인 상품 수
select count(*) as cnt
  from products p
 where p.stock_quantity = 0
;

--21. 가장 비싼 상품 5개 이름, 가격 구하기
select p."name" , p.price 
  from products p 
 order by p.price desc 
 limit 5
;

--22. 가장 먼저 가입한 회원 5명 이름, 가입일
select c."name" , c.signup_date 
  from customers c  
 order by c.signup_date
 limit 5
;