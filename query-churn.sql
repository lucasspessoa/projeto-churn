CREATE OR ALTER VIEW vwQueryChurn AS
WITH CustomerSales AS (
    SELECT 
        c.CustomerKey, 
        c.GeographyKey, 
        c.CustomerAlternateKey AS CustomerID, 
        c.FirstName, 
        c.LastName,
        c.YearlyIncome, 
        fis.SalesOrderNumber, 
        fis.OrderDateKey, 
        d.FullDateAlternateKey AS OrderDate, 
        fis.SalesAmount, 
        fis.OrderQuantity, 
        fis.ProductKey
    FROM DimCustomer c
    LEFT JOIN FactInternetSales fis ON c.CustomerKey = fis.CustomerKey
    LEFT JOIN DimDate d ON fis.OrderDateKey = d.DateKey
),
CustomerMetrics AS (
    SELECT 
        CustomerKey, 
        MAX(OrderDate) AS LastOrderDate, 
        DATEDIFF(DAY, MAX(OrderDate), '2014-01-29') AS DaysSinceLastOrder, 
        COUNT(SalesOrderNumber) AS TotalOrders, 
        SUM(SalesAmount) AS TotalSalesAmount
    FROM CustomerSales
    GROUP BY CustomerKey
),
ChurnDefinition AS (
    SELECT 
        CustomerKey, 
        LastOrderDate, 
        DaysSinceLastOrder, 
        TotalOrders, 
        TotalSalesAmount, 
        CASE 
            WHEN DaysSinceLastOrder > 180 THEN 1 -- it´s churn
            ELSE 0
        END AS IsChurn
    FROM CustomerMetrics
)
SELECT 
    cs.CustomerKey, 
    cs.CustomerID, 
	CONCAT_WS(' ', cs.FirstName, cs.LastName) AS ClientName, 
    cs.YearlyIncome, 
    g.StateProvinceName, 
    cm.LastOrderDate, 
    cm.DaysSinceLastOrder, 
    cm.TotalOrders, 
    cm.TotalSalesAmount, 
    cd.IsChurn,
	CASE
	WHEN cm.DaysSinceLastOrder < 90 AND cm.TotalSalesAmount > 1000 THEN 'ClienteTop'
	ELSE 'ClienteComum'
	END AS SegmentacaoCliente
FROM CustomerSales cs
LEFT JOIN ChurnDefinition cd ON cs.CustomerKey = cd.CustomerKey
LEFT JOIN CustomerMetrics cm ON cs.CustomerKey = cm.CustomerKey
INNER JOIN DimGeography g ON cs.GeographyKey = g.GeographyKey;