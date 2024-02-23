USE olist_ecommerce;
USE olist_marketing;

#TABLE JOIN
SELECT * 
FROM olist_marketing_qualified_leads MQL
JOIN olist_closed_deals OCD ON MQL.mql_id=OCD.mql_id
;

#SR 등급 산정 - 계약수
SELECT SUBSTRING(sr_id, 1, 4) AS SR, 
	COUNT(sr_id) AS closed_deals_count
FROM olist_closed_deals
GROUP BY sr_id
HAVING
#C등급-1사분위구간 COUNT(*) < 25
#B등급-중앙값까지구간 25 <= COUNT(*) AND COUNT(*) < 44
#A등급-3사분위구간 44 <= COUNT(*) AND COUNT(*) < 61
61 <= COUNT(*); #S등급

#SR 등급 산정 - 매출
SELECT SUBSTRING(CD.sr_id, 1, 4) AS SR,
	ROUND(SUM(OD.price), 0) AS TOTAL
FROM olist_ecommerce.olist_order_items_dataset OD
LEFT JOIN olist_marketing.olist_closed_deals CD ON CD.seller_id = OD.seller_id
LEFT JOIN olist_marketing.olist_marketing_qualified_leads ML ON ML.mql_id = CD.mql_id
GROUP BY CD.sr_id
HAVING 
#C등급-1사분위구간 TOTAL < 9141
#B등급-중앙값까지구간 9141 <= TOTAL AND TOTAL < 31650
#A등급-3사분위구간 31650 <= TOTAL AND TOTAL < 47345
47345 <= TOTAL; #S등급;

#SR 등급 산정 - 계약소요시간
SELECT SUBSTRING(OCD.sr_id, 1, 4) AS SR, 
    AVG(DATEDIFF(OCD.won_date, OQL.first_contact_date)) AS average_days
FROM olist_closed_deals OCD
JOIN olist_marketing_qualified_leads OQL ON OQL.mql_id = OCD.mql_id
GROUP BY SUBSTRING(OCD.sr_id, 1, 4)
HAVING 
#C등급-1사분위구간 average_days > 88
#B등급-중앙값까지구간 48 < average_days AND average_days <= 88
#A등급-3사분위구간 27 < average_days AND average_days <= 48
27 >= average_days; #S등급;

SELECT CD.mql_id,
	ROUND(SUM(OD.price), 0) AS TOTAL
FROM olist_ecommerce.olist_order_items_dataset OD
LEFT JOIN olist_marketing.olist_closed_deals CD ON CD.seller_id = OD.seller_id
LEFT JOIN olist_marketing.olist_marketing_qualified_leads ML ON ML.mql_id = CD.mql_id
GROUP BY CD.mql_id;