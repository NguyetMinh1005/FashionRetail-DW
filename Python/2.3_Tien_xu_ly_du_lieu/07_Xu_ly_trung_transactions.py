# -*- coding: utf-8 -*-
import os
import csv
import sys
from pathlib import Path

# ============================================================
# 07 - XỬ LÝ TRÙNG TRANSACTIONS (STREAMING / MEMORY OPTIMIZED)
# Dự án: Fashion Retail Data Warehouse
#
# Mục tiêu:
#   - Đọc cleaned_transactions.csv
#   - Phát hiện duplicate theo grain nghiệp vụ bằng streaming
#   - Chỉ chấp nhận duplicate thuộc Return
#   - Backup các dòng duplicate
#   - Giữ bản ghi đầu tiên, loại các bản ghi dư
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

BASE_DIR = Path(__file__).resolve().parents[2]
input_file = BASE_DIR / "data" / "cleaned" / "cleaned_transactions.csv"
output_file = BASE_DIR / "data" / "cleaned" / "cleaned_transactions.csv"
backup_file = BASE_DIR / "data" / "cleaned" / "transactions_duplicate_backup.csv"
temp_output_file = BASE_DIR / "data" / "cleaned" / "__temp_cleaned_transactions.csv"

# ============================================================
# 2. KIỂM TRA FILE TỒN TẠI
# ============================================================

if not input_file.exists():
    raise FileNotFoundError(f"Không tìm thấy file: {input_file}")

print("=" * 60)
print("BẮT ĐẦU XỬ LÝ DUPLICATE TRANSACTIONS")
print("=" * 60)

# ============================================================
# 4. CÁC CỘT XÁC ĐỊNH DUPLICATE NGHIỆP VỤ
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
# PASS 1: PHÁT HIỆN DUPLICATE BẰNG STREAMING
# ============================================================

print("Đang quét tìm các dòng duplicate nghiệp vụ...")

seen_hashes = set()
duplicate_row_indices = set()
duplicate_rows_data = []
rows_before = 0

with open(input_file, mode="r", encoding="utf-8-sig", newline="") as f_in:
    reader = csv.reader(f_in)
    header = next(reader)
    
    missing_columns = [col for col in duplicate_columns if col not in header]
    if missing_columns:
        raise ValueError(f"Thiếu các cột cần thiết: {missing_columns}")
    
    col_indices = [header.index(col) for col in duplicate_columns]
    trans_type_idx = header.index("Transaction Type")
    
    for row in reader:
        rows_before += 1
        key = hash(tuple(row[i] for i in col_indices))
        if key in seen_hashes:
            duplicate_row_indices.add(rows_before)
            duplicate_rows_data.append(row)
        else:
            seen_hashes.add(key)

print(f"Số dòng trước xử lý duplicate: {rows_before:,}")
duplicate_count = len(duplicate_row_indices)

print("\n" + "=" * 60)
print("KẾT QUẢ PHÁT HIỆN DUPLICATE")
print("=" * 60)
print(f"Số dòng duplicate dư: {duplicate_count:,}")

# ============================================================
# KIỂM TRA TRẠNG THÁI FILE ĐÃ XỬ LÝ CHƯA
# ============================================================

expected_rows_before = 6416029
expected_rows_after = 6415456
expected_duplicate_rows = 573

if rows_before == expected_rows_after and duplicate_count == 0:
    print("\n" + "=" * 60)
    print("THÔNG BÁO: DỮ LIỆU ĐÃ ĐƯỢC XỬ LÝ TRÙNG LẶP HOÀN TẤT TRƯỚC ĐÓ!")
    print("=" * 60)
    print(f"Tổng số dòng hiện tại : {rows_before:,} dòng (Đúng chuẩn 6,415,456 dòng sạch).")
    print(f"Số duplicate còn lại  : 0 dòng.")
    if backup_file.exists():
        print(f"File backup duplicate : {backup_file}")
    print("\nKẾT QUẢ: ĐẠT - Dữ liệu đã sạch hoàn toàn, không cần chạy lại!")
    print("\nBƯỚC TIẾP THEO:")
    print("1. Nạp lại cleaned_transactions.csv vào stg.transactions (dùng 14C_Nap_transactions_CSV_FAST.sql)")
    print("2. Chạy nạp Data Warehouse (các file SQL từ 15 đến 26)")
    print("3. Chạy 27_Validation_DW.sql để kiểm tra kết quả cuối")
    sys.exit(0)

# ============================================================
# 7. KIỂM TRA DUPLICATE THEO TRANSACTION TYPE
# ============================================================

