import csv
import sys
from pathlib import Path

BASE_DIR = Path(r"E:\FashionRetail-DW")
input_file = BASE_DIR / "data" / "cleaned" / "cleaned_transactions.csv"

duplicate_columns = [
    "Invoice ID", "Line", "Date", "Transaction_Time",
    "Product ID", "Size", "Color",
    "Store ID", "Employee ID", "Customer ID",
    "Transaction Type", "Payment Method", "Currency",
    "Quantity", "Unit Price", "Discount",
    "Line Total", "Net_Amount", "Net_Amount_Local",
    "Exchange_Rate_To_USD", "Exchange_Rate_Date", "Exchange_Rate_Source",
    "Net_Amount_USD"
]

print("Scanning for duplicates with streaming csv reader...")
with open(input_file, mode="r", encoding="utf-8-sig") as f:
    reader = csv.reader(f)
    headers = next(reader)
    col_indices = [headers.index(col) for col in duplicate_columns]
    
    seen = set()
    dup_row_indices = set()
    row_count = 0
    
    for row in reader:
        row_count += 1
        key = hash(tuple(row[i] for i in col_indices))
        if key in seen:
            dup_row_indices.add(row_count)
        else:
            seen.add(key)
        if row_count % 1000000 == 0:
            print(f"Processed {row_count:,} rows, found {len(dup_row_indices)} duplicates...")

print(f"\nTotal rows processed: {row_count:,}")
print(f"Total duplicates found: {len(dup_row_indices)}")
