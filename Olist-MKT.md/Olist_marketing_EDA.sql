USE olist_marketing;

#테이블 확인
SHOW TABLES;
DESCRIBE olist_closed_deals;
SELECT *
FROM olist_closed_deals;
DESCRIBE olist_marketing_qualified_leads;
SELECT *
FROM olist_marketing_qualified_leads;

#MARKETING TABLE JOIN
SELECT * 
FROM olist_marketing_qualified_leads MQL
JOIN olist_closed_deals OCD ON MQL.mql_id=OCD.mql_id;

SELECT *
FROM olist_closed_deals;

#Olist Dataset과 join하여 확인
SELECT CD.seller_id, 
	OD.order_item_id,
    OD.product_id,
	ML.origin,
    ML.landing_page_id,
    ML.mql_id,
	ROUND(SUM(OD.price), 0) AS TOTAL #매출 총합 = TOTAL
FROM olist_ecommerce.olist_order_items_dataset OD
LEFT JOIN olist_marketing.olist_closed_deals CD ON CD.seller_id = OD.seller_id
LEFT JOIN olist_marketing.olist_marketing_qualified_leads ML ON ML.mql_id = CD.mql_id
GROUP BY 1, 2, 3, 4, 5, 6
HAVING CD.seller_id IS NOT NULL
ORDER BY TOTAL DESC;

#Origin별 계약 확인
SELECT origin, 
	COUNT(*), 
	COUNT(*)/(SELECT COUNT(*) 
			FROM olist_marketing_qualified_leads MQL
			JOIN olist_closed_deals OCD ON MQL.mql_id=OCD.mql_id)*100 AS RATIO
FROM olist_marketing_qualified_leads MQL
JOIN olist_closed_deals OCD ON MQL.mql_id=OCD.mql_id
GROUP BY origin
ORDER BY COUNT(*) DESC;

#전체 Origin별 계약 확인
SELECT origin, 
	COUNT(*), 
	COUNT(*)/(SELECT COUNT(*)
			FROM olist_marketing_qualified_leads)*100 AS RATIO
FROM olist_marketing_qualified_leads
GROUP BY origin
ORDER BY COUNT(*) DESC;

#각 origin별 랜딩 페이지별 매출 확인
SELECT ML.origin,
	 ML.landing_page_id,
	ROUND(SUM(OD.price), 0) AS TOTAL
FROM olist_ecommerce.olist_order_items_dataset OD
LEFT JOIN olist_marketing.olist_closed_deals CD ON CD.seller_id = OD.seller_id
LEFT JOIN olist_marketing.olist_marketing_qualified_leads ML ON ML.mql_id = CD.mql_id
GROUP BY ML.origin, ML.landing_page_id
HAVING ML.origin IS NOT NULL
ORDER BY TOTAL DESC;
#organic_search와 paid_search의 매출이 크게 차이가 나지 않음

#mql의 계약 소요 시간
SELECT SUBSTRING(MQL.mql_id, 1, 4) AS mql_id, 
	TIMESTAMPDIFF(DAY, first_contact_date, won_date) AS contract_days
FROM olist_marketing_qualified_leads MQL
JOIN olist_closed_deals OCD ON MQL.mql_id=OCD.mql_id;

#SDR별 성사 계약수 확인
SELECT SUBSTRING(sdr_id, 1, 4) AS SDR, 
	COUNT(DISTINCT mql_id) AS closed_deals_count
FROM olist_closed_deals
GROUP BY SDR;
#TOP 1 - 4b33

#SR별 성사 계약수 확인
SELECT SUBSTRING(sr_id, 1, 4) AS SR, 
	COUNT(DISTINCT mql_id) AS closed_deals_count
FROM olist_closed_deals
GROUP BY SR;
#TOP 1 - 4ef1

#각 SDR별 매출 확인
SELECT SUBSTRING(CD.sdr_id, 1, 4) AS SDR,
	ROUND(SUM(OD.price), 0) AS TOTAL
FROM olist_ecommerce.olist_order_items_dataset OD
LEFT JOIN olist_marketing.olist_closed_deals CD ON CD.seller_id = OD.seller_id
LEFT JOIN olist_marketing.olist_marketing_qualified_leads ML ON ML.mql_id = CD.mql_id
GROUP BY SDR
HAVING SDR IS NOT NULL
ORDER BY TOTAL DESC;
#56bf

