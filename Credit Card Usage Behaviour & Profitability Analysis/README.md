# Credit Card Usage Behavior & Profitability Analysis

## Table of Contents

1. [Project Overview](#project-overview)
2. [Objectives](#objectives)
3. [Business Context & Case Study](#business-context--case-study)
4. [Project Structure](#project-structure)
5. [Schema Design](#schema-design)
6. [Tables Preview](#tables-preview)
7. [Key Queries & Insights](#key-queries--insights)
8. [Recommendations](#recommendations)
9. [Setup Instructions](#setup-instructions)
10. [Author](#author)

---
## Project Overview

This project analyzes customer behavior, repayment patterns, and profitability in a simulated credit card dataset using SQL. It provides insights into spending habits, repayment consistency, and identifies high-value customers using advanced query logic. The dataset and insights are tailored to reflect realistic banking scenarios in emerging economies like Nigeria.

---
## Objectives

* Understand customer spending behavior by demographic groups.
* Identify high-risk and high-value customer segments
* Evaluate profitability at customer and group level
* Segment customers for better decision-making and targeted upgrades.

---
## Business Context & Case Study

**Context:** A commercial bank operating across African regions has rolled out various card products. While card adoption is growing, profitability varies across customer segments. The bank wants to understand behavioral and financial patterns driving profitability and risk.

**Challenge:** Despite high transaction volumes, some customers accumulate unpaid debt, while others transact heavily but generate minimal profit. Management needs clarity on which segments to target for growth and which to manage better.

**Case Questions:**

* Are high-income customers spending more or repaying on time?
* Which channels and card types are most used by millennials or boomers?
* Which regions pose the highest credit risk?
* Who should be offered Platinum upgrades?

This analysis provides answers using clean, structured SQL logic grounded in real-world banking scenarios.

---
## Project Structure

```
├── README.md
├── schema_setup.sql         # SQL script to set up the database schema
├── queries.sql              # Main SQL analysis queries
├── screenshots/
│   ├── customer_table.png   # Preview of customer table
│   ├── repayment_table.png  # Preview of repayment table
│   └── transaction_table.png# Preview of transaction table
│
├── datasets/
│   ├── customers.csv
│   ├── transactions.csv
│   ├── repayments.csv
│   └── cards.csv
```
---
## Schema Design

**Tables Used:**

* `customers`: Contains customer demographics, region, income level, and credit score
* `cards`: Stores card metadata – type, annual fee, reward rates
* `transactions`: Records all spending activity (with channel info)
* `repayments`: Logs actual repayments versus due amounts

Each table is connected via `customer_id` and `card_id` as appropriate.

---
## Tables Preview

<table>
  <tr>
    <td><img src="screenshots/customer_table.png" width="300"></td>
    <td><img src="screenshots/transactions_table.png" width="300"></td>
    <td><img src="screenshots/repayment_table.png" width="300"></td>
  </tr>
  <tr>
    <td align="center">Customer Table</td>
    <td align="center">Transaction Table</td>
    <td align="center">Repayment Table</td>
  </tr>
</table>

---

## Key Queries & Insights

### Card Usage Behavior

## 1. **Spending Patterns by Income Level & Region**

   * Analyzes total and average transaction values across regions and income groups to understand how wealth and location affect card usage.
```sql
SELECT
    c.income_level,
    c.region,
    ROUND(SUM(t.amount), 2) AS total_spent,
    COUNT(t.transaction_id) AS transaction_count,
    ROUND(AVG(t.amount), 2) AS avg_transaction_amount
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
GROUP BY c.income_level, c.region
ORDER BY c.income_level, c.region, total_spent DESC;
```

## 2. **Most Used Channel by Card Type & Age Group**

   * Identifies whether mobile, POS, or online channels dominate usage by demographic – informing digital investment strategy.
```sql
SELECT 
	t.channel,
	cu.age_group,
	ca.card_type,
	COUNT(transaction_id) AS total_transactions,
	cu.region
FROM transactions t
JOIN customers cu ON t.customer_id = cu.customer_id
JOIN cards ca ON t.card_id = ca.card_id
GROUP BY cu.age_group, ca.card_type, t.channel, cu.region
ORDER BY total_transactions DESC;
```
## 3. **Transaction Size & Frequency by Segment**

   * Evaluates how frequently different segments transact and how much they spend, supporting segmentation.
```sql
SELECT
    c.income_level,
    c.age_group,
    c.region,
    t.customer_id,
    COUNT(t.transaction_id) AS transaction_frequency,
    ROUND(AVG(t.amount), 2) AS avg_transaction_size
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
GROUP BY c.income_level, c.age_group, c.region, t.customer_id
ORDER BY c.income_level, c.age_group, c.region, transaction_frequency DESC;
```
* Medium-income customers showed higher average transaction sizes despite fewer total transactions.

---

### Repayment Behavior

## 4. **Repeated Late Payments**

  * Flags customers who miss due dates 3+ times – a credit risk metric used by lending teams.
```sql
WITH late_payments AS (
	SELECT 
		customer_id,
		COUNT(*) AS late_count
	FROM repayments
	WHERE repayment_date > due_date
	GROUP BY customer_id
)
SELECT
    COUNT(*) FILTER (WHERE late_count >= 3) AS customers_missed_3plus,
    COUNT(*) AS total_customers,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE late_count >= 3) / COUNT(*), 2
    ) AS percent_missed_3plus
FROM late_payments;
```
* 18.2% of customers have missed 3+ due dates, posing a credit risk.

## 5. **Repayment Rates by Age Group**

   * Benchmarks how well different age brackets repay their dues – e.g., Gen Z vs Gen X.
```sql
SELECT
    c.age_group,
    ROUND(AVG(r.amount_paid / r.amount_due) * 100, 2) AS avg_repayment_rate_percent
FROM repayments r
JOIN customers c ON r.customer_id = c.customer_id
GROUP BY c.age_group
ORDER BY avg_repayment_rate_percent DESC;
```
* Customers aged 36–50 have the best repayment consistency.

## 6. **Unpaid Debt Over Time**

   * Tracks growing debt month-over-month to assess portfolio risk and liquidity exposure.
```sql
SELECT
	TO_CHAR(DATE_TRUNC('month', due_date), 'YYYY-MM') AS month,
	SUM(amount_due - amount_paid) AS unpaid_amount
FROM repayments
WHERE amount_due > amount_paid
GROUP BY month
ORDER BY month;
```
* Notable spikes in unpaid debt during mid-year months, suggesting potential seasonal credit strain.

### Customer Profitability

## 7. Customer-Level Profitability - Top 10 Most Profitable Customers

   * Tracks growing debt month-over-month to assess portfolio risk and liquidity exposure.
   * Profit = Annual Fee + (Spending × Reward Rate) - Unpaid Amount
   * These customers are consistent spenders with low default ratios.
```sql
WITH total_spent_per_customer AS (
    SELECT
        customer_id,
        SUM(amount) AS total_spent
    FROM
        transactions
    GROUP BY
        customer_id
),
unpaid_per_customer AS (
    SELECT
        customer_id,
        SUM(amount_due - amount_paid) AS unpaid_amount
    FROM
        repayments
    GROUP BY
        customer_id
),
profit_calc AS (
    SELECT
        c.customer_id,
        c.full_name,
        cr.card_type,
        cr.annual_fee,
        cr.reward_rate,
        COALESCE(tspc.total_spent, 0) AS total_spent,
        COALESCE(upc.unpaid_amount, 0) AS unpaid_amount,
        ROUND(
            cr.annual_fee + (COALESCE(tspc.total_spent, 0) * cr.reward_rate) - COALESCE(upc.unpaid_amount, 0),
            2
        ) AS estimated_profit
    FROM
        customers c
    JOIN
        transactions t ON c.customer_id = t.customer_id
    JOIN
        cards cr ON t.card_id = cr.card_id
    LEFT JOIN
        total_spent_per_customer tspc ON c.customer_id = tspc.customer_id
    LEFT JOIN
        unpaid_per_customer upc ON c.customer_id = upc.customer_id
    GROUP BY
        c.customer_id, c.full_name, cr.card_type, cr.annual_fee, cr.reward_rate, tspc.total_spent, upc.unpaid_amount
)
SELECT * FROM profit_calc
ORDER BY estimated_profit DESC
LIMIT 10;

```

## 8. Customer-Level Profitability - income/age/region groups that contribute most to profit
* Aggregates profits by income, region, and age – guiding strategic targeting.

```sql
WITH customer_profit AS (
    SELECT
        c.customer_id,
        c.income_level,
        c.age_group,
        c.region,
        cr.annual_fee + SUM(t.amount) * cr.reward_rate - COALESCE(SUM(r.amount_due - r.amount_paid), 0) AS estimated_profit
    FROM
        customers c
    JOIN
        transactions t ON c.customer_id = t.customer_id
    JOIN
        cards cr ON t.card_id = cr.card_id
    LEFT JOIN
        repayments r ON c.customer_id = r.customer_id
    GROUP BY
        c.customer_id, c.income_level, c.age_group, c.region, cr.annual_fee, cr.reward_rate
)
SELECT
    income_level,
    age_group,
    region,
    ROUND(SUM(estimated_profit), 2) AS total_profit,
    COUNT(DISTINCT customer_id) AS customer_count,
    ROUND(AVG(estimated_profit), 2) AS avg_profit_per_customer
FROM
    customer_profit
GROUP BY
    income_level, age_group, region
ORDER BY
    total_profit DESC;
```

   * Urban, middle-aged, and upper-income groups contribute significantly to profit margins.

---
### Segmentation & Recommendations

## 9. **Customer Segmentation**

Categorizes customers by behavior:

* High Spender, On-Time Payer
* High Spender, Late Payer
* Medium Spender
* Low Spender
```sql
WITH usage_stats AS (
    SELECT
        c.customer_id,
        COUNT(t.transaction_id) AS transaction_count,
        SUM(t.amount) AS total_spent,
        AVG(CASE WHEN r.repayment_date > r.due_date THEN 1 ELSE 0 END) AS late_payment_ratio
    FROM
        customers c
    LEFT JOIN
        transactions t ON c.customer_id = t.customer_id
    LEFT JOIN
        repayments r ON c.customer_id = r.customer_id
    GROUP BY
        c.customer_id
)
SELECT
    customer_id,
    transaction_count,
    total_spent,
    ROUND(late_payment_ratio, 2),
    CASE
        WHEN total_spent > 100000 AND late_payment_ratio < 0.2 THEN 'High Spender, On-time Payer'
        WHEN total_spent > 100000 AND late_payment_ratio >= 0.2 THEN 'High Spender, Late Payer'
        WHEN total_spent BETWEEN 50000 AND 100000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS segment
FROM
    usage_stats
ORDER BY
    total_spent DESC;
```
## 10. **Upgrade Recommendations**
* Selects customers eligible for Platinum upgrade using filters like total spend, credit score, and repayment behavior.
* High spenders with excellent credit scores and low late repayment ratios.

```sql
WITH usage_stats AS (
    SELECT
        c.customer_id,
        c.full_name,
        c.income_level,
        c.credit_score,
        SUM(t.amount) AS total_spent,
        AVG(CASE WHEN r.repayment_date > r.due_date THEN 1 ELSE 0 END) AS late_payment_ratio
    FROM
        customers c
    LEFT JOIN
        transactions t ON c.customer_id = t.customer_id
    LEFT JOIN
        repayments r ON c.customer_id = r.customer_id
    GROUP BY
        c.customer_id, c.full_name, c.income_level, c.credit_score
)
SELECT
    customer_id,
    full_name,
    income_level,
    credit_score,
    total_spent,
    ROUND(late_payment_ratio, 2) AS payment_ratio
FROM
    usage_stats
WHERE
    total_spent > 150000
    AND credit_score > 700
    AND late_payment_ratio < 0.1
ORDER BY
    total_spent DESC;
```
## 11. **Regions Needing Financial Education or Credit Control**

* Regions with high overdue amounts and frequent late repayments need policy interventions.
```sql
SELECT
    c.region,
	SUM(r.amount_due - r.amount_paid) AS amount_overdue,
    ROUND(AVG(CASE WHEN r.repayment_date > r.due_date THEN 1 ELSE 0 END), 2) AS avg_late_payment_ratio,
    COUNT(DISTINCT c.customer_id) AS customer_count
FROM customers c
LEFT JOIN repayments r ON c.customer_id = r.customer_id
GROUP BY c.region
HAVING AVG(CASE WHEN r.repayment_date > r.due_date THEN 1 ELSE 0 END) > 0.3
ORDER BY avg_late_payment_ratio DESC;
```

## 12. **Year-on-Year Spending Growth by Income Group**
* Understand how each income group's credit usage is evolving to spot emerging segments.*

```sql
SELECT
    income_level,
    EXTRACT(YEAR FROM t.transaction_date) AS year,
    ROUND(SUM(t.amount), 2) AS total_spent
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
GROUP BY income_level, year
ORDER BY income_level, year;
```
---
## Recommendations

* **Offer Premium Upgrades**: Target high-spending, credit-worthy, on-time payers for Platinum upgrade.
* **Risk Management**: Review credit limits or apply stricter controls in regions with >30% late payments.
* **Customer Education**: Deploy campaigns in regions with low repayment performance.
* **Channel Optimization**: Invest more in mobile and POS channels where young customers dominate.

---

## Setup Instructions

1. **Run the schema**

   ```sql
   -- Run schema_setup.sql to create and populate tables
   ```
2. **Run the queries**

   ```sql
   -- Execute queries.sql to explore behaviors and insights
   ```
3. **Use PgAdmin or DBeaver** for optimal SQL interface and result visualization.

---

## Tools Used

* PostgreSQL (via PgAdmin)
* SQL (CTEs, Aggregations, CASE WHEN logic)
* Screenshots from database table previews

---
## Author

### Franklin Durueke
Data Analyst | Financial Analysis | Business Intelligence
- 📧 [duruekefranklin@gmail.com](mailto:duruekefranklin@gmail.com)
- 🔗 [LinkedIn](https://www.linkedin.com/in/franklinanalytics/)
- 💼 [Portfolio](https://franklinanalytics.github.io/portfolio/)

---

## Final Thoughts

This analysis simulates a robust financial analytics use case involving behavior segmentation, credit risk evaluation, and profitability analysis. It can be extended into dashboard development, ML credit scoring, or campaign recommendation systems.

> 💬 *Feel free to fork, reuse, or contribute to this repository. Feedback and collaboration are welcome!*
