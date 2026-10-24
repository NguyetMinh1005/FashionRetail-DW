import pandas as pd
from pathlib import Path
import gc


# ============================================================
# 2.2.3. KIỂM TRA DỮ LIỆU TRÙNG LẶP
#
# Kiểm tra:
# 1. Trùng theo khóa nghiệp vụ
# 2. Trùng hoàn toàn trên toàn bộ các cột
#
# Chỉ khảo sát - KHÔNG xóa dữ liệu ở bước 2.2
# ============================================================


# ------------------------------------------------------------
# 1. XÁC ĐỊNH THƯ MỤC
# ------------------------------------------------------------

THU_MUC_GOC = Path(__file__).resolve().parents[2]
THU_MUC_RAW = THU_MUC_GOC / "data" / "raw"
THU_MUC_KET_QUA = THU_MUC_GOC / "data" / "ket_qua_khao_sat"
THU_MUC_KET_QUA.mkdir(parents=True, exist_ok=True)


# ------------------------------------------------------------
# 2. KHAI BÁO KHÓA NGHIỆP VỤ CỦA TỪNG FILE
# ------------------------------------------------------------

KHOA_NGHIEP_VU = {
    "transactions.csv": ["Invoice ID", "Line"],
    "customers.csv": ["Customer ID"],
    "products.csv": ["Product ID"],
    "stores.csv": ["Store ID"],
    "employees.csv": ["Employee ID"],

    # discounts không có ID riêng nên dùng tổ hợp thuộc tính
    "discounts.csv": [
        "Start",
        "End",
        "Discont",
        "Category",
        "Sub Category"
    ]
}


print("=" * 80)
print("2.2.3 - KIỂM TRA DỮ LIỆU TRÙNG LẶP")
print("=" * 80)

ket_qua = []


# ============================================================
# HÀM TÍNH THỐNG KÊ TRÙNG TỪ HASH
# ============================================================

def thong_ke_trung(ds_hash):
    """
    Nhận vào Series chứa hash của từng bản ghi.
    Trả về:
    - số nhóm trùng
    - số dòng nằm trong các nhóm trùng
    - số dòng dư nếu mỗi nhóm chỉ giữ 1 dòng
    """

    tan_suat = ds_hash.value_counts()
    nhom_trung = tan_suat[tan_suat > 1]

    so_nhom_trung = len(nhom_trung)
    so_dong_trong_nhom_trung = int(nhom_trung.sum())
    so_dong_du = int((nhom_trung - 1).sum())

    return (
        so_nhom_trung,
        so_dong_trong_nhom_trung,
        so_dong_du
    )


# ============================================================
# 3. KIỂM TRA TỪNG FILE
# ============================================================

for ten_file, khoa in KHOA_NGHIEP_VU.items():

    duong_dan = THU_MUC_RAW / ten_file

    print("\n" + "-" * 80)
    print(f"Đang kiểm tra: {ten_file}")
    print(f"Khóa nghiệp vụ: {', '.join(khoa)}")

    if not duong_dan.exists():
        print(f"KHÔNG TÌM THẤY FILE: {duong_dan}")
        continue

    # Hash giúp không phải giữ toàn bộ dữ liệu trong RAM
    hash_khoa = []
    hash_toan_dong = []
    tong_so_dong = 0

    # --------------------------------------------------------
    # Đọc CSV theo từng phần để giảm áp lực RAM
    # --------------------------------------------------------

    for chunk in pd.read_csv(
        duong_dan,
        chunksize=100000,
        dtype=str,
        low_memory=False,
        keep_default_na=False
    ):

        tong_so_dong += len(chunk)

        # Kiểm tra cột khóa có tồn tại không
        cot_thieu = [
            cot
            for cot in khoa
            if cot not in chunk.columns
        ]

        if cot_thieu:
            raise ValueError(
                f"{ten_file} thiếu cột khóa: {cot_thieu}\n"
                f"Các cột hiện có: {list(chunk.columns)}"
            )

        # HASH THEO KHÓA NGHIỆP VỤ
        h_khoa = pd.util.hash_pandas_object(
            chunk[khoa],
            index=False
        )
        hash_khoa.append(h_khoa.reset_index(drop=True))

        # HASH TOÀN BỘ DÒNG
        h_dong = pd.util.hash_pandas_object(
            chunk,
            index=False
        )
        hash_toan_dong.append(h_dong.reset_index(drop=True))

    print(f"Tổng số dòng: {tong_so_dong:,}")

    # ========================================================
    # 4. TRÙNG THEO KHÓA NGHIỆP VỤ
    # ========================================================

    hash_khoa = pd.concat(hash_khoa, ignore_index=True)

    (
        so_nhom_trung_khoa,
        so_dong_nhom_khoa,
        so_dong_du_khoa
    ) = thong_ke_trung(hash_khoa)

    print("\n[TRÙNG KHÓA NGHIỆP VỤ]")
    print(f"  Số nhóm trùng: {so_nhom_trung_khoa:,}")
    print(f"  Số dòng nằm trong nhóm trùng: {so_dong_nhom_khoa:,}")
    print(f"  Số dòng dư nếu mỗi khóa chỉ giữ 1 dòng: {so_dong_du_khoa:,}")

    del hash_khoa
    gc.collect()

    # ========================================================
    # 5. TRÙNG HOÀN TOÀN
    # ========================================================

    hash_toan_dong = pd.concat(hash_toan_dong, ignore_index=True)

    (
        so_nhom_trung_toan_dong,
        so_dong_nhom_toan_dong,
        so_dong_du_toan_dong
    ) = thong_ke_trung(hash_toan_dong)

    print("\n[TRÙNG HOÀN TOÀN]")
    print(f"  Số nhóm trùng hoàn toàn: {so_nhom_trung_toan_dong:,}")
    print(f"  Số dòng nằm trong nhóm trùng hoàn toàn: {so_dong_nhom_toan_dong:,}")
    print(f"  Số dòng trùng hoàn toàn dư: {so_dong_du_toan_dong:,}")

    # ========================================================
    # 6. LƯU KẾT QUẢ TỔNG HỢP
    # ========================================================

    ket_qua.append({
        "Tep_du_lieu": ten_file,
        "Khoa_nghiep_vu": " + ".join(khoa),
        "Tong_so_dong": tong_so_dong,
        "So_nhom_trung_khoa": so_nhom_trung_khoa,
        "So_dong_trong_nhom_trung_khoa": so_dong_nhom_khoa,
        "So_dong_du_theo_khoa": so_dong_du_khoa,
        "So_nhom_trung_hoan_toan": so_nhom_trung_toan_dong,
        "So_dong_trong_nhom_trung_hoan_toan": so_dong_nhom_toan_dong,
        "So_dong_trung_hoan_toan_du": so_dong_du_toan_dong
    })

    del hash_toan_dong
    gc.collect()


