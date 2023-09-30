/* Database: AdventureWorksDW2019 */
USE AdventureWorksDW2019;
Go
-- 1) Holen Sie eine Liste der Kostenrechnungskonten mit einem '-' Zeichen in der Formel ab.
SELECT AccountDescription, AccountType, Operator
FROM DimAccount
WHERE AccountType = 'Expenditures'
AND Operator = '-';

/* 2) Holen Sie eine Liste von Lagervertriebsunternehmen mit Telefonnummern, 
die mit 1 (11) beginnen und eine Bank mit 'Bank' am Ende verwenden. */
SELECT ResellerName, Phone, BusinessType, BankName
FROM DimReseller
WHERE Phone LIKE '1 (11)%'
AND BusinessType = 'Warehouse'
AND BankName LIKE '%Bank'; 

/* 3) Holen Sie eine Liste der Mitarbeiter mit der Berufsbezeichnung 'Technician', 
die im Jahr 2007 oder danach eingestellt wurden, ein Gehalt von weniger als 30 haben und 
im Jahr 2008 mit ihrer Arbeit begonnen haben. */
SELECT FirstName, LastName, Title, HireDate, BaseRate, StartDate
FROM DimEmployee
WHERE (Title LIKE '%Technician%' AND HireDate >= '2007-01-01') 
OR (BaseRate < 30 AND StartDate >= '2008-01-01');

/* 4) Holen Sie eine Liste von Produkten mit dem Wort 'Frame' im Namen, 
in schwarzer Farbe und einer Größe zwischen 50 und 60. */
SELECT EnglishProductName, Color, Size
FROM DimProduct
WHERE EnglishProductName LIKE '%Frame%'
AND Color = 'Black' 
AND Size BETWEEN '50' AND '60';

-- 5) Informationen zu Kunden abrufen, die älter sind als alle Mitarbeiter im Unternehmen.
SELECT FirstName, LastName, Gender, BirthDate
FROM DimCustomer
WHERE BirthDate < ALL(
	SELECT BirthDate
	FROM DimEmployee);

-- 6) Informationen über Kunden abrufen, die Bestellungen im Wert von über 2200 im Jahr 2013 platziert haben.
SELECT FirstName, LastName, Gender 
FROM DimCustomer
WHERE CustomerKey = ANY(
	SELECT CustomerKey
	FROM FactInternetSales
	WHERE YEAR(OrderDate) = 2013
	AND SalesAmount >= 2200
	GROUP BY CustomerKey
	);

/* 7) Holen Sie eine Liste von Mitarbeitern in der Position 'Supervisor', 
die männlich sind und in den Abteilungen 'Production' und 'Quality Assurance' arbeiten, 
die im Jahr 2008 eingestellt wurden, sortiert in aufsteigender Reihenfolge nach ihrem Einstiegsdatum. */
SELECT FirstName, Title, Gender, DepartmentName, HireDate, StartDate
FROM dbo.DimEmployee
WHERE Title LIKE '%Supervisor%' 
AND Gender = 'M'
AND DepartmentName IN ('Production', 'Quality Assurance') 
AND HireDate BETWEEN '2008-01-01' AND '2008-12-31' 
ORDER BY StartDate ASC;

-- 8) Zählen Sie, wie viele Städte in der Tabelle 'Geography' Namen haben, die mit 'SAN' beginnen. 
SELECT COUNT(*) FROM dbo.DimGeography WHERE City LIKE 'SAN%';

/* 9) Erstellen Sie eine Tabelle, die die Anzahl der Kunden nach Produktlinie zählt, 
und sortieren Sie sie in absteigender Reihenfolge. */
SELECT ProductLine, COUNT(ResellerKey) AS TotalReseller
FROM dbo.DimReseller 
GROUP BY ProductLine
ORDER BY TotalReseller DESC;

/* 10) Geben Sie die Top 10 Kunden mit dem höchsten Internetverkaufsumsatz aus, 
die im Jahr 2013 Bestellungen aufgegeben haben. */
SELECT TOP(10) c.CustomerName, SUM(f.SalesAmount) AS SalesAmount
FROM FactInternetSales f
JOIN (SELECT CustomerKey, 
		CONCAT(FirstName, ' ', MiddleName, ' ', LastName) AS CustomerName 
	  FROM DimCustomer ) AS c 
ON f.CustomerKey = c.CustomerKey
WHERE YEAR(OrderDate) = 2013
GROUP BY c.CustomerName
ORDER BY SalesAmount DESC;

/* 11) Geben Sie eine Liste von Kunden mit einem jährlichen Einkommen aus, 
das höher ist als das durchschnittliche jährliche Einkommen der Kundenbasis des Unternehmens. */
SELECT FirstName, LastName, YearlyIncome
FROM DimCustomer
WHERE YearlyIncome > 
	(SELECT AVG(YearlyIncome) FROM DimCustomer)
ORDER BY YearlyIncome DESC;

-- 12) Zählen Sie die Anzahl der Tage für jedes Geschäftsjahr.
SELECT FiscalYear, COUNT(DateKey) AS NbDays
FROM DimDate
GROUP BY FiscalYear
ORDER BY FiscalYear DESC;

-- 13) Zählen Sie die Anzahl der Tage für jedes normale Kalenderjahr.
SELECT CalendarYear, COUNT(DateKey) AS NbDays
FROM DimDate
GROUP BY CalendarYear
ORDER BY CalendarYear DESC;

/* 14) Geben Sie Informationen zu Produkttyp, Produktgruppe und 
Produkt mit dem Gesamtumsatz für das Jahr 2013 zurück. */
SELECT p.EnglishProductName, s.EnglishProductSubcategoryName, 
	c.EnglishProductCategoryName, SUM(f.SalesAmount) AS SalesAmount
FROM FactInternetSales f
	JOIN DimProduct p ON f.ProductKey = p.ProductKey
	JOIN DimProductSubcategory s ON p.ProductSubcategoryKey = s.ProductSubcategoryKey
	JOIN DimProductCategory c ON s.ProductCategoryKey = c.ProductCategoryKey
WHERE YEAR(OrderDate) = 2013
GROUP BY p.EnglishProductName, s.EnglishProductSubcategoryName, c.EnglishProductCategoryName;

-- 15) Geben Sie Informationen zu Produkten mit höheren Einnahmen im Jahr 2013 im Vergleich zu 2012 zurück.
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

/* 16) Zählen Sie die Anzahl der männlichen Kunden nach GeographyKey und filtern Sie die Orte heraus, 
an denen mehr als 100 männliche Kunden sind. */
SELECT GeographyKey, COUNT(CustomerKey) 
FROM DimCustomer
WHERE MaritalStatus = 'M'
GROUP BY GeographyKey
HAVING COUNT(CustomerKey)  > 100
ORDER BY COUNT(CustomerKey)  DESC;

-- 17) Geben Sie die Anzahl der Kunden nach Einkommenskategorie für das Jahr zurück.
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

-- 18) Sortieren Sie die Kunden in RFM-Segmente auf Grundlage der RFM-Methode. 
-- Eine RFM Tabelle erstellen
WITH RFM AS(
	-- Die RFM-Kennzahlen für jeden Kunden berechnen.
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
	-- Perzentile für die Kennzahlen Recency (Aktualität) und Monetary (Monetär) berechnen
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
	-- Die RFM-Werte basierend auf den Perzentilen zuweisen
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
	-- Die RFM-Werte zu einem einzelnen String verketten.
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
