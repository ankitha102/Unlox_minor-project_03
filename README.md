# Unlox_minor-project_03
# 🚨 RedFlag — The Fraud Files

> 💳 A MySQL-based fraud detection engine for identifying suspicious transaction behaviour using 12 rule-based SQL detection patterns.

## 📌 Overview

**RedFlag — The Fraud Files** is a practical fraud analytics project built entirely with **MySQL**.

The objective is to analyze a large transaction dataset and identify users and merchants exhibiting behavioural patterns associated with potentially fraudulent activity.

This project demonstrates the practical use of **SQL for fraud analytics** through aggregation, conditional logic, Common Table Expressions (CTEs), and window functions.

## 🎯 Objectives

- 🔎 Identify suspicious transaction behaviour using rule-based SQL patterns.
- 👤 Detect abnormal user activity.
- 🏪 Identify suspicious merchant behaviour.
- 🧠 Apply practical SQL techniques used in transaction analytics.
- 🚫 Build the detection engine without Python or Machine Learning.

## 🛠️ Technology Stack

- 🗄️ **Database:** MySQL
- 💻 **Environment:** MySQL Workbench
- 📝 **Language:** SQL

## 📊 Dataset

The project uses approximately **200,000 transaction records** representing six months of payment activity.

### 📋 Transaction Table

`transactions`

### 🔑 Key Columns

| Column | Description |
|---|---|
| 🆔 `txn_id` | Unique transaction identifier |
| 👤 `user_id` | User identifier |
| 🏪 `merchant_id` | Merchant identifier |
| 💰 `amount` | Transaction amount |
| 🕒 `txn_time` | Transaction timestamp |
| ✅ `status` | Transaction status |
| 💳 `payment_mode` | Payment method |
| 📍 `city` | Transaction city |
| 🔄 `txn_type` | Transaction type |

## 🚨 Fraud Detection Patterns

The project implements **12 fraud detection patterns**:

| ID | Pattern | Detection Logic |
|---|---|---|
| ⚡ P1 | **Velocity Detection** | Detects users making 30+ distinct transactions on the same day |
| 💵 P2 | **Round-Amount Clustering** | Detects users repeatedly using predefined round transaction amounts |
| 🧪 P3 | **Card Testing** | Detects 30+ transactions under ₹10 on the same day |
| ❌ P4 | **Failed Transaction Detection** | Detects users with 20+ failed transactions |
| 🌙 P5 | **Odd-Hour Activity** | Detects users with 80%+ of activity between 2 AM and 5 AM |
| 🐴 P6 | **Mule Account Detection** | Detects users with 8+ credit transactions |
| 🔄 P7 | **Refund Abuse** | Detects users with 20+ transactions and a refund ratio above 40% |
| 🏪 P8 | **Top-5 Merchant Concentration** | Detects merchants where the top 5 users contribute over 60% of transaction value |
| 💳 P9 | **₹9,999 Structuring** | Detects users with 10+ transactions of exactly ₹9,999 |
| 😴 P10 | **Dormant-Then-Active** | Detects 90+ day inactivity followed by 15+ transactions |
| 📈 P11 | **Velocity Spike** | Detects users whose peak monthly activity is at least 5× their average |
| 🌍 P12 | **Geographic Impossibility** | Detects consecutive transactions in different cities within 60 minutes |

## 🧠 SQL Concepts Demonstrated

- 🔍 Filtering with `WHERE`
- 📊 Aggregation using `COUNT()`, `SUM()`, `AVG()` and `MAX()`
- 📦 `GROUP BY` and `HAVING`
- 🔀 Conditional logic with `CASE WHEN`
- 📅 Date and time functions
- ⏱️ `TIMESTAMPDIFF()`
- 🧩 Common Table Expressions (`WITH`)
- 🪟 Window Functions
- ↔️ `LAG()`
- 🔢 `ROW_NUMBER()`
- 🗂️ `PARTITION BY`
- 🔗 Multi-stage analytical queries

## 📁 Project Structure

```text
RedFlag-The-Fraud-Files/
│
├── 📄 redflag_fraud_detection.sql
└── 📘 README.md
