# -*- coding: utf-8 -*-

import pandas as pd
from pathlib import Path
import os


# ============================================================
# 2.3.4. XÂY DỰNG CÁC THUỘC TÍNH DẪN XUẤT
#
# transactions:
# - Transaction_Date
# - Transaction_Time
# - Is_Return
# - Net_Amount
# - Sales_Quantity
# - Return_Quantity
#
# Bổ sung kiểm tra dữ liệu đa quốc gia:
# - Country_Code
# - Expected_Currency
# - Currency_Match
#
# customers:
# - Age
# - Age_Group
#
# KHÔNG tạo Year / Quarter / Month / Season ở Fact.
# Các thuộc tính thời gian này sẽ thuộc Dim_Date.
#
# Lưu ý:
# - Country_Name_EN / Country_Name_VI được giữ ở stores.csv,
#   không lặp lại trên hơn 6 triệu dòng transactions.
# - Chưa thực hiện quy đổi tỷ giá ở bước này.
# ============================================================


# ------------------------------------------------------------
# 1. XÁC ĐỊNH THƯ MỤC
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


FILE_TRANSACTIONS = (
    THU_MUC_PROCESSED
    / "transactions.csv"
)

FILE_CUSTOMERS = (
    THU_MUC_PROCESSED
    / "customers.csv"
)

FILE_STORES = (
    THU_MUC_PROCESSED
    / "stores.csv"
)


print("=" * 95)
print("2.3.4 - XÂY DỰNG CÁC THUỘC TÍNH DẪN XUẤT")
print("=" * 95)


# ============================================================
# 2. KIỂM TRA FILE ĐẦU VÀO
# ============================================================

for file_can_kiem_tra in [
    FILE_TRANSACTIONS,
    FILE_CUSTOMERS,
    FILE_STORES
]:

    if not file_can_kiem_tra.exists():

        raise FileNotFoundError(
            f"Không tìm thấy file: {file_can_kiem_tra}"
        )


# ============================================================
# 3. ĐỌC THÔNG TIN QUỐC GIA / TIỀN TỆ TỪ STORES
# ============================================================

print(
    "\nBƯỚC 1/4 - "
    "Đọc thông tin quốc gia và tiền tệ từ stores.csv..."
)


stores = pd.read_csv(
    FILE_STORES,
    dtype=str,
    keep_default_na=False,
    low_memory=False
)


# ------------------------------------------------------------
# Trim tên cột
# ------------------------------------------------------------

stores.columns = (
    stores.columns
    .astype(str)
    .str.strip()
)


# ------------------------------------------------------------
# Kiểm tra các cột cần thiết
# Các cột này phải được tạo ở bước 2.3.3
# ------------------------------------------------------------

CAC_COT_STORE_CAN_CO = [
    "Store ID",
    "Country_Code",
    "Expected_Currency"
]


cot_store_thieu = [
    cot
    for cot in CAC_COT_STORE_CAN_CO
    if cot not in stores.columns
]


if cot_store_thieu:

    raise ValueError(
        "\nstores.csv thiếu các cột: "
        + ", ".join(cot_store_thieu)
        + "\nHãy chạy lại 03_Chuan_hoa_du_lieu.py trước."
    )


# ------------------------------------------------------------
# Chuẩn hóa Store ID / Country / Currency
# ------------------------------------------------------------

stores["Store ID"] = (
    stores["Store ID"]
    .astype("string")
    .str.strip()
)

stores["Country_Code"] = (
    stores["Country_Code"]
    .astype("string")
    .str.strip()
    .str.upper()
)

stores["Expected_Currency"] = (
    stores["Expected_Currency"]
    .astype("string")
    .str.strip()
    .str.upper()
)


# ------------------------------------------------------------
# Kiểm tra Store ID có duy nhất hay không
# ------------------------------------------------------------

store_id_trung = (
    stores["Store ID"]
    .duplicated(
        keep=False
    )
)


if store_id_trung.any():

    print(
        "\nLỖI: Store ID bị trùng trong stores.csv:"
    )

    print(
        stores.loc[
            store_id_trung,
            [
                "Store ID",
                "Country_Code",
                "Expected_Currency"
            ]
        ].to_string(
            index=False
        )
    )

    raise ValueError(
        "Store ID trong stores.csv phải duy nhất."
    )


