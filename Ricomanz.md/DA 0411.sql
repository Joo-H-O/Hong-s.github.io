USE ricomanz;

#RFM - 고객 줄세우기
SELECT 주문자ID,
	일수, NTILE(3) OVER (ORDER BY 일수),
    Fre, Mon
	FROM (SELECT 주문자ID,
		MAX(주문일시) AS Rec,
		DATEDIFF('2024-01-01', MAX(주문일시)) AS 일수,
		COUNT(DISTINCT 주문번호) AS Fre,
		SUM(총_주문금액) - SUM(총_실제_환불금액) - SUM(주문서_쿠폰_할인금액) AS Mon
	FROM (SELECT DISTINCT 주문번호, 총_주문금액, 총_실제_환불금액, 주문서_쿠폰_할인금액, 주문자ID, 주문상품명, 주문일시, 수량
		FROM order_data
		GROUP BY 주문자ID, 주문번호) AS orders
	WHERE 주문자ID != '' AND (총_주문금액 - 총_실제_환불금액) >= 6000
	GROUP BY 주문자ID) Sub;

#RFM - 고객 나누기
CREATE OR REPLACE VIEW rfm_list AS
SELECT 주문자ID, R_RATE, F_RATE, M_RATE, CONCAT(R_RATE, F_RATE, M_RATE) AS RFM
	FROM (SELECT 주문자ID,
		CASE WHEN DATEDIFF('2024-01-01', MAX(주문일시)) <= 90 THEN 3
			WHEN 90 < DATEDIFF('2024-01-01', MAX(주문일시)) AND DATEDIFF('2024-01-01', MAX(주문일시)) <= 180 THEN 2
			WHEN DATEDIFF('2024-01-01', MAX(주문일시)) > 180 THEN 1 END AS R_RATE,
		CASE WHEN COUNT(DISTINCT 주문번호) = 1 THEN 1
			WHEN COUNT(DISTINCT 주문번호) = 2 THEN 2
			WHEN COUNT(DISTINCT 주문번호) >= 3 THEN 3 END AS F_RATE,
		CASE WHEN SUM(총_주문금액) - SUM(총_실제_환불금액) - SUM(주문서_쿠폰_할인금액) <= 41000 THEN 1
			WHEN SUM(총_주문금액) - SUM(총_실제_환불금액) - SUM(주문서_쿠폰_할인금액) > 41000 AND 
				SUM(총_주문금액) - SUM(총_실제_환불금액) - SUM(주문서_쿠폰_할인금액) < 133000 THEN 2
			WHEN SUM(총_주문금액) - SUM(총_실제_환불금액) - SUM(주문서_쿠폰_할인금액) >= 133000 THEN 3 END AS M_RATE,
		SUM(총_주문금액) - SUM(총_실제_환불금액) - SUM(주문서_쿠폰_할인금액) AS 매출
	FROM (SELECT DISTINCT 주문번호, 총_주문금액, 총_실제_환불금액, 주문서_쿠폰_할인금액, 주문자ID, 주문상품명, 주문일시, 수량
			FROM order_data
			GROUP BY 주문자ID, 주문번호) AS orders
	WHERE 주문자ID != '' AND (총_주문금액 - 총_실제_환불금액) >= 6000
	GROUP BY 주문자ID) RFM_table;

