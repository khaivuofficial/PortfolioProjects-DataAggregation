/* Database: AdventureWorksDW2019 */
USE AdventureWorksDW2019;
Go
-- 1) Retrieve a list of cost accounting accounts with a '-' sign in the formula. 
SELECT AccountDescription, AccountType, Operator
FROM DimAccount
WHERE AccountType = 'Expenditures'
AND Operator = '-';

/* 2) Retrieve a list of warehouse-type distributors with phone numbers starting with 1 (11) 
and using a bank with "Bank" at the end. */
SELECT ResellerName, Phone, BusinessType, BankName
FROM DimReseller
WHERE Phone LIKE '1 (11)%'
AND BusinessType = 'Warehouse'
AND BankName LIKE '%Bank'; 

/* 3) Retrieve a list of employees with the occupation "Technician" who were hired in or after 2007 
and have a salary less than 30, and they started working in 2008. */
SELECT FirstName, LastName, Title, HireDate, BaseRate, StartDate
FROM DimEmployee
WHERE (Title LIKE '%Technician%' AND HireDate >= '2007-01-01') 
OR (BaseRate < 30 AND StartDate >= '2008-01-01');

/* 4) Retrieve a list of products with the word "Frame" in their name, 
black color, and a size between 50 and 60. */
SELECT EnglishProductName, Color, Size
FROM DimProduct
WHERE EnglishProductName LIKE '%Frame%'
AND Color = 'Black' 
AND Size BETWEEN '50' AND '60';

-- 5) Retrieve information about customers who are older than all employees in the company.
SELECT FirstName, LastName, Gender, BirthDate
FROM DimCustomer
WHERE BirthDate < ALL(
	SELECT BirthDate
	FROM DimEmployee);

-- 6) Retrieve information about customers who placed orders totaling over 2200 in the year 2013.
SELECT FirstName, LastName, Gender 
FROM DimCustomer
WHERE CustomerKey = ANY(
	SELECT CustomerKey
	FROM FactInternetSales
	WHERE YEAR(OrderDate) = 2013
	AND SalesAmount >= 2200
	GROUP BY CustomerKey
	);

/* 7) Retrieve a list of employees in the Supervisor position 
who are male and work in the Production and Quality Assurance department, 
hired in the year 2008, sorted in ascending order by their start date. */
SELECT FirstName, Title, Gender, DepartmentName, HireDate, StartDate
FROM dbo.DimEmployee
WHERE Title LIKE '%Supervisor%' 
AND Gender = 'M'
AND DepartmentName IN ('Production', 'Quality Assurance') 
AND HireDate BETWEEN '2008-01-01' AND '2008-12-31' 
ORDER BY StartDate ASC;

-- 8) Count how many cities in the Geography table have names starting with "SAN" 
SELECT COUNT(*) FROM dbo.DimGeography WHERE City LIKE 'SAN%';

/* 9) Return a table that counts the number of customers distributed by Product Line, 
sorted in descending order. */
SELECT ProductLine, COUNT(ResellerKey) AS TotalReseller
FROM dbo.DimReseller 
GROUP BY ProductLine
ORDER BY TotalReseller DESC;

/* 10) Return the top 10 customers with the highest InternetSales revenue 
who placed orders in the year 2013. */
SELECT TOP(10) c.CustomerName, SUM(f.SalesAmount) AS SalesAmount
FROM FactInternetSales f
JOIN (SELECT CustomerKey, 
		CONCAT(FirstName, ' ', MiddleName, ' ', LastName) AS CustomerName 
	  FROM DimCustomer ) AS c 
ON f.CustomerKey = c.CustomerKey
WHERE YEAR(OrderDate) = 2013
GROUP BY c.CustomerName
ORDER BY SalesAmount DESC;

/* 11) Return a list of customers with yearly income higher than the average yearly income 
of the company's customer base. */
SELECT FirstName, LastName, YearlyIncome
FROM DimCustomer
WHERE YearlyIncome > 
	(SELECT AVG(YearlyIncome) FROM DimCustomer)
ORDER BY YearlyIncome DESC;

-- 12) Count the number of days for each fiscal year.
SELECT FiscalYear, COUNT(DateKey) AS NbDays
FROM DimDate
GROUP BY FiscalYear
ORDER BY FiscalYear DESC;

-- 13) Count the number of days for each normal calendar year.
SELECT CalendarYear, COUNT(DateKey) AS NbDays
FROM DimDate
GROUP BY CalendarYear
ORDER BY CalendarYear DESC;

/* 14) Return information about Product Type, Product Group, 
and Product with the total revenue for the year 2013. */
SELECT p.EnglishProductName, s.EnglishProductSubcategoryName, 
	c.EnglishProductCategoryName, SUM(f.SalesAmount) AS SalesAmount
FROM FactInternetSales f
	JOIN DimProduct p ON f.ProductKey = p.ProductKey
	JOIN DimProductSubcategory s ON p.ProductSubcategoryKey = s.ProductSubcategoryKey
	JOIN DimProductCategory c ON s.ProductCategoryKey = c.ProductCategoryKey
