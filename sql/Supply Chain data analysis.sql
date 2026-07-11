use electronics_supplyChain
select * from electronics_supplyChain

-------------------------------
-- 1) Duplicate Records Removed
-------------------------------

select *
from (
    select *,
    row_number() over(partition by Order_ID order by (select null)) as rn
    from electronics_supplyChain
) t
where rn = 1

--------

select 
count(*) as Duplicate_Count
from (
    select 
    Order_ID,
    count(*) as Total
    from electronics_supplyChain
    group by Order_ID
    having count(*) > 1
) t;



------------------------------------
-- 2)Date Processing and Validation
------------------------------------

-- Date Conversion
ALTER TABLE electronics_supplyChain
ALTER COLUMN Order_Date DATE;

ALTER TABLE electronics_supplyChain
ALTER COLUMN Ship_Date DATE;

ALTER TABLE electronics_supplyChain
ALTER COLUMN Delivery_Date DATE;


-- Date Validation

-- Remove orders with future dates
DELETE FROM electronics_supplyChain
WHERE Order_Date > GETDATE();


-- Ensure correct chronological sequence
DELETE FROM electronics_supplyChain
WHERE Ship_Date < Order_Date;


DELETE FROM electronics_supplyChain
WHERE Delivery_Date < Ship_Date;

--------------
------------------------------------
-- Check Date Data Types
------------------------------------

SELECT 
COLUMN_NAME,
DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'electronics_supplyChain'
AND COLUMN_NAME IN ('Order_Date','Ship_Date','Delivery_Date');


-------------------------------
-- 4) Text Standardization
-------------------------------

UPDATE electronics_supplyChain
SET 
Product_type = TRIM(Product_type),
Category = TRIM(Category),
Sales_Channel = TRIM(Sales_Channel),
Payment_Method = TRIM(Payment_Method),
Region = TRIM(Region),
Supplier_name = TRIM(Supplier_name),
Return_Reason = TRIM(Return_Reason),
Customer_demographics = TRIM(Customer_demographics);


UPDATE electronics_supplyChain
SET 
Product_type = LOWER(Product_type),
Category = LOWER(Category),
Sales_Channel = LOWER(Sales_Channel),
Payment_Method = LOWER(Payment_Method),
Region = LOWER(Region),
Supplier_name = LOWER(Supplier_name),
Return_Reason = LOWER(Return_Reason),
Customer_demographics = LOWER(Customer_demographics);

-------

SELECT
'Text Standardization' AS Validation_Check,
COUNT(*) AS Issues_Found,
'Completed' AS Status
FROM electronics_supplyChain
WHERE
Product_type <> TRIM(Product_type)
OR Category <> TRIM(Category)
OR Sales_Channel <> TRIM(Sales_Channel)
OR Payment_Method <> TRIM(Payment_Method)
OR Region <> TRIM(Region)
OR Supplier_name <> TRIM(Supplier_name)
OR Return_Reason <> TRIM(Return_Reason)
OR Customer_demographics <> TRIM(Customer_demographics)

-------------------------------
-- 5) Missing Value Handling
-------------------------------

UPDATE electronics_supplyChain
SET Return_Reason = 'no return'
WHERE Units_Returned = 0;


UPDATE t1
SET customer_demographics = t2.customer_demographics
FROM electronics_supplyChain t1
OUTER APPLY 
(
    SELECT TOP 1 customer_demographics
    FROM electronics_supplyChain t2
    WHERE t2.order_id <= t1.order_id
    AND t2.customer_demographics <> 'unknown'
    ORDER BY t2.order_id DESC
) t2
WHERE t1.customer_demographics = 'unknown';

---------
SELECT 
'All Columns Missing Values Check' AS Validation_Check,
(
    SELECT COUNT(*)
    FROM electronics_supplyChain
    WHERE 
    Order_ID IS NULL
    OR Order_Date IS NULL
    OR Ship_Date IS NULL
    OR Delivery_Date IS NULL
    OR Product_type IS NULL
    OR SKU IS NULL
    OR Category IS NULL
    OR Price IS NULL
    OR Revenue_generated IS NULL
    OR Profit IS NULL
    OR Customer_Satisfaction_Score IS NULL
    OR Customer_demographics IS NULL
    OR Sales_Channel IS NULL
    OR Payment_Method IS NULL
    OR Region IS NULL
    OR Supplier_name IS NULL
    OR Return_Reason IS NULL
) AS Missing_Count,
'Completed' AS Status;


