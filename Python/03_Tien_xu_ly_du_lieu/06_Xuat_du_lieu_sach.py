import pandas as pd
from pathlib import Path
import shutil


# ============================================================
# 2.3.6. XUẤT DỮ LIỆU SẠCH SAU TIỀN XỬ LÝ
#
# Mục tiêu:
# - Không biến đổi thêm dữ liệu
# - Xuất 6 file cuối cùng từ processed -> cleaned
# - Kiểm tra số dòng
# - Tạo bảng đối soát
#
# Đây sẽ là nguồn đầu vào cho SSIS.
# ============================================================


# ------------------------------------------------------------
# 1. THƯ MỤC
# ------------------------------------------------------------

THU_MUC_GOC = Path(__file__).resolve().parents[2]

THU_MUC_RAW = (
    THU_MUC_GOC
    / "data"
    / "raw"
)

THU_MUC_PROCESSED = (
    THU_MUC_GOC
    / "data"
    / "processed"
)

THU_MUC_CLEANED = (
    THU_MUC_GOC
    / "data"
    / "cleaned"
)

THU_MUC_REJECT = (
    THU_MUC_GOC
    / "data"
    / "reject"
)

THU_MUC_REVIEW = (
    THU_MUC_GOC
    / "data"
    / "review"
)

THU_MUC_KET_QUA = (
    THU_MUC_GOC
    / "data"
    / "ket_qua_tien_xu_ly"
)


THU_MUC_CLEANED.mkdir(
    parents=True,
    exist_ok=True
)

THU_MUC_KET_QUA.mkdir(
    parents=True,
    exist_ok=True
)


# ============================================================
# 2. DANH SÁCH FILE
# ============================================================

DANH_SACH_FILE = [
    "customers.csv",
    "products.csv",
    "stores.csv",
    "employees.csv",
    "discounts.csv",
    "transactions.csv"
]


print("=" * 90)
print("2.3.6 - XUẤT DỮ LIỆU SẠCH SAU TIỀN XỬ LÝ")
print("=" * 90)


# ============================================================
# 3. HÀM ĐẾM DÒNG CSV
# ============================================================

def dem_dong_csv(file_path):

    tong_dong = 0

    for chunk in pd.read_csv(
        file_path,
        chunksize=100000,
        dtype=str,
        low_memory=False
    ):

        tong_dong += len(chunk)

    return tong_dong


# ============================================================
# 4. XUẤT TỪ PROCESSED SANG CLEANED
# ============================================================

ket_qua = []


for ten_file in DANH_SACH_FILE:

    file_raw = (
        THU_MUC_RAW
        / ten_file
    )

    file_processed = (
        THU_MUC_PROCESSED
        / ten_file
    )

    file_cleaned = (
        THU_MUC_CLEANED
        / f"cleaned_{ten_file}"
    )


    print("\n" + "-" * 90)
    print(f"Đang xử lý: {ten_file}")


    # --------------------------------------------------------
    # Kiểm tra file
    # --------------------------------------------------------

    if not file_raw.exists():

        raise FileNotFoundError(
            f"Không tìm thấy RAW: {file_raw}"
        )


    if not file_processed.exists():

        raise FileNotFoundError(
            f"Không tìm thấy PROCESSED: "
            f"{file_processed}"
        )


    # --------------------------------------------------------
    # Đếm dòng RAW
    # --------------------------------------------------------

    so_dong_raw = dem_dong_csv(
        file_raw
    )


    # --------------------------------------------------------
    # Đếm dòng PROCESSED
    # --------------------------------------------------------

    so_dong_processed = dem_dong_csv(
        file_processed
    )


    # --------------------------------------------------------
    # Copy thành CLEANED
    # --------------------------------------------------------

    shutil.copy2(
        file_processed,
        file_cleaned
    )


    # --------------------------------------------------------
    # Đếm lại CLEANED
    # --------------------------------------------------------

    so_dong_cleaned = dem_dong_csv(
        file_cleaned
    )


    # --------------------------------------------------------
    # Đối soát processed = cleaned
    # --------------------------------------------------------

    doi_soat = (
        so_dong_processed
        ==
        so_dong_cleaned
    )


    print(
        f"RAW       : "
        f"{so_dong_raw:,}"
    )

    print(
        f"Processed : "
        f"{so_dong_processed:,}"
    )

    print(
        f"Cleaned   : "
        f"{so_dong_cleaned:,}"
    )

    print(
        f"Đối soát  : "
        f"{'ĐẠT' if doi_soat else 'KHÔNG ĐẠT'}"
    )


    ket_qua.append({

        "Tep_du_lieu":
            ten_file,

        "So_dong_RAW":
            so_dong_raw,

        "So_dong_Processed":
            so_dong_processed,

        "So_dong_Cleaned":
            so_dong_cleaned,

        "So_dong_giam":
            (
                so_dong_raw
                - so_dong_cleaned
            ),

        "Ten_file_sach":
            f"cleaned_{ten_file}",

        "Doi_soat":
            (
                "DAT"
                if doi_soat
                else "KHONG_DAT"
            )
    })


