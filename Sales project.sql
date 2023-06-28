--inspecting data
SELECT * FROM [dbo].[sales_data_sample];


-- checking unique values
select distinct status from [dbo].[sales_data_sample] --nice to plot
select distinct year_id from [dbo].[sales_data_sample]
select distinct productline from [dbo].[sales_data_sample]-- nice to plot
select distinct country from [dbo].[sales_data_sample]-- nice to plot
select distinct dealsize from [dbo].[sales_data_sample]-- nice to plot
select distinct territory from [dbo].[sales_data_sample]-- nice to plot


-- analysis

-- group sales by product line
select PRODUCTLINE, round(sum(sales),2) as Revenue from [dbo].[sales_data_sample]
group by PRODUCTLINE
order by 2 desc


-- group sales by year
select YEAR_ID, round(sum(sales),2) as Revenue from [dbo].[sales_data_sample]
group by YEAR_ID
order by 2 desc

-- group sales by dealsize
select DEALSIZE, round(sum(sales),2) as Revenue from [dbo].[sales_data_sample]
group by DEALSIZE
order by 2 desc

--what was the best month for sales in a specific year? and how much was earned that month?
select month_id, round(sum(sales),2) as revenue, count(ordernumber) as frequency
from [dbo].[sales_data_sample]
where YEAR_ID = 2003
group by MONTH_ID
order by 2 desc

--what is the most sold prouct in the year checked above?
select PRODUCTLINE, month_id, round(sum(sales),2) as revenue, count(ordernumber) as frequency
from [dbo].[sales_data_sample]
where YEAR_ID = 2003
group by PRODUCTLINE, MONTH_ID
order by 3 desc

--who is our best customer? rfm analysis

DROP TABLE IF EXISTS #rfm ;--clearing table

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
  --ORDER BY monetary_value DESC
),

rfm_calc as(
SELECT
  r.*,
  NTILE(4) OVER (ORDER BY recency DESC) AS rfm_recency,
  NTILE(4) OVER (ORDER BY frequency) AS rfm_frequency,
  NTILE(4) OVER (ORDER BY monetary_value) AS rfm_monetary
FROM rfm AS r
--ORDER BY rfm_monetary DESC;
)

select 
c.*, rfm_recency+rfm_frequency+rfm_monetary as rfm_cell,
cast(rfm_recency as VARCHAR(10))+cast(rfm_frequency as VARCHAR(10))+cast(rfm_monetary as VARCHAR(10)) as rfm_cell_string
INTO #rfm -- creating temp table
from rfm_calc as c

SELECT customername, rfm_recency, rfm_frequency, rfm_monetary, rfm_cell_string, rfm_cell,
CASE
WHEN rfm_cell = 2 THEN 'Potential Loyalist'
WHEN rfm_cell = 3 THEN 'Promising'
WHEN rfm_cell = 4 THEN 'New Customer'
WHEN rfm_cell = 5 THEN 'Champions'
WHEN rfm_cell = 6 THEN 'Need Attention'
WHEN rfm_cell = 7 THEN 'About to Sleep'
END AS rfm_group
FROM #rfm

-- what produts are mostly sold together? using xml path analysis
SELECT DISTINCT ordernumber, STUFF(

(SELECT ',' + productcode
 from [dbo].[sales_data_sample] p
 where ORDERNUMBER in (

select ordernumber
from(
select ORDERNUMBER, count(*) as rn
from [dbo].[sales_data_sample]
where STATUS = 'Shipped'
group by ORDERNUMBER
--order by 2 desc
)m 
where rn = 2

 )
 and p.ORDERNUMBER = s.ORDERNUMBER
 for xml path('')),1,1,'') prduct_codes

from [dbo].[sales_data_sample] s
ORDER by 2 DESC
