# -*- coding: utf-8 -*-

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
# - Kiểm tra cấu trúc transactions sau xử lý
# - Kiểm tra các cột Country / Currency / USD
# - Tạo bảng đối soát
#
# Đây sẽ là nguồn đầu vào cho SSIS.
# ============================================================


# ============================================================
# 1. THƯ MỤC
# ============================================================

THU_MUC_GOC = (
    Path(__file__)
    .resolve()
    .parents[2]
)


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


print("=" * 95)
print("2.3.6 - XUẤT DỮ LIỆU SẠCH SAU TIỀN XỬ LÝ")
print("=" * 95)


# ============================================================
# 3. HÀM ĐẾM DÒNG CSV
# ============================================================

def dem_dong_csv(
    file_path
):

    tong_dong = 0


    for chunk in pd.read_csv(

        file_path,

        chunksize=100000,

        dtype=str,

        low_memory=False
    ):

        tong_dong += len(
            chunk
        )


    return tong_dong


# ============================================================
# 4. HÀM ĐỌC TÊN CỘT
# ============================================================

def doc_danh_sach_cot(
    file_path
):

    df_header = pd.read_csv(
        file_path,
        nrows=0,
        encoding="utf-8-sig"
    )


    return list(
        df_header.columns
    )


# ============================================================
# 5. XUẤT TỪ PROCESSED SANG CLEANED
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


    print("\n" + "-" * 95)

    print(
        f"Đang xử lý: "
        f"{ten_file}"
    )


    # --------------------------------------------------------
    # A. KIỂM TRA FILE
    # --------------------------------------------------------

    if not file_raw.exists():

        raise FileNotFoundError(
            f"Không tìm thấy RAW: "
            f"{file_raw}"
        )


    if not file_processed.exists():

        raise FileNotFoundError(
            f"Không tìm thấy PROCESSED: "
            f"{file_processed}"
        )


    # --------------------------------------------------------
    # B. ĐẾM DÒNG RAW
    # --------------------------------------------------------

    so_dong_raw = (
        dem_dong_csv(
            file_raw
        )
    )


    # --------------------------------------------------------
    # C. ĐẾM DÒNG PROCESSED
    # --------------------------------------------------------

    so_dong_processed = (
        dem_dong_csv(
            file_processed
        )
    )


    # --------------------------------------------------------
    # D. COPY PROCESSED -> CLEANED
    #
    # Không đọc rồi ghi lại bằng pandas.
    # Giữ nguyên file processed.
    # --------------------------------------------------------

    shutil.copy2(
        file_processed,
        file_cleaned
    )


    # --------------------------------------------------------
    # E. ĐẾM CLEANED
    # --------------------------------------------------------

    so_dong_cleaned = (
        dem_dong_csv(
            file_cleaned
        )
    )


    # --------------------------------------------------------
    # F. ĐỐI SOÁT SỐ DÒNG
    # --------------------------------------------------------

    doi_soat = (

        so_dong_processed

        ==

        so_dong_cleaned
    )


    # --------------------------------------------------------
    # G. ĐỐI SOÁT CẤU TRÚC CỘT
    # --------------------------------------------------------

    cot_processed = (
        doc_danh_sach_cot(
            file_processed
        )
    )


    cot_cleaned = (
        doc_danh_sach_cot(
            file_cleaned
        )
    )


    doi_soat_cot = (

        cot_processed

        ==

        cot_cleaned
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
        f"Đối soát số dòng : "
        f"{'ĐẠT' if doi_soat else 'KHÔNG ĐẠT'}"
    )


    print(
        f"Đối soát cấu trúc: "
        f"{'ĐẠT' if doi_soat_cot else 'KHÔNG ĐẠT'}"
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
                -
                so_dong_cleaned
            ),

        "So_cot":
            len(
                cot_cleaned
            ),

        "Ten_file_sach":
            f"cleaned_{ten_file}",

        "Doi_soat_dong":
            (
                "DAT"
                if doi_soat
                else "KHONG_DAT"
            ),

        "Doi_soat_cot":
            (
                "DAT"
                if doi_soat_cot
                else "KHONG_DAT"
            )
    })


# ============================================================
# 6. KIỂM TRA CÁC CỘT QUỐC GIA / TIỀN TỆ
# ============================================================

print("\n")
print("=" * 95)
print("KIỂM TRA CẤU TRÚC CLEANED_TRANSACTIONS")
print("=" * 95)


FILE_CLEANED_TRANSACTIONS = (
    THU_MUC_CLEANED
    / "cleaned_transactions.csv"
)


cac_cot_transactions = (
    doc_danh_sach_cot(
        FILE_CLEANED_TRANSACTIONS
    )
)


CAC_COT_TIEN_TE_BAT_BUOC = [

    "Country_Code",

    "Expected_Currency",

    "Currency_Match",

    "Net_Amount",

    "Net_Amount_Local",

    "Exchange_Rate_To_USD",

    "Exchange_Rate_Date",

    "Exchange_Rate_Source",

    "Net_Amount_USD"
]


