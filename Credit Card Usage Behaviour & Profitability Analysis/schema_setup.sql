--Credit Card Usage Behavior & Profitability Analysis
CREATE TABLE customers (				--Master profile of bank customers
    customer_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100),
    gender VARCHAR(10),
    age_group VARCHAR(20),
    income_level VARCHAR(20),
    credit_score INT,
    city VARCHAR(50),
    region VARCHAR(50),
    date_joined DATE
);
CREATE TABLE cards (				--Credit card product info
    card_id SERIAL PRIMARY KEY,
    card_type VARCHAR(50),  		--Classic, Gold, Platinum
    annual_fee NUMERIC(10,2),
    reward_rate NUMERIC(4,2), 		-- reward points per Naira spent
    credit_limit NUMERIC(12,2)
);
CREATE TABLE transactions (					--Credit card usage history
    transaction_id SERIAL PRIMARY KEY,
    customer_id INT,
    card_id INT,
    transaction_date DATE,
    amount NUMERIC(12,2),
    category VARCHAR(50),  					-- e.g. Travel, Bills, Groceries, Luxury
    channel VARCHAR(20)    					-- Online, POS, ATM
);
CREATE TABLE repayments (					--Credit card repayment activity
    repayment_id SERIAL PRIMARY KEY,
    customer_id INT,
    due_date DATE,
    repayment_date DATE,
    amount_due NUMERIC(12,2),
    amount_paid NUMERIC(12,2)
);

SELECT * FROM customers
SELECT * FROM cards
SELECT * FROM transactions
SELECT * FROM repayments

