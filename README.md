# Olist E-Commerce Business Performance Analysis


> **End-to-end business performance analysis of 96,478 real e-commerce orders using Python, MySQL, Excel & Power BI — revenue trends, RFM customer segmentation, seller KPIs & delivery impact analysis**

---

## The Business Problem

Olist is a Brazilian e-commerce marketplace connecting small businesses to major retail channels. Despite growing order volumes, three critical problems were silently bleeding revenue:

| Problem | Metric | Business Impact |
|---|---|---|
| Near-zero customer retention | **3% repeat purchase rate** | 97% of customers buy once and never return — zero CLV |
| Geographic revenue concentration | **63.4% revenue from 3 states** | SP, RJ, MG dependency creates fragile single-region risk |
| Delivery delays suppressing satisfaction | **6.8% late delivery rate** | Late orders score 1.39 points lower in reviews on average |

**Objective:** Diagnose these three problems across the full analyst stack and deliver boardroom-ready recommendations.

---

## Key Findings

```
Total Revenue       R$ 13,221,498     across 20 months (Sep 2016 – Aug 2018)
Total Orders              96,478      delivered orders analysed
Unique Customers          93,358      individual buyers
Avg Order Value          R$137.04     per transaction
Avg Review Score            4.16 / 5  overall platform satisfaction
Late Delivery Rate           6.8%     of orders arrived after estimated date
```

### Finding 1 — Health & Beauty is the #1 Revenue Driver
`health_beauty` generates **R$1.23M (9.3% of total revenue)**. Top 5 categories account for 39.7% of all revenue — a strong Pareto concentration that signals where to invest.

### Finding 2 — 3% Retention Rate is a Critical Business Risk
Only **3% of 93,358 customers** make more than one purchase. The business is 100% dependent on new customer acquisition with no retention engine. Champions segment (7,894 customers) already contributes **R$2.36M** — the highest ROI group for any retention investment.

### Finding 3 — Delivery Delays Directly Destroy Review Scores
| Delivery Status | Avg Review Score |
|---|---|
| Early (>10 days early) | 4.42 |
| On Time | 4.28 |
| 1–5 days late | 3.65 |
| 6–15 days late | 3.21 |
| 15+ days late | 2.89 |

A **1.39-point drop** from on-time to 15d+ late. This is a direct link between logistics performance and customer satisfaction.

### Finding 4 — SP Alone Drives 38.3% of Revenue
São Paulo: **R$5.07M**. Top 3 states combined: **R$8.38M (63.4%)**. Revenue concentration this high creates existential fragility — a single regional economic shock would devastate P&L.

### Finding 5 — 74% of Customers Are Still Reachable
RFM segmentation shows 83,675 customers (74%) are Champions, Loyal, or Potential Loyalists — all reachable with targeted campaigns. The 12,434 At-Risk customers represent a **R$660K winback opportunity**.

---

## Tech Stack

| Tool | Version | Usage |
|---|---|---|
| Python | 3.10+ | Data cleaning, EDA, RFM segmentation, 8 charts |
| Pandas | 2.x | Merging 8 tables, null handling, feature engineering |
| Matplotlib / Seaborn | latest | EDA visualisations |
| MySQL | 8.0 | 25+ analytical queries — window functions, CTEs, cohorts |
| Excel | Office 365 | 5-sheet workbook — what-if model, pivot analysis |
| Power BI | Desktop | 3-page dashboard — DAX measures, slicers, drill-through |

---

## Project Structure

```
olist-ecommerce-business-analysis/
│
├── README.md
│
├── python/
│   └── 01_data_cleaning_eda.py       # Cleaning + EDA + RFM + 8 charts
│
├── sql/
│   └── olist_analysis.sql            # 25+ queries across 8 analysis sections
│
├── excel/
│   └── Olist_Business_Analysis.xlsx  # 5-sheet workbook
│
├── data/
│   └── cleaned/
│       ├── olist_master.csv          # 96,478 rows — merged master dataset
│       ├── olist_rfm.csv             # 93,358 customers RFM scored
│       ├── olist_monthly.csv         # 20-month revenue summary
│       └── olist_seller_kpi.csv      # 2,960 sellers with performance tiers
│
├── outputs/                          # 8 EDA charts (PNG)
│
└── dashboard/                        # Power BI screenshots (PNG)
```

---

## How to Run

### Prerequisites
```bash
pip install pandas matplotlib seaborn openpyxl
```

### Step 1 — Download the raw data
Download all 8 CSV files from [Kaggle — Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) and place them in `data/raw/`.

### Step 2 — Run Python cleaning & EDA
```bash
cd python
python 01_data_cleaning_eda.py
```
This generates 4 cleaned CSVs in `data/cleaned/` and 8 charts in `outputs/`.

### Step 3 — Run SQL analysis
Open `sql/olist_analysis.sql` in MySQL Workbench. Run the SETUP section first to create schema and load the 4 cleaned CSVs, then run each analysis section.

