--Credit Card Usage Behavior & Profitability Analysis

-- Card Usage Behavior
-- 1. Customer spending patterns by income level and region
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

-- 2. Most used channel per card type and age group?
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

-- 3. Average transaction size and frequency per customer segment?

-- Repayment Behavior
-- 4. What % of customers miss due dates repeatedly (3+ times)?

-- 5. Compare repayment rates (amount_paid / amount_due) across age groups.

-- 6. What is the total value of unpaid debt over time?

-- Customer Profitability
-- 7. Estimate customer-level profitability:
-- profit = annual_fee + total_spent * reward_rate - unpaid_amount

-- 8. Who are the top 10 most profitable customers?

-- 9. Which income/age/region groups contribute most to profit?

-- Segmentation & Recommendations
-- 10. Cluster customers by usage (high spender, on-time payer, etc.)

-- 11. Which customers should be offered Platinum card upgrades?

-- 12. Which regions need repayment education or stricter credit policies?

