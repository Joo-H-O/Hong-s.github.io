#결제 수단에 따른 비회원 수
SELECT 결제수단, COUNT(DISTINCT 주문번호), 
	(COUNT(DISTINCT 주문번호) / SUM(COUNT(DISTINCT 주문번호)) OVER()*100) AS ratio
FROM order_2023
WHERE 주문자ID = ''
GROUP BY 결제수단;

#2023년 회원의 순 매출
SELECT (SUM(총_주문금액) - SUM(주문서_쿠폰_할인금액) - SUM(총_실제_환불금액)) AS 매출
FROM (
    SELECT DISTINCT 주문번호, 총_주문금액, 주문서_쿠폰_할인금액, 총_실제_환불금액, 주문자ID
    FROM order_data
) AS orders
WHERE 주문자ID != '';

#2023년 비회원의 순 매출
SELECT (SUM(총_주문금액) - SUM(주문서_쿠폰_할인금액) - SUM(총_실제_환불금액)) AS 매출
FROM (
    SELECT DISTINCT 주문번호, 총_주문금액, 주문서_쿠폰_할인금액, 총_실제_환불금액, 주문자ID
    FROM order_data
) AS orders
WHERE 주문자ID = '';

#2023년 재구매 비회원의 순 매출
SELECT SUM(매출)
FROM (
	SELECT (SUM(총_주문금액) - SUM(주문서_쿠폰_할인금액) - SUM(총_실제_환불금액)) AS 매출
	FROM (
		SELECT DISTINCT 주문번호, 총_주문금액, 주문서_쿠폰_할인금액, 총_실제_환불금액, 주문자ID, 주문자_상세_주소, 주문자_주소
		FROM order_data
        GROUP BY CONCAT(주문자_주소, 주문자_상세_주소)
		HAVING COUNT(주문번호) >= 2) Sub
	) AS orders;
    
#첫구매 회원 중 할인 쿠폰 미사용 회원 - 2022년 가입자 제외(회원 할인쿠폰없음)
SELECT 주문자ID, MIN(주문일시), 사용한_쿠폰명
FROM order_data
WHERE 주문자ID != '' AND 
	주문자ID NOT IN (
	SELECT 아이디
	FROM member_info
	WHERE 회원_가입일 < '2023-01-01')
GROUP BY 주문자ID
HAVING 사용한_쿠폰명 = '';

#전처리 - member_info에서 협찬 아이디 제거
CREATE OR REPLACE VIEW member_2023 AS
SELECT *
FROM member_info
WHERE 회원_가입일 >= '2023-01-01' AND 회원_가입일 < '2024-01-01' AND
	아이디 NOT IN (
	SELECT 아이디 
    FROM member_info 
    WHERE 총_실주문건수 = 0 AND 총구매금액 > 0);
    
#전체 회원 중 구매 회원 - 2023만 가입 후 구매 1,719명
SELECT COUNT(DISTINCT(아이디))
FROM member_2023
WHERE 회원_가입일 >= '2023-01-01' AND 회원_가입일 < '2024-01-01' AND
	아이디 IN (SELECT 주문자ID FROM order_data WHERE 주문자ID != '');

#전체 회원 중 구매하지 않은 회원 - 2023만 가입 후 구매 1,134명
SELECT COUNT(DISTINCT(아이디))
FROM member_2023
WHERE 회원_가입일 >= '2023-01-01' AND 회원_가입일 < '2024-01-01' AND
	아이디 NOT IN (SELECT 주문자ID FROM order_data WHERE 주문자ID != '');
    
#비구매 회원의 재방문 일 확인
SELECT 접속일차이, 인원, SUM(ratio) OVER(ORDER BY 접속일차이) AS 누적비율
FROM (
	SELECT 접속일차이, COUNT(*) AS 인원, 
		(COUNT(*) / SUM(COUNT(*)) OVER())*100 AS ratio
	FROM (
		SELECT 아이디, 회원_가입일, 최종접속일, 
			DATEDIFF(최종접속일, 회원_가입일) AS 접속일차이, 
			총_방문횟수1년_내
		FROM member_2023
		WHERE 회원_가입일 >= '2023-01-01' AND 회원_가입일 < '2024-01-01' AND
			아이디 NOT IN (SELECT 주문자ID FROM order_data WHERE 주문자ID != '')) Sub
	GROUP BY 접속일차이) Sub2;
-- 84%가 가입 후 당일 이탈
-- 24%가 들락날락 하면서 고민을 한다

#구매 회원의 평균 쿠폰 사용 기간
SELECT 쿠폰사용까지기간, COUNT(주문자ID)
FROM (SELECT DISTINCT 주문자ID, 
	주문일시, 주문자_가입일,
    DATEDIFF(주문일시, 주문자_가입일) AS 쿠폰사용까지기간
FROM order_data
WHERE 주문번호 IN (
	SELECT MIN(주문번호)
	FROM order_data
	WHERE 주문자ID IN (
		SELECT 아이디 FROM member_2023
		WHERE NOT (총_실주문건수 = 0 AND 총구매금액 > 0))
		GROUP BY 주문자ID) AND 사용한_쿠폰명 LIKE '회원가입 쿠폰') Sub
GROUP BY 쿠폰사용까지기간;

SELECT*
FROM 구매항목_관련;