------------------------------------
-- 6) Invalid Records Removal
------------------------------------

-- Remove negative Price values
UPDATE electronics_supplyChain
SET Price = 0
WHERE Price < 0;


-- Remove negative Discount values
UPDATE electronics_supplyChain
SET Discount = 0
WHERE Discount < 0;


-- Ensure Discount percentage is valid
UPDATE electronics_supplyChain
SET Discount = 100
WHERE Discount > 100;


-- Remove negative Revenue values
UPDATE electronics_supplyChain
SET Revenue_generated = 0
WHERE Revenue_generated < 0;


-- Remove negative Shipping Costs
UPDATE electronics_supplyChain
SET Shipping_costs = 0
WHERE Shipping_costs < 0;


-- Remove negative Manufacturing Costs
UPDATE electronics_supplyChain
SET Manufacturing_costs = 0
WHERE Manufacturing_costs < 0;


-- Remove negative Shipping Times
UPDATE electronics_supplyChain
SET Shipping_times = 0
WHERE Shipping_times < 0;


-- Remove negative Defect Rates
UPDATE electronics_supplyChain
SET Defect_rates = 0
WHERE Defect_rates < 0;


-- Ensure Defect Rate valid percentage
UPDATE electronics_supplyChain
SET Defect_rates = 100
WHERE Defect_rates > 100;


-- Remove negative Supplier Reliability Scores
UPDATE electronics_supplyChain
SET Supplier_Reliability_Score = 0
WHERE Supplier_Reliability_Score < 0;


-- Remove negative Quality Scores
UPDATE electronics_supplyChain
SET Quality_Score = 0
WHERE Quality_Score < 0;


-- Remove negative Customer Satisfaction Scores
UPDATE electronics_supplyChain
SET Customer_Satisfaction_Score = 0
WHERE Customer_Satisfaction_Score < 0;


-- Ensure Satisfaction Score within valid range
UPDATE electronics_supplyChain
SET Customer_Satisfaction_Score = 10
WHERE Customer_Satisfaction_Score > 10;


-- Ensure Products Sold is not negative
UPDATE electronics_supplyChain
SET Number_of_products_sold = 0
WHERE Number_of_products_sold < 0;


-- Ensure Returned Units are valid
UPDATE electronics_supplyChain
SET Units_Returned = Number_of_products_sold
WHERE Units_Returned > Number_of_products_sold;

---------
SELECT 
'Negative Values' AS Validation_Check,
COUNT(*) AS Issues_Found
FROM electronics_supplyChain
WHERE 
Price < 0
OR Revenue_generated < 0
OR Shipping_costs < 0
OR Manufacturing_costs < 0
OR Shipping_times < 0

UNION ALL

SELECT
'Discount Range',
COUNT(*)
FROM electronics_supplyChain
WHERE Discount NOT BETWEEN 0 AND 100

UNION ALL

SELECT
'Units Sold',
COUNT(*)
FROM electronics_supplyChain
WHERE Number_of_products_sold < 0

UNION ALL

SELECT
'Returned Units',
COUNT(*)
FROM electronics_supplyChain
WHERE Units_Returned > Number_of_products_sold;

-------------------------------
-- 7) Analysis Dataset Created (df_clean)
-------------------------------

ALTER TABLE electronics_supplyChain 
ALTER COLUMN Price DECIMAL(30,2);

ALTER TABLE electronics_supplyChain 
ALTER COLUMN Revenue_generated DECIMAL(30,2);

ALTER TABLE electronics_supplyChain 
ALTER COLUMN Profit DECIMAL(30,2);

ALTER TABLE electronics_supplyChain 
ALTER COLUMN Shipping_costs DECIMAL(30,2);

ALTER TABLE electronics_supplyChain 
ALTER COLUMN Manufacturing_costs DECIMAL(30,2);

ALTER TABLE electronics_supplyChain 
ALTER COLUMN Defect_rates DECIMAL(30,2);

ALTER TABLE electronics_supplyChain 
ALTER COLUMN Shipping_times DECIMAL(30,2);

