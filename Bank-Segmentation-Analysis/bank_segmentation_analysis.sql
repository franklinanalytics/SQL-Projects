CREATE TABLE customers (
	customer_id SERIAL PRIMARY KEY,
	name TEXT NOT NULL,
	gender VARCHAR(1) CHECK (gender IN ('M', 'F')),
	dob DATE,
	signup_date DATE NOT NULL,
	city TEXT
);

CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    account_type VARCHAR(20) CHECK (account_type IN ('savings', 'current', 'loan')),
    open_date DATE NOT NULL,
    balance NUMERIC(12,2) DEFAULT 0
);
ALTER TABLE accounts ADD COLUMN account_number TEXT;

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    account_id INT REFERENCES accounts(account_id),
    transaction_date DATE NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    transaction_type VARCHAR(20),     
    description VARCHAR(50) 
);

-- Insert 200 realistic Nigerian customers
INSERT INTO customers (name, gender, dob, signup_date, city)
SELECT 
    -- Full Name: Firstname + Lastname
    first_names[ceil(random() * array_length(first_names, 1))] || ' ' ||
    last_names[ceil(random() * array_length(last_names, 1))],

    -- Random gender
    CASE WHEN random() < 0.5 THEN 'M' ELSE 'F' END,

    -- Random date of birth (between 1970 and 1997)
    DATE '1970-01-01' + (trunc(random() * 10000)::int) * INTERVAL '1 day',

    -- Random signup date within last 3 years
    CURRENT_DATE - (trunc(random() * 1095)::int) * INTERVAL '1 day',

    -- Random city
    cities[ceil(random() * array_length(cities, 1))]
FROM generate_series(1, 200),
LATERAL (
    SELECT 
        ARRAY[
            'Chinedu', 'Aisha', 'Tunde', 'Ngozi', 'Bola', 'Obinna', 'Fatima', 'Yakubu',
            'Emeka', 'Zainab', 'Ifeanyi', 'Uche', 'Abubakar', 'Lilian', 'Segun', 'Halima', 
			'Adesuwa', 'Kehinde', 'Mercy', 'Emmanuel'
        ] AS first_names,
        ARRAY[
            'Okonkwo', 'Balogun', 'Adegoke', 'Nwachukwu', 'Danjuma', 'Adelaja', 'Ibrahim',
            'Umeh', 'Ogunleye', 'Abiola', 'Mohammed', 'Eze', 'Lawal', 'Obi', 'Ahmed', 'Onyeka',
			'Nwabueze', 'Ajibade', 'Suleman', 'Johnson'
        ] AS last_names,
        ARRAY[
            'Lagos', 'Abuja', 'Port Harcourt', 'Enugu', 'Kano', 'Ibadan', 'Jos', 'Abeokuta',
            'Calabar', 'Owerri', 'Benin City', 'Kaduna'
        ] AS cities
) name_data;

SELECT * FROM customers

-- Insert accounts (1-2 per customer) with realistic 10-digit account numbers and random balances
INSERT INTO accounts (customer_id, account_number, account_type, open_date, balance)
SELECT 
    c.customer_id,
    LPAD((trunc(random() * 1e10)::bigint)::text, 10, '0') AS account_number,
    (ARRAY['savings', 'current', 'loan'])[floor(random() * 3 + 1)],
    c.signup_date + (trunc(random() * 90)::int) * INTERVAL '1 day',
    round((1000 + random() * 499000)::numeric, 2)
FROM customers c
JOIN generate_series(1, 2) AS dup(n) ON true
WHERE random() < 0.75		-- Around 75% of customers get a second account
ORDER BY c.customer_id
LIMIT 1000;

SELECT * FROM accounts

-- Insert 1000 well-randomized transactions
INSERT INTO transactions (account_id, transaction_type, amount, transaction_date, description)
SELECT 
    t.account_id,
    t.transaction_type,
    t.amount,
    t.transaction_date,
    d.description
