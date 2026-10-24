import pandas as pd
from pathlib import Path


# ============================================================
# 2.2.2. KIỂM TRA DỮ LIỆU THIẾU
# Bao gồm:
# - NaN / NULL
# - Chuỗi rỗng ""
# - Chuỗi chỉ chứa khoảng trắng "   "
# ============================================================


# ------------------------------------------------------------
# 1. XÁC ĐỊNH THƯ MỤC
# ------------------------------------------------------------

THU_MUC_GOC = Path(__file__).resolve().parents[2]

THU_MUC_RAW = THU_MUC_GOC / "data" / "raw"

THU_MUC_KET_QUA = (
    THU_MUC_GOC
    / "data"
    / "ket_qua_khao_sat"
)

THU_MUC_KET_QUA.mkdir(
    parents=True,
    exist_ok=True
)


# ------------------------------------------------------------
# 2. DANH SÁCH 6 FILE NGUỒN
# ------------------------------------------------------------

DANH_SACH_FILE = [
    "customers.csv",
    "products.csv",
    "stores.csv",
    "employees.csv",
    "discounts.csv",
    "transactions.csv"
]


print("=" * 75)
print("2.2.2 - KIỂM TRA DỮ LIỆU THIẾU")
print("=" * 75)


ket_qua = []


# ------------------------------------------------------------
# 3. KIỂM TRA TỪNG FILE
# ------------------------------------------------------------

for ten_file in DANH_SACH_FILE:

    duong_dan = THU_MUC_RAW / ten_file

    print(f"\nĐang kiểm tra: {ten_file}")

    if not duong_dan.exists():
        print(f"KHÔNG TÌM THẤY FILE: {duong_dan}")
        continue


    tong_so_dong = 0

    tong_thieu = None


    # --------------------------------------------------------
    # Đọc từng phần 100.000 dòng để tránh đầy RAM
    # --------------------------------------------------------

    for chunk in pd.read_csv(
        duong_dan,
        chunksize=100000,
        low_memory=False
    ):

        tong_so_dong += len(chunk)


        # ----------------------------------------------------
        # Chuyển chuỗi rỗng hoặc chỉ có khoảng trắng thành NA
        # ----------------------------------------------------

        cot_van_ban = chunk.select_dtypes(
            include=["object", "string"]
        ).columns

        if len(cot_van_ban) > 0:

            chunk[cot_van_ban] = (
                chunk[cot_van_ban]
                .replace(
                    r"^\s*$",
                    pd.NA,
                    regex=True
                )
            )


        # ----------------------------------------------------
        # Đếm missing từng cột
        # ----------------------------------------------------

        thieu_chunk = chunk.isna().sum()


        if tong_thieu is None:
            tong_thieu = thieu_chunk
        else:
            tong_thieu = (
                tong_thieu
                .add(
                    thieu_chunk,
                    fill_value=0
                )
            )


    # --------------------------------------------------------
    # 4. TỔNG HỢP KẾT QUẢ CỦA FILE
    # --------------------------------------------------------

    print(f"  Tổng số dòng: {tong_so_dong:,}")


    for ten_cot, so_dong_thieu in tong_thieu.items():

        so_dong_thieu = int(so_dong_thieu)

        ty_le = (
            so_dong_thieu
            / tong_so_dong
            * 100
        )

        ket_qua.append({
            "Tep_du_lieu": ten_file,
            "Thuoc_tinh": ten_cot,
            "Tong_so_dong": tong_so_dong,
            "So_dong_thieu": so_dong_thieu,
            "Ty_le_thieu_%": round(ty_le, 2)
        })


        # Chỉ in ra màn hình nếu có missing
        if so_dong_thieu > 0:

            print(
                f"  {ten_cot}: "
                f"{so_dong_thieu:,} dòng thiếu "
                f"({ty_le:.2f}%)"
            )


# ------------------------------------------------------------
# 5. TẠO DATAFRAME KẾT QUẢ
# ------------------------------------------------------------

bang_ket_qua = pd.DataFrame(ket_qua)


# ------------------------------------------------------------
# Chỉ lấy các cột thực sự có dữ liệu thiếu
# ------------------------------------------------------------

bang_co_thieu = bang_ket_qua[
    bang_ket_qua["So_dong_thieu"] > 0
].copy()


print("\n")
print("=" * 75)
print("KẾT QUẢ CÁC THUỘC TÍNH CÓ DỮ LIỆU THIẾU")
print("=" * 75)


if len(bang_co_thieu) == 0:

    print("Không phát hiện dữ liệu thiếu.")

else:

    print(
        bang_co_thieu.to_string(
            index=False
        )
    )


# ------------------------------------------------------------
# 6. LƯU KẾT QUẢ
# ------------------------------------------------------------

file_ket_qua = (
    THU_MUC_KET_QUA
    / "02_Ket_qua_du_lieu_thieu.csv"
)


bang_co_thieu.to_csv(
    file_ket_qua,
    index=False,
    encoding="utf-8-sig"
)


print("\nĐã lưu kết quả tại:")
print(file_ket_qua)

print("\nHOÀN TẤT 2.2.2")