ALTER TABLE electronics_supplyChain 
ALTER COLUMN Supplier_Reliability_Score DECIMAL(30,2);

ALTER TABLE electronics_supplyChain 
ALTER COLUMN Quality_Score DECIMAL(30,2);

ALTER TABLE electronics_supplyChain 
ALTER COLUMN Discount DECIMAL(30,2);

ALTER TABLE electronics_supplyChain 
ALTER COLUMN Customer_Satisfaction_Score DECIMAL(30,2);



-------------------------------
-- 8) Final Data Validation
-------------------------------

SELECT
'Total Records' AS Validation_Check,
COUNT(*) AS Result
FROM electronics_supplyChain

UNION ALL

SELECT
'Total Columns',
COUNT(*)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'electronics_supplyChain'

UNION ALL

SELECT
'Duplicate Records',
COUNT(*)
FROM (
    SELECT Order_ID
    FROM electronics_supplyChain
    GROUP BY Order_ID
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT
'Missing Values',
COUNT(*)
FROM electronics_supplyChain
WHERE 
Order_ID IS NULL
OR Order_Date IS NULL
OR Ship_Date IS NULL
OR Delivery_Date IS NULL

UNION ALL

SELECT
'Invalid Dates',
COUNT(*)
FROM electronics_supplyChain
WHERE
Ship_Date < Order_Date
OR Delivery_Date < Ship_Date

UNION ALL

SELECT
'Invalid Numeric Values',
COUNT(*)
FROM electronics_supplyChain
WHERE
Price < 0
OR Revenue_generated < 0
OR Shipping_costs < 0
OR Manufacturing_costs < 0

UNION ALL

SELECT
'Invalid Business Rules',
COUNT(*)
FROM electronics_supplyChain
WHERE
Discount NOT BETWEEN 0 AND 100
OR Units_Returned > Number_of_products_sold;

--Normalization

CREATE TABLE Suppliers (
    SupplierID INT PRIMARY KEY,
    Supplier_name VARCHAR(255),
    Avg_Reliability_Score FLOAT)

CREATE TABLE Products (
    SKU VARCHAR(50) PRIMARY KEY,
    Product_type VARCHAR(100),
    Category VARCHAR(100),
    Price DECIMAL(10, 2),
    Stock_levels INT,
    Reorder_Point INT,
    Stockout_Risk VARCHAR(50),
    Manufacturing_costs DECIMAL(10, 2),
    Quality_Score FLOAT,
    Defect_rates FLOAT,
    Production_volumes INT)

CREATE TABLE Orders (
    Order_ID VARCHAR(50) PRIMARY KEY, 
    Order_Date DATE,
    Ship_Date DATE,
    Delivery_Date DATE,
    SKU VARCHAR(50),
    Discount_Percent DECIMAL(5, 2), 
    Number_of_products_sold INT,
    Units_Returned INT,
    Return_Reason VARCHAR(255),
    Revenue_generated DECIMAL(15, 2),
    Profit DECIMAL(15, 2),
    Customer_Satisfaction_Score FLOAT,
    Customer_demographics VARCHAR(100),
    Sales_Channel VARCHAR(100),
    Payment_Method VARCHAR(100),
    Region VARCHAR(100),
    Lead_time INT,
    On_Time_Delivery VARCHAR(50),
    SupplierID INT,
    Shipping_times decimal(30,2),
    Shipping_costs decimal(30,2),
    
    CONSTRAINT FK_Orders_Products FOREIGN KEY (SKU) 
        REFERENCES Products(SKU),
    CONSTRAINT FK_Orders_Suppliers FOREIGN KEY (SupplierID) 
        REFERENCES Suppliers(SupplierID))


       SELECT * FROM electronics_supplyChain


WITH SupplierAgg AS (
    SELECT 
        Supplier_name,
        AVG(Supplier_Reliability_Score) AS Avg_Reliability_Score
    FROM electronics_supplyChain
    GROUP BY Supplier_name
)

INSERT INTO Suppliers (SupplierID, Supplier_name, Avg_Reliability_Score)
SELECT 
    DENSE_RANK() OVER (ORDER BY Supplier_name) AS SupplierID,
    Supplier_name,
    Avg_Reliability_Score
FROM SupplierAgg


INSERT INTO Products (
    SKU,Product_type,Category,Price,Stock_levels,Reorder_Point,Stockout_Risk,
    Manufacturing_costs,Quality_Score,Defect_rates,Production_volumes
)
SELECT 
    SKU,Product_type,Category,Price,Stock_levels,Reorder_Point,Stockout_Risk,
    Manufacturing_costs,Quality_Score,Defect_rates,Production_volumes
FROM electronics_supplyChain 

INSERT INTO Orders (
    Order_ID,Order_Date,Ship_Date,Delivery_Date,SKU,Discount_Percent,Number_of_products_sold,
    Units_Returned,Return_Reason,Revenue_generated,Profit,Customer_Satisfaction_Score,
    Customer_demographics,Sales_Channel,Payment_Method,Region,Lead_time,On_Time_Delivery,SupplierID,
    Shipping_times,Shipping_costs
    )
SELECT 
    e.Order_ID,e.Order_Date,e.Ship_Date,e.Delivery_Date,e.SKU,e.Discount,e.Number_of_products_sold,
    e.Units_Returned,e.Return_Reason,e.Revenue_generated,e.Profit,e.Customer_Satisfaction_Score,
    e.Customer_demographics,e.Sales_Channel,e.Payment_Method,e.Region,e.Lead_time,e.On_Time_Delivery,
    s.SupplierID,e.Shipping_times,e.Shipping_costs

   
   FROM electronics_supplyChain e
INNER JOIN Suppliers s
    ON e.Supplier_name = s.Supplier_name

SELECT 
    o.Order_ID,o.Order_Date,o.Ship_Date,o.Delivery_Date,o.SKU,p.Product_type,p.Category,p.Price,
    p.Stock_levels,o.Discount_Percent,o.Number_of_products_sold,o.Units_Returned,o.Return_Reason,
    o.Revenue_generated,o.Profit,o.Customer_Satisfaction_Score,o.Customer_demographics,o.Sales_Channel,
    o.Payment_Method,o.Region,o.Shipping_times,o.Shipping_costs,o.Lead_time,o.On_Time_Delivery,
    o.SupplierID,s.Supplier_name,s.Avg_Reliability_Score
FROM Orders o
INNER JOIN Products p ON o.SKU = p.SKU
INNER JOIN Suppliers s ON o.SupplierID = s.SupplierID

-- Domain 1: Revenues And Profitability
-- KPIS
SELECT SUM(Revenue_generated) AS Total_Revenue
FROM Orders

SELECT SUM(Profit) AS Total_Profit
FROM Orders

SELECT
    (SUM(Profit) * 100.0) / SUM([Revenue_generated]) AS Profit_Margin
FROM Orders

SELECT 
AVG( [Discount_Percent] ) AS Average_Discount
FROM Orders

-- Revenue and profitability per product
SELECT 
    p.Product_type,
    SUM(o.Revenue_generated) AS Total_Revenue,
    SUM(o.Profit) AS Total_Profit,
    (SUM(o.Profit) * 1.0 / NULLIF(SUM(o.Revenue_generated),0)) * 100 AS Profit_Margin_Percent
FROM Orders o
JOIN Products p ON o.SKU = p.SKU
GROUP BY p.Product_type
ORDER BY Total_Revenue DESC



-- Profit margin per region
SELECT 
    Region,
    SUM(Profit) AS Total_Profit,
    SUM(Revenue_generated) AS Total_Revenue,
    (SUM(Profit) * 1.0 / NULLIF(SUM(Revenue_generated),0)) * 100 AS Profit_Margin_Percent
FROM Orders
GROUP BY Region
ORDER BY Total_Profit DESC


-- Sales Channel Revenues and Profitability
SELECT 
    Sales_Channel,
    SUM(Revenue_generated) AS Total_Revenue,
    SUM(Profit) AS Total_Profit,
    SUM(Number_of_products_sold) AS Total_Volume
FROM Orders
GROUP BY Sales_Channel

-- Quarterly Trend
WITH QuarterlyData AS (
    SELECT 
       DATEPART(QUARTER, Order_Date) AS Quarter_Number,
        'Q' + CAST(DATEPART(QUARTER, Order_Date) AS VARCHAR(1)) AS Quarter_Name,
        SUM(Revenue_generated) AS Total_Revenue,
        SUM(Profit) AS Total_Profit
    FROM Orders
    GROUP BY DATEPART(QUARTER, Order_Date)
)
SELECT 
    Quarter_Name,
    Total_Revenue,
    Total_Profit
FROM QuarterlyData
ORDER BY Quarter_Number


-- Segments Revenue and Profit
SELECT 
    Customer_demographics,
    SUM(Revenue_generated) AS Total_Revenue,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY Customer_demographics
ORDER BY Total_Revenue DESC


-- % Discount on products sold
WITH DiscountRanges AS (
    SELECT 
        CASE 
            WHEN Discount_Percent BETWEEN 0 AND 5 THEN 'Low Discount (0-5%)'
            WHEN Discount_Percent BETWEEN 5 AND 10 THEN 'Medium Discount (5-10%)'
            ELSE 'High Discount (Above 10%)'
        END AS Discount_Category,
        Number_of_products_sold
    FROM Orders
),
CategoryTotals AS (
    SELECT 
        Discount_Category,
        SUM(Number_of_products_sold) AS Category_Volume
    FROM DiscountRanges
    GROUP BY Discount_Category
),
GrandTotal AS (
    SELECT SUM(Number_of_products_sold) AS Total_Volume
    FROM Orders
)
SELECT 
    ct.Discount_Category,
    ct.Category_Volume,
    CAST(100.0 * ct.Category_Volume / gt.Total_Volume AS DECIMAL(10,2)) AS Percentage_Of_Total
FROM CategoryTotals ct
CROSS JOIN GrandTotal gt
ORDER BY Percentage_Of_Total DESC



--  Revenue and Profit by Discount Level
WITH DiscountRanges AS (
    SELECT 
        CASE 
            WHEN Discount_Percent BETWEEN 0 AND 5 THEN 'Low Discount (0-5%)'
            WHEN Discount_Percent BETWEEN 5 AND 10 THEN 'Medium Discount (5-10%)'
            ELSE 'High Discount (Above 10%)'
        END AS Discount_Category,
        Revenue_generated,
        Profit
    FROM Orders
)
SELECT 
    Discount_Category,
    SUM(Revenue_generated) AS Total_Revenue,
    SUM(Profit) AS Total_Profit
FROM DiscountRanges
GROUP BY Discount_Category
HAVING SUM(Profit) > 0


-- domain 2 (customer experience and returns )
-- AVG Retuen Rate
SELECT 
    (SUM(Units_Returned) * 1.0 / SUM(Number_of_products_sold)) * 100 AS Average_Return_Rate
FROM Orders

-- Total Units Returned
SELECT 
    SUM(Units_Returned) AS Total_Units_Returned
FROM Orders

-- AVG Customer Satisfaction Score
SELECT 
    AVG(Customer_Satisfaction_Score) AS Average_Satisfaction_Score
FROM Orders
-- Total Estimated Return Loss

SELECT 
    SUM(o.Units_Returned * p.Price) AS Total_Estimated_Return_Loss
FROM orders o
JOIN products p ON o.SKU = p.SKU


--1. Return Reasons Across Regions
 SELECT 
    Region,
    Return_Reason,
    SUM(Units_Returned) AS Total_Units_Returned
FROM Orders
WHERE Return_Reason <> 'no return'
GROUP BY Region, Return_Reason
ORDER BY Region, Total_Units_Returned DESC

--2.	Return Rate & Units Returned by Sales Channel ?
SELECT 
    Sales_Channel,
    SUM(Units_Returned) AS Total_Units_Returned,
    (SUM(Units_Returned) * 1.0 / NULLIF(SUM(Number_of_products_sold), 0)) * 100 AS Return_Rate
FROM Orders
GROUP BY Sales_Channel
ORDER BY Return_Rate DESC


--3.	Units Returned by Return Reason and Product Type
SELECT 
    o.Return_Reason,
    p.Product_Type,
    SUM(o.Units_Returned) AS Total_Units_Returned
FROM Orders o
JOIN Products p ON o.SKU = p.SKU
WHERE o.Return_Reason <> 'no return' 
GROUP BY o.Return_Reason, p.Product_Type
ORDER BY o.Return_Reason, Total_Units_Returned DESC

--4.	How does satisfaction vary across customer demographics?
SELECT 
    o.Customer_demographics,
    AVG(o.Customer_Satisfaction_Score) AS avg_csat
FROM Orders o
GROUP BY 
    o.Customer_demographics
ORDER BY avg_csat ASC


--5.	Which regions have the highest return rates and total estimated loss
SELECT 
    o.Region,
    (SUM(o.Units_Returned) * 1.0 / NULLIF(SUM(o.Number_of_products_sold), 0)) * 100 AS Average_Return_Rate,
    SUM(o.Units_Returned * p.Price) AS Total_Estimated_Return_Loss
FROM Orders o
JOIN Products p ON o.SKU = p.SKU 
GROUP BY o.Region
ORDER BY Average_Return_Rate DESC


-- domain 3 (supplier performance)
-- Average Supplier Quality Score
SELECT 
    AVG(Quality_Score) AS Average_Supplier_Quality_Score
FROM 
    Products


-- Average Supplier Reliability Score
SELECT 
    AVG(Avg_Reliability_Score) AS Average_Supplier_Reliability_Score
FROM 
    Suppliers

-- Average Defect Rate
SELECT 
    AVG(Defect_rates) AS Average_Defect_Rate
FROM 
    Products

--1.	Supplier Profit & Quality Score
SELECT 
    s.Supplier_name, 
    SUM(o.Profit) AS Total_Profit, 
    AVG(p.Quality_Score) AS Average_Quality_Score
FROM 
    Suppliers s
JOIN 
    Orders o ON s.SupplierID = o.SupplierID
JOIN 
    Products p ON o.SKU = p.SKU
GROUP BY 
    s.Supplier_name
ORDER BY 
    Total_Profit DESC


--2.	Supplier Value Score
SELECT 
    Supplier_name,
    ROUND((Avg_Quality * Avg_Reliability) / Avg_Defect, 3) AS Value_Score
FROM (
    SELECT 
        s.Supplier_name,
        AVG(p.Quality_Score) AS Avg_Quality,
        AVG(s.Avg_Reliability_Score) AS Avg_Reliability,
        AVG(p.Defect_rates) AS Avg_Defect
    FROM Suppliers s
    JOIN Orders o ON s.SupplierID = o.SupplierID
    JOIN Products p ON o.SKU = p.SKU
    GROUP BY s.Supplier_name
) AS AggregatedData
ORDER BY Value_Score DESC

--3.	Which suppliers provide high quality at optimal cost?
SELECT 
    s.Supplier_name,
    AVG(p.Quality_Score) AS avg_quality,
    AVG(p.Manufacturing_costs) AS avg_cost
FROM Orders o
JOIN Suppliers s 
    ON o.SupplierID = s.SupplierID
JOIN Products p 
    ON o.SKU = p.SKU
GROUP BY s.Supplier_name
ORDER BY avg_quality DESC, avg_cost ASC

--4.	Is there a correlation between suppliers and high return rates?
SELECT 
    s.Supplier_name,
    SUM(o.Units_Returned) * 1.0 / SUM(o.Number_of_products_sold) AS return_rate
FROM Orders o
JOIN Suppliers s 
    ON o.SupplierID = s.SupplierID
GROUP BY s.Supplier_name
ORDER BY return_rate DESC


--5.	Avg defect rates affect each supplier
SELECT 
    s.Supplier_name, 
    AVG(p.Defect_rates) AS average_defect_rate
FROM 
    Suppliers s
JOIN 
    Orders o ON s.SupplierID = o.SupplierID
JOIN 
    Products p ON o.SKU = p.SKU
GROUP BY 
    s.Supplier_name
ORDER BY 
    average_defect_rate DESC


-- Domain 4: Inventory & Demand Planning
-----------------------------
-- KPI 1: Total Production Volume
-----------------------------
SELECT

SUM([Production_volumes]) AS total_production_volume

FROM electronics_supplyChain;


-----------------------------
-- KPI 2: Total Units Sold
-----------------------------
SELECT

SUM(Number_of_products_sold) AS total_units_sold

FROM electronics_supplyChain;


-----------------------------
-- KPI 3: Total Stock
-----------------------------
SELECT

SUM([Stock_levels]) AS total_stock

FROM electronics_supplyChain;


-----------------------------
-- KPI 4: Inventory Gap
-----------------------------
SELECT

SUM([Production_volumes]-([Number_of_products_sold]+[Stock_levels])) AS inventory_gap

FROM electronics_supplyChain;


-----------------------------
-- KPI 5: Total Products
-----------------------------
SELECT

COUNT(DISTINCT SKU) AS total_products

FROM electronics_supplyChain;


-----------------------------
-- Chart 1: SKUs by Stockout Risk
-----------------------------
SELECT

[Stockout_Risk] AS stockout_risk,

COUNT(*) AS sku_count,

CAST(COUNT(*)*100.0/
SUM(COUNT(*)) OVER() AS DECIMAL(5,1)) AS percentage

FROM electronics_supplyChain

GROUP BY [Stockout_Risk]

ORDER BY sku_count DESC;


-----------------------------
-- Chart 2: Production Volume by Product Type
-----------------------------
SELECT
[Product_type],
CAST(
CAST(
SUM([Production_volumes]) * 100.0 /
SUM(SUM([Production_volumes])) OVER()
AS DECIMAL(5,2)
) AS VARCHAR(10)
) + '%' AS production_percentage

FROM electronics_supplyChain

GROUP BY [Product_type]

ORDER BY
SUM([Production_volumes]) DESC;


-----------------------------
-- Chart 3: Inventory Gap & Stock levels by Product Type
-----------------------------
SELECT

[Product_type],

SUM([Production_volumes]-([Number_of_products_sold]+[Stock_levels])) AS inventory_gap,
SUM([Stock_levels])

FROM electronics_supplyChain

GROUP BY [Product_type]

ORDER BY inventory_gap DESC;


-----------------------------
-- Chart 4: Profit Margin vs Units Sold by Product Type
-----------------------------
SELECT [Product_type],
SUM([Number_of_products_sold]) AS units_sold,
CAST(CAST(SUM([Profit]) * 100.0 / SUM([Revenue_generated])AS DECIMAL(10,2))AS VARCHAR(10)) + '%' AS profit_margin
FROM electronics_supplyChain
GROUP BY [Product_type]
ORDER BY units_sold DESC;

-----------------------------
-- Chart 5: Top & Bottom 5 SKUs by Units Sold
-----------------------------
SELECT * FROM( SELECT TOP 5 SKU,
SUM([Number_of_products_sold]) AS units_sold,
'Top 5' AS category
FROM electronics_supplyChain
GROUP BY SKU
ORDER BY units_sold DESC) t
UNION ALL
SELECT * FROM( SELECT TOP 5 SKU,
SUM([Number_of_products_sold]) AS units_sold,
'Bottom 5' AS category
FROM electronics_supplyChain
GROUP BY SKU
ORDER BY units_sold ASC) b;


-----------------------------
-- Chart 6: Products by Price Range
-----------------------------
SELECT
CASE
    WHEN Price < 400 THEN '0-400'
    WHEN Price < 800 THEN '400-800'
    WHEN Price < 1200 THEN '800-1200'
    ELSE '1200+'
END AS price_range,
COUNT(*) AS sku_count,
CAST( CAST(SUM(Profit) * 100.0 / SUM([Revenue_generated]) AS DECIMAL(10,2)) AS VARCHAR(10)) + '%' AS profit_margin
FROM electronics_supplyChain
GROUP BY
CASE
    WHEN Price < 400 THEN '0-400'
    WHEN Price < 800 THEN '400-800'
    WHEN Price < 1200 THEN '800-1200'
    ELSE '1200+'
END
ORDER BY
MIN(
CASE
    WHEN Price < 400 THEN 1
    WHEN Price < 800 THEN 2
    WHEN Price < 1200 THEN 3
    ELSE 4
END
);

-----------------------------
-- Chart 7: Defect Rate by Product Type
-----------------------------
SELECT
[Product_type],

CAST(
    CAST(
        SUM([Defect_rates]) * 100.0 /
        SUM(SUM([Defect_rates])) OVER()
    AS DECIMAL(10,1))
AS VARCHAR(10)) + '%' AS defect_rate

FROM electronics_supplyChain

GROUP BY [Product_type]

ORDER BY SUM([Defect_rates]) DESC;



-- Domain 5: Logistics & Delivery --

-- KPIs --
-- KPI 1: Total Shipping Cost
SELECT 
CAST(SUM(Shipping_Costs) AS DECIMAL(14,2)) AS total_shipping_cost
FROM electronics_supplyChain;

-- KPI 2: Avg_lead_time
SELECT 
CAST(AVG(CAST(Lead_Time AS DECIMAL(10,2))) AS DECIMAL(10,1)) AS Avg_lead_time
FROM electronics_supplyChain

-- KPI 3: Avg_shipping_time
SELECT 
CAST(AVG(Shipping_Times) AS DECIMAL(10,1)) AS Avg_shipping_times
FROM electronics_supplyChain

-- KPI 4: Avg Shipping Cost
SELECT 
CAST(avg(Shipping_Costs) AS DECIMAL(14,2)) AS avg_shipping_cost
FROM electronics_supplyChain;

-- Questions --
--1--
-- Insight:Shipping Time per Region
SELECT                                          
Region AS Regions,
CAST(AVG(Shipping_Times) AS DECIMAL(10,2)) AS avg_shipping_time
FROM electronics_supplyChain
GROUP BY Region
ORDER BY Regions ASC;

---2---
--- Region Shipping Performance ----

WITH base AS ( SELECT Region, Product_Type, Number_of_Products_Sold, Shipping_Costs
FROM electronics_supplyChain),

aggregated AS (SELECT  Region, SUM(Number_of_Products_Sold) AS total_units_shipped, SUM(Shipping_Costs) AS total_shipping_cost
FROM base
GROUP BY Region),

top_product AS ( SELECT Region, Product_Type, SUM(Number_of_Products_Sold) AS units_per_product, ROW_NUMBER() OVER ( PARTITION BY Region 
 ORDER BY SUM(Number_of_Products_Sold) DESC ) AS rank_num
 FROM base
 GROUP BY Region, Product_Type)

SELECT 

--- Region ---
a.Region AS Region,

--- total units shipped ---
a.total_units_shipped,

--- total shipping cost ---
CAST(a.total_shipping_cost AS DECIMAL(14,2)) AS total_shipping_cost,

--- shipping percentage ---
CAST(CAST(a.total_units_shipped * 100.0 / SUM(a.total_units_shipped) OVER() AS DECIMAL(5,1)) AS VARCHAR) + '%' AS shipping_percentage,

--- top product ---
t.Product_Type AS top_product
FROM aggregated a
JOIN top_product t 
ON a.Region = t.Region AND t.rank_num = 1
ORDER BY a.total_units_shipped DESC;

---3---
--- On-Time vs Delayed Orders ---

SELECT 
--- delivery status ---
CASE 
    WHEN On_Time_Delivery = 1 THEN 'Yes'
    ELSE 'No'
END AS on_time_Deliv,

--- total orders ---
COUNT(*) AS total_orders,

--- orders percentage ---
CAST(CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,1)) AS VARCHAR) + '%' AS orders_percentage
FROM electronics_supplyChain
GROUP BY 
CASE 
    WHEN On_Time_Delivery = 1 THEN 'Yes'
    ELSE 'No'
