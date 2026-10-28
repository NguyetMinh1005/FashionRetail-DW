import os
import pandas as pd


# ============================================================
# 07 - XỬ LÝ TRÙNG TRANSACTIONS
# Dự án: Fashion Retail Data Warehouse
#
# Mục tiêu:
#   - Đọc cleaned_transactions.csv
#   - Phát hiện duplicate theo grain nghiệp vụ
#   - Chỉ chấp nhận duplicate thuộc Return
#   - Backup các dòng duplicate
#   - Giữ bản ghi đầu tiên
#   - Loại các bản ghi dư
#   - Ghi đè cleaned_transactions.csv
#
# Kết quả kỳ vọng:
#   Trước xử lý : 6,416,029
#   Loại        : 573
#   Sau xử lý   : 6,415,456
#   Duplicate   : 0
# ============================================================


# ============================================================
# 1. ĐƯỜNG DẪN FILE
# ============================================================

input_file = "data/cleaned/cleaned_transactions.csv"
output_file = "data/cleaned/cleaned_transactions.csv"
backup_file = "data/cleaned/transactions_duplicate_backup.csv"


# ============================================================
# 2. KIỂM TRA FILE TỒN TẠI
# ============================================================

if not os.path.exists(input_file):
    raise FileNotFoundError(
        f"Không tìm thấy file: {input_file}"
    )


# ============================================================
# 3. ĐỌC FILE CLEANED TRANSACTIONS
# ============================================================

print("=" * 60)
print("BẮT ĐẦU XỬ LÝ DUPLICATE TRANSACTIONS")
print("=" * 60)

df = pd.read_csv(
    input_file,
    low_memory=False
)

rows_before = len(df)

print(f"Số dòng trước xử lý duplicate: {rows_before:,}")


# ============================================================
# 4. CÁC CỘT XÁC ĐỊNH DUPLICATE NGHIỆP VỤ
#
# Dùng đúng tên cột thực tế trong CSV
# ============================================================

duplicate_columns = [
    "Invoice ID",
    "Line",
    "Date",
    "Transaction_Time",

    "Product ID",
    "Size",
    "Color",

    "Store ID",
    "Employee ID",
    "Customer ID",

    "Transaction Type",
    "Payment Method",
    "Currency",

    "Quantity",
    "Unit Price",
    "Discount",

    "Line Total",
    "Net_Amount",
    "Net_Amount_Local",

    "Exchange_Rate_To_USD",
    "Exchange_Rate_Date",
    "Exchange_Rate_Source",
    "Net_Amount_USD"
]


# ============================================================
# 5. KIỂM TRA CÁC CỘT CÓ TỒN TẠI KHÔNG
# ============================================================

missing_columns = [
    col
    for col in duplicate_columns
    if col not in df.columns
]

if missing_columns:

    print("\nCác cột bị thiếu:")
    for col in missing_columns:
        print("-", col)

    print("\nCác cột thực tế trong CSV:")
    for col in df.columns:
        print("-", col)

    raise ValueError(
        "Thiếu cột cần thiết để kiểm tra duplicate."
    )


print("\nKiểm tra tên cột: ĐẠT")


# ============================================================
# 6. XÁC ĐỊNH DUPLICATE DƯ
#
# keep='first':
#   - giữ dòng đầu tiên
#   - các dòng sau được đánh dấu duplicate
# ============================================================

duplicate_mask = df.duplicated(
    subset=duplicate_columns,
    keep="first"
)

duplicate_rows = df.loc[duplicate_mask].copy()

duplicate_count = len(duplicate_rows)

print("\n" + "=" * 60)
print("KẾT QUẢ PHÁT HIỆN DUPLICATE")
print("=" * 60)

print(f"Số dòng duplicate dư: {duplicate_count:,}")


# ============================================================
# 7. KIỂM TRA DUPLICATE THEO TRANSACTION TYPE
# ============================================================

print("\nDuplicate theo Transaction Type:")

duplicate_by_type = (
    duplicate_rows["Transaction Type"]
    .value_counts(dropna=False)
)

print(duplicate_by_type)


# ============================================================
# 8. CHỈ CHẤP NHẬN DUPLICATE RETURN
# ============================================================

non_return_duplicates = duplicate_rows[
    duplicate_rows["Transaction Type"]
    .astype(str)
    .str.strip()
    .str.lower()
    != "return"
]

if len(non_return_duplicates) > 0:

    print("\nCẢNH BÁO:")
    print(
        "Phát hiện duplicate không thuộc Transaction Type = Return."
    )

    print("\nMột số dòng mẫu:")

    sample_columns = [
        "Invoice ID",
        "Line",
        "Product ID",
        "Transaction Type"
    ]

    print(
        non_return_duplicates[
            sample_columns
        ].head(20)
    )

    raise ValueError(
        "Có duplicate không phải Return. "
        "Dừng xử lý để kiểm tra lại."
    )


print("\nKiểm tra loại duplicate: ĐẠT")
print("Tất cả duplicate đều thuộc Return.")


# ============================================================
# 9. KIỂM TRA SỐ DUPLICATE KỲ VỌNG
# ============================================================