# ------------------------------------------------------------
# Tạo bảng Lookup gọn
# ------------------------------------------------------------

store_lookup = (
    stores[
        [
            "Store ID",
            "Country_Code",
            "Expected_Currency"
        ]
    ]
    .copy()
)


print(
    f"Số cửa hàng dùng để Lookup: "
    f"{len(store_lookup):,}"
)


print("\nThông tin Country / Currency theo Store:")

print(
    store_lookup
    .sort_values(
        "Store ID",
        key=lambda x: pd.to_numeric(
            x,
            errors="coerce"
        )
    )
    .to_string(
        index=False
    )
)


# ============================================================
# 4. XÁC ĐỊNH NGÀY THAM CHIẾU
#
# Lấy ngày giao dịch lớn nhất trong dataset.
# Dùng ngày này để tính Age.
# ============================================================

print(
    "\nBƯỚC 2/4 - "
    "Xác định ngày tham chiếu..."
)


ngay_lon_nhat = None


for chunk in pd.read_csv(
    FILE_TRANSACTIONS,
    usecols=["Date"],
    chunksize=100000,
    dtype=str,
    low_memory=False
):

    ngay = pd.to_datetime(
        chunk["Date"],
        errors="coerce"
    )

    max_chunk = ngay.max()

    if pd.notna(
        max_chunk
    ):

        if (
            ngay_lon_nhat is None
            or max_chunk > ngay_lon_nhat
        ):

            ngay_lon_nhat = max_chunk


if ngay_lon_nhat is None:

    raise ValueError(
        "Không xác định được ngày giao dịch lớn nhất."
    )


NGAY_THAM_CHIEU = (
    ngay_lon_nhat
    .normalize()
)


print(
    "Ngày tham chiếu tính tuổi: "
    f"{NGAY_THAM_CHIEU.strftime('%Y-%m-%d')}"
)


# ============================================================
# 5. XỬ LÝ TRANSACTIONS
# ============================================================

print(
    "\nBƯỚC 3/4 - "
    "Tạo thuộc tính dẫn xuất và kiểm tra Currency "
    "cho transactions.csv..."
)


FILE_TEMP_TRANSACTIONS = (
    THU_MUC_PROCESSED
    / "__temp_transactions.csv"
)


if FILE_TEMP_TRANSACTIONS.exists():

    FILE_TEMP_TRANSACTIONS.unlink()


ghi_header = True

tong_dong_transactions_truoc = 0
tong_dong_transactions_sau = 0

so_sale = 0
so_return = 0

so_store_khong_lookup = 0
so_currency_khong_khop = 0
so_currency_thieu = 0

# Chỉ lưu các tổ hợp distinct để báo cáo,
# không giữ toàn bộ 6,4 triệu dòng trong RAM.
tap_currency_check = set()