#RFM - 분류 모델 VIEW 생성
CREATE OR REPLACE VIEW member_grade AS
SELECT 주문자ID, RFM,
    고객_등급,
    RFM인원,
    COUNT(주문자ID) OVER(PARTITION BY 고객_등급) AS 등급별인원
	FROM (
	SELECT 주문자ID, 
		CASE 
			WHEN CONCAT(R_RATE, F_RATE, M_RATE) REGEXP '^33' THEN '충성 고객'
			WHEN CONCAT(R_RATE, F_RATE, M_RATE) REGEXP '^32' THEN '우수 고객'
			WHEN CONCAT(R_RATE, F_RATE, M_RATE) REGEXP '^31' THEN '일반 고객'
			WHEN CONCAT(R_RATE, F_RATE, M_RATE) REGEXP '^23' THEN '이탈 위험 충성 고객'
			WHEN CONCAT(R_RATE, F_RATE, M_RATE) REGEXP '^22' THEN '이탈 위험 우수 고객'
			WHEN CONCAT(R_RATE, F_RATE, M_RATE) REGEXP '^21' THEN '이탈 위험 일반 고객'
			WHEN CONCAT(R_RATE, F_RATE, M_RATE) REGEXP '^13' THEN '이탈 충성 고객'
			WHEN CONCAT(R_RATE, F_RATE, M_RATE) REGEXP '^12' THEN '이탈 우수 고객'
			WHEN CONCAT(R_RATE, F_RATE, M_RATE) REGEXP '^11' THEN '이탈 일반 고객' 
		END AS 고객_등급,
		CONCAT(R_RATE, F_RATE, M_RATE) AS RFM,
		COUNT(주문자ID) OVER(PARTITION BY CONCAT(R_RATE, F_RATE, M_RATE)) AS RFM인원
		FROM (SELECT 주문자ID,
			CASE WHEN DATEDIFF('2024-01-01', MAX(주문일시)) <= 90 THEN 3
				WHEN 90 < DATEDIFF('2024-01-01', MAX(주문일시)) AND DATEDIFF('2024-01-01', MAX(주문일시)) <= 180 THEN 2
				WHEN DATEDIFF('2024-01-01', MAX(주문일시)) > 180 THEN 1 END AS R_RATE,
			CASE WHEN COUNT(DISTINCT 주문번호) = 1 THEN 1
				WHEN COUNT(DISTINCT 주문번호) = 2 THEN 2
				WHEN COUNT(DISTINCT 주문번호) >= 3 THEN 3 END AS F_RATE,
			CASE WHEN SUM(총_주문금액) - SUM(총_실제_환불금액) - SUM(주문서_쿠폰_할인금액) <= 41000 THEN 1
				WHEN SUM(총_주문금액) - SUM(총_실제_환불금액) - SUM(주문서_쿠폰_할인금액) > 41000 AND 
					SUM(총_주문금액) - SUM(총_실제_환불금액) - SUM(주문서_쿠폰_할인금액) < 133000 THEN 2
				WHEN SUM(총_주문금액) - SUM(총_실제_환불금액) - SUM(주문서_쿠폰_할인금액) >= 133000 THEN 3 END AS M_RATE,
			SUM(총_주문금액) - SUM(총_실제_환불금액) - SUM(주문서_쿠폰_할인금액) AS 매출
		FROM (SELECT DISTINCT 주문번호, 총_주문금액, 총_실제_환불금액, 주문서_쿠폰_할인금액, 주문자ID, 주문상품명, 주문일시, 수량
				FROM order_data
				GROUP BY 주문자ID, 주문번호) AS orders
		WHERE 주문자ID != '' AND (총_주문금액 - 총_실제_환불금액) >= 6000
		GROUP BY 주문자ID) RFM_table) RFM_TB;
    
#각 등급의 구매일 확인 - 분포는 CANVA
SELECT O.주문자ID, R.고객_등급, MIN(O.주문일시) AS 첫주문일시
FROM order_data O
JOIN rfm_list R ON R.주문자ID = O.주문자ID
GROUP BY O.주문자ID;

#회원 가입 후 최종 구매까지 며칠이 걸렸는가 - 등급별 VIEW 생성 (MEMBER INFO JOIN하면 ROW 하나 삭제됨)
CREATE OR REPLACE VIEW RFM_DATE AS
SELECT O.주문자ID, R.RFM, R.고객_등급, MIN(O.주문일시) AS 첫주문일시, M.회원_가입일, DATEDIFF(MIN(O.주문일시), M.회원_가입일) AS 일자차이
FROM order_data O
JOIN rfm_list R ON R.주문자ID = O.주문자ID
JOIN member_info M ON M.아이디 = R.주문자ID
GROUP BY O.주문자ID;

#회원 가입 후 최종 구매까지 며칠이 걸렸는가 - 등급별 평균
SELECT RFM, AVG(일자차이)
FROM RFM_DATE
GROUP BY RFM;

SELECT*FROM RFM_DATE;

#월별/제품별 인기상품 확인
SELECT 월, 주문상품명, 주문수, DENSE_RANK() OVER (PARTITION BY 월 ORDER BY 주문수) AS cnt_rank
	FROM (SELECT MONTH(주문일시) AS 월, 주문상품명, COUNT(*) AS 주문수
		FROM (SELECT DISTINCT 주문번호, 총_주문금액, 총_실제_환불금액, 주문서_쿠폰_할인금액, 주문자ID, 주문상품명, 주문일시, 수량
			FROM order_data) AS orders
	GROUP BY MONTH(주문일시), 주문상품명) Sub
GROUP BY 월, 주문상품명;

