# -*- coding: utf-8 -*-

import pandas as pd
from pathlib import Path


# ============================================================
# 2.3.4B - TẠO BẢNG TỶ GIÁ LỊCH SỬ QUY VỀ USD
#
# Mục tiêu:
# - Lấy tỷ giá lịch sử từ ECB thông qua Frankfurter API
# - Các Currency:
#       USD
#       EUR
#       GBP
#       CNY
# - Khoảng giao dịch:
#       2023-01-01 -> 2025-03-18
#
# Quy ước:
#
# Rate_To_USD =
# số USD nhận được từ 1 đơn vị tiền địa phương
#
# Ví dụ:
# 1 EUR = 1.08 USD
# => Rate_To_USD = 1.08
#
# Với USD:
# Rate_To_USD = 1
#
# Ngày cuối tuần / ngày nghỉ:
# sử dụng tỷ giá công bố gần nhất trước đó.
# ============================================================


# ------------------------------------------------------------
# 1. THƯ MỤC
# ------------------------------------------------------------

THU_MUC_GOC = Path(__file__).resolve().parents[2]

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

THU_MUC_REFERENCE.mkdir(
    parents=True,
    exist_ok=True
)

THU_MUC_KET_QUA.mkdir(
    parents=True,
    exist_ok=True
)


FILE_TY_GIA = (
    THU_MUC_REFERENCE
    / "exchange_rates.csv"
)

FILE_KET_QUA = (
    THU_MUC_KET_QUA
    / "04B_Ket_qua_tao_bang_ty_gia.csv"
)


# ------------------------------------------------------------
# 2. KHOẢNG THỜI GIAN
# ------------------------------------------------------------

NGAY_BAT_DAU = pd.Timestamp(
    "2023-01-01"
)

NGAY_KET_THUC = pd.Timestamp(
    "2025-03-18"
)


# Lấy thêm dữ liệu trước 01/01/2023
# để ngày 01/01/2023 (ngày nghỉ)
# có thể dùng tỷ giá gần nhất trước đó.
NGAY_FETCH_BAT_DAU = pd.Timestamp(
    "2022-12-20"
)


CAC_TIEN_TE = [
    "EUR",
    "GBP",
    "CNY"
]


print("=" * 90)
print("2.3.4B - TẠO BẢNG TỶ GIÁ LỊCH SỬ QUY VỀ USD")
print("=" * 90)

print(
    f"\nKhoảng dữ liệu cần tạo: "
    f"{NGAY_BAT_DAU.date()} -> {NGAY_KET_THUC.date()}"
)


# ============================================================
# 3. TẢI TỶ GIÁ
#
# API trả:
#
# base = USD
# quote = EUR / GBP / CNY
#
# Ví dụ:
# 1 USD = 0.92 EUR
#
# Nhưng bài cần:
# 1 EUR = ? USD
#
# => Rate_To_USD = 1 / rate
# ============================================================

url = (
    "https://api.frankfurter.dev/v2/rates.csv"
    f"?from={NGAY_FETCH_BAT_DAU.strftime('%Y-%m-%d')}"
    f"&to={NGAY_KET_THUC.strftime('%Y-%m-%d')}"
    "&base=usd"
    "&quotes=eur,gbp,cny"
    "&providers=ecb"
)


print("\nĐang tải dữ liệu tỷ giá...")
print("Nguồn: ECB thông qua Frankfurter API")


try:

    raw_rates = pd.read_csv(
        url
    )

except Exception as e:

    raise RuntimeError(
        "\nKhông tải được dữ liệu tỷ giá.\n"
        "Hãy kiểm tra kết nối Internet.\n"
        f"Chi tiết: {e}"
    )


# ============================================================
# 4. KIỂM TRA CẤU TRÚC
# ============================================================

raw_rates.columns = (
    raw_rates.columns
    .astype(str)
    .str.strip()
    .str.lower()
)


CAC_COT_BAT_BUOC = [
    "date",
    "base",
    "quote",
    "rate"
]


cot_thieu = [
    cot
    for cot in CAC_COT_BAT_BUOC
    if cot not in raw_rates.columns
]


if cot_thieu:

    raise ValueError(
        "Dữ liệu API thiếu cột: "
        + ", ".join(cot_thieu)
    )


raw_rates["date"] = pd.to_datetime(
    raw_rates["date"],
    errors="coerce"
)


raw_rates["quote"] = (
    raw_rates["quote"]
    .astype("string")
    .str.strip()
    .str.upper()
)


raw_rates["rate"] = pd.to_numeric(
    raw_rates["rate"],
    errors="coerce"
)


