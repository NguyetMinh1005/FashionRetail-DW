
import csv
from pathlib import Path
import pyodbc

# Kết nối với SQL Server
conn = pyodbc.connect(
    "DRIVER={ODBC Driver 18 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=Fashion_DW;"
    "Trusted_Connection=yes;"
    "Encrypt=yes;"
    "TrustServerCertificate=yes;"
)

# Lấy dữ liệu RFM đã tạo
query = """
SELECT
    Customer_Key,
    Recency,
    Frequency,
    Monetary
FROM dbo.Customer_RFM
ORDER BY Customer_Key
"""

# Đường dẫn xuất dữ liệu
output = Path(__file__).parent / "customer_rfm.csv"

cursor = conn.cursor()
cursor.execute(query)

# Tên các cột trong CSV
columns = [col[0] for col in cursor.description]

total = 0

# Xuất dữ liệu theo từng đợt
with open(output, "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(columns)

    while True:
        rows = cursor.fetchmany(100000)

        if not rows:
            break

        writer.writerows(rows)
        total += len(rows)

        print(f"Da xuat {total:,} dong")

cursor.close()
conn.close()

print("\nHOAN THANH XUAT DU LIEU")
print("File:", output)
print("Tong so khach hang:", total)
