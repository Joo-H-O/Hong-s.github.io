USE olist_ecommerce;
USE olist_marketing;

#TABLE JOIN
SELECT * 
FROM olist_marketing_qualified_leads MQL
JOIN olist_closed_deals OCD ON MQL.mql_id=OCD.mql_id
;

#SR 등급 나누기 (기준:각 사분위-계약건수/매출/계약소요시간)
SELECT #계약건수 등급
    COALESCE(deals.SR, sales.SR, days.SR) AS SR,
    COALESCE(deals.grade, '-') AS grade_deals,
    COALESCE(deals.closed_deals_count, 0) AS closed_deals_count,
    COALESCE(sales.grade, '-') AS grade_sales,
    COALESCE(sales.TOTAL, 0) AS total_sales,
    COALESCE(days.grade, '-') AS grade_days,
    COALESCE(days.average_days, 0) AS average_days
FROM 
    (SELECT 
         SUBSTRING(sr_id, 1, 4) AS SR,
         CASE 
             WHEN COUNT(DISTINCT mql_id) < 25 THEN 'C' #계약건수 1사분위
             WHEN COUNT(DISTINCT mql_id) >= 25 AND COUNT(DISTINCT mql_id) < 44 THEN 'B' #계약건수 2사분위
             WHEN COUNT(DISTINCT mql_id) >= 44 AND COUNT(DISTINCT mql_id) < 61 THEN 'A' #계약건수 3사분위
             ELSE 'S' #계약건수 4사분위
         END AS grade,
         COUNT(mql_id) AS closed_deals_count
     FROM 
         olist_closed_deals
     GROUP BY 
         SUBSTRING(sr_id, 1, 4)) AS deals
JOIN #계약매출 등급
    (SELECT 
         SUBSTRING(CD.sr_id, 1, 4) AS SR,
         ROUND(SUM(OD.price), 0) AS TOTAL,
         CASE
             WHEN ROUND(SUM(OD.price), 0) < 9141 THEN 'C' #계약매출 1사분위
             WHEN ROUND(SUM(OD.price), 0) >= 9141 AND ROUND(SUM(OD.price), 0) < 31650 THEN 'B' #계약매출 2사분위
             WHEN ROUND(SUM(OD.price), 0) >= 31650 AND ROUND(SUM(OD.price), 0) < 47345 THEN 'A' #계약매출 3사분위
             ELSE 'S' #계약매출 4사분위
         END AS grade
     FROM 
         olist_ecommerce.olist_order_items_dataset OD
     LEFT JOIN 
         olist_marketing.olist_closed_deals CD ON CD.seller_id = OD.seller_id
     LEFT JOIN 
         olist_marketing.olist_marketing_qualified_leads ML ON ML.mql_id = CD.mql_id
     GROUP BY 
         SUBSTRING(CD.sr_id, 1, 4)) AS sales
ON 
    deals.SR = sales.SR
JOIN #계약소요시간 등급
    (SELECT 
         SUBSTRING(OCD.sr_id, 1, 4) AS SR, 
         AVG(DATEDIFF(OCD.won_date, OQL.first_contact_date)) AS average_days,
         CASE
             WHEN AVG(DATEDIFF(OCD.won_date, OQL.first_contact_date)) > 88 THEN 'C' #계약소요시간 1사분위
             WHEN AVG(DATEDIFF(OCD.won_date, OQL.first_contact_date)) <= 88 AND AVG(DATEDIFF(OCD.won_date, OQL.first_contact_date)) > 48 THEN 'B' #계약소요시간 2사분위
             WHEN AVG(DATEDIFF(OCD.won_date, OQL.first_contact_date)) <= 48 AND AVG(DATEDIFF(OCD.won_date, OQL.first_contact_date)) > 27 THEN 'A' #계약소요시간 3사분위
             ELSE 'S' #계약소요시간 4사분위
         END AS grade
     FROM 
         olist_closed_deals OCD
     JOIN 
         olist_marketing_qualified_leads OQL ON OQL.mql_id = OCD.mql_id
     GROUP BY 
         SUBSTRING(OCD.sr_id, 1, 4)) AS days
ON 
    deals.SR = days.SR;