expected_duplicate_rows = 573

if duplicate_count != expected_duplicate_rows:

    raise ValueError(
        f"Số duplicate phát hiện = {duplicate_count:,}, "
        f"không đúng kỳ vọng = {expected_duplicate_rows:,}."
    )


print(
    f"Kiểm tra số duplicate: ĐẠT "
    f"({duplicate_count:,} dòng)"
)


# ============================================================
# 10. BACKUP DUPLICATE TRƯỚC KHI XÓA
# ============================================================

os.makedirs(
    os.path.dirname(backup_file),
    exist_ok=True
)

duplicate_rows.to_csv(
    backup_file,
    index=False,
    encoding="utf-8-sig"
)

print("\nĐã backup các dòng duplicate vào:")
print(backup_file)


# ============================================================
# 11. LOẠI DUPLICATE
# ============================================================

df_clean = df.drop_duplicates(
    subset=duplicate_columns,
    keep="first"
).copy()


# ============================================================
# 12. ĐỐI SOÁT SỐ DÒNG
# ============================================================

rows_after = len(df_clean)
rows_removed = rows_before - rows_after

print("\n" + "=" * 60)
print("ĐỐI SOÁT SAU XỬ LÝ")
print("=" * 60)

print(f"Số dòng trước : {rows_before:,}")
print(f"Số dòng loại  : {rows_removed:,}")
print(f"Số dòng sau   : {rows_after:,}")


# ============================================================
# 13. KIỂM TRA DUPLICATE CÒN LẠI
# ============================================================

remaining_duplicates = (
    df_clean
    .duplicated(
        subset=duplicate_columns,
        keep=False
    )
    .sum()
)

print(
    f"Duplicate còn lại: "
    f"{remaining_duplicates:,}"
)


# ============================================================
# 14. KIỂM TRA KẾT QUẢ KỲ VỌNG
# ============================================================

expected_rows_after = 6415456
expected_removed = 573

if rows_removed != expected_removed:

    raise ValueError(
        f"Số dòng loại bỏ = {rows_removed:,}, "
        f"không đúng kỳ vọng = {expected_removed:,}."
    )


if rows_after != expected_rows_after:

    raise ValueError(
        f"Số dòng sau xử lý = {rows_after:,}, "
        f"không đúng kỳ vọng = {expected_rows_after:,}."
    )


if remaining_duplicates != 0:

    raise ValueError(
        f"Sau xử lý vẫn còn "
        f"{remaining_duplicates:,} dòng duplicate."
    )


print("\nTất cả kiểm tra sau xử lý: ĐẠT")


# ============================================================
# 15. XUẤT LẠI FILE CLEAN
# ============================================================

df_clean.to_csv(
    output_file,
    index=False,
    encoding="utf-8-sig"
)


# ============================================================
# 16. KIỂM TRA LẠI FILE SAU KHI GHI
# ============================================================

print("\nĐang kiểm tra lại file sau khi ghi...")

df_check = pd.read_csv(
    output_file,
    low_memory=False
)

final_rows = len(df_check)

if final_rows != expected_rows_after:

    raise ValueError(
        f"File sau khi ghi có {final_rows:,} dòng, "
        f"không đúng {expected_rows_after:,} dòng."
    )


# ============================================================
# 17. KIỂM TRA DUPLICATE LẦN CUỐI
# ============================================================

final_duplicate_count = (
    df_check
    .duplicated(
        subset=duplicate_columns,
        keep=False
    )
    .sum()
)

if final_duplicate_count != 0:

    raise ValueError(
        f"File sau khi ghi vẫn còn "
        f"{final_duplicate_count:,} duplicate."
    )


# ============================================================
# 18. KIỂM TRA BACKUP
# ============================================================

backup_check = pd.read_csv(
    backup_file,
    low_memory=False
)

backup_rows = len(backup_check)

if backup_rows != expected_removed:

    raise ValueError(
        f"File backup có {backup_rows:,} dòng, "
        f"không đúng {expected_removed:,} dòng."
    )


# ============================================================
# 19. THÔNG BÁO HOÀN TẤT
# ============================================================

print("\n" + "=" * 60)
print("HOÀN TẤT XỬ LÝ DUPLICATE")
print("=" * 60)

print(f"File clean  : {output_file}")
print(f"File backup : {backup_file}")

print("\nKẾT QUẢ CUỐI:")

print(f"Số dòng ban đầu : {rows_before:,}")
print(f"Số dòng đã loại : {rows_removed:,}")
print(f"Số dòng cuối    : {final_rows:,}")
print(f"Backup duplicate: {backup_rows:,}")
print(f"Duplicate còn lại: {final_duplicate_count:,}")

print("\nKẾT QUẢ: ĐẠT")

print("\nBƯỚC TIẾP THEO:")
print("1. Nạp lại cleaned_transactions.csv vào stg.transactions")
print("2. Kiểm tra STG phải có 6,415,456 dòng")
print("3. Chạy 26_Load_Fact_Sales.sql")
print("4. Chạy 27_Validation_DW.sql")