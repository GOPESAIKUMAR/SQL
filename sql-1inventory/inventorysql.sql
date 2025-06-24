-- create database --
create database total_db;

-- use database total_db --
use total_db;

-- create all tables --
-- 1. begin_inventory --
CREATE TABLE begin_inventory (
    InventoryId VARCHAR(50) PRIMARY KEY,
    Store INT,
    City VARCHAR(100),
    Brand VARCHAR(100),
    Description VARCHAR(255),
    Size VARCHAR(20),
    onHand INT,
    Price DECIMAL(10,2),
    startDate DATE
);

-- 2.end_inventory --
CREATE TABLE end_inventory (
    InventoryId VARCHAR(50) PRIMARY KEY,
    Store INT,
    City VARCHAR(100),
    Brand VARCHAR(100),
    Description VARCHAR(255),
    Size VARCHAR(20),
    onHand INT,
    Price DECIMAL(10,2),
    endDate DATE
);

-- 3. purchase_prices --
CREATE TABLE purchase_prices (
    Brand VARCHAR(100),
    Description VARCHAR(255),
    Price DECIMAL(10,2),
    Size VARCHAR(20),
    Volume VARCHAR(50),
    Classification VARCHAR(100),
    PurchasePrice DECIMAL(10,2),
    VendorNumber INT,
    VendorName VARCHAR(255)
);

-- 4.purchases --
CREATE TABLE purchases (
    InventoryId VARCHAR(50),
    Store INT,
    Brand VARCHAR(100),
    Description VARCHAR(255),
    Size VARCHAR(20),
    VendorNumber INT,
    VendorName VARCHAR(255),
    PONumber INT,
    PODate DATE,
    ReceivingDate DATE,
    InvoiceDate DATE,
    PayDate DATE,
    PurchasePrice DECIMAL(10,2),
    Quantity INT,
    Dollars DECIMAL(10,2),
    Classification VARCHAR(100)
);

-- 5.vendor_invoice --
CREATE TABLE vendor_invoice (
    VendorNumber INT,
    VendorName VARCHAR(255),
    InvoiceDate DATE,
    PONumber INT,
    PODate DATE,
    PayDate DATE,
    Quantity INT,
    Dollars DECIMAL(10,2),
    Freight DECIMAL(10,2),
    Approval DECIMAL(10,2)
);

-- 6.sales --
CREATE TABLE sales (
    InventoryId VARCHAR(50),
    Store INT,
    Brand VARCHAR(100),
    Description VARCHAR(255),
    Size VARCHAR(20),
    SalesQuantity INT,
    SalesDollars DECIMAL(10,2),
    SalesPrice DECIMAL(10,2),
    SalesDate DATE,
    Volume VARCHAR(50),
    Classification VARCHAR(100),
    ExciseTax DECIMAL(10,2),
    VendorNo INT,
    VendorName VARCHAR(255)
);

-- loaded files thorugh python(spyder)
-- use this for every table so all files tables can be loaded -
LOAD DATA INFILE '/path/to/file.csv' --file path
INTO TABLE your_table --table name
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- SQL QUERIES --
-- 1 TOTAL BEINNING INVENTORY PER BRAND--
SELECT Brand, SUM(onHand) AS total_begin_inventory
FROM begin_inventory
GROUP BY Brand
ORDER by SUM(onHand) desc limit 10;

 -- 2 Items with decreasing stock (begin > end) --
SELECT b.InventoryId,
b.Description, b.onHand AS begin_qty,  e.onHand AS end_qty FROM begin_inventory b 
JOIN end_inventory e ON b.InventoryId = e.InventoryId WHERE b.onHand > e.onHand;

-- 3 Total sales revenue per store --
SELECT Store,Round( SUM(SalesDollars) ,2)AS total_sales FROM  
sales GROUP BY Store
order by sum(SalesDollars) desc limit 10;

-- 4 Average sales price per product --
SELECT Description, round(Avg(SalesPrice),2) AS avg_sales_price
FROM (SELECT * FROM sales LIMIT 500000) AS sub
GROUP BY Description;

-- 5 Vendors with most purchases (by count)--
SELECT VendorName, COUNT(*) AS total_orders
FROM purchases GROUP BY VendorName 
ORDER BY total_orders DESC 
limit 10;

