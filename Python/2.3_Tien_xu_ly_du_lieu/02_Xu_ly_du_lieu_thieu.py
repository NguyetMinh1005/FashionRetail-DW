import pandas as pd
from pathlib import Path
import os


# ============================================================
# 2.3.2. XỬ LÝ DỮ LIỆU THIẾU
#
# Dữ liệu đầu vào:
#   data/processed/
#
# Dữ liệu RAW không bị thay đổi.
#
# Quy tắc:
# - NULL / NaN
# - chuỗi rỗng ""
# - chuỗi chỉ chứa khoảng trắng
#
# được thay bằng "Unknown"
# tại các thuộc tính đã xác định từ 2.2.2.
# ============================================================


# ------------------------------------------------------------
# 1. THƯ MỤC
# ------------------------------------------------------------

THU_MUC_GOC = Path(__file__).resolve().parents[2]

THU_MUC_PROCESSED = (
    THU_MUC_GOC
    / "data"
    / "processed"
)

THU_MUC_KET_QUA = (
    THU_MUC_GOC
    / "data"
    / "ket_qua_tien_xu_ly"
)

THU_MUC_KET_QUA.mkdir(
    parents=True,
    exist_ok=True
)


# ============================================================
# 2. KHAI BÁO CÁC THUỘC TÍNH CẦN XỬ LÝ
# ============================================================

COT_CAN_XU_LY = {

    "customers.csv": [
        "Job Title"
    ],

    "products.csv": [
        "Color",
        "Sizes"
    ],

    "discounts.csv": [
        "Category",
        "Sub Category"
    ],

    "transactions.csv": [
        "Size",
        "Color"
    ]
}


GIA_TRI_THAY_THE = "Unknown"


print("=" * 80)
print("2.3.2 - XỬ LÝ DỮ LIỆU THIẾU")
print("=" * 80)


ket_qua = []


# ============================================================
# 3. XỬ LÝ TỪNG FILE
# ============================================================

for ten_file, danh_sach_cot in COT_CAN_XU_LY.items():

    file_goc = (
        THU_MUC_PROCESSED
        / ten_file
    )

    file_tam = (
        THU_MUC_PROCESSED
        / f"__temp_{ten_file}"
    )


    print("\n" + "-" * 80)
    print(f"Đang xử lý: {ten_file}")


    if not file_goc.exists():

        print(
            f"KHÔNG TÌM THẤY FILE: "
            f"{file_goc}"
        )

        continue


    # Xóa file tạm cũ nếu còn
    if file_tam.exists():
        file_tam.unlink()


    tong_dong = 0

    thong_ke_file = {
        cot: 0
        for cot in danh_sach_cot
    }


    ghi_header = True


    # ========================================================
    # ĐỌC THEO CHUNK
    # ========================================================

    for chunk in pd.read_csv(
        file_goc,
        chunksize=100000,
        dtype=str,
        low_memory=False,
        keep_default_na=True
    ):

        tong_dong += len(chunk)


        # ----------------------------------------------------
        # Kiểm tra tên cột
        # ----------------------------------------------------

        cot_khong_ton_tai = [
            cot
            for cot in danh_sach_cot
            if cot not in chunk.columns
        ]

        if cot_khong_ton_tai:

            raise ValueError(
                f"{ten_file} không có các cột: "
                f"{cot_khong_ton_tai}\n"
                f"Các cột hiện tại: "
                f"{list(chunk.columns)}"
            )


        # ====================================================
        # XỬ LÝ TỪNG CỘT
        # ====================================================

        for cot in danh_sach_cot:

            # Chuỗi chỉ chứa khoảng trắng -> NA
            chunk[cot] = (
                chunk[cot]
                .replace(
                    r"^\s*$",
                    pd.NA,
                    regex=True
                )
            )


            # Đếm missing trước khi xử lý
            so_thieu = int(
                chunk[cot]
                .isna()
                .sum()
            )


            thong_ke_file[cot] += (
                so_thieu
            )


            # Thay missing bằng Unknown
            chunk[cot] = (
                chunk[cot]
                .fillna(
                    GIA_TRI_THAY_THE
                )
            )


        # ====================================================
        # GHI FILE TẠM
        # ====================================================

        if ghi_header:

            chunk.to_csv(
                file_tam,
                mode="w",
                index=False,
                header=True,
                encoding="utf-8-sig"
            )

            ghi_header = False

        else:

            chunk.to_csv(
                file_tam,
                mode="a",
                index=False,
                header=False,
                encoding="utf-8"
            )


    # ========================================================
    # THAY FILE CŨ BẰNG FILE ĐÃ XỬ LÝ
    # ========================================================

    os.replace(
        file_tam,
        file_goc
    )


    # ========================================================
    # HIỂN THỊ + GHI THỐNG KÊ
    # ========================================================

    print(
        f"Tổng số dòng: "
        f"{tong_dong:,}"
    )


    for cot in danh_sach_cot:

        so_dong_thieu = (
            thong_ke_file[cot]
        )

        ty_le = (
            so_dong_thieu
            / tong_dong
            * 100
            if tong_dong > 0
            else 0
        )


        print(
            f"  {cot:<20}: "
            f"{so_dong_thieu:,} "
            f"-> '{GIA_TRI_THAY_THE}'"
        )


        ket_qua.append({

            "Tep_du_lieu":
                ten_file,

            "Thuoc_tinh":
                cot,

            "So_dong_truoc_xu_ly":
                tong_dong,

            "So_dong_thieu":
                so_dong_thieu,

            "Ty_le_thieu_%":
                round(
                    ty_le,
                    2
                ),

            "Gia_tri_thay_the":
                GIA_TRI_THAY_THE,

            "So_dong_sau_xu_ly":
                tong_dong
        })


