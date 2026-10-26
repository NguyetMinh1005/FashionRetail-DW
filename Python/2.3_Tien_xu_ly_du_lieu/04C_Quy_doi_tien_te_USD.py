# -*- coding: utf-8 -*-

import pandas as pd
from pathlib import Path
import os


# ============================================================
# 2.3.4C - QUY ĐỔI TIỀN TỆ VỀ USD
#
# Giữ:
# - Currency
# - Net_Amount
#
# Thêm:
# - Net_Amount_Local
# - Exchange_Rate_To_USD
# - Exchange_Rate_Date
# - Exchange_Rate_Source
# - Net_Amount_USD
#
# Công thức:
# Net_Amount_USD
# =
# Net_Amount_Local * Exchange_Rate_To_USD
#
# KHÔNG ghi đè tiền gốc.
# ============================================================


# ============================================================
# 1. THƯ MỤC
# ============================================================

THU_MUC_GOC = Path(__file__).resolve().parents[2]

THU_MUC_PROCESSED = (
    THU_MUC_GOC
    / "data"
    / "processed"
)

THU_MUC_REFERENCE = (
    THU_MUC_GOC
    / "data"
    / "reference"
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


FILE_TRANSACTIONS = (
    THU_MUC_PROCESSED
    / "transactions.csv"
)

FILE_TY_GIA = (
    THU_MUC_REFERENCE
    / "exchange_rates.csv"
)

FILE_TEMP = (
    THU_MUC_PROCESSED
    / "__temp_transactions_currency.csv"
)

FILE_KET_QUA = (
    THU_MUC_KET_QUA
    / "04C_Ket_qua_quy_doi_tien_te_USD.csv"
)


print("=" * 95)
print("2.3.4C - QUY ĐỔI TIỀN TỆ VỀ USD")
print("=" * 95)


# ============================================================
# 2. KIỂM TRA FILE
# ============================================================

if not FILE_TRANSACTIONS.exists():

    raise FileNotFoundError(
        f"Không tìm thấy: {FILE_TRANSACTIONS}"
    )


if not FILE_TY_GIA.exists():

    raise FileNotFoundError(
        "\nKhông tìm thấy exchange_rates.csv.\n"
        "Hãy chạy 04B_Tao_bang_ty_gia.py trước."
    )


# ============================================================
# 3. ĐỌC BẢNG TỶ GIÁ
# ============================================================

rates = pd.read_csv(
    FILE_TY_GIA,
    dtype=str,
    encoding="utf-8-sig",
    keep_default_na=False
)


rates.columns = (
    rates.columns
    .astype(str)
    .str.strip()
)


CAC_COT_TY_GIA = [
    "Date",
    "Currency",
    "Rate_To_USD",
    "Rate_Date_Source",
    "Rate_Source"
]


cot_thieu = [
    cot
    for cot in CAC_COT_TY_GIA
    if cot not in rates.columns
]


if cot_thieu:

    raise ValueError(
        "exchange_rates.csv thiếu cột: "
        + ", ".join(cot_thieu)
    )


# ============================================================
# 4. CHUẨN HÓA BẢNG TỶ GIÁ
# ============================================================

rates["Date"] = (
    rates["Date"]
    .astype("string")
    .str.strip()
)


rates["Currency"] = (
    rates["Currency"]
    .astype("string")
    .str.strip()
    .str.upper()
)


rates["Rate_To_USD"] = pd.to_numeric(
    rates["Rate_To_USD"],
    errors="coerce"
)


if rates["Rate_To_USD"].isna().any():

    raise ValueError(
        "Có Rate_To_USD không hợp lệ."
    )


if (
    rates["Rate_To_USD"]
    <= 0
).any():

    raise ValueError(
        "Có Rate_To_USD <= 0."
    )


# ============================================================
# 5. KIỂM TRA TRÙNG DATE + CURRENCY
# ============================================================

duplicate_rate = (
    rates.duplicated(
        subset=[
            "Date",
            "Currency"
        ],
        keep=False
    )
)


if duplicate_rate.any():

    print(
        rates.loc[
            duplicate_rate
        ].to_string(
            index=False
        )
    )

    raise ValueError(
        "Bảng tỷ giá bị trùng Date + Currency."
    )


# ============================================================
# 6. TẠO BẢNG LOOKUP
# ============================================================

rates_lookup = rates[
    [
        "Date",
        "Currency",
        "Rate_To_USD",
        "Rate_Date_Source",
        "Rate_Source"
    ]
].copy()


rates_lookup = rates_lookup.rename(
    columns={

        "Date":
            "Transaction_Date",

        "Rate_To_USD":
            "Exchange_Rate_To_USD",

        "Rate_Date_Source":
            "Exchange_Rate_Date",

        "Rate_Source":
            "Exchange_Rate_Source"
    }
)


# ============================================================
# 7. CHUẨN BỊ XỬ LÝ TRANSACTIONS
# ============================================================

if FILE_TEMP.exists():

    FILE_TEMP.unlink()


ghi_header = True

tong_dong_truoc = 0
tong_dong_sau = 0

so_thieu_currency = 0
so_thieu_ty_gia = 0
so_ty_gia_khong_hop_le = 0
so_net_amount_usd_thieu = 0

currency_counts = {}


# ============================================================
# 8. XỬ LÝ TRANSACTIONS THEO CHUNK
# ============================================================

for chunk in pd.read_csv(

    FILE_TRANSACTIONS,

    chunksize=100000,

    dtype=str,

    keep_default_na=False,

    low_memory=False
):

    # --------------------------------------------------------
    # A. ĐẾM SỐ DÒNG ĐẦU VÀO
    # --------------------------------------------------------

    tong_dong_truoc += len(
        chunk
    )


    # --------------------------------------------------------
    # B. XÓA CỘT QUY ĐỔI CŨ NẾU CHẠY LẠI
    # --------------------------------------------------------

    cot_quy_doi_cu = [

        "Net_Amount_Local",

        "Exchange_Rate_To_USD",

        "Exchange_Rate_Date",

        "Exchange_Rate_Source",

        "Net_Amount_USD"
    ]


    cot_can_xoa = [

        cot

        for cot in cot_quy_doi_cu

        if cot in chunk.columns
    ]


    if cot_can_xoa:

        chunk = chunk.drop(
            columns=cot_can_xoa
        )


    # --------------------------------------------------------
    # C. KIỂM TRA CỘT BẮT BUỘC
    # --------------------------------------------------------

    CAC_COT_CAN_CO = [

        "Transaction_Date",

        "Currency",

        "Net_Amount"
    ]


    cot_thieu_transactions = [

        cot

        for cot in CAC_COT_CAN_CO

        if cot not in chunk.columns
    ]


    if cot_thieu_transactions:

        if FILE_TEMP.exists():

            FILE_TEMP.unlink()


        raise ValueError(

            "transactions.csv thiếu cột: "

            + ", ".join(
                cot_thieu_transactions
            )

            + "\nHãy chạy "
            "04_Tao_thuoc_tinh_dan_xuat.py trước."
        )


    # --------------------------------------------------------
    # D. CHUẨN HÓA KHÓA LOOKUP
    # --------------------------------------------------------

    chunk["Transaction_Date"] = (
        chunk["Transaction_Date"]
        .astype("string")
        .str.strip()
    )


    chunk["Currency"] = (
        chunk["Currency"]
        .astype("string")
        .str.strip()
        .str.upper()
    )


    # --------------------------------------------------------
    # E. KIỂM TRA CURRENCY THIẾU
    # --------------------------------------------------------

    mask_currency_thieu = (

        chunk["Currency"].isna()

        |

        chunk["Currency"].eq("")

        |

        chunk["Currency"].eq("UNKNOWN")
    )


    so_thieu_currency += int(
        mask_currency_thieu.sum()
    )


    # --------------------------------------------------------
    # F. LOOKUP TỶ GIÁ
    # --------------------------------------------------------

    chunk = chunk.merge(

        rates_lookup,

        how="left",

        on=[
            "Transaction_Date",
            "Currency"
        ],

        validate="many_to_one"
    )


    # --------------------------------------------------------
    # G. RESET INDEX SAU MERGE
    #
    # CỰC KỲ QUAN TRỌNG:
    # tránh lệch index giữa các chunk.
    # --------------------------------------------------------

    chunk = chunk.reset_index(
        drop=True
    )


    # --------------------------------------------------------
    # H. CHUYỂN NET_AMOUNT THÀNH SỐ SAU MERGE
    # --------------------------------------------------------

    net_amount_numeric = pd.to_numeric(

        chunk["Net_Amount"],

        errors="coerce"
    )


    if net_amount_numeric.isna().any():

        if FILE_TEMP.exists():

            FILE_TEMP.unlink()


        raise ValueError(
            "Có Net_Amount không chuyển được sang số."
        )


    # --------------------------------------------------------
    # I. NET_AMOUNT_LOCAL
    # --------------------------------------------------------

    chunk["Net_Amount_Local"] = (

        net_amount_numeric

        .astype("Float64")

        .astype("string")
    )


    # --------------------------------------------------------
    # J. CHUYỂN EXCHANGE RATE SANG SỐ
    # --------------------------------------------------------

    rate_numeric = pd.to_numeric(

        chunk["Exchange_Rate_To_USD"],

        errors="coerce"
    )


    # --------------------------------------------------------
    # K. KIỂM TRA TỶ GIÁ THIẾU
    # --------------------------------------------------------

    mask_thieu_ty_gia = (
        rate_numeric.isna()
    )


    so_thieu_ty_gia += int(
        mask_thieu_ty_gia.sum()
    )


    # --------------------------------------------------------
    # L. KIỂM TRA TỶ GIÁ <= 0
    # --------------------------------------------------------

    mask_ty_gia_loi = (

        rate_numeric.notna()

        &

        (
            rate_numeric
            <= 0
        )
    )


    so_ty_gia_khong_hop_le += int(
        mask_ty_gia_loi.sum()
    )


    # --------------------------------------------------------
    # M. TÍNH NET_AMOUNT_USD
    # --------------------------------------------------------

    net_amount_usd = (

        net_amount_numeric

        *

        rate_numeric
    )


    chunk["Net_Amount_USD"] = (

        net_amount_usd

        .round(4)

        .astype("Float64")

        .astype("string")
    )


    # --------------------------------------------------------
    # N. KIỂM TRA NET_AMOUNT_USD
    # --------------------------------------------------------

    so_net_amount_usd_thieu += int(

        net_amount_usd
        .isna()
        .sum()
    )


    # --------------------------------------------------------
    # O. THỐNG KÊ SỐ GIAO DỊCH THEO CURRENCY
    # --------------------------------------------------------

    counts = (
        chunk["Currency"]
        .value_counts()
    )


    for currency, count in counts.items():

        currency_counts[
            currency
        ] = (

            currency_counts.get(
                currency,
                0
            )

            +

            int(
                count
            )
        )


    # --------------------------------------------------------
    # P. CẬP NHẬT SỐ DÒNG SAU XỬ LÝ
    # --------------------------------------------------------

    tong_dong_sau += len(
        chunk
    )


    # --------------------------------------------------------
    # Q. GHI FILE TẠM
    # --------------------------------------------------------

    if ghi_header:

        chunk.to_csv(

            FILE_TEMP,

            mode="w",

            index=False,

            header=True,

            encoding="utf-8-sig"
        )


        ghi_header = False

    else:

        chunk.to_csv(

            FILE_TEMP,

            mode="a",

            index=False,

            header=False,

            encoding="utf-8"
        )


# ============================================================
# 9. KIỂM TRA ĐỐI SOÁT
# ============================================================

print("\n")
print("-" * 95)
print("KIỂM TRA ĐỐI SOÁT")
print("-" * 95)


print(
    f"Tổng dòng trước xử lý : "
    f"{tong_dong_truoc:,}"
)


print(
    f"Tổng dòng sau xử lý   : "
    f"{tong_dong_sau:,}"
)


print(
    f"Currency thiếu        : "
    f"{so_thieu_currency:,}"
)


print(
    f"Tỷ giá thiếu          : "
    f"{so_thieu_ty_gia:,}"
)


print(
    f"Tỷ giá <= 0           : "
    f"{so_ty_gia_khong_hop_le:,}"
)


print(
    f"Net Amount USD thiếu  : "
    f"{so_net_amount_usd_thieu:,}"
)


doi_soat = (

    tong_dong_truoc

    ==

    tong_dong_sau
)


# ============================================================
# 10. KHÔNG THAY FILE NẾU CÓ LỖI
# ============================================================

if (

    not doi_soat

    or so_thieu_currency > 0

    or so_thieu_ty_gia > 0

    or so_ty_gia_khong_hop_le > 0

    or so_net_amount_usd_thieu > 0
):


    if FILE_TEMP.exists():

        FILE_TEMP.unlink()


    raise ValueError(

        "\nQUY ĐỔI TIỀN TỆ KHÔNG ĐẠT.\n"

        f"Đối soát số dòng     : {doi_soat}\n"

        f"Currency thiếu       : "
        f"{so_thieu_currency:,}\n"

        f"Tỷ giá thiếu         : "
        f"{so_thieu_ty_gia:,}\n"

        f"Tỷ giá <= 0          : "
        f"{so_ty_gia_khong_hop_le:,}\n"

        f"Net Amount USD thiếu : "
        f"{so_net_amount_usd_thieu:,}"
    )


# ============================================================
# 11. THAY FILE TRANSACTIONS
# ============================================================

os.replace(
    FILE_TEMP,
    FILE_TRANSACTIONS
)


# ============================================================
# 12. LƯU KẾT QUẢ
# ============================================================

ket_qua = pd.DataFrame(

    [

        {

            "So_dong_truoc":
                tong_dong_truoc,

            "So_dong_sau":
                tong_dong_sau,

            "Currency_thieu":
                so_thieu_currency,

            "Ty_gia_thieu":
                so_thieu_ty_gia,

            "Ty_gia_khong_hop_le":
                so_ty_gia_khong_hop_le,

            "Net_Amount_USD_thieu":
                so_net_amount_usd_thieu,

            "Doi_soat":
                (
                    "DAT"
                    if doi_soat
                    else "KHONG_DAT"
                )
        }
    ]
)


ket_qua.to_csv(

    FILE_KET_QUA,

    index=False,

    encoding="utf-8-sig"
)


# ============================================================
# 13. HIỂN THỊ KẾT QUẢ
# ============================================================

print("\n")
print("=" * 95)
print("KẾT QUẢ QUY ĐỔI TIỀN TỆ VỀ USD")
print("=" * 95)


print(
    f"Số dòng trước xử lý      : "
    f"{tong_dong_truoc:,}"
)


print(
    f"Số dòng sau xử lý        : "
    f"{tong_dong_sau:,}"
)


print(
    f"Currency thiếu/rỗng       : "
    f"{so_thieu_currency:,}"
)


print(
    f"Tỷ giá không tìm thấy     : "
    f"{so_thieu_ty_gia:,}"
)


print(
    f"Tỷ giá <= 0               : "
    f"{so_ty_gia_khong_hop_le:,}"
)


print(
    f"Net Amount USD thiếu      : "
    f"{so_net_amount_usd_thieu:,}"
)


print(
    "\nSố giao dịch theo Currency:"
)


for currency in sorted(
    currency_counts
):

    print(
        f"- {currency}: "
        f"{currency_counts[currency]:,}"
    )


print(
    f"\nĐối soát số dòng          : "
    f"{'ĐẠT' if doi_soat else 'KHÔNG ĐẠT'}"
)


print(
    "\nCác cột được bổ sung:"
)


print(
    "- Net_Amount_Local\n"
    "- Exchange_Rate_To_USD\n"
    "- Exchange_Rate_Date\n"
    "- Exchange_Rate_Source\n"
    "- Net_Amount_USD"
)


print(
    "\nĐã lưu kết quả tại:"
)

print(
    FILE_KET_QUA
)


print(
    "\nHOÀN TẤT 2.3.4C"
)