#각 SR별 매출 확인
SELECT SUBSTRING(CD.sr_id, 1, 4) AS SR,
	ROUND(SUM(OD.price), 0) AS TOTAL
FROM olist_ecommerce.olist_order_items_dataset OD
LEFT JOIN olist_marketing.olist_closed_deals CD ON CD.seller_id = OD.seller_id
LEFT JOIN olist_marketing.olist_marketing_qualified_leads ML ON ML.mql_id = CD.mql_id
GROUP BY SR
HAVING SR IS NOT NULL
ORDER BY TOTAL DESC;
#9ae0

#SDR-SR PAIR
SELECT SUBSTRING(sr_id, 1, 4) AS SR, 
	SUBSTRING(sdr_id, 1, 4) AS SDR, 
    COUNT(*)
FROM olist_closed_deals
GROUP BY SR, SDR
ORDER BY COUNT(*) DESC;

#리드 유형별 계약 성사수 확인
SELECT lead_behaviour_profile, COUNT(*)
FROM olist_closed_deals
GROUP BY lead_behaviour_profile;
#TOP 1 - CAT

#리드 유형-SDR PAIR
SELECT lead_behaviour_profile, 
	SUBSTRING(sdr_id, 1, 4) AS SDR, 
    COUNT(*)
FROM olist_closed_deals
GROUP BY lead_behaviour_profile, sdr_id
ORDER BY COUNT(*) DESC;

#리드유형-SR PAIR
SELECT lead_behaviour_profile, 
	SUBSTRING(sr_id, 1, 4) AS SR, 
    COUNT(*)
FROM olist_closed_deals
GROUP BY lead_behaviour_profile, sr_id
ORDER BY COUNT(*) DESC;

#lead_behaviour_profile별 평균 매출
SELECT CD.lead_behaviour_profile,
	ROUND((SUM(OD.price) / COUNT(*)), 0) AS AVERAGE_SALES
FROM olist_ecommerce.olist_order_items_dataset OD
LEFT JOIN olist_marketing.olist_closed_deals CD ON CD.seller_id = OD.seller_id
LEFT JOIN olist_marketing.olist_marketing_qualified_leads ML ON ML.mql_id = CD.mql_id
GROUP BY CD.lead_behaviour_profile
HAVING CD.lead_behaviour_profile LIKE 'cat' OR
	CD.lead_behaviour_profile LIKE 'eagle' OR
    CD.lead_behaviour_profile LIKE 'wolf' OR
    CD.lead_behaviour_profile LIKE 'shark'
ORDER BY AVERAGE_SALES DESC;
#cat의 평균 매출이 가장 높고, wolf가 낮음

#Segment별 계약 성사수 확인
SELECT business_segment, COUNT(*)
FROM olist_closed_deals
GROUP BY business_segment;
#TOP 1 - HOME DECO

#SEGMENT-SDR PAIR
SELECT business_segment, 
	SUBSTRING(sdr_id, 1, 4) AS SDR, 
    COUNT(*)
FROM olist_closed_deals
GROUP BY business_segment, SDR
ORDER BY COUNT(*) DESC;

#SEGMENT-SR PAIR
SELECT business_segment, 
	SUBSTRING(sr_id, 1, 4) AS SR, 
    COUNT(*)
FROM olist_closed_deals
GROUP BY business_segment, SR
ORDER BY COUNT(*) DESC;

#SDR-SR-Segment Pair
SELECT SUBSTRING(sr_id, 1, 4) AS SR, 
	SUBSTRING(sdr_id, 1, 4) AS SDR, 
    business_segment,
    COUNT(*)
FROM olist_closed_deals
GROUP BY SR, SDR, business_segment;

#리드 타입 확인
SELECT lead_type, COUNT(*)
FROM olist_closed_deals
GROUP BY lead_type;

#리드 타입-SDR PAIR
SELECT lead_type, 
	SUBSTRING(sdr_id, 1, 4) AS SDR, 
    COUNT(*)
FROM olist_closed_deals
GROUP BY lead_type, sdr_id;

