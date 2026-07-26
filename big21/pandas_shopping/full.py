import pandas as pd

customers_df = pd.read_csv("./data/customers.csv", parse_dates=["birth_date", "signup_date"])
orders_df = pd.read_csv("data/orders.csv")
items_df = pd.read_csv("data/order_items.csv")
products_df = pd.read_csv("data/products.csv")
weblogs_df = pd.read_csv("data/web_logs.csv")

####### customers_df ##########

# 중복 제거
customers_df = customers_df.drop_duplicates()
# print(customers_df.duplicated().sum())

# customers city 앞 뒤 띄어쓰기 제거
customers_df["city"] = customers_df["city"].str.strip()
# print(customers_df["city"].unique())


# customers gender 2가지로 통일
gmap = {"여":"여","F":"여","남":"남","M":"남"}
customers_df["gender"] = customers_df["gender"].map(gmap)
# print(customers_df["gender"].unique())

# customers birth_date, signup_date datetime으로


####### orders_df ##########

# order_datetime datetime 형식으로.(문제에서 변경)
# print(orders_df.info())


####### items_df ##########

# 중복 제거
items_df = items_df.drop_duplicates()

# quantity - 제거
items_df = items_df[items_df["quantity"]>0]
# print(items_df.describe())


####### products_df ##########

# price 부적절 str 제거
products_df["price"] = products_df["price"].str.replace(",","").str.replace("원","")

# price 정수화
products_df["price"] = pd.to_numeric(products_df["price"])

# category strip 처리
products_df["category"] = products_df["category"].str.strip()
# print(products_df["category"].unique())


# 중복 제거
products_df = products_df.drop_duplicates()

# price - 제거
products_df = products_df[products_df["price"]>0]


full = (items_df.merge(orders_df,on="order_id",how="inner", validate="m:1")
        .merge(products_df,on="product_id",how="inner", validate="m:1")
        .merge(customers_df,on="customer_id",how="inner", validate="m:1"))