for chunk in pd.read_csv(
    FILE_TRANSACTIONS,
    chunksize=100000,
    dtype=str,
    keep_default_na=False,
    low_memory=False
):

    tong_dong_transactions_truoc += len(
        chunk
    )


    # --------------------------------------------------------
    # A. XÓA CÁC CỘT LOOKUP CŨ NẾU CHẠY LẠI SCRIPT
    #
    # Tránh sinh:
    # Country_Code_x / Country_Code_y
    # --------------------------------------------------------

    cot_lookup_cu = [
        "Country_Code",
        "Expected_Currency",
        "Currency_Match"
    ]


    cot_can_xoa = [
        cot
        for cot in cot_lookup_cu
        if cot in chunk.columns
    ]


    if cot_can_xoa:

        chunk = chunk.drop(
            columns=cot_can_xoa
        )


    # --------------------------------------------------------
    # B. CHUẨN HÓA STORE ID
    # --------------------------------------------------------

    if "Store ID" not in chunk.columns:

        raise ValueError(
            "transactions.csv không có cột Store ID."
        )


    chunk["Store ID"] = (
        chunk["Store ID"]
        .astype("string")
        .str.strip()
    )


    # --------------------------------------------------------
    # C. CHUẨN HÓA CURRENCY
    # --------------------------------------------------------

    if "Currency" not in chunk.columns:

        raise ValueError(
            "transactions.csv không có cột Currency."
        )


    chunk["Currency"] = (
        chunk["Currency"]
        .astype("string")
        .str.strip()
        .str.upper()
    )


    # --------------------------------------------------------
    # D. LOOKUP COUNTRY / EXPECTED CURRENCY THEO STORE
    # --------------------------------------------------------

    chunk = chunk.merge(
        store_lookup,
        how="left",
        on="Store ID",
        validate="many_to_one"
    )


    # --------------------------------------------------------
    # E. KIỂM TRA STORE KHÔNG LOOKUP ĐƯỢC
    # --------------------------------------------------------

    mask_store_khong_lookup = (
        chunk["Country_Code"].isna()
        |
        chunk["Expected_Currency"].isna()
    )


    so_store_khong_lookup += int(
        mask_store_khong_lookup.sum()
    )


    # --------------------------------------------------------
    # F. KIỂM TRA CURRENCY THIẾU / RỖNG
    # --------------------------------------------------------

    mask_currency_thieu = (
        chunk["Currency"].isna()
        |
        chunk["Currency"].eq("")
        |
        chunk["Currency"].eq("UNKNOWN")
    )


    so_currency_thieu += int(
        mask_currency_thieu.sum()
    )


    # --------------------------------------------------------
    # G. CURRENCY MATCH
    #
    # True:
    # Currency thực tế = Currency dự kiến theo Country
    #
    # Ví dụ:
    # United States -> USD
    # China         -> CNY
    # Germany       -> EUR
    # UK            -> GBP
    # --------------------------------------------------------

    currency_match_bool = (
        chunk["Currency"]
        ==
        chunk["Expected_Currency"]
    )


    # Store lookup thất bại hoặc Currency thiếu
    # thì không coi là Match.
    currency_match_bool = (
        currency_match_bool
        & ~mask_store_khong_lookup
        & ~mask_currency_thieu
    )


    chunk["Currency_Match"] = (
        currency_match_bool
        .astype("string")
    )


    so_currency_khong_khop += int(
        (~currency_match_bool).sum()
    )


    # --------------------------------------------------------
    # H. LƯU CÁC TỔ HỢP DISTINCT PHỤC VỤ BÁO CÁO
    # --------------------------------------------------------

    currency_check_distinct = (
        chunk[
            [
                "Store ID",
                "Country_Code",
                "Currency",
                "Expected_Currency",
                "Currency_Match"
            ]
        ]
        .drop_duplicates()
    )


    for row in currency_check_distinct.itertuples(
        index=False,
        name=None
    ):

        tap_currency_check.add(
            tuple(
                str(x)
                for x in row
            )
        )


    # --------------------------------------------------------
    # I. CHUYỂN DATE
    # --------------------------------------------------------

    ngay_giao_dich = pd.to_datetime(
        chunk["Date"],
        errors="coerce"
    )


    if ngay_giao_dich.isna().any():

        raise ValueError(
            "Phát hiện Date không chuyển được sang datetime."
        )


    # --------------------------------------------------------
    # J. TRANSACTION_DATE
    # --------------------------------------------------------

    chunk["Transaction_Date"] = (
        ngay_giao_dich
        .dt.strftime(
            "%Y-%m-%d"
        )
    )


    # --------------------------------------------------------
    # K. TRANSACTION_TIME
    # --------------------------------------------------------

    chunk["Transaction_Time"] = (
        ngay_giao_dich
        .dt.strftime(
            "%H:%M:%S"
        )
    )


    # --------------------------------------------------------
    # L. TRANSACTION TYPE
    # --------------------------------------------------------

    transaction_type = (
        chunk["Transaction Type"]
        .astype(str)
        .str.strip()
    )


    # --------------------------------------------------------
    # M. IS_RETURN
    #
    # Return = 1
    # Sale   = 0
    # --------------------------------------------------------

    chunk["Is_Return"] = (
        transaction_type
        .eq("Return")
        .astype(int)
        .astype("string")
    )


    # --------------------------------------------------------
    # N. CHUYỂN QUANTITY / LINE TOTAL SANG SỐ
    # --------------------------------------------------------

    quantity = pd.to_numeric(
        chunk["Quantity"],
        errors="coerce"
    )


    line_total = pd.to_numeric(
        chunk["Line Total"],
        errors="coerce"
    )


    if quantity.isna().any():

        raise ValueError(
            "Phát hiện Quantity không hợp lệ."
        )


    if line_total.isna().any():

        raise ValueError(
            "Phát hiện Line Total không hợp lệ."
        )


    # --------------------------------------------------------
    # O. NET_AMOUNT
    #
    # Sale   -> Line Total dương
    # Return -> Line Total âm
    #
    # Sử dụng trực tiếp Line Total có dấu.
    # KHÔNG tính lại từ:
    # Unit Price * Quantity * Discount
    # --------------------------------------------------------

    chunk["Net_Amount"] = (
        line_total
        .astype("Float64")
        .astype("string")
    )


    # --------------------------------------------------------
    # P. SALES_QUANTITY
    # --------------------------------------------------------

    chunk["Sales_Quantity"] = (
        quantity.where(
            transaction_type.eq(
                "Sale"
            ),
            0
        )
        .astype("Int64")
        .astype("string")
    )


    # --------------------------------------------------------
    # Q. RETURN_QUANTITY
    # --------------------------------------------------------

    chunk["Return_Quantity"] = (
        quantity.where(
            transaction_type.eq(
                "Return"
            ),
            0
        )
        .astype("Int64")
        .astype("string")
    )


    # --------------------------------------------------------
    # R. THỐNG KÊ SALE / RETURN
    # --------------------------------------------------------

    so_sale += int(
        transaction_type
        .eq("Sale")
        .sum()
    )


    so_return += int(
        transaction_type
        .eq("Return")
        .sum()
    )


    tong_dong_transactions_sau += len(
        chunk
    )


    # --------------------------------------------------------
    # S. GHI FILE TẠM
    # --------------------------------------------------------

    if ghi_header:

        chunk.to_csv(
            FILE_TEMP_TRANSACTIONS,
            mode="w",
            index=False,
            header=True,
            encoding="utf-8-sig"
        )

        ghi_header = False

    else:

        chunk.to_csv(
            FILE_TEMP_TRANSACTIONS,
            mode="a",
            index=False,
            header=False,
            encoding="utf-8"
        )


