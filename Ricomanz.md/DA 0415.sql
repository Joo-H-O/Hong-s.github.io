USE ricomanz;

SELECT 고객_등급, 등급별인원
FROM member_grade
GROUP BY 고객_등급;

SELECT*FROM rfm_list WHERE 주문자ID ='3006856941@k';
SELECT*FROM order_data WHERE 주문자ID ='2770618927@k';
SELECT*FROM ricomanz_item;

#R GROUP 1의 재구매율 (첫구매 180일 이전)
SELECT 구매수, COUNT(주문자ID), (COUNT(주문자ID) / SUM(COUNT(주문자ID)) OVER())*100 AS Ratio
FROM (
	SELECT 주문자ID, COUNT(DISTINCT 주문번호) AS 구매수
	FROM order_data
	WHERE 주문자ID IN (
		SELECT 주문자ID
		FROM rfm_list
		WHERE R_RATE = 1)
	GROUP BY 주문자ID) Buy
GROUP BY 구매수;
-- 재구매율 약 10%

#R GROUP 2의 재구매율 (첫구매 90-180일)
SELECT 구매수, COUNT(주문자ID), (COUNT(주문자ID) / SUM(COUNT(주문자ID)) OVER())*100 AS Ratio
FROM (
	SELECT 주문자ID, COUNT(DISTINCT 주문번호) AS 구매수
	FROM order_data
	WHERE 주문자ID IN (
		SELECT 주문자ID
		FROM rfm_list
		WHERE R_RATE = 2)
	GROUP BY 주문자ID) Buy
GROUP BY 구매수;
-- 재구매율 약 13%

#R GROUP 3의 재구매율 (첫구매 90일 이내)
SELECT 구매수, COUNT(주문자ID), (COUNT(주문자ID) / SUM(COUNT(주문자ID)) OVER())*100 AS Ratio
FROM (
	SELECT 주문자ID, COUNT(DISTINCT 주문번호) AS 구매수
	FROM order_data
	WHERE 주문자ID IN (
		SELECT 주문자ID
		FROM rfm_list
		WHERE R_RATE = 3)
	GROUP BY 주문자ID) Buy
GROUP BY 구매수;
-- 재구매율 약 15%
-- R 점수가 오를수록 재구매율이 올라간다

#일반 고객의 다중 구매 현황
SELECT 상품수, COUNT(주문자ID), (COUNT(주문자ID) / SUM(COUNT(주문자ID)) OVER())*100 AS Ratio
FROM (
	SELECT 주문자ID, COUNT(주문상품명) AS 상품수, 주문상품명
	FROM order_data
	WHERE 주문자ID IN (
		SELECT 주문자ID
		FROM member_grade
		WHERE 고객_등급 LIKE '%일반%')
	GROUP BY 주문자ID) Item
GROUP BY 상품수
ORDER BY 상품수;
-- 다중 구매자가 전체의 25%
-- 최대 5개까지 구매

#일반 고객의 단일/다중 구매 상품
SELECT 주문상품명, COUNT(주문자ID), (COUNT(주문자ID) / SUM(COUNT(주문자ID)) OVER())*100 AS Ratio
FROM (
	SELECT 주문자ID, COUNT(주문상품명) AS 상품수, 주문상품명
	FROM order_data
	WHERE 주문자ID IN (
		SELECT 주문자ID
		FROM member_grade
		WHERE 고객_등급 LIKE '%일반%')
	GROUP BY 주문자ID) Item
GROUP BY 주문상품명
ORDER BY COUNT(주문자ID) DESC;
-- 상품수 1일 때, 호안오닉스 39%
-- 상품수 2일 때, 호안오닉스 33%
-- 상품수 3일 때, 호안오닉스 18%
-- 상품수 4일 때, 호안오닉스 27%
-- 65 종류의 주문

#우수 고객의 단일/다중 구매 현황 view 생성
CREATE OR REPLACE VIEW 2nd_item AS
SELECT O.주문자ID, O.주문일시, O.주문상품명
FROM order_data O
INNER JOIN (
    SELECT 주문자ID, MAX(주문일시) AS 재주문
    FROM order_data
    WHERE 주문자ID IN (
        SELECT 주문자ID
        FROM member_grade
        WHERE 고객_등급 LIKE '%우수%'
    )
    GROUP BY 주문자ID
) AS first_orders ON O.주문자ID = first_orders.주문자ID AND O.주문일시 = first_orders.재주문;

#우수 고객의 단일/다중 구매 현황 - 첫구매
SELECT 구매수, COUNT(주문자ID), (COUNT(주문자ID) / SUM(COUNT(주문자ID)) OVER())*100 AS Ratio
FROM (
	SELECT 주문자ID, COUNT(*) AS 구매수
	FROM 1st_item
	GROUP BY 주문자ID) Sub
GROUP BY 구매수;
-- 첫구매의 약 37%가 호안오닉스
-- 첫구매의 약 27%가 다중구매