#리드 타입-SR PAIR
SELECT lead_type, 
	SUBSTRING(sr_id, 1, 4) AS SR, 
    COUNT(*)
FROM olist_closed_deals
GROUP BY lead_type, sr_id;

#2018.01의 각 SR별 매출
SELECT SUBSTRING(CD.sr_id, 1, 4) AS SR,
	ROUND(SUM(OD.price), 0) AS total_sales
FROM olist_ecommerce.olist_order_items_dataset OD
LEFT JOIN olist_marketing.olist_closed_deals CD ON CD.seller_id = OD.seller_id
LEFT JOIN olist_marketing.olist_marketing_qualified_leads ML ON ML.mql_id = CD.mql_id
WHERE YEAR(CD.won_date) = 2018 AND MONTH(CD.won_date) = 01
GROUP BY CD.sr_id;
#cf)2017년의 계약건수가 매우 적고 2018이 대부분임

#2018년의 월별 SR별 계약 건수
SELECT 
    YEAR(CD.won_date) AS year,
    MONTH(CD.won_date) AS month,
    SUBSTRING(CD.sr_id, 1, 4) AS SR,
    COUNT(*) AS contract_count
FROM 
    olist_marketing.olist_closed_deals CD
WHERE 
    YEAR(CD.won_date) = 2018
GROUP BY 
    YEAR(CD.won_date),
    MONTH(CD.won_date),
    SUBSTRING(CD.sr_id, 1, 4)
ORDER BY year, month, SR;
#SR의 입/퇴사 날짜 등의 detail 정보 확인 가능

SELECT 
    YEAR(won_date) AS year,
    MONTH(won_date) AS month,
    SUM(CASE WHEN LEFT(sr_id, 4) = '0680' THEN 1 ELSE 0 END) AS SR680_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = '2695' THEN 1 ELSE 0 END) AS SR2695_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = '6565' THEN 1 ELSE 0 END) AS SR6565_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = '9749' THEN 1 ELSE 0 END) AS SR9749_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = '060c' THEN 1 ELSE 0 END) AS SR060c_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = '0a0f' THEN 1 ELSE 0 END) AS SR0a0f_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = '34d4' THEN 1 ELSE 0 END) AS SR34d4_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = '495d' THEN 1 ELSE 0 END) AS SR495d_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = '4b33' THEN 1 ELSE 0 END) AS SR4b33_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = '4ef1' THEN 1 ELSE 0 END) AS SR4ef1_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = '56bf' THEN 1 ELSE 0 END) AS SR56bf_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = '6aa3' THEN 1 ELSE 0 END) AS SR6aa3_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = '85fc' THEN 1 ELSE 0 END) AS SR85fc_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = '9ae0' THEN 1 ELSE 0 END) AS SR9ae0_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = '9d12' THEN 1 ELSE 0 END) AS SR9d12_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = '9e4d' THEN 1 ELSE 0 END) AS SR9e4d_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = 'a838' THEN 1 ELSE 0 END) AS SRa838_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = 'b90f' THEN 1 ELSE 0 END) AS SRb90f_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = 'c638' THEN 1 ELSE 0 END) AS SRc638_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = 'd3d1' THEN 1 ELSE 0 END) AS SRd3d1_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = 'de63' THEN 1 ELSE 0 END) AS SRde63_contract_count,
    SUM(CASE WHEN LEFT(sr_id, 4) = 'fbf4' THEN 1 ELSE 0 END) AS SRfbf4_contract_count
FROM 
    olist_marketing.olist_closed_deals
WHERE 
    YEAR(won_date) = 2018
GROUP BY 
    YEAR(won_date), MONTH(won_date)
ORDER BY 
    year, month;


-- 시간별 분석


# MQL의 유입 요일 분석
SELECT
    DAYNAME(first_contact_date) AS day_week, 
    COUNT(*) AS traffic,
    COUNT(*) / (SELECT COUNT(*) FROM olist_marketing_qualified_leads) * 100 AS ratio
FROM
    olist_marketing_qualified_leads
GROUP BY day_week
ORDER BY traffic DESC;

#2018년의 월별 계약 건수
SELECT 
    YEAR(CD.won_date) AS year,
    MONTH(CD.won_date) AS month,
    COUNT(CD.seller_id) AS contract_count