-- 6 Total freight cost paid to each vendor --
SELECT VendorName, round(SUM(Freight),2) AS total_freight
FROM vendor_invoice GROUP BY VendorName
ORDER BY total_freight DESC;

-- 7 Products sold below purchase price (loss) --
SELECT s.Description, s.SalesPrice, p.PurchasePrice FROM sales s 
JOIN purchase_prices p ON s.Description = p.Description AND s.Size = p.Size
WHERE s.SalesPrice < p.PurchasePrice;

-- 8 Most profitable products (highest margin) --
SELECT s.Description, round(  AVG(s.SalesPrice - p.PurchasePrice) ,2)AS avg_margin 
FROM (SELECT * FROM sales LIMIT 500000) as s
JOIN purchase_prices p ON s.Description = p.Description AND s.Size = p.Size 
GROUP BY s.Description 
ORDER BY avg_margin DESC LIMIT 5;

-- 9 Items with the highest ending inventory value --
SELECT end.Description, end.onHand * pp.PurchasePrice AS inventory_value 
FROM end_inventory end 
JOIN purchase_prices pp ON end.Description = pp.Description AND end.Size = pp.Size 
ORDER BY inventory_value DESC LIMIT 5;

-- 10 Average delivery time (ReceivingDate - PODate) --
SELECT AVG(DATEDIFF(ReceivingDate, PODate)) AS avg_delivery_days 
FROM purchases;

-- 11 Total excise tax paid per product --
SELECT Description, round(sum(ExciseTax),2) AS total_excise 
FROM (SELECT * FROM sales LIMIT 500000) as s
GROUP BY Description 
ORDER BY total_excise DESC limit 10;

-- 12 Monthly sales trend --
SELECT MONTH(SalesDate) AS sale_month, round(SUM(SalesDollars),2) AS total_sales 
FROM sales 
GROUP BY MONTH(SalesDate) 
ORDER BY sale_month;

-- 13 Classification-wise average purchase price --
SELECT Classification, AVG(PurchasePrice) AS avg_cost 
FROM purchase_prices 
GROUP BY Classification;

-- 14 Brands with the highest volume sold --
SELECT Brand, SUM(Volume * SalesQuantity) AS total_volume_sold 
FROM sales GROUP BY Brand 
ORDER BY total_volume_sold DESC;
select*from sales;

-- 15. Most Frequent Item Purchased Per Vendor
SELECT VendorName, Description, COUNT(*) AS times_purchased
FROM purchases
GROUP BY VendorName, Description
ORDER BY times_purchased DESC;

------------------------------------------------------------------------------------
-- 16 Vendors Who Supplied More Than the Average Quantity sub --
SELECT VendorName, SUM(SalesQuantity) AS total_qty
FROM (SELECT * FROM sales LIMIT 500000) as s
GROUP BY VendorName
HAVING SUM(SalesQuantity) >
  (SELECT AVG(total_vendor_qty)
   FROM (
   SELECT VendorName, SUM(SalesQuantity) AS total_vendor_qty
     FROM (SELECT * FROM sales LIMIT 500000) as s
     GROUP BY VendorName
   ) AS vendor_avg);

-- 17 Most Sold Product per Vendor cte sub--
WITH vendor_sales AS (
  SELECT VendorName, Description, SUM(SalesQuantity) AS total_qty,
         RANK() OVER (PARTITION BY VendorName 
  ORDER BY SUM(SalesQuantity) DESC) AS rnk
  FROM (SELECT * FROM sales LIMIT 500000) as s
  GROUP BY VendorName, Description
)
SELECT VendorName, Description, total_qty,rnk
FROM vendor_sales
WHERE rnk <= 3
ORDER BY total_qty DESC;

-- 18 Find Top 5 Vendors with Shortest Average Delivery Time
WITH avg_delivery AS (
  SELECT VendorName, AVG(DATEDIFF(ReceivingDate, PODate)) AS avg_days
  FROM purchases
  GROUP BY VendorName
)
SELECT *
FROM avg_delivery
ORDER BY avg_days ASC
LIMIT 5;
