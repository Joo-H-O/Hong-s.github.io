USE ricomanz;

# 주문취소건 제외, 30% 할인쿠폰, 총 주문금액 0원 제외 VIEW 생성 + 환불건 제외
CREATE OR REPLACE VIEW order_data AS
SELECT *
FROM order_2023
WHERE
	사용한_쿠폰명 != '30% 할인쿠폰' AND
	NOT(결제수단 = '무통장입금' AND 총_결제금액 = 0 AND 총_실제_환불금액 = 0) AND
	NOT(결제수단 = '가상계좌' AND 총_결제금액 = 0 AND 총_실제_환불금액 = 0) AND
    총_주문금액 != 0 AND
    총_실제_환불금액 < 1;
    
#회원별 매출
SELECT 주문자ID, SUM(총_주문금액) AS 주문매출, SUM(총_결제금액) AS 결제매출
FROM (
    SELECT DISTINCT 주문번호, 총_주문금액, 주문자ID, 총_결제금액
    FROM order_data
) AS orders
GROUP BY 주문자ID;

SELECT DISTINCT 주문번호, 총_주문금액, 주문자ID, 총_결제금액
FROM order_data;

#회원 주문당 매출
SELECT 주문자ID, CEIL(SUM(총_주문금액) / COUNT(주문번호) OVER(PARTITION BY 주문자ID)) AS 주문당매출
FROM (
    SELECT DISTINCT 주문번호, 총_주문금액, 주문자ID
    FROM order_data
) AS orders
GROUP BY 주문자ID
ORDER BY 주문당매출 DESC
LIMIT 21;

#비회원 주문당 매출
SELECT 주문자_주소, CEIL(SUM(총_주문금액) / COUNT(주문번호) OVER(PARTITION BY 주문자_주소)) AS 주문당매출
FROM (
    SELECT DISTINCT 주문번호, 총_주문금액, 주문자_주소
    FROM order_data
) AS orders
GROUP BY 주문자_주소
ORDER BY 주문당매출 DESC
LIMIT 21;

#비회원에 임의ID 부여 - X
INSERT INTO new_first_half_order (주문자ID)
SELECT CONCAT(주문자_상세_주소, '', LEFT(주문자_주소, 4))
FROM new_first_half_order
WHERE 주문자ID = '';

INSERT INTO new_first_half_order (주문자ID)
SELECT 'D1'
FROM new_first_half_order
WHERE 주문자ID = '';

SELECT*FROM new_first_half_order;

#회원 등급 분류
SELECT 아이디, 
	CASE WHEN 총구매금액 BETWEEN 150000 AND 299999 THEN 'SILVER'
		WHEN 총구매금액 BETWEEN 300000 AND 499999 THEN 'GOLD'
        WHEN 총구매금액 BETWEEN 500000 AND 999999 THEN 'VIP'
        WHEN 총구매금액 >= 1000000 THEN 'VVIP'
        ELSE '일반' END AS member_grade
FROM member_info
ORDER BY 2 DESC;

SELECT member_grade, COUNT(아이디) AS member_count
FROM (
    SELECT 아이디, 
        CASE
            WHEN 총구매금액 BETWEEN 150000 AND 299999 THEN 'SILVER'
            WHEN 총구매금액 BETWEEN 300000 AND 499999 THEN 'GOLD'
            WHEN 총구매금액 BETWEEN 500000 AND 999999 THEN 'VIP'
            WHEN 총구매금액 >= 1000000 THEN 'VVIP'
            ELSE '일반'
        END AS member_grade
    FROM member_info
) AS grade
GROUP BY member_grade;

SELECT*FROM member_info;

#GOLD/SILVER MEMBER VIEW
CREATE OR REPLACE VIEW vip_member AS
SELECT 아이디, member_grade, COUNT(아이디) AS member_count
FROM (
    SELECT 아이디, 
        CASE
            WHEN 총구매금액 BETWEEN 150000 AND 299999 THEN 'SILVER'
            WHEN 총구매금액 BETWEEN 300000 AND 499999 THEN 'GOLD'
            WHEN 총구매금액 BETWEEN 500000 AND 999999 THEN 'VIP'
            WHEN 총구매금액 >= 1000000 THEN 'VVIP'
            ELSE '일반'
        END AS member_grade
    FROM member_info
) AS grade
GROUP BY 아이디
HAVING member_grade NOT LIKE '일반';

#VIP MEMBER ORDER - 주문일시 차이
SELECT O.주문자ID, V.member_grade, 
	COUNT(O.주문번호) OVER(PARTITION BY 주문자ID) AS order_count, O.주문일시,
	DATEDIFF(주문일시, LAG(주문일시) OVER(PARTITION BY 주문자ID ORDER BY 주문일시)) AS 주문일시_차이