FROM 
    olist_marketing.olist_closed_deals CD
WHERE 
    YEAR(CD.won_date) = 2018
GROUP BY 
    YEAR(CD.won_date),
    MONTH(CD.won_date)
ORDER BY year, month;

# SR 요일별 계약건수 분석
SELECT DAYNAME(won_date) AS day_of_week, COUNT(*)
FROM olist_closed_deals
GROUP BY day_of_week;
#평일에 계약건수가 높음 > 당연

#SDR-SR PAIR의 평균 계약 소요 시간
SELECT SUBSTRING(OCD.sr_id, 1, 4) AS SR, 
    SUBSTRING(OCD.sdr_id, 1, 4) AS SDR, 
    AVG(DATEDIFF(OCD.won_date, OQL.first_contact_date)) AS average_days
FROM olist_closed_deals OCD
JOIN olist_marketing_qualified_leads OQL ON OQL.mql_id = OCD.mql_id
GROUP BY SUBSTRING(OCD.sr_id, 1, 4), SUBSTRING(OCD.sdr_id, 1, 4)
ORDER BY average_days DESC;

# MQL의 유입 경로별 요일 분석-피벗차트화
SELECT 
    origin,
    SUM(CASE WHEN DAYNAME(first_contact_date) = 'Monday' THEN 1 ELSE 0 END) AS Mon,
    SUM(CASE WHEN DAYNAME(first_contact_date) = 'Tuesday' THEN 1 ELSE 0 END) AS Tue,
    SUM(CASE WHEN DAYNAME(first_contact_date) = 'Wednesday' THEN 1 ELSE 0 END) AS Wed,
    SUM(CASE WHEN DAYNAME(first_contact_date) = 'Thursday' THEN 1 ELSE 0 END) AS Thur,
    SUM(CASE WHEN DAYNAME(first_contact_date) = 'Friday' THEN 1 ELSE 0 END) AS Fri,
    SUM(CASE WHEN DAYNAME(first_contact_date) = 'Saturday' THEN 1 ELSE 0 END) AS Sat,
    SUM(CASE WHEN DAYNAME(first_contact_date) = 'Sunday' THEN 1 ELSE 0 END) AS Sun
FROM 
    olist_marketing_qualified_leads
GROUP BY origin
ORDER BY origin;

# MQL의 유입 경로별 월별 분석
SELECT origin, 
	YEAR(first_contact_date) AS year,
   	MONTH(first_contact_date) AS month,
	COUNT(*)
FROM olist_marketing_qualified_leads
GROUP BY origin, year, month
HAVING year = 2018;

#월별 origin의 traffic - 피벗차트화
SELECT 
    origin,
    SUM(CASE WHEN MONTH(first_contact_date) = 1 THEN 1 ELSE 0 END) AS Jan,
    SUM(CASE WHEN MONTH(first_contact_date) = 2 THEN 1 ELSE 0 END) AS Feb,
    SUM(CASE WHEN MONTH(first_contact_date) = 3 THEN 1 ELSE 0 END) AS Mar,
    SUM(CASE WHEN MONTH(first_contact_date) = 4 THEN 1 ELSE 0 END) AS Apr,
    SUM(CASE WHEN MONTH(first_contact_date) = 5 THEN 1 ELSE 0 END) AS May,
    SUM(CASE WHEN MONTH(first_contact_date) = 6 THEN 1 ELSE 0 END) AS Jun,
    SUM(CASE WHEN MONTH(first_contact_date) = 7 THEN 1 ELSE 0 END) AS Jul,
    SUM(CASE WHEN MONTH(first_contact_date) = 8 THEN 1 ELSE 0 END) AS Aug,
    SUM(CASE WHEN MONTH(first_contact_date) = 9 THEN 1 ELSE 0 END) AS Sep,
    SUM(CASE WHEN MONTH(first_contact_date) = 10 THEN 1 ELSE 0 END) AS Oct,
    SUM(CASE WHEN MONTH(first_contact_date) = 11 THEN 1 ELSE 0 END) AS Nov,
    SUM(CASE WHEN MONTH(first_contact_date) = 12 THEN 1 ELSE 0 END) AS Dece
FROM 
    olist_marketing_qualified_leads
GROUP BY origin;