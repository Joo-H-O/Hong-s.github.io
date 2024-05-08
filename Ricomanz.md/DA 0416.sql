USE ricomanz;

#재구매 상품 조합 확인
SELECT 조합, COUNT(*) AS 구매_횟수
FROM (
    SELECT DISTINCT 주문자ID, GROUP_CONCAT(주문상품명 ORDER BY 주문상품명) AS 조합
    FROM order_data
    GROUP BY 주문자ID
) AS Item_matching
GROUP BY 조합;

#월별 제품별 주문 건수, 리뷰 건수, 리뷰 점수
SELECT MONTH(O.주문일시) AS 월, 
	O.주문상품명, 
    SUM(O.수량) OVER(PARTITION BY MONTH(O.주문일시), O.주문상품명) AS 판매수, 
	AVG(R.리뷰평점) AS 평점, 
    COUNT(R.리뷰번호) OVER(PARTITION BY MONTH(R.리뷰작성일시), R.상품명) AS 리뷰수
FROM order_data O
JOIN review_data R ON R.상품명 = O.주문상품명;

#GROUP BY로 진행
SELECT MONTH(O.주문일시) AS 월, 
       O.주문상품명, 
       SUM(O.수량) AS 판매수, 
       AVG(R.리뷰평점) AS 평점, 
       COUNT(R.리뷰번호) AS 리뷰수
FROM order_data O
JOIN review_data R ON R.상품명 = O.주문상품명
GROUP BY MONTH(O.주문일시), O.주문상품명;

#주문 데이터 검증
SELECT MONTH(주문일시) AS 월, 
	주문상품명, 
    SUM(수량) AS 판매수
FROM order_data
WHERE 주문상품명 = '블랙 루이스 키링'
GROUP BY MONTH(주문일시), 주문상품명;

#리뷰 데이터 검증
SELECT 상품명, 리뷰내용
FROM review_data
WHERE 상품명 = '오닉스 케어스톤';

SELECT MONTH(O.주문일시) AS 월, 
       O.주문상품명, 
       SUM(O.수량) AS 판매수,
       COUNT(R.리뷰번호) AS 리뷰수
FROM order_data O
JOIN review_data R ON MONTH(O.주문일시) = MONTH(R.리뷰작성일시) AND O.주문상품명 = R.상품명
GROUP BY MONTH(O.주문일시), O.주문상품명;
