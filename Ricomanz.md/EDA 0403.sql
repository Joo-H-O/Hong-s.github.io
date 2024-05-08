USE ricomanz;

#order table UNION VIEW
CREATE OR REPLACE VIEW order_2023 AS
SELECT 주문일시, 주문자ID, 주문_시_회원등급, 총_주문금액, 총_결제금액, 주문상품명, 수량, 판매가, 주문자_가입일, 주문자_주소, 주문자_상세_주소, 주문자우편번호, 총_배송비_전체_품목에_표시, 총_실제_환불금액, 사용한_쿠폰명, 주문서_쿠폰_할인금액, 결제수단, 주문번호
FROM (
SELECT * FROM new_first_half_order
UNION ALL
SELECT * FROM new_second_half_order
) AS a;

#미입금건 제외, 30% 할인쿠폰, 총 주문금액 0원, 협찬 제외 VIEW 생성
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
    
SELECT*FROM order_data;
    
#회원 전체 주문 1983건, 216명 재구매율 13%
SELECT SUM(A)
FROM (
	SELECT COUNT(DISTINCT 주문번호) AS A
	FROM order_data
    WHERE 주문자ID != ''
	GROUP BY 주문자ID
	HAVING COUNT(DISTINCT 주문번호) >= 2) Sub;

#비회원 8003 재구매율 13%
SELECT SUM(A)
FROM (
	SELECT COUNT(DISTINCT 주문번호) AS A
	FROM order_data
    WHERE 주문자ID = ''
	GROUP BY CONCAT(주문자_주소, 주문자_상세_주소)
	HAVING COUNT(DISTINCT 주문번호) >= 2) Sub;

#회원의 구매 순번별 매출 확인
SELECT SUM(Total), COUNT(Total), (SUM(Total) / COUNT(Total)) AS 객단가
FROM (
	SELECT 주문자ID, 주문번호, 
    ROW_NUMBER() OVER(PARTITION BY 주문자ID ORDER BY 주문번호) AS 순번, 주문일시, 
    (SUM(총_주문금액) - SUM(주문서_쿠폰_할인금액) - SUM(총_실제_환불금액)) AS Total
		FROM (SELECT DISTINCT 주문번호, 총_주문금액, 주문자ID, 총_결제금액, 총_실제_환불금액, 주문서_쿠폰_할인금액, 주문일시 FROM order_data) AS orders
		GROUP BY 주문자ID, 주문번호
		HAVING 주문자ID != '') Sub
WHERE 순번 >= 1;

#비회원의 구매 순번별 매출 확인
SELECT SUM(Total), COUNT(Total), (SUM(Total) / COUNT(Total)) AS 객단가
FROM (
	SELECT 비회원주소, 주문번호, 주문자ID,
    ROW_NUMBER() OVER(PARTITION BY 비회원주소 ORDER BY 주문번호) AS 순번, 주문일시, 
    (SUM(총_주문금액) - SUM(주문서_쿠폰_할인금액) - SUM(총_실제_환불금액)) AS Total
		FROM (SELECT DISTINCT 주문번호, 총_주문금액, 주문자ID, CONCAT(주문자_주소, 주문자_상세_주소) AS 비회원주소, 총_결제금액, 총_실제_환불금액, 주문서_쿠폰_할인금액, 주문일시 FROM order_data) AS orders
		GROUP BY 비회원주소, 주문번호, 주문자ID
        HAVING 주문자ID = '') Sub
WHERE 순번 >= 1;

SELECT 8003*0.116 FROM DUAL;