# ============================================================
# 6. ĐỐI SOÁT TRANSACTIONS TRƯỚC KHI THAY FILE
# ============================================================

doi_soat_transactions = (
    tong_dong_transactions_truoc
    ==
    tong_dong_transactions_sau
)


if not doi_soat_transactions:

    if FILE_TEMP_TRANSACTIONS.exists():

        FILE_TEMP_TRANSACTIONS.unlink()

    raise ValueError(
        "Đối soát số dòng transactions KHÔNG ĐẠT."
    )


# ------------------------------------------------------------
# Store lookup là điều kiện bắt buộc.
# Nếu không Lookup được Store, không thay file cũ.
# ------------------------------------------------------------

if so_store_khong_lookup > 0:

    if FILE_TEMP_TRANSACTIONS.exists():

        FILE_TEMP_TRANSACTIONS.unlink()

    raise ValueError(
        f"Có {so_store_khong_lookup:,} giao dịch "
        "không xác định được Country/Currency theo Store."
    )


# ------------------------------------------------------------
# Currency mismatch chưa xóa dữ liệu ở đây.
# Chỉ ghi nhận để bước 2.3.5 Quality Gate phân loại.
# ------------------------------------------------------------

os.replace(
    FILE_TEMP_TRANSACTIONS,
    FILE_TRANSACTIONS
)


# ============================================================
# 7. XỬ LÝ CUSTOMERS
# ============================================================

print(
    "\nBƯỚC 4/4 - "
    "Tạo Age và Age_Group cho customers.csv..."
)


FILE_TEMP_CUSTOMERS = (
    THU_MUC_PROCESSED
    / "__temp_customers.csv"
)


if FILE_TEMP_CUSTOMERS.exists():

    FILE_TEMP_CUSTOMERS.unlink()


ghi_header = True

tong_dong_customers_truoc = 0
tong_dong_customers_sau = 0

so_loi_tuoi = 0