# ============================================================
# 4. KIỂM TRA LẠI SAU XỬ LÝ
# ============================================================

print("\n")
print("=" * 80)
print("KIỂM TRA LẠI SAU XỬ LÝ")
print("=" * 80)


tong_missing_con_lai = 0


for ten_file, danh_sach_cot in COT_CAN_XU_LY.items():

    file_goc = (
        THU_MUC_PROCESSED
        / ten_file
    )


    missing_file = 0


    for chunk in pd.read_csv(
        file_goc,
        chunksize=100000,
        dtype=str,
        low_memory=False,
        keep_default_na=True
    ):

        for cot in danh_sach_cot:

            chunk[cot] = (
                chunk[cot]
                .replace(
                    r"^\s*$",
                    pd.NA,
                    regex=True
                )
            )

            missing_file += int(
                chunk[cot]
                .isna()
                .sum()
            )


    tong_missing_con_lai += (
        missing_file
    )


    print(
        f"{ten_file:<20}: "
        f"{missing_file:,} missing còn lại"
    )


# ============================================================
# 5. LƯU BẢNG KẾT QUẢ
# ============================================================

bang_ket_qua = pd.DataFrame(
    ket_qua
)


FILE_KET_QUA = (
    THU_MUC_KET_QUA
    / "02_Ket_qua_xu_ly_du_lieu_thieu.csv"
)


bang_ket_qua.to_csv(
    FILE_KET_QUA,
    index=False,
    encoding="utf-8-sig"
)


# ============================================================
# 6. KẾT LUẬN
# ============================================================

print("\n")
print("=" * 80)
print("KẾT QUẢ 2.3.2")
print("=" * 80)


if tong_missing_con_lai == 0:

    print(
        "Các thuộc tính đã chọn "
        "không còn dữ liệu thiếu."
    )

    print(
        "Đối soát: ĐẠT"
    )

else:

    print(
        f"Còn {tong_missing_con_lai:,} "
        f"giá trị thiếu."
    )

    print(
        "Đối soát: KHÔNG ĐẠT"
    )


print("\nĐã lưu kết quả tại:")
print(FILE_KET_QUA)

print("\nHOÀN TẤT 2.3.2")