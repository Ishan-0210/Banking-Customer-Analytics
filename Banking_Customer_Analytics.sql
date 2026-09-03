CREATE DATABASE banking_analytics;
USE banking_analytics;
CREATE TABLE customers(
 customer_id VARCHAR(20) PRIMARY KEY,
 first_name VARCHAR(50),
 last_name VARCHAR(50),
 email VARCHAR(100),
 city VARCHAR(50),
 credit_score INT,
 created_at DATETIME
);

CREATE TABLE accounts(
 account_id VARCHAR(20) PRIMARY KEY,
 customer_id VARCHAR(20),
 account_type VARCHAR(20),
 balance_usd DECIMAL(12,2),
 open_date DATE,
 FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE cards(
 card_id VARCHAR(20) PRIMARY KEY,
 account_id VARCHAR(20),
 card_type VARCHAR(20),
 expiration_date DATE,
 FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

CREATE TABLE merchants(
 merchant_id VARCHAR(20) PRIMARY KEY,
 merchant_name VARCHAR(100),
 city VARCHAR(50)
);

CREATE TABLE branches(
 branch_id VARCHAR(20) PRIMARY KEY,
 branch_name VARCHAR(100),
 manager_name VARCHAR(100),
 city VARCHAR(50),
 country VARCHAR(50)      
);

CREATE TABLE loans(
 loan_id VARCHAR(20) PRIMARY KEY,
 customer_id VARCHAR(20),
 loan_amount DECIMAL(12,2),
 interest_rate DECIMAL(5,2),
 start_date DATE,
 FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE transactions(
 transaction_id VARCHAR(25) PRIMARY KEY,
 account_id VARCHAR(20),
 merchant_id VARCHAR(20),
 amount_usd DECIMAL(12,2),
 transaction_date DATETIME,  -- <- بدل DATE
 FOREIGN KEY (account_id) REFERENCES accounts(account_id),
 FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id)
 );


SELECT 'Customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'Accounts', COUNT(*) FROM accounts
UNION ALL
SELECT 'Cards', COUNT(*) FROM cards
UNION ALL
SELECT 'Merchants', COUNT(*) FROM merchants
UNION ALL
SELECT 'Branches', COUNT(*) FROM branches
UNION ALL
SELECT 'Loans', COUNT(*) FROM loans
UNION ALL
SELECT 'Transactions', COUNT(*) FROM transactions;

-- Business Question 1: Total Customers

SELECT COUNT(*) AS total_customers
FROM customers;

-- Customers by City

SELECT
    city,
    COUNT(*) AS customer_count
FROM customers
GROUP BY city
ORDER BY customer_count DESC;

-- Business Question 2: Customer Credit Profile

SELECT
    MIN(credit_score) AS minimum_credit_score,
    MAX(credit_score) AS maximum_credit_score,
    ROUND(AVG(credit_score), 2) AS average_credit_score
FROM customers;

-- Business Question 3: Credit Score Distribution

SELECT
    CASE
        WHEN credit_score < 580 THEN 'Poor'
        WHEN credit_score < 670 THEN 'Fair'
        WHEN credit_score < 740 THEN 'Good'
        WHEN credit_score < 800 THEN 'Very Good'
        ELSE 'Excellent'
    END AS credit_score_category,
    COUNT(*) AS customer_count
FROM customers
GROUP BY
    CASE
        WHEN credit_score < 580 THEN 'Poor'
        WHEN credit_score < 670 THEN 'Fair'
        WHEN credit_score < 740 THEN 'Good'
        WHEN credit_score < 800 THEN 'Very Good'
        ELSE 'Excellent'
    END
ORDER BY customer_count DESC;

-- Business Question 4: Account Balance Overview

SELECT
    COUNT(*) AS total_accounts,
    ROUND(SUM(balance_usd), 2) AS total_account_balance,
    ROUND(AVG(balance_usd), 2) AS average_account_balance,
    ROUND(MIN(balance_usd), 2) AS minimum_account_balance,
    ROUND(MAX(balance_usd), 2) AS maximum_account_balance
FROM accounts;

-- Business Question 5: Account Balance by Account Type

SELECT
    account_type,
    COUNT(*) AS account_count,
    ROUND(SUM(balance_usd), 2) AS total_balance,
    ROUND(AVG(balance_usd), 2) AS average_balance
FROM accounts
GROUP BY account_type
ORDER BY total_balance DESC;

-- Business Question 6: Transaction Overview

SELECT
    COUNT(*) AS total_transactions,
    ROUND(SUM(amount_usd), 2) AS total_transaction_value,
    ROUND(AVG(amount_usd), 2) AS average_transaction_value,
    ROUND(MIN(amount_usd), 2) AS minimum_transaction,
    ROUND(MAX(amount_usd), 2) AS maximum_transaction
FROM transactions;

-- Business Question 7: Monthly Transaction Trends

SELECT
    YEAR(transaction_date) AS transaction_year,
    MONTH(transaction_date) AS transaction_month,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount_usd), 2) AS total_transaction_value,
    ROUND(AVG(amount_usd), 2) AS average_transaction_value