# ============================================================
# 5. ĐỌC KẾT QUẢ ERROR / REVIEW
# ============================================================

# ------------------------------------------------------------
# Transactions Error
# ------------------------------------------------------------

file_error_transactions = (
    THU_MUC_REJECT
    / "transactions_error.csv"
)


if file_error_transactions.exists():

    so_error_transactions = (
        dem_dong_csv(
            file_error_transactions
        )
    )

else:

    so_error_transactions = 0


# ------------------------------------------------------------
# Discounts Error
# ------------------------------------------------------------

file_error_discounts = (
    THU_MUC_REJECT
    / "discounts_error.csv"
)


if file_error_discounts.exists():

    so_error_discounts = (
        dem_dong_csv(
            file_error_discounts
        )
    )

else:

    so_error_discounts = 0


# ------------------------------------------------------------
# Review R13
# ------------------------------------------------------------

file_review = (
    THU_MUC_REVIEW
    / "transactions_trung_khoa_can_kiem_tra.csv"
)


if file_review.exists():

    so_dong_review = (
        dem_dong_csv(
            file_review
        )
    )

else:

    so_dong_review = 0


# ============================================================
# 6. TẠO BẢNG KẾT QUẢ
# ============================================================

bang_ket_qua = pd.DataFrame(
    ket_qua
)


FILE_KET_QUA = (
    THU_MUC_KET_QUA
    / "06_Ket_qua_du_lieu_sach.csv"
)


bang_ket_qua.to_csv(
    FILE_KET_QUA,
    index=False,
    encoding="utf-8-sig"
)


# ============================================================
# 7. KIỂM TRA TOÀN BỘ
# ============================================================

tat_ca_dat = (
    bang_ket_qua["Doi_soat"]
    .eq("DAT")
    .all()
)


# ============================================================
# 8. HIỂN THỊ KẾT QUẢ
# ============================================================

print("\n")
print("=" * 90)
print("KẾT QUẢ 2.3.6")
print("=" * 90)


bang_hien_thi = (
    bang_ket_qua[
        [
            "Tep_du_lieu",
            "So_dong_RAW",
            "So_dong_Cleaned",
            "So_dong_giam",
            "Doi_soat"
        ]
    ]
)


print(
    bang_hien_thi.to_string(
        index=False
    )
)


print("\n" + "-" * 90)

print(
    f"Transactions Error : "
    f"{so_error_transactions:,}"
)

print(
    f"Discounts Error    : "
    f"{so_error_discounts:,}"
)

print(
    f"Transactions Review: "
    f"{so_dong_review:,}"
)


print("\n" + "-" * 90)

print(
    f"ĐỐI SOÁT TOÀN BỘ: "
    f"{'ĐẠT' if tat_ca_dat else 'KHÔNG ĐẠT'}"
)


print("\nĐã lưu dữ liệu sạch tại:")
print(THU_MUC_CLEANED)


print("\nĐã lưu bảng kết quả tại:")
print(FILE_KET_QUA)


print("\nHOÀN TẤT 2.3.6")