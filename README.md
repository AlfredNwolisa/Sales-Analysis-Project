# SQL Project README

This README provides an overview of the SQL project and explains the queries used to analyze the sales data. The project aims to explore and gain insights from a sales dataset stored in the `[dbo].[sales_data_sample]` table.

## Table of Contents

- [Inspecting Data](#inspecting-data)
- [Checking Unique Values](#checking-unique-values)
- [Analysis](#analysis)
- [Grouping Sales by Product Line](#grouping-sales-by-product-line)
- [Grouping Sales by Year](#grouping-sales-by-year)
- [Grouping Sales by Deal Size](#grouping-sales-by-deal-size)
- [Best Month for Sales in a Specific Year](#best-month-for-sales-in-a-specific-year)
- [Most Sold Product in a Specific Year](#most-sold-product-in-a-specific-year)
- [Best Customer Analysis using RFM](#best-customer-analysis-using-rfm)
- [Products Frequently Sold Together](#products-frequently-sold-together)

## Inspecting Data

To begin the analysis, you can inspect the data in the `[dbo].[sales_data_sample]` table using the following query:

```sql
SELECT * FROM [dbo].[sales_data_sample];
```

This query will retrieve all the records from the table.

## Checking Unique Values<a name="checking-unique-values"></a>

Next, you can check the unique values in specific columns of the `[dbo].[sales_data_sample]` table. These unique values can be helpful for plotting purposes or understanding the data distribution. Here are the queries to retrieve unique values from various columns:

```sql
-- Unique values in the 'status' column
SELECT DISTINCT status FROM [dbo].[sales_data_sample];

-- Unique values in the 'year_id' column
SELECT DISTINCT year_id FROM [dbo].[sales_data_sample];

-- Unique values in the 'productline' column
SELECT DISTINCT productline FROM [dbo].[sales_data_sample];

-- Unique values in the 'country' column
SELECT DISTINCT country FROM [dbo].[sales_data_sample];

-- Unique values in the 'dealsize' column
SELECT DISTINCT dealsize FROM [dbo].[sales_data_sample];

-- Unique values in the 'territory' column
SELECT DISTINCT territory FROM [dbo].[sales_data_sample];
```

You can execute these queries to obtain the distinct values in the respective columns.

## Analysis

The following queries perform various analyses on the sales data.

### Grouping Sales by Product Line

To group the sales by product line and calculate the revenue for each product line, you can execute the following query:

```sql
SELECT PRODUCTLINE, ROUND(SUM(sales), 2) AS Revenue
FROM [dbo].[sales_data_sample]
GROUP BY PRODUCTLINE
ORDER BY 2 DESC;
```

This query will provide a summary of the revenue generated by each product line, sorted in descending order.

### Grouping Sales by Year

To group the sales by year and calculate the revenue for each year, you can use the following query:

```sql
SELECT YEAR_ID, ROUND(SUM(sales), 2) AS Revenue
FROM [dbo].[sales_data_sample]
GROUP BY YEAR_ID
ORDER BY 2 DESC;
```

This query will provide the total revenue for each year, sorted in descending order.

### Grouping Sales by Deal Size

To group the sales by deal size and calculate the revenue for each deal size, execute the following query:

```sql
SELECT DEALSIZE, ROUND(SUM

(sales), 2) AS Revenue
FROM [dbo].[sales_data_sample]
GROUP BY DEALSIZE
ORDER BY 2 DESC;
```

This query will give you the revenue generated for different deal sizes, sorted in descending order.

### Best Month for Sales in a Specific Year

To determine the best month for sales in a specific year and the corresponding revenue earned that month, run the following query:

```sql
SELECT MONTH_ID, ROUND(SUM(sales), 2) AS Revenue, COUNT(ordernumber) AS Frequency
FROM [dbo].[sales_data_sample]
WHERE YEAR_ID = 2003
GROUP BY MONTH_ID
ORDER BY 2 DESC;
```

This query will provide the revenue and frequency of sales for each month in the specified year, ordered by revenue in descending order.

### Most Sold Product in a Specific Year

To find the most sold product in a specific year, execute the following query:

```sql
SELECT PRODUCTLINE, MONTH_ID, ROUND(SUM(sales), 2) AS Revenue, COUNT(ordernumber) AS Frequency
FROM [dbo].[sales_data_sample]
WHERE YEAR_ID = 2003
GROUP BY PRODUCTLINE, MONTH_ID
ORDER BY 3 DESC;
```

This query will return the product line, month, revenue, and frequency for each product sold in the specified year, sorted by revenue in descending order.

### Best Customer Analysis using RFM

To perform RFM (Recency, Frequency, Monetary) analysis and identify the best customer, the following query utilizes a temporary table:

```sql
-- Creating temporary table #rfm
DROP TABLE IF EXISTS #rfm;

WITH rfm AS (
  SELECT
    customername,
    SUM(sales) AS monetary_value,
    AVG(sales) AS avg_monetary_value,
    COUNT(ordernumber) AS frequency,
    MAX(orderdate) AS recent_order_date,
    (
      SELECT MAX(orderdate)
      FROM [dbo].[sales_data_sample]
    ) AS max_order_date,
    DATEDIFF(DD, MAX(orderdate), (SELECT MAX(orderdate) FROM [dbo].[sales_data_sample])) AS recency
  FROM [dbo].[sales_data_sample]
  GROUP BY customername
),

rfm_calc AS (
SELECT
  r.*,
  NTILE(4) OVER (ORDER BY recency DESC) AS rfm_recency,
  NTILE(4) OVER (ORDER BY frequency) AS rfm_frequency,
  NTILE(4) OVER (ORDER BY monetary_value) AS rfm_monetary
FROM rfm AS r
)

-- Populating temporary table #rfm
SELECT
  c.*,
  rfm_recency + rfm_frequency + rfm_monetary AS rfm_cell,
  CAST(rfm_recency AS VARCHAR(10)) + CAST(rfm_frequency AS VARCHAR(10)) + CAST(rfm_monetary AS VARCHAR(10)) AS rfm_cell_string
INTO #rfm
FROM rfm_calc AS c;

-- Analyzing RFM results
SELECT
  customername,
  rfm_recency,
  rfm_frequency,
  rfm_monetary,
  rfm_cell_string,
  rfm_cell,
  CASE
    WHEN rfm_cell = 2 THEN 'Potential Loyalist'
    WHEN rfm_cell = 3 THEN 'Promising'
    WHEN rfm_cell = 4 THEN 'New Customer'
    WHEN rfm_cell = 5 THEN 'Champions'
    WHEN rfm_cell = 6 THEN 'Need Attention'
    WHEN rfm_cell =

 7 THEN 'About to Sleep'
  END AS rfm_group
FROM #rfm;
```

This query calculates the RFM values for each customer, assigns RFM cells, and classifies the customers into different groups based on their RFM cells.

### Products Frequently Sold Together

To determine which products are frequently sold together, the following query uses XML Path analysis:

```sql
SELECT DISTINCT ordernumber, STUFF(
  (
    SELECT ',' + productcode
    FROM [dbo].[sales_data_sample] p
    WHERE ORDERNUMBER IN (
      SELECT ordernumber
      FROM (
        SELECT ORDERNUMBER, COUNT(*) AS rn
        FROM [dbo].[sales_data_sample]
        WHERE STATUS = 'Shipped'
        GROUP BY ORDERNUMBER
      ) m
      WHERE rn = 2
    )
    AND p.ORDERNUMBER = s.ORDERNUMBER
    FOR XML PATH('')
  ), 1, 1, ''
) AS product_codes
FROM [dbo].[sales_data_sample] s
ORDER BY 2 DESC;
```

This query retrieves distinct order numbers and the associated product codes for orders that have a count of 2 and a status of 'Shipped'. The results provide insights into which products are frequently sold together.

Feel free to modify and execute these queries according to your specific requirements for further analysis of the sales data.