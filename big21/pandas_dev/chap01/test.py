import pandas as pd

customers = pd.read_csv("./data/customers.csv")
print("shape : ", customers.shape)
print(customers.head())