### Step 4 — Open Excel workbook
Open `excel/Olist_Business_Analysis.xlsx` directly — all 5 sheets are pre-built with live formulas.

### Step 5 — Power BI dashboard
Load the 4 cleaned CSVs into Power BI Desktop. See the [Power BI Setup Guide](dashboard/PowerBI_Dashboard_Guide.docx) for full step-by-step instructions including data types, relationships, and DAX measures.

---

## EDA Charts

### Monthly Revenue Trend (2017–2018)
![Monthly Revenue Trend](outputs/01_monthly_revenue_trend.png)

### Top 10 Product Categories by Revenue
![Top Categories](outputs/02_top_categories_revenue.png)

### Revenue by Customer State
![Revenue by State](outputs/03_revenue_by_state.png)

### Review Score Distribution
![Review Scores](outputs/04_review_score_distribution.png)

### Payment Method Distribution
![Payment Types](outputs/05_payment_type_share.png)

### Delivery Delay vs Review Score
![Delivery vs Reviews](outputs/06_delay_vs_review_score.png)

### Customer RFM Segmentation
![RFM Segments](outputs/07_rfm_segments.png)

### Orders by Day of Week
![Orders by DOW](outputs/08_orders_by_dow.png)

---

## Power BI Dashboard

### Page 1 — Executive Overview
![Executive Overview](dashboard/page1_executive_overview.png)

### Page 2 — Customer & RFM Analysis
![Customer RFM](dashboard/page2_customer_rfm.png)

### Page 3 — Seller Performance & Delivery
![Seller Performance](dashboard/page3_seller_performance.png)

---

## Excel Workbook — 5 Sheets

| Sheet | Contents |
|---|---|
| Executive Summary | 6 KPI cards + monthly revenue table + bar chart |
| Revenue Scenario Model | What-if model: 4 growth scenarios with live formulas (blue = inputs) |
| RFM Analysis | Segment summary + top 200 customers colour-coded by segment |
| Seller Performance | Tier breakdown + top 50 sellers flagged by review risk |
| Key Insights | 5 data-backed insights with real numbers and action recommendations |

---

## SQL Analysis — 8 Sections

| Section | Queries | Techniques Used |
|---|---|---|
| Business Overview KPIs | 3 | Aggregations, GROUP BY |
| Revenue Trend Analysis | 3 | LAG(), cumulative SUM(), rolling averages |
| Product Category Analysis | 3 | RANK(), Pareto cumulative %, HAVING |
| Customer Analysis | 5 | NTILE(), retention cohort, concentration |
| RFM Segment Analysis | 2 | JOIN across tables, segment revenue share |
| Seller Performance | 5 | NTILE(), tier analysis, risk flagging |
| Delivery & Logistics | 4 | CASE buckets, monthly trend, financial impact |
| Payment Behaviour | 3 | Modal aggregation, installment analysis |

---

## Recommendations

### 1. Launch a Retention Program — Target Champions First
- Deploy post-purchase email at 30/60/90 days after first order
- Offer loyalty incentives to 7,894 Champions — highest ROI segment
- Re-engage 12,434 At-Risk customers who spent R$300+ historically
- **Goal:** Lift repeat rate from 3% to 8% within 6 months

### 2. Fix Logistics — SLA Tracking Per Seller
- Suspend sellers with >15% late delivery rate immediately
- Negotiate carrier SLA agreements in Northern/Northeast states
- Show customers realistic delivery estimates to reduce expectation mismatch
- **Goal:** Reduce late delivery rate from 6.8% to below 3%

### 3. Diversify Revenue — Target RS, PR, SC States
- Launch seller acquisition and marketing campaigns in RS, PR, SC
- Run state-specific promotions to stimulate demand outside SP/RJ/MG
- Expand seller count in `health_beauty` and `computers_accessories`
- **Goal:** Grow non-top-3 state revenue share from 36.6% to 50%

---

## Dataset

**Source:** [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — Kaggle

| File | Rows | Description |
|---|---|---|
| olist_orders_dataset.csv | 99,441 | Core order lifecycle and status |
| olist_order_items_dataset.csv | 112,650 | Products, pricing, and freight per order |
| olist_order_payments_dataset.csv | 103,886 | Payment type and installments |
| olist_order_reviews_dataset.csv | 99,224 | Customer review scores and comments |
| olist_customers_dataset.csv | 99,441 | Customer city, state, unique ID |
| olist_products_dataset.csv | 32,951 | Product category, dimensions, weight |
| olist_sellers_dataset.csv | 3,095 | Seller location |
| product_category_name_translation.csv | 71 | Portuguese to English category names |

> Raw data files are not included in this repository. Download directly from Kaggle using the link above.

---

## Author

Final Year B.Tech CSE | Data Analyst (Fresher)
📍 Hyderabad, India