#우수 고객의 단일/다중 구매 현황 - 재구매
SELECT 구매수, COUNT(주문자ID), (COUNT(주문자ID) / SUM(COUNT(주문자ID)) OVER())*100 AS Ratio
FROM (
	SELECT 주문자ID, COUNT(*) AS 구매수
	FROM 2nd_item
	GROUP BY 주문자ID) Sub
GROUP BY 구매수;
-- 재구매의 약 22%가 호안오닉스
-- 재구매의 약 21%가 다중구매

#충성 고객의 단일/다중 구매 현황 view 생성
CREATE OR REPLACE VIEW 2nd_충성 AS
SELECT O.주문자ID, O.주문일시, O.주문상품명
FROM order_data O
INNER JOIN (
    SELECT 주문자ID, MIN(주문일시) AS 첫주문
    FROM order_data
    WHERE 주문자ID IN (
        SELECT 주문자ID
        FROM member_grade
        WHERE 고객_등급 LIKE '%충성%'
    )
    GROUP BY 주문자ID
) AS first_orders ON O.주문자ID = first_orders.주문자ID AND O.주문일시 != first_orders.첫주문;

#충성 고객의 단일/다중 구매 현황 - 첫구매
SELECT 주문상품명, 구매수, COUNT(주문자ID), (COUNT(주문자ID) / SUM(COUNT(주문자ID)) OVER())*100 AS Ratio
FROM (
	SELECT 주문자ID, COUNT(*) AS 구매수, 주문상품명
	FROM 2nd_충성
	GROUP BY 주문자ID) Sub
GROUP BY 구매수, 주문상품명;
-- 첫구매의 약 45%가 호안오닉스
-- 재구매의 약 17%가 호안오닉스
-- 첫구매의 약 17%가 다중구매
-- 재구매의 약 45%가 다중구매

#전체 상품 개괄
SELECT 상품구분, 상품명
FROM ricomanz_item
WHERE 상품구분 = '키링' AND 판매상태 = 'Y';
-- 구분1 단품 81%, 세트 19%
-- 메인원석 오닉스 19%, 호안석 13%, 터키석 13%, 자마노 12$
-- 상품구분 팔찌 64% 키링 16% 목걸이 7%
-- 남성향 39%, 여성향 45%

#일반 고객의 주문 상품
SELECT 메인원석, COUNT(주문자ID), (COUNT(주문자ID) / SUM(COUNT(주문자ID)) OVER())*100 AS Ratio
FROM (
	SELECT 주문자ID, COUNT(주문상품명) AS 상품수, 주문상품명
	FROM order_data
	WHERE 주문자ID IN (
		SELECT 주문자ID
		FROM member_grade
		WHERE 고객_등급 LIKE '%일반%')
	GROUP BY 주문자ID) Item
JOIN ricomanz_item I ON I.상품명 = Item.주문상품명
WHERE I.상품명 != '호안오닉스 카네스톤'
GROUP BY 메인원석;
-- 65종류의 주문
-- 호안석 약 54%, 자마노 약 17%
-- 남성향 70%, 여성향 28%
-- 단품 85%, 세트 15%
-- 팔찌 91%, 키링 4%

#우수 고객의 주문 상품
SELECT 상품구분, COUNT(주문자ID), (COUNT(주문자ID) / SUM(COUNT(주문자ID)) OVER())*100 AS Ratio
FROM (
	SELECT 주문자ID, COUNT(주문상품명) AS 상품수, 주문상품명
	FROM order_data
	WHERE 주문자ID IN (
		SELECT 주문자ID
		FROM member_grade
		WHERE 고객_등급 LIKE '%우수%')
	GROUP BY 주문자ID) Item
JOIN ricomanz_item I ON I.상품명 = Item.주문상품명
GROUP BY 상품구분;
-- 37종류의 주문
-- 호안석 약 50%, 자마노 약 16%
-- 남성향 65%, 여성향 28%
-- 단품 84%, 세트 16%
-- 팔찌 86%, 키링 3%, 목걸이 2%

#충성 고객의 주문 상품
SELECT Item.주문상품명, COUNT(*), (COUNT(*) / SUM(COUNT(*)) OVER())*100 AS Ratio
FROM (
	SELECT 주문자ID, COUNT(주문상품명) AS 상품수, 주문상품명
	FROM order_data
	WHERE 주문자ID IN (
		SELECT 주문자ID
		FROM member_grade
		WHERE 고객_등급 LIKE '%충성%')
	GROUP BY 주문자ID, 주문상품명) Item
JOIN ricomanz_item I ON I.상품명 = Item.주문상품명
GROUP BY Item.주문상품명;
-- 15종류의 주문
-- 호안석 약 61%, 헤마타이트 약 11%
-- 남성향 82%, 여성향 10%
-- 단품 96%, 세트 4%
-- 팔찌 86%, 키링 3%, 목걸이 3%

SELECT 리뷰내용
FROM review_data
WHERE 상품명 LIKE '호안오닉스 카네스톤' AND
빠른리뷰 = 0
;