# ============================================================
# 5. KIỂM TRA TỶ GIÁ API
# ============================================================

if raw_rates["date"].isna().any():

    raise ValueError(
        "Có ngày tỷ giá không hợp lệ."
    )


if raw_rates["rate"].isna().any():

    raise ValueError(
        "Có tỷ giá không chuyển được sang số."
    )


if (
    raw_rates["rate"]
    <= 0
).any():

    raise ValueError(
        "Có tỷ giá <= 0."
    )


# ============================================================
# 6. TẠO LỊCH ĐẦY ĐỦ TỪ 2023-01-01 -> 2025-03-18
# ============================================================

lich_ngay = pd.date_range(
    start=NGAY_FETCH_BAT_DAU,
    end=NGAY_KET_THUC,
    freq="D"
)


ket_qua = []


# ============================================================
# 7. XỬ LÝ EUR / GBP / CNY
# ============================================================

for currency in CAC_TIEN_TE:

    print(
        f"Đang xử lý: {currency} -> USD"
    )


    temp = (
        raw_rates[
            raw_rates["quote"]
            == currency
        ][
            [
                "date",
                "rate"
            ]
        ]
        .copy()
        .sort_values(
            "date"
        )
    )


    if temp.empty:

        raise ValueError(
            f"Không có dữ liệu tỷ giá cho {currency}."
        )


    # --------------------------------------------------------
    # API đang cho:
    #
    # 1 USD = rate Currency
    #
    # Đổi thành:
    #
    # 1 Currency = Rate_To_USD USD
    # --------------------------------------------------------

    temp[
        "Rate_To_USD"
    ] = (
        1
        /
        temp["rate"]
    )


    temp[
        "Rate_Date_Source"
    ] = (
        temp["date"]
    )


    temp = (
        temp[
            [
                "date",
                "Rate_To_USD",
                "Rate_Date_Source"
            ]
        ]
        .set_index(
            "date"
        )
        .reindex(
            lich_ngay
        )
    )


    # --------------------------------------------------------
    # Ngày cuối tuần / ngày nghỉ:
    # dùng tỷ giá gần nhất trước đó
    # --------------------------------------------------------

    temp[
        "Rate_To_USD"
    ] = (
        temp[
            "Rate_To_USD"
        ]
        .ffill()
    )


    temp[
        "Rate_Date_Source"
    ] = (
        temp[
            "Rate_Date_Source"
        ]
        .ffill()
    )


    # Fallback đầu chuỗi nếu cần
    temp[
        "Rate_To_USD"
    ] = (
        temp[
            "Rate_To_USD"
        ]
        .bfill()
    )


    temp[
        "Rate_Date_Source"
    ] = (
        temp[
            "Rate_Date_Source"
        ]
        .bfill()
    )


    temp = (
        temp
        .reset_index()
        .rename(
            columns={
                "index": "Date"
            }
        )
    )


    temp[
        "Currency"
    ] = currency


    temp[
        "Rate_Source"
    ] = "ECB"


    ket_qua.append(
        temp
    )


# ============================================================
# 8. USD
#
# USD -> USD luôn bằng 1
# ============================================================

usd = pd.DataFrame({

    "Date":
        lich_ngay,

    "Rate_To_USD":
        1.0,

    "Rate_Date_Source":
        lich_ngay,

    "Currency":
        "USD",

    "Rate_Source":
        "BASE"
})


ket_qua.append(
    usd
)


# ============================================================
# 9. GHÉP TOÀN BỘ
# ============================================================

exchange_rates = pd.concat(
    ket_qua,
    ignore_index=True
)


# Chỉ giữ đúng khoảng giao dịch
exchange_rates = exchange_rates[
    (
        exchange_rates["Date"]
        >= NGAY_BAT_DAU
    )
    &
    (
        exchange_rates["Date"]
        <= NGAY_KET_THUC
    )
].copy()


# ============================================================
# 10. CHUẨN HÓA
# ============================================================

exchange_rates[
    "Date"
] = (
    exchange_rates["Date"]
    .dt.strftime(
        "%Y-%m-%d"
    )
)


exchange_rates[
    "Rate_Date_Source"
] = pd.to_datetime(
    exchange_rates[
        "Rate_Date_Source"
    ]
).dt.strftime(
    "%Y-%m-%d"
)


exchange_rates[
    "Rate_To_USD"
] = (
    pd.to_numeric(
        exchange_rates[
            "Rate_To_USD"
        ],
        errors="raise"
    )
    .round(8)
)


exchange_rates[
    "Currency"
] = (
    exchange_rates[
        "Currency"
    ]
    .astype("string")
    .str.upper()
)