print("\nDuplicate theo Transaction Type:")
type_counts = {}
for row in duplicate_rows_data:
    t_type = row[trans_type_idx].strip()
    type_counts[t_type] = type_counts.get(t_type, 0) + 1

for t_type, count in type_counts.items():
    print(f"- {t_type}: {count:,}")

non_return = [row for row in duplicate_rows_data if row[trans_type_idx].strip().lower() != "return"]
if non_return:
    raise ValueError(f"Có {len(non_return)} duplicate không phải Return. Dừng xử lý.")

print("\nKiểm tra loại duplicate: ĐẠT")
print("Tất cả duplicate đều thuộc Return.")

# ============================================================
# 9. KIỂM TRA SỐ DUPLICATE KỲ VỌNG
# ============================================================

if duplicate_count != expected_duplicate_rows:
    raise ValueError(f"Số duplicate phát hiện = {duplicate_count:,}, không đúng kỳ vọng = {expected_duplicate_rows:,}.")

print(f"Kiểm tra số duplicate: ĐẠT ({duplicate_count:,} dòng)")

# ============================================================
# 10. BACKUP DUPLICATE TRƯỚC KHI XÓA
# ============================================================

backup_file.parent.mkdir(parents=True, exist_ok=True)
with open(backup_file, mode="w", encoding="utf-8-sig", newline="") as f_bak:
    writer = csv.writer(f_bak)
    writer.writerow(header)
    writer.writerows(duplicate_rows_data)

print("\nĐã backup các dòng duplicate vào:")
print(backup_file)

# ============================================================
# PASS 2: XUẤT LẠI FILE CLEAN (LOẠI BỎ 573 DÒNG DUPLICATE)
# ============================================================

print("\nĐang ghi file clean sau khi loại bỏ duplicate...")
rows_after = 0

with open(input_file, mode="r", encoding="utf-8-sig", newline="") as f_in, \
     open(temp_output_file, mode="w", encoding="utf-8-sig", newline="") as f_out:
    
    reader = csv.reader(f_in)
    writer = csv.writer(f_out)
    
    # write header
    writer.writerow(next(reader))
    
    current_row = 0
    for row in reader:
        current_row += 1
        if current_row not in duplicate_row_indices:
            writer.writerow(row)
            rows_after += 1

# Thay thế file gốc an toàn
if temp_output_file.exists():
    if output_file.exists():
        output_file.unlink()
    temp_output_file.rename(output_file)

rows_removed = rows_before - rows_after

print("\n" + "=" * 60)
print("ĐỐI SOÁT SAU XỬ LÝ")
print("=" * 60)
print(f"Số dòng trước : {rows_before:,}")
print(f"Số dòng loại  : {rows_removed:,}")
print(f"Số dòng sau   : {rows_after:,}")

expected_rows_after = 6415456
expected_removed = 573

if rows_removed != expected_removed:
    raise ValueError(f"Số dòng loại bỏ = {rows_removed:,}, không đúng kỳ vọng = {expected_removed:,}.")

if rows_after != expected_rows_after:
    raise ValueError(f"Số dòng sau xử lý = {rows_after:,}, không đúng kỳ vọng = {expected_rows_after:,}.")

# ============================================================
# 16. KIỂM TRA LẠI FILE SAU KHI GHI
# ============================================================

print("\nĐang kiểm tra lại file sau khi ghi...")
final_rows = 0
final_seen = set()
final_dup_count = 0

with open(output_file, mode="r", encoding="utf-8-sig", newline="") as f_chk:
    reader = csv.reader(f_chk)
    chk_header = next(reader)
    chk_col_indices = [chk_header.index(col) for col in duplicate_columns]
    
    for row in reader:
        final_rows += 1
        key = hash(tuple(row[i] for i in chk_col_indices))
        if key in final_seen:
            final_dup_count += 1
        else:
            final_seen.add(key)

if final_rows != expected_rows_after:
    raise ValueError(f"File sau khi ghi có {final_rows:,} dòng, không đúng {expected_rows_after:,} dòng.")

if final_dup_count != 0:
    raise ValueError(f"File sau khi ghi vẫn còn {final_dup_count:,} duplicate.")

backup_rows = len(duplicate_rows_data)

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
print(f"Duplicate còn lại: {final_dup_count:,}")
print("\nKẾT QUẢ: ĐẠT")
print("\nBƯỚC TIẾP THEO:")
print("1. Nạp lại cleaned_transactions.csv vào stg.transactions (dùng 14C_Nap_transactions_CSV_FAST.sql)")
print("2. Kiểm tra STG phải có 6,415,456 dòng")
print("3. Chạy 26_Load_Fact_Sales.sql")
print("4. Chạy 27_Validation_DW.sql")