END
ORDER BY on_time_Deliv DESC;

---4---
---  Delivery Performance ---

SELECT 
-- Region
Region,

-- total orders
COUNT(*) AS total_orders,

-- on-time orders
SUM(CASE 
        WHEN On_Time_Delivery = 1 THEN 1
        ELSE 0
    END) AS on_time_orders,

-- delayed orders
SUM(CASE 
        WHEN On_Time_Delivery = 0 THEN 1
        ELSE 0
    END) AS delayed_orders

FROM electronics_supplyChain

GROUP BY Region

ORDER BY total_orders DESC;

--5--
-- Region Shipping Performance --
SELECT p.Product_type,
SUM(o.[Shipping_costs]) AS total_shipping_cost,
SUM(o.Number_of_products_sold) AS total_units_shipped
FROM Orders o
LEFT JOIN Products p ON o.SKU = p.SKU
GROUP BY p.Product_type
ORDER BY total_units_shipped DESC;

--6--
-- Delivery Status vs Profit --
SELECT 
CASE 
    WHEN On_Time_Delivery = 1 THEN 'On-Time'
    ELSE 'Delayed'
END AS status,
CAST(SUM(Profit) AS INT) AS total_profit
FROM Orders
GROUP BY On_Time_Delivery
ORDER BY total_profit DESC;