FROM transactions
GROUP BY
    YEAR(transaction_date),
    MONTH(transaction_date)
ORDER BY
    transaction_year,
    transaction_month;
    
    -- Business Question 8: Highest-Value Transaction Months

SELECT
    YEAR(transaction_date) AS transaction_year,
    MONTH(transaction_date) AS transaction_month,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount_usd), 2) AS total_transaction_value
FROM transactions
GROUP BY
    YEAR(transaction_date),
    MONTH(transaction_date)
ORDER BY total_transaction_value DESC
LIMIT 10;

-- Business Question 9: Transaction Value by Customer City

-- Step 1: Query Performance Check

SHOW INDEX FROM transactions;

EXPLAIN
SELECT
    c.city,
    COUNT(t.transaction_id) AS transaction_count,
    SUM(t.amount_usd) AS total_transaction_value
FROM customers c
JOIN accounts a
    ON c.customer_id = a.customer_id
JOIN transactions t
    ON a.account_id = t.account_id
GROUP BY c.city
ORDER BY total_transaction_value DESC;

-- Question 9 Step 2:  Test Customer-Account-Transaction JOIN

SELECT
    c.city,
    a.account_id,
    t.amount_usd
FROM customers c
JOIN accounts a
    ON c.customer_id = a.customer_id
JOIN transactions t
    ON a.account_id = t.account_id
LIMIT 100;

-- Business Question 9 Step 3: Optimize Transaction Summary

CREATE TEMPORARY TABLE account_transaction_summary AS
SELECT
    account_id,
    COUNT(*) AS transaction_count,
    SUM(amount_usd) AS total_transaction_value
FROM transactions
GROUP BY account_id;

SELECT COUNT(*) AS accounts_with_transactions
FROM account_transaction_summary;

-- Business Question 9 Step 4: Final City Analysis

SELECT
    c.city,
    SUM(s.transaction_count) AS transaction_count,
    ROUND(SUM(s.total_transaction_value), 2) AS total_transaction_value,
    ROUND(
        SUM(s.total_transaction_value) / SUM(s.transaction_count),
        2
    ) AS average_transaction_value
FROM customers c
JOIN accounts a
    ON c.customer_id = a.customer_id
JOIN account_transaction_summary s
    ON a.account_id = s.account_id
GROUP BY c.city
ORDER BY total_transaction_value DESC;

-- Business Question 10: Loan Portfolio Overview

SELECT
    COUNT(*) AS total_loans,
    ROUND(SUM(loan_amount), 2) AS total_loan_value,
    ROUND(AVG(loan_amount), 2) AS average_loan_amount,
    ROUND(AVG(interest_rate), 2) AS average_interest_rate,
    ROUND(MIN(loan_amount), 2) AS minimum_loan_amount,
    ROUND(MAX(loan_amount), 2) AS maximum_loan_amount
FROM loans;

-- Business Question 11: Loan Interest Rate Distribution

SELECT
    CASE
        WHEN interest_rate < 5 THEN 'Below 5%'
        WHEN interest_rate < 10 THEN '5% - 9.99%'
        WHEN interest_rate < 15 THEN '10% - 14.99%'
        ELSE '15% or Higher'
    END AS interest_rate_category,
    COUNT(*) AS loan_count,
    ROUND(SUM(loan_amount), 2) AS total_loan_value,
    ROUND(AVG(loan_amount), 2) AS average_loan_amount
FROM loans
GROUP BY
    CASE
        WHEN interest_rate < 5 THEN 'Below 5%'
        WHEN interest_rate < 10 THEN '5% - 9.99%'
        WHEN interest_rate < 15 THEN '10% - 14.99%'
        ELSE '15% or Higher'
    END
ORDER BY total_loan_value DESC;

-- Business Question 12: Loan Exposure by Credit Score Category

SELECT
    CASE
        WHEN c.credit_score < 580 THEN 'Poor'
        WHEN c.credit_score < 670 THEN 'Fair'
        WHEN c.credit_score < 740 THEN 'Good'
        WHEN c.credit_score < 800 THEN 'Very Good'
        ELSE 'Excellent'
    END AS credit_score_category,
    COUNT(l.loan_id) AS loan_count,
    ROUND(SUM(l.loan_amount), 2) AS total_loan_value,
    ROUND(AVG(l.loan_amount), 2) AS average_loan_amount
