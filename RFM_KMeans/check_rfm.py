
import pandas as pd
from pathlib import Path

# Đọc dữ liệu khách hàng
folder = Path(__file__).parent
df = pd.read_csv(folder / "customer_rfm.csv")

# Kiểm tra số lượng dữ liệu
print("=== KIEM TRA DU LIEU RFM ===")
print("So dong, so cot:", df.shape)

print("\n5 dong dau:")
print(df.head())

print("\nTen cac cot:")
print(df.columns.tolist())

print("\nGia tri thieu:")
print(df.isnull().sum())

print("\nSo Customer_Key trung lap:")
print(df["Customer_Key"].duplicated().sum())

print("\nThong ke RFM:")
print(df[["Recency", "Frequency", "Monetary"]].describe())

# Kiểm tra dữ liệu không hợp lệ
invalid = (
    (df["Recency"] < 0)
    | (df["Frequency"] <= 0)
    | (df["Monetary"] < 0)
)

print("\nSo dong khong hop le:", invalid.sum())
