USE ricomanz;

SELECT*FROM member_info;

#order table UNION VIEW
CREATE VIEW order_2023 AS
SELECT 주문일시, 주문자ID, 주문_시_회원등급, 총_주문금액, 총_결제금액, 주문상품명, 수량, 판매가, 주문자_가입일, 주문자_주소, 주문자_상세_주소, 주문자우편번호, 총_배송비_전체_품목에_표시, 총_실제_환불금액, 사용한_쿠폰명, 주문서_쿠폰_할인금액, 결제수단, 주문번호
FROM (
SELECT * FROM new_first_half_order
UNION ALL
SELECT * FROM new_second_half_order
) AS a;

# 미입금건 제외, 30% 할인쿠폰, 총 주문금액 0원, 협찬 제외 VIEW 생성
CREATE OR REPLACE VIEW order_data AS
SELECT *
FROM order_2023
WHERE
	사용한_쿠폰명 != '30% 할인쿠폰' AND
	NOT(결제수단 = '무통장입금' AND 총_결제금액 = 0 AND 총_실제_환불금액 = 0) AND
	NOT(결제수단 = '가상계좌' AND 총_결제금액 = 0 AND 총_실제_환불금액 = 0) AND
    총_주문금액 != 0 AND 
    주문자ID NOT IN (
    SELECT 아이디 
	FROM member_info 
	WHERE 회원_가입일 < "2024-01-01" AND 총_실주문건수 = 0 AND 총구매금액 > 0);    

    
#2023년 매출 (중복건 제외)
SELECT SUM(총_주문금액) AS 매출
FROM (
    SELECT DISTINCT 주문번호, 총_주문금액
    FROM order_data
) AS orders;

#2023년 월별 오더 VIEW 생성
CREATE OR REPLACE VIEW order_monthly AS
SELECT MONTH(주문일시) AS order_month, 
		COUNT(*) AS order_count,
		ROUND((COUNT(*) / (SELECT COUNT(*) FROM order_data) * 100), 1) AS order_ratio,
        SUM(총_주문금액) AS order_sales,
        ROUND((SUM(총_주문금액) / (SELECT SUM(총_주문금액) FROM order_data) * 100), 1) AS sales_ratio
FROM order_data
GROUP BY MONTH(주문일시);

#월별 오더 VIEW 보기
SELECT * FROM order_monthly;

#월별 다건 구매 비율 확인
SELECT Sub.order_month, 
	SUM(num_orders) AS 다건구매, 
	O.order_count, 
	ROUND(((SUM(num_orders) / O.order_count) * 100), 1) AS ratio
FROM (
	SELECT MONTH(주문일시) AS order_month, 
		   COUNT(*) AS num_orders
	FROM order_data
	GROUP BY MONTH(주문일시), 주문번호
	HAVING COUNT(*) >= 2) Sub
JOIN order_monthly O ON O.order_month = Sub.order_month
GROUP BY order_month;   

#전체 주문건수 - 9,986건
SELECT COUNT(DISTINCT 주문번호)
FROM order_data;

#전체 주문건수 - 회원 주문 1,983건
SELECT COUNT(DISTINCT 주문번호)
FROM order_data
WHERE 주문자ID != '';

#회원 주문에서 회원 ID - 1,727건
SELECT COUNT(DISTINCT 주문자ID)
FROM order_data
WHERE 주문자ID != '';

#전체 주문건수 - 비회원 주문 8,003건 / 6,953회원
SELECT COUNT(*)
FROM order_data
WHERE 주문자ID = ''
GROUP BY CONCAT(주문자_주소, 주문자_상세_주소)
HAVING COUNT(*) >= 2;

#재구매 회원 찾기 member_info
SELECT COUNT(아이디)
FROM member_info
WHERE 총_실주문건수 >= 2 AND
	아이디 NOT IN (SELECT 아이디 FROM member_info WHERE 총_실주문건수 = 0 AND 총구매금액 > 0);
    
#재구매 회원 주문금액
SELECT 주문자ID, MIN(주문번호), AVG(총_주문금액), COUNT(*)
FROM order_data
WHERE 주문자ID IN (SELECT 주문자ID FROM reorder_member)
GROUP BY 주문자ID;

CREATE OR REPLACE VIEW refund AS
SELECT 주문일시, 주문자ID, 주문번호, 총_주문금액, 총_결제금액, 총_실제_환불금액
FROM order_data
WHERE 총_실제_환불금액 != 0;

#재구매 비회원 VIEW
CREATE VIEW reorder_nonmember AS
SELECT 주문자_주소
FROM order_data
GROUP BY 주문자_주소
HAVING COUNT(DISTINCT 주문번호) >= 2;

#재구매 비회원 주문금액
SELECT 주문자_주소, MIN(주문일시), 총_주문금액
FROM order_data
WHERE 주문자_주소 IN (SELECT 주문자_주소 FROM reorder_nonmember)
GROUP BY 주문자_주소;