cot_tien_te_thieu = [

    cot

    for cot
    in CAC_COT_TIEN_TE_BAT_BUOC

    if cot
    not in cac_cot_transactions
]


if cot_tien_te_thieu:


    print(
        "\nTHIẾU CÁC CỘT:"
    )


    for cot in (
        cot_tien_te_thieu
    ):

        print(
            f"- {cot}"
        )


    raise ValueError(

        "\ncleaned_transactions.csv "
        "thiếu các cột Country/Currency/USD.\n"

        "Hãy kiểm tra lại các bước:\n"

        "03_Chuan_hoa_du_lieu.py\n"

        "04_Tao_thuoc_tinh_dan_xuat.py\n"

        "04B_Tao_bang_ty_gia.py\n"

        "04C_Quy_doi_tien_te_USD.py\n"

        "05_Phan_loai_valid_error.py"
    )


else:


    print(
        "\nĐầy đủ các cột "
        "Country / Currency / USD:"
    )


    for cot in (
        CAC_COT_TIEN_TE_BAT_BUOC
    ):

        print(
            f"- {cot}"
        )


    print(
        "\nKiểm tra cấu trúc tiền tệ: ĐẠT"
    )


# ============================================================
# 7. KIỂM TRA NHANH DỮ LIỆU TIỀN TỆ
# ============================================================

so_thieu_net_amount_usd = 0
so_thieu_exchange_rate = 0
so_exchange_rate_loi = 0


for chunk in pd.read_csv(

    FILE_CLEANED_TRANSACTIONS,

    usecols=[
        "Exchange_Rate_To_USD",
        "Net_Amount_USD"
    ],

    chunksize=100000,

    dtype=str,

    keep_default_na=False,

    low_memory=False
):


    rate = pd.to_numeric(

        chunk[
            "Exchange_Rate_To_USD"
        ],

        errors="coerce"
    )


    net_usd = pd.to_numeric(

        chunk[
            "Net_Amount_USD"
        ],

        errors="coerce"
    )


    so_thieu_exchange_rate += int(
        rate.isna().sum()
    )


    so_exchange_rate_loi += int(
        (
            rate.notna()
            &
            (
                rate
                <= 0
            )
        ).sum()
    )


    so_thieu_net_amount_usd += int(
        net_usd.isna().sum()
    )


print("\n")
print("-" * 95)

print(
    f"Exchange Rate thiếu : "
    f"{so_thieu_exchange_rate:,}"
)

print(
    f"Exchange Rate <= 0  : "
    f"{so_exchange_rate_loi:,}"
)

print(
    f"Net Amount USD thiếu: "
    f"{so_thieu_net_amount_usd:,}"
)


kiem_tra_tien_te_dat = (

    so_thieu_exchange_rate
    == 0

    and

    so_exchange_rate_loi
    == 0

    and

    so_thieu_net_amount_usd
    == 0
)


print(
    f"Kiểm tra tiền tệ    : "
    f"{'ĐẠT' if kiem_tra_tien_te_dat else 'KHÔNG ĐẠT'}"
)


# ============================================================
# 8. ĐỌC KẾT QUẢ ERROR / REVIEW
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
# 9. TẠO BẢNG KẾT QUẢ
# ============================================================

bang_ket_qua = (
    pd.DataFrame(
        ket_qua
    )
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
# 10. KIỂM TRA TOÀN BỘ
# ============================================================

tat_ca_dong_dat = (

    bang_ket_qua[
        "Doi_soat_dong"
    ]
    .eq(
        "DAT"
    )
    .all()
)


tat_ca_cot_dat = (

    bang_ket_qua[
        "Doi_soat_cot"
    ]
    .eq(
        "DAT"
    )
    .all()
)


tat_ca_dat = (

    tat_ca_dong_dat

    and

    tat_ca_cot_dat

    and

    kiem_tra_tien_te_dat
)


# ============================================================
# 11. HIỂN THỊ KẾT QUẢ
# ============================================================

print("\n")
print("=" * 95)
print("KẾT QUẢ 2.3.6")
print("=" * 95)


bang_hien_thi = (

    bang_ket_qua[

        [
            "Tep_du_lieu",

            "So_dong_RAW",

            "So_dong_Processed",

            "So_dong_Cleaned",

            "So_dong_giam",

            "So_cot",

            "Doi_soat_dong",

            "Doi_soat_cot"
        ]
    ]
)


print(

    bang_hien_thi.to_string(
        index=False
    )
)


print("\n" + "-" * 95)


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


print("\n" + "-" * 95)


print(
    f"ĐỐI SOÁT TOÀN BỘ: "
    f"{'ĐẠT' if tat_ca_dat else 'KHÔNG ĐẠT'}"
)


print(
    "\nĐã lưu dữ liệu sạch tại:"
)

print(
    THU_MUC_CLEANED
)


print(
    "\nĐã lưu bảng kết quả tại:"
)

print(
    FILE_KET_QUA
)


print(
    "\nHOÀN TẤT 2.3.6"
)