for chunk in pd.read_csv(
    FILE_CUSTOMERS,
    chunksize=100000,
    dtype=str,
    keep_default_na=False,
    low_memory=False
):

    tong_dong_customers_truoc += len(
        chunk
    )


    # --------------------------------------------------------
    # A. DATE OF BIRTH
    # --------------------------------------------------------

    dob = pd.to_datetime(
        chunk["Date Of Birth"],
        errors="coerce"
    )


    # --------------------------------------------------------
    # B. TÍNH TUỔI CHÍNH XÁC THEO NGÀY THAM CHIẾU
    # --------------------------------------------------------

    age = (
        NGAY_THAM_CHIEU.year
        - dob.dt.year
    )


    chua_den_sinh_nhat = (
        (
            dob.dt.month
            > NGAY_THAM_CHIEU.month
        )
        |
        (
            (
                dob.dt.month
                == NGAY_THAM_CHIEU.month
            )
            &
            (
                dob.dt.day
                > NGAY_THAM_CHIEU.day
            )
        )
    )


    age = (
        age
        - chua_den_sinh_nhat.astype(
            "Int64"
        )
    )


    # --------------------------------------------------------
    # C. KIỂM TRA TUỔI BẤT HỢP LÝ
    # --------------------------------------------------------

    mask_tuoi_loi = (
        age.isna()
        |
        (age < 0)
        |
        (age > 120)
    )


    so_loi_tuoi += int(
        mask_tuoi_loi.sum()
    )


    age = age.mask(
        mask_tuoi_loi,
        pd.NA
    )


    chunk["Age"] = (
        age
        .astype("Int64")
        .astype("string")
    )


    # --------------------------------------------------------
    # D. AGE_GROUP
    # --------------------------------------------------------

    age_group = pd.Series(
        "Unknown",
        index=chunk.index,
        dtype="string"
    )


    age_group.loc[
        age.notna()
        & (age < 18)
    ] = "<18"


    age_group.loc[
        age.between(
            18,
            25,
            inclusive="both"
        )
    ] = "18-25"


    age_group.loc[
        age.between(
            26,
            35,
            inclusive="both"
        )
    ] = "26-35"


    age_group.loc[
        age.between(
            36,
            50,
            inclusive="both"
        )
    ] = "36-50"


    age_group.loc[
        age > 50
    ] = ">50"


    chunk["Age_Group"] = (
        age_group
    )


    tong_dong_customers_sau += len(
        chunk
    )


    # --------------------------------------------------------
    # E. GHI FILE TẠM
    # --------------------------------------------------------

    if ghi_header:

        chunk.to_csv(
            FILE_TEMP_CUSTOMERS,
            mode="w",
            index=False,
            header=True,
            encoding="utf-8-sig"
        )

        ghi_header = False

    else:

        chunk.to_csv(
            FILE_TEMP_CUSTOMERS,
            mode="a",
            index=False,
            header=False,
            encoding="utf-8"
        )


# ============================================================
# 8. ĐỐI SOÁT CUSTOMERS
# ============================================================

doi_soat_customers = (
    tong_dong_customers_truoc
    ==
    tong_dong_customers_sau
)


if not doi_soat_customers:

    if FILE_TEMP_CUSTOMERS.exists():

        FILE_TEMP_CUSTOMERS.unlink()

    raise ValueError(
        "Đối soát số dòng customers KHÔNG ĐẠT."
    )


os.replace(
    FILE_TEMP_CUSTOMERS,
    FILE_CUSTOMERS
)


# ============================================================
# 9. TẠO BẢNG KIỂM TRA COUNTRY / CURRENCY
# ============================================================

bang_currency_check = pd.DataFrame(
    list(
        tap_currency_check
    ),
    columns=[
        "Store_ID",
        "Country_Code",
        "Currency",
        "Expected_Currency",
        "Currency_Match"
    ]
)


if not bang_currency_check.empty:

    bang_currency_check[
        "Store_ID_Sort"
    ] = pd.to_numeric(
        bang_currency_check[
            "Store_ID"
        ],
        errors="coerce"
    )


    bang_currency_check = (
        bang_currency_check
        .sort_values(
            [
                "Store_ID_Sort",
                "Currency"
            ]
        )
        .drop(
            columns=[
                "Store_ID_Sort"
            ]
        )
        .reset_index(
            drop=True
        )
    )