WHERE YEAR(OrderDate) = 2013
GROUP BY p.EnglishProductName, s.EnglishProductSubcategoryName, c.EnglishProductCategoryName;

-- 15) Return information about products with revenue in 2013 greater than in 2012.
WITH s AS (
    SELECT ProductKey, YEAR(OrderDate) AS Year, COUNT(SalesOrderNumber) AS NbOrders
    FROM FactInternetSales
    GROUP BY ProductKey,YEAR(OrderDate)
	)
SELECT s2013.ProductKey, s2013.NbOrders AS NbOrders2013, s2012.NbOrders AS NbOrders2012
FROM 
(SELECT * FROM s WHERE Year = 2013) AS s2013 
LEFT JOIN (SELECT * FROM s WHERE Year=2012) AS s2012 
ON s2013.ProductKey=s2012.ProductKey
WHERE s2013.NbOrders > s2012.NbOrders;

/* 16) Count the number of male customers by GeographyKey 
and filter out the places with more than 100 male customers. */
SELECT GeographyKey, COUNT(CustomerKey) 
FROM DimCustomer
WHERE MaritalStatus = 'M'
GROUP BY GeographyKey
HAVING COUNT(CustomerKey)  > 100
ORDER BY COUNT(CustomerKey)  DESC;

-- 17) Return the number of customers by income category for the year.
WITH s AS (
	SELECT CustomerKey, YearlyIncome, 
	CASE
		WHEN YearlyIncome <= 40000 THEN '<= 40K'
		WHEN YearlyIncome <= 60000 THEN 'From 40K - 60K'
		WHEN YearlyIncome <= 80000 THEN 'From 60K - 80K'
		WHEN YearlyIncome <= 100000 THEN 'From 80K - 100K'
		ELSE 'Over 100K'
	END AS Category	
	FROM DimCustomer)
SELECT Category, COUNT(CustomerKey) AS TotalCustomer
FROM s
GROUP BY Category
ORDER BY Category;

-- 18) Sort the customers into RFM segments based on the RFM method. 
-- Create RFM Table
WITH RFM AS(
	-- Calculate RFM metrics for each customer
	SELECT CONCAT_WS(FirstName, ' ', LastName) AS CustomerName, 
			CONVERT(DATE, MAX(OrderDate)) AS DateLastPurchase,
			DATEDIFF(DAY, MAX(OrderDate), GETDATE()) AS Recency,
			COUNT(DISTINCT SalesOrderNumber) AS Frequency,
			SUM(SalesAmount) AS Monetary
	FROM FactInternetSales AS fi
	JOIN DimCustomer AS c ON fi.CustomerKey = c.CustomerKey
	GROUP BY CONCAT_WS(FirstName, ' ', LastName)
),

Percentile_Rank AS(
	-- Calculate percentiles for Recency and Monetary
	SELECT *,
			PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Recency) OVER() AS Percentile_25_R,
			PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Recency) OVER() AS Percentile_50_R,
			PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Recency) OVER() AS Percentile_75_R,
			PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Monetary) OVER() AS Percentile_25_M,
			PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Monetary) OVER() AS Percentile_50_M,
			PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Monetary) OVER() AS Percentile_75_M
	FROM RFM
),

RFM_Score AS(
	-- Assign RFM scores based on percentiles
	SELECT *,
		CASE 
			WHEN Recency >= Percentile_75_R THEN 1
			WHEN Recency >= Percentile_50_R THEN 2
			WHEN Recency >= Percentile_25_R THEN 3
			ELSE 4
		END AS Score_Recency,
		CASE
			WHEN Frequency >= 4 THEN 4
			WHEN Frequency = 3 THEN 3
			WHEN Frequency = 2 THEN 2
			ELSE 1
		END AS Score_Frequency,
		CASE 
			WHEN Monetary >= Percentile_75_M THEN 4
			WHEN Monetary >= Percentile_50_M THEN 3
			WHEN Monetary >= Percentile_25_M THEN 2
			ELSE 1
		END AS Score_Monetary
	FROM Percentile_Rank
),

Score_RFM_Concat AS(
	-- Concatenate RFM scores into a single string
	SELECT *, 
			CONCAT(Score_Recency, Score_Frequency, Score_Monetary) AS Score_RFM
	FROM RFM_Score
)

SELECT *,
	CASE
		WHEN Score_RFM IN ('444') THEN 'Most Valuable'
		WHEN Score_RFM IN ('442', '441') THEN 'Low Spending Loyal'
		WHEN Score_RFM IN ('414', '413') THEN 'New High Spending'
		WHEN Score_RFM IN ('412', '411') THEN 'New Low Spending'
		WHEN Score_RFM IN ('144', '143', '134', '133') THEN 'Churn High Spending'
		WHEN Score_RFM IN ('434', '443', '344') THEN 'Valuable'
		WHEN Score_RFM IN ('334', '343', '433') THEN 'Frequent'
		WHEN Score_RFM IN ('432', '423', '324', '342', '234', '243') THEN 'Regular'
		ELSE 'Other'
	END AS RFM_Segment
FROM Score_RFM_Concat
ORDER BY Score_RFM DESC;
