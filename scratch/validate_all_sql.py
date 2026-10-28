import os
import glob
import subprocess

sql_dir = "e:/FashionRetail-DW/SQL"

dw_pipeline = [
    "14C_Nap_transactions_CSV_FAST.sql",
    "15_Create_Fashion_DW.sql",
    "16_Create_Dimensions.sql",
    "17_Create_Fact_Sales.sql",
    "18_Load_Dim_Customer.sql",
    "19_Load_Dim_Product.sql",
    "20_Load_Dim_Store.sql",
    "21_Load_Dim_Employee.sql",
    "22_Load_Dim_Date.sql",
    "23_Load_Dim_Promotion.sql",
    "24_Load_Dim_Payment.sql",
    "25_Load_Dim_Currency.sql",
    "26_Load_Fact_Sales.sql",
    "27_Validation_DW.sql"
]

print("BAT DAU KIEM TRA TOAN BO PIPELINE SQL")
print("=" * 60)

for filename in dw_pipeline:
    filepath = os.path.join(sql_dir, filename)
    if not os.path.exists(filepath):
        print(f"[THIEU FILE] {filename}")
        continue
    
    # Tao file tam chua SET PARSEONLY ON o dau
    temp_file = "e:/FashionRetail-DW/scratch/temp_parse.sql"
    with open(filepath, "r", encoding="utf-8-sig", errors="ignore") as f_in, open(temp_file, "w", encoding="utf-8") as f_out:
        f_out.write("SET PARSEONLY ON;\nGO\n")
        f_out.write(f_in.read())
    
    cmd = f'sqlcmd -S localhost -E -C -i "{temp_file}"'
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    out = res.stdout + res.stderr
    if "Msg " in out:
        print(f"[LOI CU PHAP] {filename}:")
        for line in out.splitlines():
            if "Msg " in line or "Level " in line:
                print("   ->", line)
    else:
        print(f"[HOP LE 100%]  {filename}")

if os.path.exists("e:/FashionRetail-DW/scratch/temp_parse.sql"):
    os.remove("e:/FashionRetail-DW/scratch/temp_parse.sql")

print("=" * 60)
print("DA HOAN TAT RÀ SOÁT!")