# ============================================================
# 11. SẮP XẾP
# ============================================================

thu_tu_currency = pd.CategoricalDtype(
    categories=[
        "USD",
        "EUR",
        "GBP",
        "CNY"
    ],
    ordered=True
)


exchange_rates[
    "Currency"
] = (
    exchange_rates[
        "Currency"
    ]
    .astype(
        thu_tu_currency
    )
)


exchange_rates = (
    exchange_rates
    .sort_values(
        [
            "Date",
            "Currency"
        ]
    )
    .reset_index(
        drop=True
    )
)


exchange_rates[
    "Currency"
] = (
    exchange_rates[
        "Currency"
    ]
    .astype("string")
)


# ============================================================
# 12. KIỂM TRA DUPLICATE
# ============================================================

duplicate_mask = (
    exchange_rates
    .duplicated(
        subset=[
            "Date",
            "Currency"
        ],
        keep=False
    )
)


if duplicate_mask.any():

    raise ValueError(
        "Có trùng khóa Date + Currency "
        "trong bảng tỷ giá."
    )


# ============================================================
# 13. KIỂM TRA MISSING
# ============================================================

missing_rate = int(
    exchange_rates[
        "Rate_To_USD"
    ]
    .isna()
    .sum()
)


invalid_rate = int(
    (
        exchange_rates[
            "Rate_To_USD"
        ]
        <= 0
    )
    .sum()
)


if missing_rate > 0:

    raise ValueError(
        f"Còn {missing_rate:,} tỷ giá bị thiếu."
    )


if invalid_rate > 0:

    raise ValueError(
        f"Có {invalid_rate:,} tỷ giá <= 0."
    )


# ============================================================
# 14. KIỂM TRA ĐỦ NGÀY × CURRENCY
# ============================================================

so_ngay = (
    NGAY_KET_THUC
    - NGAY_BAT_DAU
).days + 1


so_dong_ky_vong = (
    so_ngay
    * 4
)


so_dong_thuc_te = len(
    exchange_rates
)


doi_soat = (
    so_dong_ky_vong
    ==
    so_dong_thuc_te
)


# ============================================================
# 15. LƯU FILE
# ============================================================

exchange_rates.to_csv(
    FILE_TY_GIA,
    index=False,
    encoding="utf-8-sig"
)


# ============================================================
# 16. LƯU KẾT QUẢ KIỂM TRA
# ============================================================

bang_ket_qua = pd.DataFrame(
    [
        {
            "Ngay_bat_dau":
                NGAY_BAT_DAU.strftime(
                    "%Y-%m-%d"
                ),

            "Ngay_ket_thuc":
                NGAY_KET_THUC.strftime(
                    "%Y-%m-%d"
                ),

            "So_ngay":
                so_ngay,

            "So_currency":
                4,

            "So_dong_ky_vong":
                so_dong_ky_vong,

            "So_dong_thuc_te":
                so_dong_thuc_te,

            "Missing_rate":
                missing_rate,

            "Invalid_rate":
                invalid_rate,

            "Doi_soat":
                (
                    "DAT"
                    if doi_soat
                    else "KHONG_DAT"
                )
        }
    ]
)


bang_ket_qua.to_csv(
    FILE_KET_QUA,
    index=False,
    encoding="utf-8-sig"
)


# ============================================================
# 17. HIỂN THỊ
# ============================================================

print("\n")
print("=" * 90)
print("KẾT QUẢ TẠO BẢNG TỶ GIÁ")
print("=" * 90)


print(
    f"Số ngày                : "
    f"{so_ngay:,}"
)

print(
    f"Số Currency            : 4"
)

print(
    f"Số dòng kỳ vọng        : "
    f"{so_dong_ky_vong:,}"
)

print(
    f"Số dòng thực tế        : "
    f"{so_dong_thuc_te:,}"
)

print(
    f"Tỷ giá thiếu           : "
    f"{missing_rate:,}"
)

print(
    f"Tỷ giá <= 0            : "
    f"{invalid_rate:,}"
)

print(
    f"Đối soát               : "
    f"{'ĐẠT' if doi_soat else 'KHÔNG ĐẠT'}"
)


print("\nMẫu dữ liệu:")

print(
    exchange_rates
    .head(20)
    .to_string(
        index=False
    )
)


print("\nĐã lưu bảng tỷ giá tại:")
print(FILE_TY_GIA)

print("\nĐã lưu kết quả kiểm tra tại:")
print(FILE_KET_QUA)

print("\nHOÀN TẤT 2.3.4B")