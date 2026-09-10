-- ============================================================
-- REDFLAG – THE FRAUD FILES
-- Fraud Detection Engine using MySQL
-- ============================================================

CREATE DATABASE IF NOT EXISTS redflag;
USE redflag;

-- ============================================================
-- TABLE CHECK
-- ============================================================

SHOW TABLES;

SELECT COUNT(*) AS total_transactions
FROM transactions;

DESCRIBE transactions;


-- ============================================================
-- P1 – VELOCITY DETECTION
-- Signature:
-- A user with 30 or more distinct transactions
-- on the same calendar date.
-- ============================================================

SELECT
    user_id,
    DATE(txn_time) AS txn_date,
    COUNT(DISTINCT txn_id) AS transaction_count
FROM transactions
GROUP BY
    user_id,
    DATE(txn_time)
HAVING COUNT(DISTINCT txn_id) >= 30
ORDER BY transaction_count DESC;

-- Finding:
-- User-days with 30 or more distinct transactions
-- are flagged as potential velocity fraud.


-- ============================================================
-- P2 – ROUND-AMOUNT CLUSTERING DETECTION
-- Signature:
-- A user with 15 or more transactions where the amount is
-- exactly 100, 200, 500, 1000, 2000, 5000, or 10000.
-- ============================================================

SELECT
    user_id,
    COUNT(*) AS round_amount_transaction_count,
    SUM(amount) AS total_round_amount
FROM transactions
WHERE amount IN (100, 200, 500, 1000, 2000, 5000, 10000)
GROUP BY user_id
HAVING COUNT(*) >= 15
ORDER BY round_amount_transaction_count DESC;

-- Finding:
-- Users repeatedly using predefined round transaction amounts
-- are flagged for possible suspicious transaction clustering.


-- ============================================================
-- P3 – CARD TESTING DETECTION
-- Signature:
-- A user with 30 or more transactions under ₹10
-- on the same calendar date.
-- ============================================================

SELECT
    user_id,
    DATE(txn_time) AS attack_date,
    COUNT(DISTINCT txn_id) AS tiny_txn_count
FROM transactions
WHERE amount < 10
GROUP BY
    user_id,
    DATE(txn_time)
HAVING COUNT(DISTINCT txn_id) >= 30
ORDER BY tiny_txn_count DESC;

-- Finding:
-- High-volume low-value transactions on the same day
-- are flagged as possible card-testing activity.


-- ============================================================
-- P4 – FAILED TRANSACTION DETECTION
-- Simplified signature:
-- A user with 20 or more FAILED transactions.
-- ============================================================

SELECT
    user_id,
    COUNT(*) AS failed_transaction_count
FROM transactions
WHERE status = 'FAILED'
GROUP BY user_id
HAVING COUNT(*) >= 20
ORDER BY failed_transaction_count DESC;

-- Finding:
-- Users with 20 or more failed transactions are flagged
-- for possible scripted retries or card-testing behaviour.


-- ============================================================
-- P5 – ODD-HOUR ACTIVITY DETECTION
-- Signature:
-- At least 30 total transactions and 80% or more
-- occurring between 2 AM and 5 AM
-- (hours 2, 3, and 4).
-- ============================================================

SELECT
    user_id,
    COUNT(*) AS total_transactions,
    SUM(
        CASE
            WHEN HOUR(txn_time) BETWEEN 2 AND 4
            THEN 1
            ELSE 0
        END
    ) AS odd_hour_transactions,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN HOUR(txn_time) BETWEEN 2 AND 4
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS odd_hour_percentage
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 30
   AND (
        100.0 *
        SUM(
            CASE
                WHEN HOUR(txn_time) BETWEEN 2 AND 4
                THEN 1
                ELSE 0
            END
        ) / COUNT(*)
       ) >= 80
ORDER BY
    odd_hour_percentage DESC,
    total_transactions DESC;

-- Finding:
-- Users whose transaction activity is heavily concentrated
-- between 2 AM and 5 AM are flagged for investigation.