FROM customers c
JOIN loans l
    ON c.customer_id = l.customer_id
GROUP BY
    CASE
        WHEN c.credit_score < 580 THEN 'Poor'
        WHEN c.credit_score < 670 THEN 'Fair'
        WHEN c.credit_score < 740 THEN 'Good'
        WHEN c.credit_score < 800 THEN 'Very Good'
        ELSE 'Excellent'
    END
ORDER BY total_loan_value DESC;

-- Business Question 13: Loan Portfolio Share by Credit Score

SELECT
    CASE
        WHEN c.credit_score < 580 THEN 'Poor'
        WHEN c.credit_score < 670 THEN 'Fair'
        WHEN c.credit_score < 740 THEN 'Good'
        WHEN c.credit_score < 800 THEN 'Very Good'
        ELSE 'Excellent'
    END AS credit_score_category,
    ROUND(SUM(l.loan_amount), 2) AS total_loan_value,
    ROUND(
        SUM(l.loan_amount) * 100.0 /
        (SELECT SUM(loan_amount) FROM loans),
        2
    ) AS portfolio_share_percent
FROM customers c
JOIN loans l
    ON c.customer_id = l.customer_id
GROUP BY
    CASE
        WHEN c.credit_score < 580 THEN 'Poor'
        WHEN c.credit_score < 670 THEN 'Fair'
        WHEN c.credit_score < 740 THEN 'Good'
        WHEN c.credit_score < 800 THEN 'Very Good'
        ELSE 'Excellent'
    END
ORDER BY portfolio_share_percent DESC;

-- Business Question 14: Transaction Activity by Account Type

SELECT
    a.account_type,
    COUNT(t.transaction_id) AS transaction_count,
    ROUND(SUM(t.amount_usd), 2) AS total_transaction_value,
    ROUND(AVG(t.amount_usd), 2) AS average_transaction_value
FROM accounts a
JOIN transactions t
    ON a.account_id = t.account_id
GROUP BY a.account_type
ORDER BY total_transaction_value DESC;

SHOW TABLES LIKE 'account_transaction_summary';

USE banking_analytics;

SHOW TABLES;

-- Business Question 15: Top Customers by Transaction Value
-- Performance issue: Error 2013 during customer-level aggregation

CREATE TEMPORARY TABLE customer_transaction_summary AS
SELECT
    a.customer_id,
    COUNT(t.transaction_id) AS transaction_count,
    SUM(t.amount_usd) AS total_transaction_value,
    AVG(t.amount_usd) AS average_transaction_value
FROM accounts a
JOIN transactions t
    ON a.account_id = t.account_id
GROUP BY a.customer_id;

-- Business Question 16: Average Loan Amount by Credit Score Category

SELECT
    CASE
        WHEN c.credit_score < 580 THEN 'Poor'
        WHEN c.credit_score < 670 THEN 'Fair'
        WHEN c.credit_score < 740 THEN 'Good'
        WHEN c.credit_score < 800 THEN 'Very Good'
        ELSE 'Excellent'
    END AS credit_score_category,
    COUNT(l.loan_id) AS loan_count,
    ROUND(AVG(l.loan_amount), 2) AS average_loan_amount,
    ROUND(AVG(l.interest_rate), 2) AS average_interest_rate
FROM customers c
JOIN loans l
    ON c.customer_id = l.customer_id
GROUP BY
    CASE
        WHEN c.credit_score < 580 THEN 'Poor'
        WHEN c.credit_score < 670 THEN 'Fair'
        WHEN c.credit_score < 740 THEN 'Good'
        WHEN c.credit_score < 800 THEN 'Very Good'
        ELSE 'Excellent'
    END
ORDER BY average_loan_amount DESC;

-- Business Question 17: Loan Concentration by Customer

SELECT
    loan_count_category,
    COUNT(*) AS customer_count
FROM (
    SELECT
        customer_id,
        CASE
            WHEN COUNT(*) = 1 THEN '1 Loan'
            WHEN COUNT(*) = 2 THEN '2 Loans'
            WHEN COUNT(*) = 3 THEN '3 Loans'
            ELSE '4+ Loans'
        END AS loan_count_category
    FROM loans
    GROUP BY customer_id
) AS customer_loans
GROUP BY loan_count_category
ORDER BY customer_count DESC;

-- Business Question 18: Customer Account Ownership

SELECT
    account_count_category,
    COUNT(*) AS customer_count
