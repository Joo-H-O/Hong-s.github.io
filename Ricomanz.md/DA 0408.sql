USE ricomanz;

CREATE OR REPLACE VIEW review_data AS
SELECT*FROM first_half_review
UNION
SELECT*FROM second_half_review;

SELECT 주문자ID, SUM(총_주문금액) - SUM(총_실제_환불금액) - SUM(주문서_쿠폰_할인금액) AS 매출, COUNT(DISTINCT 주문번호) AS 주문건수
FROM (
        SELECT DISTINCT 주문번호, 총_주문금액, 총_실제_환불금액, 주문서_쿠폰_할인금액, 주문자ID
        FROM order_data
    ) AS orders
WHERE 주문자ID IN (SELECT 작성자ID
FROM review_data
WHERE 작성자ID != '' AND 작성자ID != '비회원'
GROUP BY 작성자ID)
GROUP BY 주문자ID
HAVING 주문건수 >= 2;

CREATE OR REPLACE VIEW member_list AS
SELECT 주문자ID, SUM(총_주문금액) - SUM(총_실제_환불금액) - SUM(주문서_쿠폰_할인금액) AS 매출, COUNT(주문번호) AS 주문건수
FROM (
    SELECT DISTINCT 주문번호, 총_주문금액, 총_실제_환불금액, 주문서_쿠폰_할인금액, 주문자ID
    FROM order_data
    WHERE (총_주문금액 - 총_실제_환불금액) >= 6000
) AS orders
WHERE 주문자ID != ''
GROUP BY 주문자ID;

#멤버 등급 나누기 - 1
SELECT 매출등급, 주문등급, COUNT(*)
FROM
	(SELECT 주문자ID, 매출,
			CASE WHEN 매출 <= 60702 THEN '평균이하'
				WHEN 매출 BETWEEN 60703 AND 132999 THEN '평균이상'
				WHEN 매출 >= 133000 THEN 'IQR이상' END AS 매출등급,
			주문건수,
			CASE WHEN 주문건수 = 1 THEN '1회 구매'
				WHEN 주문건수 >= 2 THEN '2회 이상' END AS 주문등급
	FROM member_list) Grade
GROUP BY 매출등급, 주문등급;

#멤버 등급 나누기 - 2
SELECT 매출등급, 주문등급, COUNT(*)
FROM
	(SELECT 주문자ID, 매출,
			CASE WHEN 매출 <= 59000 THEN '평균이하' #가장 비싼 제품가
				WHEN 매출 BETWEEN 59001 AND 132999 THEN '평균이상'
				WHEN 매출 >= 133000 THEN 'IQR이상' END AS 매출등급,
			주문건수,
			CASE WHEN 주문건수 = 1 THEN '1회 구매'
				WHEN 주문건수 >= 2 THEN '2회 이상' END AS 주문등급
	FROM member_list) Grade
GROUP BY 매출등급, 주문등급;

#멤버 등급 나누기 - 3
SELECT 매출등급, 주문등급, COUNT(*)
FROM
	(SELECT 주문자ID, 매출,
			CASE WHEN 매출 <= 41000 THEN '평균이하' #MEDIAN값 (호안오닉스 가격과 동일)
				WHEN 매출 BETWEEN 41001 AND 132999 THEN '평균이상'
				WHEN 매출 >= 133000 THEN 'IQR이상' END AS 매출등급,
			주문건수,
			CASE WHEN 주문건수 = 1 THEN '1회 구매'
				WHEN 주문건수 >= 2 THEN '2회 이상' END AS 주문등급
	FROM member_list) Grade
GROUP BY 매출등급, 주문등급;

SELECT 주문자ID, 주문번호, 주문일시, 총_주문금액, 총_결제금액, 주문상품명, 판매가, 주문자_가입일, 총_실제_환불금액, 주문서_쿠폰_할인금액, 결제수단
FROM order_data
WHERE 주문자ID IN ('2678190999@k', '2756130503@k');

SELECT 주문자ID, 주문번호, 주문일시, LAG(주문일시) OVER(PARTITION BY 주문자ID ORDER BY 주문일시) AS 주문차이, 총_주문금액, 총_결제금액, 주문상품명, 판매가, 주문자_가입일, 총_실제_환불금액, 주문서_쿠폰_할인금액, 결제수단
FROM order_data;

SELECT 주문상품명, COUNT(*)
FROM order_data
GROUP BY 주문상품명;