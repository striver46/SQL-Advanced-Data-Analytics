# SQL-Advanced-Data-Analytics
Project Overview This project explores a bike-and-accessories sales data warehouse (gold layer) using only SQL. It starts with data exploration and KPIs, then moves to advanced analytics: change over time, cumulative trends, year-over-year performance, part-to-whole analysis and customer/product segmentation. 
<div align="center">

# 🚲 SQL Advanced Data Analytics

### Sales, Customer & Product Analytics on a Star-Schema Data Warehouse (MySQL)

![MySQL](https://img.shields.io/badge/MySQL_8.0+-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![SQL](https://img.shields.io/badge/Advanced_SQL-14213d?style=for-the-badge)
![CTEs](https://img.shields.io/badge/CTEs-00a6a6?style=for-the-badge)
![Window Functions](https://img.shields.io/badge/Window_Functions-f28f3b?style=for-the-badge)
![Queries](https://img.shields.io/badge/62_Queries-d1495b?style=for-the-badge)

**👤 Author: Aman Nakhate** &nbsp;|&nbsp; Data Analyst

</div>

---

## 🎯 Project Overview

This project explores a bike-and-accessories sales data warehouse (gold layer) using **only SQL**. It starts with data exploration and KPIs, then moves to advanced analytics: **change over time, cumulative trends, year-over-year performance, part-to-whole analysis and customer/product segmentation**. The work ends in two reusable reporting **views** built with **CTEs and window functions**.

<img width="1657" height="538" alt="sql_proj_kpi_banner" src="https://github.com/user-attachments/assets/b7300b17-9dae-4514-83df-284eef1bc384" />


### 🔑 Highlights

- 📈 **$16.34M revenue in 2013**, a **179.77% growth over 2012**
- 🚴 **Bikes drive 96.46%** of total revenue (**$28.32M**)
- 👥 Customers split into **VIP, Regular and New** segments, with a report view for each customer
- 📦 Products split into **High / Mid / Low performers**, with a report view for each product

---

## 🗂️ Data Model

<img width="1425" height="618" alt="sql_proj_schema" src="https://github.com/user-attachments/assets/2acadf20-92ec-4936-a761-53d1bf6ac167" />


| Table | Rows | Description |
|:--|--:|:--|
| `gold.fact_sales` | 60,398 | One row per order line (amount, quantity, price, dates) |
| `gold.dim_customers` | 18,484 | Customer name, country, gender, birthdate |
| `gold.dim_products` | 295 | Product name, category, subcategory, cost |

---

## 📈 Change Over Time & Cumulative Analysis

<p align="center">
  <img src="assets/yearly_revenue.png" alt="Yearly revenue" width="80%">
</p>

| Year | Revenue | Change vs previous year |
|:--|--:|--:|
| 2011 | $7.08M | n/a (2010 has only December) |
| 2012 | $5.84M | **-17.43%** |
| **2013** | **$16.34M** | **+179.77%** |

> ⚠️ 2010 (December only) and 2014 (January only) are partial years, so 2013 vs 2012 is the only fair year-over-year comparison.

<img width="1650" height="750" alt="sql_proj_yearly_revenue" src="https://github.com/user-attachments/assets/912219ee-e765-4a73-a7bc-5980b1ca9d73" />

**SQL techniques:** `SUM() OVER (ORDER BY ...)` for running totals, `PARTITION BY year` for year-to-date sales, `AVG() OVER` for the moving average price, `LAG()` for YoY growth.

---

## 🧩 Part-to-Whole Analysis


- 🚴 **Bikes: $28.32M (96.46%)**, Accessories: $0.70M (2.39%), Clothing: $0.34M (1.16%)
- Road Bikes ($14.52M) and Mountain Bikes ($9.95M) alone make up most of the revenue
- Revenue is highly concentrated, so the business depends heavily on the bike range

<img width="1800" height="720" alt="sql_proj_category_share" src="https://github.com/user-attachments/assets/70b68db3-9506-481f-ba57-9dc74d9abedf" />

- The **United States ($9.16M)** and **Australia ($9.06M)** are the two biggest markets, together roughly 62% of revenue

---

<img width="1500" height="690" alt="sql_proj_country_revenue" src="https://github.com/user-attachments/assets/0546f107-2bf5-417f-9040-8c9588b0f703" />


## 👥 Customer Segmentation

<img width="1800" height="690" alt="sql_proj_customer_segments" src="https://github.com/user-attachments/assets/a3d5b6a8-ffe2-4acb-905e-295854c54150" />

| Segment | Rule | Customers | Revenue |
|:--|:--|--:|--:|
| 🥇 **VIP** | 12+ months history and spend > $5,000 | 1,617 | $10.55M |
| 🥈 **Regular** | 12+ months history and spend <= $5,000 | 2,039 | $7.01M |
| 🥉 **New** | Less than 12 months history | 14,826 | $11.79M |

- **VIP customers are only ~9% of customers but bring ~36% of revenue**, with an average order value of about $2,648 against $614 for New customers.

---

## 🧾 Reporting Views (CTEs + Window Functions)

| View | Grain | What it gives |
|:--|:--|:--|
| `gold.report_customers` | 1 row per customer | Age group, segment, recency, orders, sales, quantity, products, lifespan, avg order value, avg monthly spend |
| `gold.report_products` | 1 row per product | Category, cost, performance segment, recency, orders, sales, customers, avg selling price, avg monthly revenue |

```sql
-- example: how are VIP / Regular / New customers performing?
SELECT customer_segment,
       COUNT(customer_key) AS total_customers,
       SUM(total_sales)    AS total_sales,
       ROUND(SUM(total_sales) / SUM(SUM(total_sales)) OVER () * 100, 2) AS pct_of_sales
FROM gold.report_customers
GROUP BY customer_segment
ORDER BY total_sales DESC;
```

Product performance groups: **High Performer** (> $50K), **Mid Range** ($10K-$50K) and **Low Performer** (< $10K). 66 high performers generate about $27.6M of the revenue.

---

## 🧹 Data Quality Notes

| Check | Finding | How it was handled |
|:--|--:|:--|
| Order lines with no `order_date` | 19 | Excluded from every time-based query |
| Customers with no country | 337 | Kept, shown as NULL in country analysis |
| Customers with no gender / birthdate | 15 / 17 | Age group shown as "Unknown" |
| Products with no category | 7 | None of them has any sales |
| Orphan sales rows (no matching product or customer) | 0 | n/a |

---

## 🛠️ Skills Demonstrated

- **Advanced SQL (MySQL 8):** CTEs, window functions (`SUM/AVG OVER`, `LAG`, `RANK`, `ROW_NUMBER`), views, `CASE` segmentation, date functions
- **Analytical thinking:** trend analysis, YoY growth, part-to-whole, customer and product segmentation
- **Data quality:** null handling, partial-period awareness, orphan checks
- **Business reporting:** reusable views for customer and product performance

---

## 📁 Repository Structure

```
📦 sql-advanced-data-analytics
 ┣ 📂 datasets
 ┃ ┣ 📜 gold.dim_customers.csv
 ┃ ┣ 📜 gold.dim_products.csv
 ┃ ┗ 📜 gold.fact_sales.csv
 ┣ 📜 Advanced_Sales_Analytics.sql  → all 62 queries and the 2 views
 ┗ 📜 README.md
```

---

## 🚀 How to Run

**1. Create the schema and tables**

```sql
CREATE DATABASE IF NOT EXISTS gold;

CREATE TABLE gold.dim_customers (
    customer_key    INT PRIMARY KEY,
    customer_id     INT,
    customer_number VARCHAR(20),
    first_name      VARCHAR(50),
    last_name       VARCHAR(50),
    country         VARCHAR(50),
    marital_status  VARCHAR(20),
    gender          VARCHAR(20),
    birthdate       DATE,
    create_date     DATE
);

CREATE TABLE gold.dim_products (
    product_key    INT PRIMARY KEY,
    product_id     INT,
    product_number VARCHAR(30),
    product_name   VARCHAR(100),
    category_id    VARCHAR(10),
    category       VARCHAR(50),
    subcategory    VARCHAR(50),
    maintenance    VARCHAR(10),
    cost           INT,
    product_line   VARCHAR(30),
    start_date     DATE
);

CREATE TABLE gold.fact_sales (
    order_number  VARCHAR(20),
    product_key   INT,
    customer_key  INT,
    order_date    DATE,
    shipping_date DATE,
    due_date      DATE,
    sales_amount  INT,
    quantity      INT,
    price         INT
);
```

**2. Import the three CSV files** from `datasets/` (MySQL Workbench: *Table Data Import Wizard*, or `LOAD DATA LOCAL INFILE`). Empty values should be loaded as `NULL`.

**3. Run `Advanced_Sales_Analytics.sql`** in MySQL 8.0 or newer. Queries are numbered Q1 to Q62 so you can run them one section at a time.

---

## 📬 Contact

**Aman Nakhate**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/amannakhate111/)
[![Email](https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:amannakhate1111@gmail.com)

<div align="center">


</div>
