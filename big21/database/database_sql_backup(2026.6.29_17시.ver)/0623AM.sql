-- 한 줄 주석
/* 
 * 여러 줄 주석
 * 
 * */

-- 회원 정보를 저장하는 members 테이블 생성

/*
 create table 테이블명 (
	컬럼명1 데이터타입 [제약조건]
	컬럼명2 데이터타입 [제약조건]
	컬럼명3 데이터타입 [제약조건]
	...
);

*/

drop table if exists members;

create table members (
	 id			integer generated always as identity	-- 회원 번호, 일련번호 자동 부여
	,name		varchar(50)								-- 회원 이름, 50자까지
	,email		varchar(100)							-- 이메일, 100자까지
	,reg_date	date									-- 등록일	
);