-- ============================================================
-- P6 – MULE ACCOUNT DETECTION
-- Simplified signature:
-- A user with 8 or more CREDIT transactions.
-- ============================================================

SELECT
    user_id,
    COUNT(*) AS credit_transaction_count
FROM transactions
WHERE txn_type = 'CREDIT'
GROUP BY user_id
HAVING COUNT(*) >= 8
ORDER BY credit_transaction_count DESC;

-- Finding:
-- Users with frequent CREDIT transactions are flagged
-- as potential mule-account candidates.


-- ============================================================
-- P7 – REFUND ABUSE DETECTION
-- Signature:
-- At least 20 total transactions and more than 40%
-- of transactions are REFUND transactions.
-- ============================================================

SELECT
    user_id,
    COUNT(*) AS total_transactions,
    SUM(
        CASE
            WHEN txn_type = 'REFUND'
            THEN 1
            ELSE 0
        END
    ) AS refund_transactions,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN txn_type = 'REFUND'
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS refund_percentage
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 20
   AND (
        1.0 *
        SUM(
            CASE
                WHEN txn_type = 'REFUND'
                THEN 1
                ELSE 0
            END
        ) / COUNT(*)
       ) > 0.40
ORDER BY refund_percentage DESC;

-- Finding:
-- Users with a high refund ratio and sufficient transaction
-- volume are flagged for possible refund abuse.


-- ============================================================
-- P8 – TOP-5 MERCHANT CONCENTRATION DETECTION
-- Signature:
-- The top 5 users by transaction value account for
-- more than 60% of a merchant's total transaction value.
-- ============================================================

WITH merchant_user_volume AS (
    SELECT
        merchant_id,
        user_id,
        SUM(amount) AS user_volume
    FROM transactions
    GROUP BY
        merchant_id,
        user_id
),

ranked_users AS (
    SELECT
        merchant_id,
        user_id,
        user_volume,
        ROW_NUMBER() OVER (
            PARTITION BY merchant_id
            ORDER BY user_volume DESC
        ) AS user_rank
    FROM merchant_user_volume
),

top5_volume AS (
    SELECT
        merchant_id,
        SUM(user_volume) AS top5_user_volume
    FROM ranked_users
    WHERE user_rank <= 5
    GROUP BY merchant_id
),

merchant_totals AS (
    SELECT
        merchant_id,
        SUM(amount) AS merchant_total_volume
    FROM transactions
    GROUP BY merchant_id
)

SELECT
    mt.merchant_id,
    mt.merchant_total_volume,
    t5.top5_user_volume,
    ROUND(
        100.0 *
        t5.top5_user_volume /
        NULLIF(mt.merchant_total_volume, 0),
        2
    ) AS top5_volume_percentage
FROM merchant_totals mt
JOIN top5_volume t5
    ON mt.merchant_id = t5.merchant_id
WHERE
    100.0 *
    t5.top5_user_volume /
    NULLIF(mt.merchant_total_volume, 0) > 60
ORDER BY top5_volume_percentage DESC;

-- Finding:
-- Merchants where a small group of top users contributes
-- more than 60% of transaction value are flagged
-- for possible collusion or concentration risk.


-- ============================================================
-- P9 – ₹9,999 STRUCTURING DETECTION
-- Signature:
-- A user with 10 or more transactions of exactly ₹9,999.
-- ============================================================

SELECT
    user_id,
    COUNT(*) AS threshold_txn_count
FROM transactions
WHERE amount = 9999.00
GROUP BY user_id
HAVING COUNT(*) >= 10
ORDER BY threshold_txn_count DESC;

-- Finding:
-- Users repeatedly transacting exactly at ₹9,999
-- are flagged for possible structuring behaviour.


-- ============================================================
-- P10 – DORMANT-THEN-ACTIVE DETECTION
-- Signature:
-- A user with a gap of 90 or more days between consecutive
-- transactions, followed by 15 or more transactions
-- after the gap.
-- ============================================================

