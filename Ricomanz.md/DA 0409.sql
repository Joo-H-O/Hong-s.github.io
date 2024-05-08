USE ricomanz;

#첫주문에 쿠폰할인 금액이 O (쿠폰 사용 안함) - 336명 (환불 19명)
SELECT 주문자ID, 순매출
	FROM (SELECT 주문자ID, 주문서_쿠폰_할인금액, DATEDIFF(주문일시, 회원_가입일) AS 가입to주문, COUNT(주문번호), (SUM(총_주문금액) - SUM(주문서_쿠폰_할인금액) - SUM(총_실제_환불금액)) AS 순매출
	FROM (
			SELECT 주문자ID, 주문번호, 
			ROW_NUMBER() OVER(PARTITION BY 주문자ID ORDER BY 주문번호) AS 순번, 주문일시, 주문상품명, 수량, 주문서_쿠폰_할인금액, 총_실제_환불금액, 총_주문금액
				FROM (SELECT DISTINCT 주문번호, 총_주문금액, 주문자ID, 주문상품명, 주문일시, 수량, 주문서_쿠폰_할인금액, 총_실제_환불금액 FROM order_data) AS orders
				GROUP BY 주문자ID
				HAVING 주문자ID != '') Sub
	JOIN member_info M ON M.아이디 = Sub.주문자ID
	WHERE 순번 >= 1 AND 주문서_쿠폰_할인금액 = '' AND 
		주문자ID IN (SELECT 아이디 FROM member_info WHERE 회원_가입일 >= '2023-01-01') AND
		DATEDIFF(주문일시, 회원_가입일) < 90
	GROUP BY 주문자ID) S1	
WHERE 순매출 > 41000;

#회원 중 미구매자의 최종접속일
SELECT 차이, COUNT(*), SUM(COUNT(*)) OVER (ORDER BY 차이)
FROM (SELECT 아이디, 회원_가입일, 최종접속일, DATEDIFF(최종접속일, 회원_가입일) AS 차이
	FROM member_info M
	LEFT JOIN order_data O ON O.주문자ID = M.아이디
	WHERE O.주문번호 IS NULL AND M.회원_가입일 < '2024-01-01') Sub
GROUP BY 차이;

#회원 중 미구매자의 최종접속일
SELECT 차이, COUNT(*), SUM(COUNT(*)) OVER (ORDER BY 차이)
FROM (SELECT 아이디, 회원_가입일, 최종접속일, DATEDIFF(최종접속일, 회원_가입일) AS 차이
	FROM member_info
	WHERE 회원_가입일 < '2024-01-01' AND 아이디 NOT IN (SELECT 주문자ID FROM order_data)) Sub
GROUP BY 차이;

SELECT*FROM 구매항목_관련;
SELECT*FROM 전환수;

