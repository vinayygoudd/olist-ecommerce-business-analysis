import warnings
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

warnings.filterwarnings("ignore")

sns.set_theme(style="whitegrid", palette="muted")
plt.rcParams.update({"figure.dpi": 120, "font.size": 10})

print("\n" + "="*60)
print("OLIST PROJECT — Data Cleaning + EDA")
print("="*60)

# ═══════════════════════════════════════════════════════════
# 1. LOAD DATA
# ═══════════════════════════════════════════════════════════
orders   = pd.read_csv("olist_orders_dataset.csv")
items    = pd.read_csv("olist_order_items_dataset.csv")
pays     = pd.read_csv("olist_order_payments_dataset.csv")
reviews  = pd.read_csv("olist_order_reviews_dataset.csv")
custs    = pd.read_csv("olist_customers_dataset.csv")
products = pd.read_csv("olist_products_dataset.csv")
sellers  = pd.read_csv("olist_sellers_dataset.csv")
cat_xlat = pd.read_csv("product_category_name_translation.csv")

# ═══════════════════════════════════════════════════════════
# 2. CLEANING
# ═══════════════════════════════════════════════════════════
date_cols = [
    "order_purchase_timestamp", "order_approved_at",
    "order_delivered_carrier_date", "order_delivered_customer_date",
    "order_estimated_delivery_date"
]
for col in date_cols:
    orders[col] = pd.to_datetime(orders[col])

delivered = orders[orders["order_status"] == "delivered"].copy()
reviews_clean = reviews.drop_duplicates(subset="order_id", keep="first")

products["product_category_name"] = products["product_category_name"].fillna("unknown")
products = products.merge(cat_xlat, on="product_category_name", how="left")
products["product_category_name_english"] = products["product_category_name_english"].fillna("unknown")

pays_agg = pays.groupby("order_id").agg(
    payment_type=("payment_type", lambda x: x.mode()[0]),
    payment_installments=("payment_installments", "max"),
    payment_value=("payment_value", "sum")
).reset_index()

order_revenue = items.groupby("order_id").agg(
    revenue=("price", "sum"),
    freight=("freight_value", "sum"),
    items_count=("order_item_id", "count")
).reset_index()

# ═══════════════════════════════════════════════════════════
# 3. MASTER DATASET
# ═══════════════════════════════════════════════════════════
master = delivered.copy()

master = master.merge(custs, on="customer_id", how="left")
master = master.merge(order_revenue, on="order_id", how="left")
master = master.merge(pays_agg, on="order_id", how="left")

master = master.merge(
    reviews_clean[["order_id", "review_score"]],
    on="order_id", how="left"
)

master = master.merge(
    items[["order_id", "product_id", "seller_id"]].drop_duplicates("order_id"),
    on="order_id", how="left"
)

master = master.merge(
    products[["product_id", "product_category_name_english"]],
    on="product_id", how="left"
)

master = master.merge(
    sellers[["seller_id", "seller_state", "seller_city"]],
    on="seller_id", how="left"
)

# ═══════════════════════════════════════════════════════════
# 4. FEATURE ENGINEERING
# ═══════════════════════════════════════════════════════════
master["delivery_delay_days"] = (
    master["order_delivered_customer_date"] -
    master["order_estimated_delivery_date"]
).dt.days.fillna(0)

master["delivery_time_days"] = (
    master["order_delivered_customer_date"] -
    master["order_purchase_timestamp"]
).dt.days

master["order_month"] = master["order_purchase_timestamp"].dt.to_period("M").astype(str)
master["order_dow"]   = master["order_purchase_timestamp"].dt.day_name()

master["review_score"] = master["review_score"].fillna(master["review_score"].median())

# ═══════════════════════════════════════════════════════════
# 5. MONTHLY SUMMARY
# ═══════════════════════════════════════════════════════════
monthly = master.groupby("order_month").agg(
    total_revenue=("revenue", "sum"),
    total_orders=("order_id", "count")
).reset_index()

monthly = monthly[monthly["order_month"] >= "2017-01"]

# ═══════════════════════════════════════════════════════════
# 6. VISUALS
# ═══════════════════════════════════════════════════════════

# 1. Monthly Revenue Trend
plt.figure(figsize=(10,4))
plt.plot(monthly["order_month"], monthly["total_revenue"], marker="o")
plt.xticks(rotation=45)
plt.title("Monthly Revenue Trend")
plt.xlabel("Month")
plt.ylabel("Revenue")
plt.show()

# 2. Top Categories
top_cats = master.groupby("product_category_name_english")["revenue"].sum().nlargest(10)
plt.figure(figsize=(8,5))
top_cats.sort_values().plot(kind="barh")
plt.title("Top 10 Categories by Revenue")
plt.xlabel("Revenue")
plt.show()

# 3. Review Distribution
plt.figure(figsize=(6,4))
sns.countplot(x="review_score", data=master)
plt.title("Review Score Distribution")
plt.show()

# 4. Payment Type
plt.figure(figsize=(6,6))
pays["payment_type"].value_counts().plot(kind="pie", autopct="%1.1f%%")
plt.title("Payment Method Share")
plt.ylabel("")
plt.show()

# 5. Delay vs Review
master["delay_bucket"] = pd.cut(
    master["delivery_delay_days"],
    bins=[-100, 0, 5, 15, 100],
    labels=["On Time/Early", "1-5 Late", "6-15 Late", ">15 Late"]
)

delay_avg = master.groupby("delay_bucket")["review_score"].mean()

plt.figure(figsize=(8,4))
delay_avg.plot(kind="bar")
plt.title("Delivery Delay vs Review Score")
plt.ylabel("Avg Review")
plt.show()

# 6. Orders by Day
order_counts = master["order_dow"].value_counts()

plt.figure(figsize=(8,4))
order_counts.plot(kind="bar")
plt.title("Orders by Day of Week")
plt.ylabel("Count")
plt.show()

print("\nEDA Completed Successfully")
