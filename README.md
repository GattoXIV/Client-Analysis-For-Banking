# 🏦 Banking Intelligence - Customer Analytical Record (CAR)

## 📝 Project Overview
This SQL script is designed to create a Customer Analytical Record (CAR), a denormalized table (one row per customer) that serves as an essential input for Supervised Machine Learning models (e.g., Churn prediction or Cross-Selling).

## 🎯 Main Objectives
* **Data Aggregation:** Shifting from a transactional granularity (many-to-one) to a customer-level view (one-to-one).
* **Feature Engineering:**
  * Dynamic calculation of customer age.
  * Asset Allocation: Pivoting account types to evaluate portfolio diversification.
  * Behavioral Analysis (RFM): Calculating Recency, Frequency, and Monetary values for cash inflows and outflows.
* **Missing Data Handling:** Managing NULL values to ensure clean and valid inputs for predictive models.

## 🛠️ Technologies
* SQL (MySQL/MariaDB)
