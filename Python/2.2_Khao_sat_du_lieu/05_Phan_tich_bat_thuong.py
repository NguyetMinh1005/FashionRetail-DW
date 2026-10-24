import pandas as pd
from pathlib import Path


# ============================================================
# 2.2.1. KH?O SÁT T?NG QUAN D? LI?U
# ============================================================

# T? ??ng xác ??nh th? m?c g?c c?a project
THU_MUC_GOC = Path(__file__).resolve().parents[2]

# Th? m?c ch?a d? li?u CSV g?c
THU_MUC_RAW = THU_MUC_GOC / "data" / "raw"

# Th? m?c l?u k?t qu? kh?o sát
THU_MUC_KET_QUA = THU_MUC_GOC / "data" / "ket_qua_khao_sat"

# N?u ch?a có th? m?c k?t qu? thì t? t?o
THU_MUC_KET_QUA.mkdir(parents=True, exist_ok=True)


# Danh sách 6 file d? li?u ngu?n
DANH_SACH_FILE = [
    "customers.csv",
    "products.csv",
    "stores.csv",
    "employees.csv",
    "discounts.csv",
    "transactions.csv"
]


print("=" * 70)
print("2.2.1 - KH?O SÁT T?NG QUAN D? LI?U")
print("=" * 70)


ket_qua = []


# ============================================================
# KI?M TRA T?NG FILE
# ============================================================

for ten_file in DANH_SACH_FILE:

    duong_dan = THU_MUC_RAW / ten_file

    print(f"\n?ang kh?o sát: {ten_file}")

    # Ki?m tra file có t?n t?i hay không
    if not duong_dan.exists():
        print(f"KHÔNG TÌM TH?Y FILE: {duong_dan}")
        continue

    tong_so_dong = 0
    so_cot = 0
    ten_cot = None

    # ??c theo t?ng ph?n 100.000 dòng
    # ?? không chi?m quá nhi?u RAM
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

    print(f"  S? dòng : {tong_so_dong:,}")
    print(f"  S? c?t  : {so_cot}")
    print(f"  Tên c?t : {ten_cot}")


# ============================================================
# T?O B?NG T?NG H?P
# ============================================================

bang_tong_hop = pd.DataFrame(ket_qua)

print("\n")
print("=" * 70)
print("K?T QU? KH?O SÁT T?NG QUAN")
print("=" * 70)

print(
    bang_tong_hop.to_string(
        index=False
    )
)


# ============================================================
# L?U K?T QU? RA CSV
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

print("\n?ã l?u k?t qu? t?i:")
print(file_ket_qua)

print("\nHOÀN T?T 2.2.1")