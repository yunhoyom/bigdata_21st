import pandas as pd
from full import full, items_df, orders_df, products_df, customers_df

pd.set_option("display.float_format", "{:,.0f}".format)

print("\n########################## 문제 01 #######################\n")
# 과제 1 orders 와 order_items 를 결합해 주문 라인 단위의 매출 원장을 만듭니다. 조인 키와 방식의 선택 근거를 밝힙니다.

full["amount"] = full["unit_price"] * full["quantity"] * (1-full["discount"])
print(f"과제 1 . 주문 라인 단위 매출 원장 : \n {full[['order_id', 'amount']]}")

# 과제 2중복 행을 제거하고, order_datetime 의 타입 오염을 errors="coerce" 로 정제한 뒤 손실 행 수를 보고합니다. 상태별 처리 규칙(총매출 대 순매출)을 정의합니다.

full["order_datetime"] = pd.to_datetime(full["order_datetime"], errors="coerce")
print(full.shape[0])  # order_datetime  484945 non-null  datetime64[us]
print(f"\n과제 2. order_datetime 정제 후 손실 행 수 : {full['order_datetime'].isna().sum()}") # 4685
full = full.dropna(subset=["order_datetime"])
print(full.shape[0])
full["pure"] = full[~full["status"].isin(["canceled", "returned"])]["amount"]

gb = full.groupby("status").agg(
    total_amount=("amount", "sum"),
    pure_amount=("pure", "sum")
)
print(gb)

# 과제 3. 월별 총매출, 순매출, 취소반품 제외액, 유효 주문 수 대사표를 만들고, 두 팀 수치가 달랐던 원인을 상태 포함 범위 차이로 설명
full["month"] = full["order_datetime"].dt.strftime("%Y-%m")
full["excepted"] = full[full["status"].isin(["canceled", "returned"])]["amount"]
print(f"full: {full[full['status'].isin(['canceled','returned'])]}")

mon = full.groupby("month").agg(
    total_amount=("amount", "sum"),
    pure_amount=("pure", "sum"),
    excepted=("excepted","sum"),
    valid_order=("pure", "count")
)
print(f"\n과제 3. {mon}")
print("위 그래프를 기반으로 봤을 때 총매출과 순매출은 차이가 있습니다.\n매출은 순매출(pure_amount)를 기준으로 합니다.")

print("\n########################## 문제 02 #######################\n")
# 과제 1. 월별 순매출을 구매 고객수 × 고객당 주문수 × 주문당 금액(AOV) 로 분해합니다
pure_amo = full[~full["status"].isin(["canceled", "returned"])]

pure_divide = pure_amo.groupby("month").agg(
    cust_count=("customer_id", "nunique"),
    order_count=("order_id", "count"),
    pure_amount=("amount", "sum")
)

pure_divide["order_per_cust"] = pure_divide["order_count"] / pure_divide["cust_count"]
pure_divide["aov"] = pure_divide["pure_amount"] / pure_divide["order_count"]

pure_divide["pure_amount_check"] = (
    pure_divide["cust_count"] * pure_divide["order_per_cust"] * pure_divide["aov"]
)

# 과제 2. 분해 항등식이 실제 순매출과 일치하는지 검산 코드를 포함합니다
compare = mon[["pure_amount"]].join(
    pure_divide[["pure_amount_check"]],
    how="outer"
)

compare["diff"] = compare["pure_amount"] - mon["pure_amount"]
print(f"{compare}\n")

# 과제 3. 
print(f"과제 3. {pure_divide.loc[['2024-01', '2024-06']]}")
print("1. 구매 고객 수 16.5% 증가 \n2. 1명당 주문 건 수가 57% 증가.\n위 이유로 성장했음을 판단할 수 있음.")


print("\n########################## 문제 03 #######################\n")
# 과제 1. 기준일 2024-07-01을 기준으로 고객별 R(마지막 구매 경과일)·F(유효 주문수)·M(순매출)을 산출합니다. 취소·반품은 제외합니다.
standard = full[full["order_datetime"]> "2024-07-01"]
standard = standard[~standard["status"].isin(["canceled", "returned"])]
standard["amount"] = standard["unit_price"] * standard["quantity"] * (1-standard["discount"])
rfm = standard.groupby("customer_id").agg(
    last_order=("order_datetime", "max"),
    frequency=("order_id","count"),
    momentary=("amount","sum")
)

rfm["recency"] = (pd.Timestamp.now() - rfm["last_order"]).dt.days

print(f"과제 1. \n {rfm}")

# 과제 2. 구매 이력이 없는 고객을 어떻게 처리할지 규칙을 명시합니다.
cus_ord = customers_df.merge(orders_df, how="left")
print(f"과제 2. {cus_ord[cus_ord['order_id'].isna()]}")

# 과제 3. qcut 으로 각 축에 1~5점을 매기고, 동점 경계를 어떻게 처리하는지 설명합니다.
rfm["recency_tier"] = pd.qcut(rfm["recency"].rank(method="first"), q=5, labels=[5,4,3,2,1])
rfm["frequency_tier"] = pd.qcut(rfm["frequency"].rank(method="first"), q=5, labels=[1,2,3,4,5])
rfm["momentary_tier"] = pd.qcut(rfm["momentary"].rank(method="first"), q=5, labels=[1,2,3,4,5])
print(f"과제 3. .rank(method='first')로 동점이 없는 순위를 만들어 동점자 많을 경우의 오류 해결. \n {rfm[['recency_tier','frequency_tier','momentary_tier']]}")

# 과제 4 안 함..

print("\n########################## 문제 05 #######################\n")
# 과제 1. 고객별 첫 유효 주문 월(코호트)과 각 주문의 경과 월(period 차이)을 계산합니다
print(full.head())
cust_month = full.groupby("customer_id")["month"].min()
print(cust_month)