FROM (
    SELECT 
        a.account_id,
        -- Randomly assign credit or debit
        CASE 
            WHEN random() < 0.5 THEN 'debit' 
            ELSE 'credit' 
        END AS transaction_type,
        -- Random amount between 500 and 250,000
        ROUND((500 + random() * 249500)::numeric, 2) AS amount,
        -- Random date within past 2 years
        NOW() - (trunc(random() * 730) || ' days')::INTERVAL AS transaction_date
    FROM accounts a,
         generate_series(1, 10) gs
) t
-- Attach description based on type
JOIN LATERAL (
    SELECT 
        CASE 
            WHEN t.transaction_type = 'credit' THEN
                (ARRAY[
                    'Salary credited',
                    'Bank transfer from GTBank',
                    'Credit alert from Zenith',
                    'Reversal of failed transaction',
                    'Loan disbursement',
                    'Wallet top-up',
                    'Refund from vendor',
                    'POS reversal',
                    'Received from customer',
                    'Online payment received',
                    'Cash deposit'
                ])[FLOOR(random() * 11 + 1)::int]
            ELSE
                (ARRAY[
                    'POS payment at Shoprite',
                    'MTN Airtime recharge',
                    'Fuel purchase at Mobil',
                    'Electricity bill payment',
                    'Loan EMI debit',
                    'House rent payment',
                    'Online purchase at Jumia',
                    'Cash withdrawal from ATM',
                    'Subscription payment',
                    'Insurance premium debit',
                    'Bank transfer to Fidelity Bank'
                ])[FLOOR(random() * 11 + 1)::int]
        END AS description
) d ON TRUE
ORDER BY random()
LIMIT 1000;

SELECT * FROM transactions

-- Confirm balanced transaction type
SELECT 
	transaction_type, 
	COUNT(*) 
FROM transactions 
GROUP BY transaction_type;

-- See variety of descriptions
SELECT 
	description, 
	COUNT(*) 
FROM transactions 
GROUP BY description 
ORDER BY COUNT(*) DESC;

-- Count total rows
SELECT 
	COUNT(*) 
FROM transactions;


---DATA QUERYING FOR FINANCIAL INSIGHTS

-- 1. Total Spend Per Customer
SELECT 
    c.customer_id,
    c.name,
    SUM(t.amount) AS total_spent
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
JOIN transactions t ON a.account_id = t.account_id
WHERE t.transaction_type = 'debit'
GROUP BY c.customer_id, c.name
ORDER BY total_spent DESC;

-- 2. Salary Trend Analysis
SELECT 
    TO_CHAR(DATE_TRUNC('month', t.transaction_date), 'YYYY-MM') AS month,
    SUM(t.amount) AS total_salary_credited
FROM transactions t
WHERE t.transaction_type = 'credit'
  AND LOWER(t.description) LIKE '%salary credited%'
  AND t.transaction_date >= NOW() - INTERVAL '12 months'
GROUP BY month
ORDER BY month;

-- 3. Most Active Accounts by Number of Transactions
SELECT 
    t.account_id,
    c.name,
    COUNT(*) AS transaction_count
FROM transactions t
JOIN accounts a ON t.account_id = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
GROUP BY t.account_id, c.name
ORDER BY transaction_count DESC
LIMIT 10;

-- 4. MOST ACTIVE ACCOUNTS BY VOLUME
SELECT 
    t.account_id, 
	c.name, 
	a.account_number,
    COUNT(*) AS transaction_count, 
	SUM(t.amount) AS total_transaction,
	ROUND(AVG(t.amount), 2) AS avg_transaction_size,

	COUNT(CASE WHEN t.transaction_type = 'debit' THEN 1 END) AS debit_count,
    COUNT(CASE WHEN t.transaction_type = 'credit' THEN 1 END) AS credit_count,
    
    SUM(CASE WHEN t.transaction_type = 'debit' THEN t.amount ELSE 0 END) AS total_debit_volume,
    SUM(CASE WHEN t.transaction_type = 'credit' THEN t.amount ELSE 0 END) AS total_credit_volume
	
FROM transactions t
JOIN accounts a ON t.account_id = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
GROUP BY t.account_id, c.name, a.account_number
ORDER BY transaction_count DESC
LIMIT 10;

-- 5. Monthly Transaction Breakdown (Count and Volume)
SELECT 
    TO_CHAR(DATE_TRUNC('month', t.transaction_date), 'YYYY-MM') AS month,
    
    COUNT(*) AS total_transactions,
    
    SUM(CASE WHEN t.transaction_type = 'debit' THEN 1 ELSE 0 END) AS debit_count,
    SUM(CASE WHEN t.transaction_type = 'credit' THEN 1 ELSE 0 END) AS credit_count,
    
    SUM(CASE WHEN t.transaction_type = 'debit' THEN t.amount ELSE 0 END) AS total_debit_volume,
    SUM(CASE WHEN t.transaction_type = 'credit' THEN t.amount ELSE 0 END) AS total_credit_volume,
    
    SUM(t.amount) AS total_transaction_volume,
    
    ROUND(AVG(t.amount), 2) AS avg_transaction_size

