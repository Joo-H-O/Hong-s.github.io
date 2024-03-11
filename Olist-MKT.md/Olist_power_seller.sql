USE olist_ecommerce;
USE olist_marketing;

#Olist Dataset과 연결
SELECT *
FROM olist_ecommerce.olist_order_items_dataset OD
LEFT JOIN olist_marketing.olist_closed_deals CD ON CD.seller_id = OD.seller_id
LEFT JOIN olist_marketing.olist_marketing_qualified_leads ML ON ML.mql_id = CD.mql_id;

SELECT* FROM seller_money;

#매출 상위 20% SELLER VIEW
CREATE OR REPLACE VIEW seller_money AS

WITH SalesBySeller AS (
    SELECT 
        SUBSTRING(seller_id, 1, 4) AS seller,
        SUM(price) AS total_sales,
        PERCENT_RANK() OVER (ORDER BY SUM(price) DESC) AS sales_percent_rank
    FROM olist_ecommerce.olist_order_items_dataset
    GROUP BY seller
)
SELECT 
    seller,
    total_sales
FROM SalesBySeller
WHERE sales_percent_rank <= 0.2;

#리뷰 4점 이상 SELLER VIEW
CREATE OR REPLACE VIEW seller_review AS
SELECT SUBSTRING(OID.seller_id, 1, 4) AS seller,
	AVG(ORD.review_score) AS score
FROM olist_ecommerce.olist_order_reviews_dataset ORD
JOIN olist_ecommerce.olist_order_items_dataset OID ON ORD.order_id = OID.order_id
GROUP BY seller
HAVING score >= 4;

#매출 상위 20% SELLER-INTERSECTION-리뷰 4점 이상 SELLER = POWER SELLER
CREATE OR REPLACE VIEW intersection_view AS
SELECT seller
FROM seller_money
INTERSECT
SELECT seller
FROM seller_review;

SELECT seller
FROM intersection_view;

#POWER SELLER 중 mql data에 있는 seller view 생성
CREATE OR REPLACE VIEW mql_seller AS
SELECT seller
FROM intersection_view
INTERSECT
SELECT substring(seller_id, 1, 4)
FROM olist_closed_deals;
USE olist_marketing;
SELECT seller
FROM mql_seller;

#power seller 중 mql data에 있는 seller list와 매출 확인
SELECT MS.seller,
       OS.total_sales
FROM mql_seller MS
LEFT JOIN (
    SELECT seller, SUM(total_sales) AS total_sales
    FROM seller_money
    GROUP BY seller
) OS ON MS.seller = OS.seller;

#seller-mql전체 매출 확인
SELECT CD.mql_id,
	ROUND(SUM(OD.price), 0) AS TOTAL
FROM olist_ecommerce.olist_order_items_dataset OD
LEFT JOIN olist_marketing.olist_closed_deals CD ON CD.seller_id = OD.seller_id
LEFT JOIN olist_marketing.olist_marketing_qualified_leads ML ON ML.mql_id = CD.mql_id
GROUP BY CD.mql_id;

USE olist_ecommerce;

SELECT 
    seller_id,
    SUM(price) AS total_sales
FROM 
    olist_order_items_dataset
GROUP BY 
    seller_id
HAVING 
    SUBSTRING(seller_id, 1, 4) IN ('7d13', 'ba90', 'c70c', '7e1f', '6121', '01fd', '6061', 'c510', '70c2', '8a43', '4bfc', '8476', 'e0a3', 'ade4', 'cc63', 'f1fd', '58f1', '33dd', 'a63b', '516e', '5670', 'dbdd', '02f6', 'ba14', '0691', 'd66c', '4d00', 'd566', 'dfa0');

#전체 셀러의 매출 확인
SELECT seller_id,
	SUM(price)
FROM olist_order_items_dataset
GROUP BY seller_id;

SELECT PW.seller_id,
       SUM(PW.price) AS total_sales
FROM olist_order_items_dataset PW
WHERE PW.seller_id IN (
    SELECT MS.seller
    FROM mql_seller MS
)
GROUP BY PW.seller_id;

#power seller - lead type
SELECT lead_type, COUNT(*) AS count
FROM olist_closed_deals
WHERE LEFT(seller_id, 4) IN (
    SELECT seller
    FROM mql_seller
)
GROUP BY lead_type;
#Online Big, Medium

#power seller - lead behavior
SELECT lead_behaviour_profile, COUNT(*) AS count
FROM olist_closed_deals
WHERE LEFT(seller_id, 4) IN (
    SELECT seller
    FROM mql_seller
)
GROUP BY lead_behaviour_profile;
#Cat, Eagle

#power seller - business segment
SELECT business_segment, COUNT(*) AS count
FROM olist_closed_deals
WHERE LEFT(seller_id, 4) IN (
    SELECT seller
    FROM mql_seller
)
GROUP BY business_segment;

#power seller - business type
SELECT business_type, COUNT(*) AS count
FROM olist_closed_deals
WHERE LEFT(seller_id, 4) IN (
    SELECT seller
    FROM mql_seller
)
GROUP BY business_type;
    
#power seller - origin
SELECT MQL.origin,
	COUNT(*) AS count
FROM olist_closed_deals OCD
JOIN olist_marketing_qualified_leads MQL ON MQL.mql_id = OCD.mql_id
WHERE LEFT(seller_id, 4) IN (
	SELECT seller
	FROM mql_seller
    )
GROUP BY MQL.origin;
    
#power seller - landing page
SELECT SUBSTRING(MQL.landing_page_id, 1, 4) AS LANDING,
	COUNT(*) AS count
FROM olist_closed_deals OCD
JOIN olist_marketing_qualified_leads MQL ON MQL.mql_id = OCD.mql_id
WHERE LEFT(seller_id, 4) IN (
	SELECT seller
	FROM mql_seller
    )
GROUP BY LANDING;
    
#power seller - 계약체결걸린일수
SELECT SUBSTRING(OCD.seller_id, 1, 4), 
	DATEDIFF(OCD.won_date, MQL.first_contact_date)
FROM olist_closed_deals OCD
JOIN olist_marketing_qualified_leads MQL ON MQL.mql_id = OCD.mql_id
WHERE LEFT(seller_id, 4) IN (
	SELECT seller
	FROM mql_seller
    );
    
#power seller - SR - SDR PAIR
SELECT SUBSTRING(OCD.seller_id, 1, 4), 
	SUBSTRING(OCD.sr_id, 1, 4),
    SUBSTRING(OCD.sdr_id, 1, 4)
FROM olist_closed_deals OCD
JOIN olist_marketing_qualified_leads MQL ON MQL.mql_id = OCD.mql_id
WHERE LEFT(seller_id, 4) IN (
	SELECT seller
	FROM mql_seller
    );
