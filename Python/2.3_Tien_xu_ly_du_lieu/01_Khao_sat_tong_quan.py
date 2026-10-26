import pandas as pd
from pathlib import Path


# ============================================================
# 2.2.1. KHẢO SÁT TỔNG QUAN DỮ LIỆU
# ============================================================

# Tự động xác định thư mục gốc của project
THU_MUC_GOC = Path(__file__).resolve().parents[2]

# Thư mục chứa dữ liệu CSV gốc
THU_MUC_RAW = THU_MUC_GOC / "data" / "raw"

# Thư mục lưu kết quả khảo sát
THU_MUC_KET_QUA = THU_MUC_GOC / "data" / "ket_qua_khao_sat"

# Nếu chưa có thư mục kết quả thì tự tạo
THU_MUC_KET_QUA.mkdir(parents=True, exist_ok=True)


# Danh sách 6 file dữ liệu nguồn
DANH_SACH_FILE = [
    "customers.csv",
    "products.csv",
    "stores.csv",
    "employees.csv",
    "discounts.csv",
    "transactions.csv"
]


print("=" * 70)
print("2.2.1 - KHẢO SÁT TỔNG QUAN DỮ LIỆU")
print("=" * 70)


ket_qua = []


# ============================================================
# KIỂM TRA TỪNG FILE
# ============================================================

for ten_file in DANH_SACH_FILE:

    duong_dan = THU_MUC_RAW / ten_file

    print(f"\nĐang khảo sát: {ten_file}")

    # Kiểm tra file có tồn tại hay không
    if not duong_dan.exists():
        print(f"KHÔNG TÌM THẤY FILE: {duong_dan}")
        continue

    tong_so_dong = 0
    so_cot = 0
    ten_cot = None

    # Đọc theo từng phần 100.000 dòng
    # để không chiếm quá nhiều RAM
    for chunk in pd.read_csv(
        duong_dan,
        chunksize=100000,
        low_memory=False
    ):
        tong_so_dong += len(chunk)

        if ten_cot is None:
            ten_cot = list(chunk.columns)
            so_cot = len(chunk.columns)

    ket_qua.append({
        "Tep_du_lieu": ten_file,
        "So_dong": tong_so_dong,
        "So_cot": so_cot
    })

    print(f"  Số dòng : {tong_so_dong:,}")
    print(f"  Số cột  : {so_cot}")
    print(f"  Tên cột : {ten_cot}")


# ============================================================
# TẠO BẢNG TỔNG HỢP
# ============================================================

bang_tong_hop = pd.DataFrame(ket_qua)

print("\n")
print("=" * 70)
print("KẾT QUẢ KHẢO SÁT TỔNG QUAN")
print("=" * 70)

print(
    bang_tong_hop.to_string(
        index=False
    )
)


# ============================================================
# LƯU KẾT QUẢ RA CSV
# ============================================================

file_ket_qua = (
    THU_MUC_KET_QUA
    / "01_Ket_qua_khao_sat_tong_quan.csv"
)

bang_tong_hop.to_csv(
    file_ket_qua,
    index=False,
    encoding="utf-8-sig"
)

print("\nĐã lưu kết quả tại:")
print(file_ket_qua)

print("\nHOÀN TẤT 2.2.1")