FROM transactions t

GROUP BY DATE_TRUNC('month', t.transaction_date)
ORDER BY month;

-- 6. Yearly Transaction Breakdown
SELECT 
    TO_CHAR(DATE_TRUNC('year', t.transaction_date), 'YYYY') AS year,
    
    COUNT(*) AS total_transactions,
    
    SUM(CASE WHEN t.transaction_type = 'debit' THEN 1 ELSE 0 END) AS debit_count,
    SUM(CASE WHEN t.transaction_type = 'credit' THEN 1 ELSE 0 END) AS credit_count,
    
    SUM(CASE WHEN t.transaction_type = 'debit' THEN t.amount ELSE 0 END) AS total_debit_volume,
    SUM(CASE WHEN t.transaction_type = 'credit' THEN t.amount ELSE 0 END) AS total_credit_volume,
    
    SUM(t.amount) AS total_transaction_volume,
    
    ROUND(AVG(t.amount), 2) AS avg_transaction_size

FROM transactions t

GROUP BY DATE_TRUNC('year', t.transaction_date)
ORDER BY year;

-- 7. Top 20 High-Value Customers (By Total Credit Amount)
SELECT 
	c.customer_id,
	c.name,
	c.gender,
	c.city,
	COUNT(t.transaction_id) AS credit_transaction_count,
	SUM(t.amount) AS total_credits
FROM transactions t
JOIN accounts a ON t.account_id = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
WHERE t.transaction_type = 'credit'
GROUP BY c.customer_id, c.name, c.gender, c.city
ORDER BY total_credits DESC
LIMIT 20;

-- 8. Dormant accounts (Customers Inactive in the Last 12 months)
SELECT
	c.customer_id,
	c.name,
	c.gender,
	c.city,
	MAX(transaction_date) AS last_transaction_date
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
LEFT JOIN transactions t ON a.account_id = t.account_id
GROUP BY c.customer_id, c.name, c.gender, c.city
HAVING MAX(transaction_date) < CURRENT_DATE - INTERVAL '12 months'
ORDER BY MAX(transaction_date);

-- 9. Single Product Customers (Customers with only one account)
SELECT 
	c.customer_id,
	c.name,
	a.account_type,
	COUNT(account_id) AS total_accounts
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
GROUP BY c.customer_id, c.name, a.account_type
HAVING COUNT(account_id) = 1;

-- 10. Most Used Transaction Services
SELECT 
    description,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount
FROM transactions
GROUP BY description
ORDER BY transaction_count DESC;

-- 11. City-wise performance 
SELECT 
	c.city,
	COUNT(DISTINCT c.customer_id) AS total_customers,
	COUNT(transaction_id) AS total_transaction,
	SUM(amount) AS total_transaction_amount,
	ROUND(AVG(t.amount), 2) AS Avg_transaction_amount
FROM customers c
LEFT JOIN accounts a ON c.customer_id = a.customer_id
LEFT JOIN transactions t ON a.account_id = t.account_id
GROUP BY c.city
ORDER BY total_transaction DESC;

-- 12. Engagement by Region (Geo spread of Active/Dormant Accounts & Customers)
SELECT 
	c.city,
	COUNT(DISTINCT c.customer_id) AS total_customers,
	COUNT(DISTINCT a.account_id) AS total_accounts,
	COUNT(CASE WHEN t.transaction_date > CURRENT_DATE - INTERVAL '12 months' THEN 1 END) AS active_accounts,
	COUNT(CASE WHEN t.transaction_date < CURRENT_DATE - INTERVAL '12 months' THEN 1 END) AS dormant_accounts
FROM customers c
LEFT JOIN accounts a ON c.customer_id = a.customer_id
LEFT JOIN transactions t ON a.account_id = t.transaction_id
GROUP BY c.city
ORDER BY total_customers DESC;

-- Highest Spender by City
WITH customer_spending AS (
    SELECT 
        c.customer_id,
        c.name,
        c.city,
        SUM(t.amount) AS total_spent
    FROM customers c
    JOIN accounts a ON c.customer_id = a.customer_id
    JOIN transactions t ON a.account_id = t.account_id
    WHERE t.transaction_type = 'debit'
    GROUP BY c.customer_id, c.name, c.city
)

SELECT DISTINCT ON (city)
    city,
    name,
    total_spent
FROM customer_spending
ORDER BY city, total_spent DESC;

	