#월별/제품별 판매량 확인
SELECT MONTH(주문일시) AS 월, 주문상품명, COUNT(*) AS 주문수
FROM (SELECT DISTINCT 주문번호, 총_주문금액, 총_실제_환불금액, 주문서_쿠폰_할인금액, 주문자ID, 주문상품명, 주문일시, 수량
			FROM order_data) AS orders
GROUP BY MONTH(주문일시), 주문상품명;

SELECT*FROM rfm_list;

#구매자 등급별 리뷰 작성 비율
SELECT 고객_등급, COUNT(DISTINCT 작성자ID) AS 리뷰작성인원, 등급별인원,
		CONCAT(CEIL((COUNT(DISTINCT 작성자ID) / 등급별인원)*100), '%') AS 리뷰작성비율,
		COUNT(작성자ID) AS 리뷰작성개수, COUNT(작성자ID) / COUNT(DISTINCT 작성자ID) AS 중복리뷰
FROM (
	SELECT R.작성자ID, R.리뷰평점, R.리뷰내용, R.작성플랫폼, M.고객_등급, M.RFM인원, M.등급별인원, R.상품명
	FROM review_data R
	JOIN rfm_list M ON M.주문자ID = R.작성자ID) Review_member
GROUP BY 고객_등급;
-- 이탈한 고객이 리뷰 작성 비율이 가장 높지만 전반적으로 35% 내외
-- 충성 고객 일수록 리뷰 작성 비율이 높다

#어떤 상품이 리뷰가 많은가 (일반회원)
SELECT 고객_등급, 상품명, COUNT(DISTINCT 작성자ID) AS 리뷰수
FROM (
	SELECT R.작성자ID, R.리뷰평점, R.리뷰내용, R.작성플랫폼, M.고객_등급, M.RFM인원, M.등급별인원, R.상품명
	FROM review_data R
	JOIN rfm_list M ON M.주문자ID = R.작성자ID) Review_member
WHERE 고객_등급 LIKE '%일반%'
GROUP BY 고객_등급, 상품명
ORDER BY 1, 3 DESC;
-- 1위는 모두 호안오닉스, 이탈(호안닉스 리치스톤) / 위험(호안석 트레스톤) / 일반(자마노)

#등급별 리뷰평점
SELECT 고객_등급, ROUND(AVG(리뷰평점), 1) AS 평균별점
FROM (
	SELECT R.작성자ID, R.리뷰평점, R.리뷰내용, R.작성플랫폼, M.고객_등급, M.RFM인원, M.등급별인원, R.상품명
	FROM review_data R
	JOIN rfm_list M ON M.주문자ID = R.작성자ID) Review_member
GROUP BY 고객_등급;
-- 4.6 ~ 4.7로 크게 차이가 없음

#등급별 리뷰평점
SELECT 고객_등급, ROUND(AVG(리뷰평점), 1) AS 평균별점5제외, COUNT(*) AS 리뷰수
FROM (
	SELECT R.작성자ID, R.리뷰평점, R.리뷰내용, R.작성플랫폼, M.고객_등급, M.RFM인원, M.등급별인원, R.상품명
	FROM review_data R
	JOIN rfm_list M ON M.주문자ID = R.작성자ID) Review_member
WHERE 리뷰평점 != 5
GROUP BY 고객_등급;
-- 2.8 ~ 3.0로 이탈 위험 일반 고객이 가장 낮음
-- 1.5 ~ 3.5로 다소 차이를 보이며, '이탈 위험 충성 고객'의 평점이 가장 낮음 / '이탈 충성 고객'의 평점이 가장 높았음

#등급별 상품별 리뷰평점
SELECT 고객_등급, 상품명, ROUND(AVG(리뷰평점), 1) AS 평균별점상품별, COUNT(*) AS 리뷰수
FROM (
	SELECT R.작성자ID, R.리뷰평점, R.리뷰내용, R.작성플랫폼, M.고객_등급, M.RFM인원, M.등급별인원, R.상품명
	FROM review_data R
	JOIN rfm_list M ON M.주문자ID = R.작성자ID) Review_member
WHERE 고객_등급 LIKE '%일반%'
GROUP BY 고객_등급, 상품명
HAVING 상품명 LIKE '호안오닉스%';

#구매 후 재방문자 리뷰 작성 비율 -- NOT YET DONE
SELECT R.작성자ID, R.리뷰평점, R.리뷰내용, R.작성플랫폼, M.고객_등급, M.RFM인원, M.등급별인원, R.상품명, O.주문번호, O.주문일시
FROM review_data R
JOIN order_data O ON O.주문번호 = R.주문번호
JOIN rfm_list M ON M.주문자ID = O.주문자ID;