WITH user_activity AS (
    SELECT
        user_id,
        txn_id,
        txn_time,
        LAG(txn_time) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_txn_time
    FROM transactions
),

qualifying_gaps AS (
    SELECT
        user_id,
        txn_id,
        previous_txn_time,
        txn_time,
        TIMESTAMPDIFF(
            DAY,
            previous_txn_time,
            txn_time
        ) AS dormant_days
    FROM user_activity
    WHERE previous_txn_time IS NOT NULL
      AND TIMESTAMPDIFF(
            DAY,
            previous_txn_time,
            txn_time
          ) >= 90
)

SELECT
    qg.user_id,
    qg.previous_txn_time,
    qg.txn_time AS resumed_txn_time,
    qg.dormant_days,
    COUNT(t.txn_id) AS transactions_after_gap
FROM qualifying_gaps qg
JOIN transactions t
    ON t.user_id = qg.user_id
   AND t.txn_time > qg.txn_time
GROUP BY
    qg.user_id,
    qg.previous_txn_time,
    qg.txn_time,
    qg.dormant_days
HAVING COUNT(t.txn_id) >= 15
ORDER BY
    qg.dormant_days DESC,
    transactions_after_gap DESC;

-- Finding:
-- Users returning after 90+ days of inactivity and then
-- generating 15 or more subsequent transactions are flagged
-- for possible dormant-account takeover.


-- ============================================================
-- P11 – VELOCITY SPIKE DETECTION
-- Signature:
-- Peak monthly transaction count is at least 5 times
-- the average monthly transaction count,
-- and the peak month has at least 20 transactions.
-- ============================================================

WITH monthly_counts AS (
    SELECT
        user_id,
        YEAR(txn_time) AS txn_year,
        MONTH(txn_time) AS txn_month,
        COUNT(*) AS monthly_transaction_count
    FROM transactions
    GROUP BY
        user_id,
        YEAR(txn_time),
        MONTH(txn_time)
),

user_stats AS (
    SELECT
        user_id,
        AVG(monthly_transaction_count) AS average_monthly_transactions,
        MAX(monthly_transaction_count) AS peak_monthly_transactions
    FROM monthly_counts
    GROUP BY user_id
)

SELECT
    user_id,
    ROUND(
        average_monthly_transactions,
        2
    ) AS average_monthly_transactions,
    peak_monthly_transactions,
    ROUND(
        peak_monthly_transactions /
        NULLIF(average_monthly_transactions, 0),
        2
    ) AS peak_to_average_ratio
FROM user_stats
WHERE peak_monthly_transactions >= 20
  AND peak_monthly_transactions >=
      5 * average_monthly_transactions
ORDER BY
    peak_to_average_ratio DESC,
    peak_monthly_transactions DESC;

-- Finding:
-- Users showing an extreme monthly transaction spike
-- are flagged as possible abnormal-velocity cases.


-- ============================================================
-- P12 – GEOGRAPHIC IMPOSSIBILITY DETECTION
-- Signature:
-- Consecutive transactions by the same user occur
-- in different cities within 60 minutes.
-- ============================================================

WITH location_changes AS (
    SELECT
        user_id,
        txn_id,
        city,
        txn_time,
        LAG(city) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_city,
        LAG(txn_time) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_txn_time
    FROM transactions
)

SELECT
    user_id,
    txn_id,
    previous_city,
    city AS current_city,
    previous_txn_time,
    txn_time,
    TIMESTAMPDIFF(
        MINUTE,
        previous_txn_time,
        txn_time
    ) AS minutes_between
FROM location_changes
WHERE previous_city IS NOT NULL
  AND previous_city <> city
  AND TIMESTAMPDIFF(
        MINUTE,
        previous_txn_time,
        txn_time
      ) <= 60
ORDER BY minutes_between ASC;

-- Finding:
-- Consecutive transactions in different cities within
-- 60 minutes are flagged as geographically impossible
-- and possible account-takeover activity.