#재구매 회원ID VIEW (주문취소건 제외, 30% 할인쿠폰, 총 주문금액 0원 제외)
CREATE OR REPLACE VIEW reorder_member AS
SELECT DISTINCT 주문자ID
FROM order_data
WHERE 주문자ID != '' AND
	주문자ID NOT IN (SELECT 아이디 FROM member_info WHERE 총_실주문건수 = 0 AND 총구매금액 > 0)
GROUP BY 주문자ID
HAVING COUNT(DISTINCT 주문번호) >= 2;

SELECT*
FROM order_data
WHERE 주문자ID IN (SELECT 주문자ID FROM reorder_member);

#재구매 TERM VIEW 생성
CREATE OR REPLACE VIEW reorder_term AS
SELECT 주문자ID, 주문일시,
		DATEDIFF(주문일시, LAG(주문일시) OVER(PARTITION BY 주문자ID ORDER BY 주문일시)) AS 주문일시_차이
FROM (
    SELECT 주문자ID, 주문일시, ROW_NUMBER() OVER(PARTITION BY 주문자ID ORDER BY 주문일시) AS 주문순번
    FROM order_data
    WHERE 주문자ID IN (SELECT 주문자ID FROM reorder_member) 
    ) AS Subquery
GROUP BY 주문자ID, 주문일시;

#재구매 TERM이 0일인 주문자 VIEW 생성
CREATE OR REPLACE VIEW reorder_inaday AS
SELECT 주문자ID
FROM reorder_term
WHERE 주문일시_차이 = 0;

#재구매 TERM이 0인 주문자 정보 확인
SELECT *
FROM order_data
WHERE 주문자ID IN (
	SELECT 주문자ID FROM reorder_inaday) AND 총_실제_환불금액 != 0;

#재구매 회원 주문 상품 VIEW 생성
CREATE OR REPLACE VIEW reorder_item AS
SELECT 주문자ID, 주문순번, 주문상품명, COUNT(*)
FROM (
    SELECT 주문자ID, 주문상품명, ROW_NUMBER() OVER(PARTITION BY 주문자ID ORDER BY 주문일시) AS 주문순번
    FROM order_data
    WHERE 주문자ID IN (SELECT 주문자ID FROM reorder_member) 
    ) AS Subquery
GROUP BY 주문자ID, 주문순번, 주문상품명;

#재구매 회원 주문 상품 보기 - 주문순번별
SELECT*
FROM reorder_item
GROUP BY 주문순번, 주문상품명;

#제품별 판매 순위 확인
SELECT 주문상품명, COUNT(*)
FROM order_data
GROUP BY 주문상품명
ORDER BY 2 DESC;

#월별/제품별 판매건수 확인
SELECT MONTH(주문일시) AS month,
    SUM(CASE WHEN 주문상품명 LIKE '호안오닉스 카네스톤' THEN 1 ELSE 0 END) AS 호안,
    SUM(CASE WHEN 주문상품명 LIKE '자마노 레브스톤%' THEN 1 ELSE 0 END) AS 자마노,
    SUM(CASE WHEN 주문상품명 LIKE '호안석 트레스톤' THEN 1 ELSE 0 END) AS 호트,
    SUM(CASE WHEN 주문상품명 LIKE '아이아게이트%' THEN 1 ELSE 0 END) AS 아이아,
    SUM(CASE WHEN 주문상품명 LIKE '레브스톤%' THEN 1 ELSE 0 END) AS 레브
FROM order_data
GROUP BY MONTH(주문일시)
ORDER BY 1;

#다건 구매자의 구매 조합
SELECT 주문자ID, GROUP_CONCAT(DISTINCT 주문상품명 ORDER BY 주문상품명 ASC) AS 구매_조합
FROM order_data
GROUP BY 주문자ID
HAVING COUNT(DISTINCT 주문번호) >= 2 AND COUNT(DISTINCT 주문상품명) >= 2;

#다건 구매자 VIEW
CREATE OR REPLACE VIEW several_order AS
SELECT 주문자ID
FROM order_data
GROUP BY 주문자ID
HAVING COUNT(DISTINCT 주문번호) >= 2 AND COUNT(DISTINCT 주문상품명) >= 2 AND 주문자ID != '' ;

SELECT 주문자ID FROM several_order;

#다건 구매자 상품 확인
SELECT 주문자ID, 주문일시, 주문상품명
FROM order_data
WHERE 주문자ID IN (SELECT 주문자ID FROM several_order);


SELECT 조합, COUNT(*) AS 구매_횟수
FROM (
    SELECT DISTINCT 주문자ID, GROUP_CONCAT(주문상품명 ORDER BY 주문상품명 ASC) AS 조합
    FROM order_data
    GROUP BY 주문자ID
	HAVING COUNT(DISTINCT 주문번호) >= 2 AND COUNT(DISTINCT 주문상품명) >= 1
) AS 상품_조합
GROUP BY 조합;

SELECT *
FROM (
	SELECT*
	FROM reorder_item
	GROUP BY 주문순번, 주문상품명) Sub
WHERE 주문순번 = 2;