FROM (
    SELECT
        customer_id,
        CASE
            WHEN COUNT(*) = 1 THEN '1 Account'
            WHEN COUNT(*) = 2 THEN '2 Accounts'
            ELSE '3+ Accounts'
        END AS account_count_category
    FROM accounts
    GROUP BY customer_id
) AS customer_accounts
GROUP BY account_count_category
ORDER BY customer_count DESC;

-- Business Question 19: Customers Without Accounts

SELECT
    COUNT(*) AS customers_without_accounts
FROM customers c
LEFT JOIN accounts a
    ON c.customer_id = a.customer_id
WHERE a.account_id IS NULL;

-- Business Question 20: Average Accounts per Customer

SELECT
    COUNT(*) AS total_accounts,
    COUNT(DISTINCT customer_id) AS customers_with_accounts,
    ROUND(
        COUNT(*) / COUNT(DISTINCT customer_id),
        2
    ) AS average_accounts_per_customer
FROM accounts;

-- Business Question 21: Card Ownership by Account

SELECT
    COUNT(*) AS total_cards,
    COUNT(DISTINCT account_id) AS accounts_with_cards,
    ROUND(
        COUNT(*) / COUNT(DISTINCT account_id),
        2
    ) AS average_cards_per_account
FROM cards;

-- Business Question 22: Card Type Distribution

SELECT
    card_type,
    COUNT(*) AS card_count,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cards),
        2
    ) AS percentage_of_cards
FROM cards
GROUP BY card_type
ORDER BY card_count DESC;

-- Business Question 23: Card Expiration by Year

SELECT
    YEAR(expiration_date) AS expiration_year,
    COUNT(*) AS cards_expiring
FROM cards
GROUP BY YEAR(expiration_date)
ORDER BY expiration_year;

-- Business Question 24: Branch Distribution by Country

SELECT
    country,
    COUNT(*) AS branch_count,
    COUNT(DISTINCT city) AS city_count
FROM branches
GROUP BY country
ORDER BY branch_count DESC;

-- Business Question 25: Branch Concentration by City

SELECT
    city,
    COUNT(*) AS branch_count
FROM branches
GROUP BY city
HAVING COUNT(*) > 1
ORDER BY branch_count DESC;

-- Business Question 26: Merchant Distribution by City

SELECT
    city,
    COUNT(*) AS merchant_count
FROM merchants
GROUP BY city
ORDER BY merchant_count DESC;

-- Business Question 27: Merchant-Transaction JOIN Test

SELECT
    m.merchant_name,
    m.city,
    t.amount_usd
FROM merchants m
JOIN transactions t
    ON m.merchant_id = t.merchant_id
LIMIT 100;

-- Business Question 28: Credit Score by City

SELECT
    city,
    COUNT(*) AS customer_count,
    ROUND(AVG(credit_score), 2) AS average_credit_score,
    MIN(credit_score) AS minimum_credit_score,
    MAX(credit_score) AS maximum_credit_score
FROM customers
GROUP BY city
HAVING COUNT(*) >= 20
ORDER BY average_credit_score DESC;

-- Business Question 29: Loan Value by Account Ownership

SELECT
    account_count_category,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_loan_value), 2) AS average_loan_value,
    ROUND(AVG(loan_count), 2) AS average_loan_count
FROM (
    SELECT
        c.customer_id,
        CASE
            WHEN COUNT(DISTINCT a.account_id) = 0 THEN '0 Accounts'
            WHEN COUNT(DISTINCT a.account_id) = 1 THEN '1 Account'
            WHEN COUNT(DISTINCT a.account_id) = 2 THEN '2 Accounts'
            ELSE '3+ Accounts'
        END AS account_count_category,
        COALESCE(SUM(l.loan_amount), 0) AS total_loan_value,
        COUNT(DISTINCT l.loan_id) AS loan_count
    FROM customers c
    LEFT JOIN accounts a
        ON c.customer_id = a.customer_id
    LEFT JOIN loans l
        ON c.customer_id = l.customer_id
    GROUP BY c.customer_id
) AS customer_profile
GROUP BY account_count_category
ORDER BY average_loan_value DESC;

-- Business Question 30: Executive Banking KPIs

SELECT
    (SELECT COUNT(*) FROM customers) AS total_customers,
    (SELECT COUNT(*) FROM accounts) AS total_accounts,
    (SELECT ROUND(SUM(balance_usd), 2) FROM accounts) AS total_account_balance,
    (SELECT COUNT(*) FROM loans) AS total_loans,
    (SELECT ROUND(SUM(loan_amount), 2) FROM loans) AS total_loan_value,
    (SELECT COUNT(*) FROM cards) AS total_cards,
    (SELECT COUNT(*) FROM transactions) AS total_transactions,
    (SELECT ROUND(SUM(amount_usd), 2) FROM transactions) AS total_transaction_value;