FROM order_data O
RIGHT JOIN vip_member V ON O.주문자ID = V.아이디
GROUP BY O.주문자ID, 주문일시;

#재구매 회원 - 주문일시 차이
SELECT 주문자ID,
	COUNT(주문번호) OVER(PARTITION BY 주문자ID) AS order_count, 주문일시,
	DATEDIFF(주문일시, LAG(주문일시) OVER(PARTITION BY 주문자ID ORDER BY 주문일시)) AS 주문일시_차이
FROM order_data
WHERE 주문자ID IN (SELECT 주문자ID FROM reorder_member)
GROUP BY 주문자ID, 주문일시;

#1년 내에 방문한 방문자 view 생성
CREATE OR REPLACE VIEW visit_user AS
SELECT 아이디, 총_방문횟수1년_내
FROM member_info
WHERE 총_방문횟수1년_내 > 0
ORDER BY 2 DESC;

#방문 횟수별 주문금액
SELECT V.아이디, V.총_방문횟수1년_내, O.총_주문금액, 
	CEIL(SUM(총_주문금액) OVER(PARTITION BY 총_방문횟수1년_내) / COUNT(아이디) OVER(PARTITION BY 총_방문횟수1년_내)) AS AVG_SALES
FROM visit_user V
LEFT JOIN order_data O ON O.주문자ID = V.아이디
GROUP BY V.아이디, V.총_방문횟수1년_내, O.총_주문금액
ORDER BY 4 DESC;
#방문횟수-주문 금액은 정비례하지 않음

#방문 횟수별 주문금액, MIN/MAX 제외
SELECT V.아이디, V.총_방문횟수1년_내, O.총_주문금액,
	CEIL((SUM(총_주문금액) OVER(PARTITION BY 총_방문횟수1년_내) - MIN(총_주문금액) OVER(PARTITION BY 총_방문횟수1년_내) - MAX(총_주문금액) OVER(PARTITION BY 총_방문횟수1년_내))
    / (COUNT(아이디) OVER(PARTITION BY 총_방문횟수1년_내) - 2)) AS AVG_SALES
FROM visit_user V
LEFT JOIN order_data O ON O.주문자ID = V.아이디
GROUP BY V.아이디, V.총_방문횟수1년_내, O.총_주문금액;
#방문횟수-주문 금액은 정비례하지 않음

#비회원 중 다건 구매 회원
SELECT 주문자_주소
FROM order_data
GROUP BY 주문자_주소
HAVING COUNT(주문번호) >= 2;

#비회원 중 다건 구매 회원 구매 상품
SELECT 주문상품명, COUNT(주문상품명)
FROM order_data
WHERE 주문자_주소 IN
	(SELECT 주문자_주소
	FROM order_data
	GROUP BY 주문자_주소
	HAVING COUNT(주문번호) >= 2)
GROUP BY 주문상품명
ORDER BY 2 DESC;

#비회원 구매 중 리뷰가 낮은 회원 VIEW 생성
CREATE OR REPLACE VIEW dis_users AS
SELECT O.주문자_주소
FROM first_half_review R
LEFT JOIN order_data O ON O.주문번호 = LEFT(R.주문번호, 16)
WHERE O.주문상품명 = R.상품명 AND
	R.리뷰평점 = 1 OR R.리뷰평점 = 2;

SELECT*FROM dis_users;

#리뷰 VIEW 생성
CREATE OR REPLACE VIEW reviews AS
SELECT*FROM first_half_review
UNION ALL
SELECT*FROM second_half_review;

#주문-리뷰까지 걸린 일수
SELECT O.주문자_주소, DATEDIFF(R.리뷰작성일시, O.주문일시) AS DIF
FROM order_data O
LEFT JOIN reviews R ON O.주문번호 = LEFT(R.주문번호, 16);

#가입-주문까지 걸린 일수
SELECT M.아이디, DATEDIFF(MIN(O.주문일시), MIN(M.회원_가입일)) AS DIF
FROM member_info M
LEFT JOIN order_data O ON O.주문자ID = M.아이디
WHERE O.주문일시 IS NOT NULL AND O.주문서_쿠폰_할인금액 = 3000
GROUP BY M.아이디
ORDER BY DIF DESC;

#리뷰 후 재구매까지 걸린 시간
SELECT O.주문자_주소, O.주문번호, O.주문일시, R.리뷰내용
FROM order_data O
JOIN reviews R ON O.주문번호 = LEFT(R.주문번호, 16)
WHERE 주문자ID IN (SELECT 주문자ID FROM reorder_member)
ORDER BY O.주문자_주소, R.리뷰내용;