# ============================================================
# 7. TẠO BẢNG KẾT QUẢ ĐẦY ĐỦ
# ============================================================

bang_ket_qua = pd.DataFrame(ket_qua)


# ============================================================
# 8. HIỂN THỊ BẢNG NGẮN GỌN, DỄ ĐỌC
# ============================================================

print("\n")
print("=" * 90)
print("KẾT QUẢ KIỂM TRA DỮ LIỆU TRÙNG LẶP")
print("=" * 90)

bang_hien_thi = bang_ket_qua[
    [
        "Tep_du_lieu",
        "Tong_so_dong",
        "So_nhom_trung_khoa",
        "So_dong_du_theo_khoa",
        "So_nhom_trung_hoan_toan",
        "So_dong_trung_hoan_toan_du"
    ]
].copy()

bang_hien_thi.columns = [
    "Tep",
    "Tong_dong",
    "Nhom_trung_khoa",
    "Dong_du_khoa",
    "Nhom_trung_100%",
    "Dong_trung_100%_du"
]

print(bang_hien_thi.to_string(index=False))


# ============================================================
# 9. HIỂN THỊ RIÊNG CHI TIẾT TRANSACTIONS
# ============================================================

gd = bang_ket_qua[
    bang_ket_qua["Tep_du_lieu"] == "transactions.csv"
]

if not gd.empty:

    gd = gd.iloc[0]

    print("\n" + "=" * 70)
    print("CHI TIẾT TRÙNG LẶP - transactions.csv")
    print("=" * 70)

    print(f"Tổng số dòng                 : {gd['Tong_so_dong']:,}")

    print("\n[1] Trùng theo khóa Invoice ID + Line")
    print(f"Số nhóm trùng                : {gd['So_nhom_trung_khoa']:,}")
    print(f"Số dòng trong nhóm trùng     : {gd['So_dong_trong_nhom_trung_khoa']:,}")
    print(f"Số dòng dư theo khóa         : {gd['So_dong_du_theo_khoa']:,}")

    print("\n[2] Trùng hoàn toàn 100%")
    print(f"Số nhóm trùng hoàn toàn      : {gd['So_nhom_trung_hoan_toan']:,}")
    print(f"Số dòng trong nhóm trùng     : {gd['So_dong_trong_nhom_trung_hoan_toan']:,}")
    print(f"Số dòng trùng hoàn toàn dư   : {gd['So_dong_trung_hoan_toan_du']:,}")


# ============================================================
# 10. LƯU KẾT QUẢ ĐẦY ĐỦ RA CSV
# ============================================================

file_ket_qua = THU_MUC_KET_QUA / "03_Ket_qua_trung_lap.csv"

bang_ket_qua.to_csv(
    file_ket_qua,
    index=False,
    encoding="utf-8-sig"
)

print("\n" + "=" * 70)
print("Đã lưu kết quả tại:")
print(file_ket_qua)

print("\nHOÀN TẤT 2.2.3")
