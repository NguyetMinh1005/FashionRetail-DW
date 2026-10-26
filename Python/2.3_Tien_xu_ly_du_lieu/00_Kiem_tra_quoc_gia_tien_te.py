import pandas as pd
from pathlib import Path

BASE_DIR = Path(r"E:\FashionRetail-DW")
RAW_DIR = BASE_DIR / "data" / "raw"

stores = pd.read_csv(RAW_DIR / "stores.csv")
transactions = pd.read_csv(RAW_DIR / "transactions.csv", nrows=5)

print("=" * 80)
print("KIỂM TRA QUỐC GIA VÀ TIỀN TỆ")
print("=" * 80)

print("\n[CỘT TRONG stores.csv]")
print(stores.columns.tolist())

print("\n[CỘT TRONG transactions.csv]")
print(transactions.columns.tolist())

# Tự tìm cột Country
country_col = None

for candidate in ["Country", "country", "COUNTRY"]:
    if candidate in stores.columns:
        country_col = candidate
        break

if country_col is None:
    print("\nKhông tìm thấy cột Country trong stores.csv")
else:
    print("\n[CÁC QUỐC GIA HIỆN CÓ]")
    print(
        stores[country_col]
        .astype(str)
        .str.strip()
        .value_counts(dropna=False)
    )

print("\n[MẪU stores.csv]")
print(stores.head(20).to_string(index=False))

print("\n[MẪU transactions.csv]")
print(transactions.to_string(index=False))

print("\n" + "=" * 80)
print("CÁC LOẠI TIỀN TỆ TRONG transactions.csv")
print("=" * 80)

currency_summary = {}

for chunk in pd.read_csv(
    RAW_DIR / "transactions.csv",
    usecols=["Store ID", "Currency", "Currency Symbol"],
    chunksize=100000
):
    for _, row in (
        chunk[["Store ID", "Currency", "Currency Symbol"]]
        .drop_duplicates()
        .iterrows()
    ):
        key = (
            row["Store ID"],
            row["Currency"],
            row["Currency Symbol"]
        )
        currency_summary[key] = True

currency_df = pd.DataFrame(
    currency_summary.keys(),
    columns=[
        "Store ID",
        "Currency",
        "Currency Symbol"
    ]
)

# Ghép Country từ stores
currency_df = currency_df.merge(
    stores[["Store ID", "Country"]],
    on="Store ID",
    how="left"
)

print(
    currency_df[
        [
            "Store ID",
            "Country",
            "Currency",
            "Currency Symbol"
        ]
    ]
    .sort_values("Store ID")
    .to_string(index=False)
)

print("\n[CURRENCY DISTINCT]")
print(
    currency_df[
        ["Currency", "Currency Symbol"]
    ]
    .drop_duplicates()
    .to_string(index=False)
)