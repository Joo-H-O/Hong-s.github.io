USE ricomanz;
 
#2023년 회원가입자 수 2,965명
SELECT COUNT(아이디)
FROM member_info
WHERE 회원_가입일 BETWEEN '2023-01-01' AND '2023-12-31';

#2023년까지 회원가입자 수 3,074명
SELECT COUNT(아이디)
FROM member_info
WHERE 회원_가입일 <= '2023-12-31';

#2023년 회원 구매자 수 1,727명
SELECT COUNT(DISTINCT 주문자ID)
FROM order_data
WHERE 주문자ID != '';

#2023년 비회원 구매자 수 6,953명
SELECT COUNT(DISTINCT CONCAT(주문자_주소, 주문자_상세_주소))
FROM order_data
WHERE 주문자ID = '';

#2023년 전체 구매 매출
SELECT (SUM(총_주문금액) - SUM(주문서_쿠폰_할인금액) - SUM(총_실제_환불금액)) 매출합계
FROM (
    SELECT DISTINCT 주문번호, 주문자ID, 총_주문금액, 주문서_쿠폰_할인금액, 총_실제_환불금액
    FROM order_data
) AS orders;

#2023년 전체 구매 매출 - 회원 104,833,770원, 비회원 397,965,000원
SELECT (SUM(총_주문금액) - SUM(주문서_쿠폰_할인금액) - SUM(총_실제_환불금액)) 매출합계
FROM (
    SELECT DISTINCT 주문번호, 주문자ID, 총_주문금액, 주문서_쿠폰_할인금액, 총_실제_환불금액
    FROM order_data
) AS orders
WHERE 주문자ID = '';

#재구매 회원 216명, 재구매율 12.5%, 매출 24,885,770원
SELECT COUNT(DISTINCT 주문번호)
FROM order_data
WHERE 주문자ID != ''
GROUP BY 주문자ID
HAVING COUNT(DISTINCT 주문번호) >= 2;

#재구매 비회원 806명, 재구매율 11.6%, 매출 92,886,000원
SELECT COUNT(DISTINCT 주문번호)
FROM order_data
WHERE 주문자ID = ''
GROUP BY CONCAT(주문자_주소, 주문자_상세_주소)
HAVING COUNT(DISTINCT 주문번호) >= 2;

#재구매 회원 매출 쿼리
SELECT (SUM(총_주문금액) - SUM(주문서_쿠폰_할인금액) - SUM(총_실제_환불금액)) 매출합계
FROM (
    SELECT DISTINCT 주문번호, 주문자ID, 총_주문금액, 주문서_쿠폰_할인금액, 총_실제_환불금액, 주문자_상세_주소, 주문자_주소, 주문일시
    FROM order_data
) AS orders
WHERE 주문자ID IN (
	SELECT 주문자ID
	FROM order_data
    WHERE 주문자ID != ''
	GROUP BY 주문자ID
	HAVING COUNT(DISTINCT 주문번호) >= 1);

#재구매 회원 주문건수
SELECT SUM(A)
FROM
	(SELECT COUNT(*) AS A
	FROM order_data
	WHERE 주문자ID != '' AND 주문자_가입일 < '2024-01-01'
	GROUP BY 주문자ID, 주문번호) S;
    
#구매 안한 회원의 방문일
SELECT MAX(방문일차이)
FROM (
	SELECT 아이디, 회원_가입일, 최종접속일, DATEDIFF(회원_가입일, 최종접속일) AS 방문일차이
	FROM member_info
	WHERE 최종주문일 = '') Sub;
    
#첫구매 회원의 첫구매 - 최종방문일 차이
SELECT O.주문자ID, MIN(DATEDIFF(O.주문일시, M.최종접속일)), MAX(DATEDIFF(O.주문일시, M.최종접속일)), AVG(DATEDIFF(O.주문일시, M.최종접속일)), COUNT(*)
FROM order_data O
LEFT JOIN member_info M ON O.주문자ID = M.아이디
WHERE 아이디 IN 
	(SELECT 주문자ID
	FROM order_data
	WHERE 주문자ID != ''
	GROUP BY 주문자ID
	HAVING COUNT(DISTINCT 주문번호) >= 2)
AND DATEDIFF(O.주문일시, M.최종접속일) = 0;

#재구매 회원 상품
SELECT 주문상품명, COUNT(*)
FROM order_data
WHERE 주문자ID != ''
GROUP BY 주문상품명
HAVING COUNT(DISTINCT 주문번호) >= 2
ORDER BY COUNT(*) DESC;

#회원의 구매 순번별 상품 확인
SELECT AVG(수량)
FROM
(SELECT SUM(수량) AS 수량
	FROM (
		SELECT 주문자ID, 주문번호, 
		ROW_NUMBER() OVER(PARTITION BY 주문자ID ORDER BY 주문번호) AS 순번, 주문일시, 주문상품명, 수량
		FROM (SELECT DISTINCT 주문번호, 총_주문금액, 주문자ID, 주문상품명, 주문일시, 수량 FROM order_data) AS orders
		GROUP BY 주문자ID, 주문번호
		HAVING 주문자ID != '') Sub
WHERE 순번 >= 2
GROUP BY 주문번호) Sub;

#재구매 회원 VIEW
CREATE OR REPLACE VIEW reorder_member AS
SELECT 주문자ID
FROM order_data
WHERE 주문자ID != ''
GROUP BY 주문자ID
HAVING COUNT(DISTINCT 주문번호) >= 2;

#재구매 회원의 주문 건수당 비율
SELECT 건수, COUNT(건수), (COUNT(건수) / (SELECT COUNT(*) FROM reorder_member))*100 AS RATIO
FROM (SELECT COUNT(DISTINCT 주문번호) AS 건수
FROM order_data O
WHERE 주문자ID IN (SELECT 주문자ID FROM reorder_member)
GROUP BY 주문자ID) Sub
GROUP BY 건수;