FILE_KET_QUA_CURRENCY = (
    THU_MUC_KET_QUA
    / "04_Ket_qua_kiem_tra_quoc_gia_tien_te.csv"
)


bang_currency_check.to_csv(
    FILE_KET_QUA_CURRENCY,
    index=False,
    encoding="utf-8-sig"
)


# ============================================================
# 10. TẠO BẢNG KẾT QUẢ 2.3.4
# ============================================================

ket_qua = [

    {
        "Tep_du_lieu":
            "transactions.csv",

        "So_dong_truoc":
            tong_dong_transactions_truoc,

        "So_dong_sau":
            tong_dong_transactions_sau,

        "Thuoc_tinh_tao_moi":
            (
                "Transaction_Date; "
                "Transaction_Time; "
                "Is_Return; "
                "Net_Amount; "
                "Sales_Quantity; "
                "Return_Quantity; "
                "Country_Code; "
                "Expected_Currency; "
                "Currency_Match"
            ),

        "Store_khong_lookup":
            so_store_khong_lookup,

        "Currency_thieu":
            so_currency_thieu,

        "Currency_khong_khop":
            so_currency_khong_khop,

        "Doi_soat":
            (
                "DAT"
                if doi_soat_transactions
                else "KHONG_DAT"
            )
    },

    {
        "Tep_du_lieu":
            "customers.csv",

        "So_dong_truoc":
            tong_dong_customers_truoc,

        "So_dong_sau":
            tong_dong_customers_sau,

        "Thuoc_tinh_tao_moi":
            "Age; Age_Group",

        "Store_khong_lookup":
            0,

        "Currency_thieu":
            0,

        "Currency_khong_khop":
            0,

        "Doi_soat":
            (
                "DAT"
                if doi_soat_customers
                else "KHONG_DAT"
            )
    }
]


bang_ket_qua = pd.DataFrame(
    ket_qua
)


FILE_KET_QUA = (
    THU_MUC_KET_QUA
    / "04_Ket_qua_thuoc_tinh_dan_xuat.csv"
)


bang_ket_qua.to_csv(
    FILE_KET_QUA,
    index=False,
    encoding="utf-8-sig"
)


# ============================================================
# 11. HIỂN THỊ KẾT QUẢ
# ============================================================

print("\n")
print("=" * 95)
print("KẾT QUẢ 2.3.4")
print("=" * 95)


print(
    f"Ngày tham chiếu tính tuổi      : "
    f"{NGAY_THAM_CHIEU.strftime('%Y-%m-%d')}"
)


print(
    f"Số giao dịch Sale              : "
    f"{so_sale:,}"
)


print(
    f"Số giao dịch Return            : "
    f"{so_return:,}"
)


print(
    f"Số tuổi bất hợp lý             : "
    f"{so_loi_tuoi:,}"
)


print(
    f"Store không Lookup được        : "
    f"{so_store_khong_lookup:,}"
)


print(
    f"Currency thiếu/rỗng            : "
    f"{so_currency_thieu:,}"
)


print(
    f"Currency không khớp Country    : "
    f"{so_currency_khong_khop:,}"
)


print("\n")
print("-" * 95)
print("KIỂM TRA COUNTRY - CURRENCY THEO STORE")
print("-" * 95)


if not bang_currency_check.empty:

    print(
        bang_currency_check.to_string(
            index=False
        )
    )

else:

    print(
        "Không có dữ liệu kiểm tra."
    )


print("\n")
print("-" * 95)
print("ĐỐI SOÁT SỐ DÒNG")
print("-" * 95)


print(
    bang_ket_qua[
        [
            "Tep_du_lieu",
            "So_dong_truoc",
            "So_dong_sau",
            "Currency_khong_khop",
            "Doi_soat"
        ]
    ].to_string(
        index=False
    )
)


print("\nĐã lưu kết quả tại:")
print(FILE_KET_QUA)

print(
    FILE_KET_QUA_CURRENCY
)


if (
    doi_soat_transactions
    and doi_soat_customers
    and so_store_khong_lookup == 0
):

    print(
        "\nĐối soát: ĐẠT"
    )

else:

    print(
        "\nĐối soát: KHÔNG ĐẠT"
    )


print(
    "\nHOÀN TẤT 2.3.4"
)