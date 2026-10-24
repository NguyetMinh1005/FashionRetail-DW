# -*- coding: utf-8 -*-import pandas as pd
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
# customers:
# - Age
# - Age_Group
#
# KHÔNG tạo Year / Quarter / Month / Season ở Fact.
# Các thuộc tính thời gian này sẽ thuộc Dim_Date.
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


print("=" * 85)
print("2.3.4 - XÂY DỰNG CÁC THUỘC TÍNH DẪN XUẤT")
print("=" * 85)


# ============================================================
# 2. XÁC ĐỊNH NGÀY THAM CHIẾU
#
# Lấy ngày giao dịch lớn nhất trong dataset.
# Dùng ngày này để tính Age.
# ============================================================

print("\nBƯỚC 1/3 - Xác định ngày tham chiếu...")


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

    if pd.notna(max_chunk):

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
    ngay_lon_nhat.normalize()
)


print(
    "Ngày tham chiếu tính tuổi: "
    f"{NGAY_THAM_CHIEU.strftime('%Y-%m-%d')}"
)


# ============================================================
# 3. XỬ LÝ TRANSACTIONS
# ============================================================

print(
    "\nBƯỚC 2/3 - "
    "Tạo thuộc tính dẫn xuất cho transactions.csv..."
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
    # Chuyển Date
    # --------------------------------------------------------

    ngay_giao_dich = pd.to_datetime(
        chunk["Date"],
        errors="coerce"
    )


    if ngay_giao_dich.isna().any():

        raise ValueError(
            "Phát hiện Date không chuyển được "
            "sang datetime."
        )


    # --------------------------------------------------------
    # Transaction_Date
    # --------------------------------------------------------

    chunk["Transaction_Date"] = (
        ngay_giao_dich
        .dt.strftime("%Y-%m-%d")
    )


    # --------------------------------------------------------
    # Transaction_Time
    # --------------------------------------------------------

    chunk["Transaction_Time"] = (
        ngay_giao_dich
        .dt.strftime("%H:%M:%S")
    )


    # --------------------------------------------------------
    # Transaction Type
    # --------------------------------------------------------

    transaction_type = (
        chunk["Transaction Type"]
        .astype(str)
        .str.strip()
    )


    # --------------------------------------------------------
    # Is_Return
    #
    # Return = 1
    # Sale   = 0
    # --------------------------------------------------------

    chunk["Is_Return"] = (
        transaction_type
        .eq("Return")
        .astype(int)
    )


    # --------------------------------------------------------
    # Chuyển Quantity / Line Total sang số
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
    # Net_Amount
    #
    # Dữ liệu 2.2 đã xác nhận:
    # Sale   -> Line Total dương
    # Return -> Line Total âm
    #
    # Vì vậy sử dụng trực tiếp Line Total có dấu.
    # KHÔNG tính lại từ Unit Price * Quantity * Discount.
    # --------------------------------------------------------

    chunk["Net_Amount"] = (
        line_total
        .astype("Float64")
        .astype("string")
    )


    # --------------------------------------------------------
    # Sales_Quantity
    # --------------------------------------------------------

    chunk["Sales_Quantity"] = (
        quantity.where(
            transaction_type.eq("Sale"),
            0
        )
        .astype("Int64")
        .astype("string")
    )


    # --------------------------------------------------------
    # Return_Quantity
    # --------------------------------------------------------

    chunk["Return_Quantity"] = (
        quantity.where(
            transaction_type.eq("Return"),
            0
        )
        .astype("Int64")
        .astype("string")
    )


    # --------------------------------------------------------
    # Thống kê
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
    # Ghi file
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


# Thay file transactions cũ
os.replace(
    FILE_TEMP_TRANSACTIONS,
    FILE_TRANSACTIONS
)


# ============================================================
# 4. XỬ LÝ CUSTOMERS
# ============================================================

print(
    "\nBƯỚC 3/3 - "
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
    # Date Of Birth
    # --------------------------------------------------------

    dob = pd.to_datetime(
        chunk["Date Of Birth"],
        errors="coerce"
    )


    # --------------------------------------------------------
    # Tính tuổi chính xác theo ngày tham chiếu
    #
    # Tuổi =
    # năm tham chiếu - năm sinh
    # - 1 nếu chưa đến sinh nhật trong năm đó
    # --------------------------------------------------------

    age = (
        NGAY_THAM_CHIEU.year
        - dob.dt.year
    )


    chua_den_sinh_nhat = (
        (dob.dt.month > NGAY_THAM_CHIEU.month)
        |
        (
            (dob.dt.month == NGAY_THAM_CHIEU.month)
            &
            (dob.dt.day > NGAY_THAM_CHIEU.day)
        )
    )


    age = (
        age
        - chua_den_sinh_nhat.astype("Int64")
    )


    # --------------------------------------------------------
    # Kiểm tra tuổi bất hợp lý
    # --------------------------------------------------------

    mask_tuoi_loi = (
        age.isna()
        | (age < 0)
        | (age > 120)
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
    # Age_Group
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
    # Ghi file
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


# Thay customers cũ
os.replace(
    FILE_TEMP_CUSTOMERS,
    FILE_CUSTOMERS
)


# ============================================================
# 5. ĐỐI SOÁT
# ============================================================

doi_soat_transactions = (
    tong_dong_transactions_truoc
    ==
    tong_dong_transactions_sau
)

doi_soat_customers = (
    tong_dong_customers_truoc
    ==
    tong_dong_customers_sau
)


# ============================================================
# 6. TẠO BẢNG KẾT QUẢ
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
                "Return_Quantity"
            ),

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
# 7. HIỂN THỊ KẾT QUẢ
# ============================================================

print("\n")
print("=" * 85)
print("KẾT QUẢ 2.3.4")
print("=" * 85)


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


print("\n")


print(
    bang_ket_qua[
        [
            "Tep_du_lieu",
            "So_dong_truoc",
            "So_dong_sau",
            "Doi_soat"
        ]
    ].to_string(
        index=False
    )
)


print("\nĐã lưu kết quả tại:")
print(FILE_KET_QUA)


if (
    doi_soat_transactions
    and doi_soat_customers
):

    print("\nĐối soát: ĐẠT")

else:

    print("\nĐối soát: KHÔNG ĐẠT")


print("\nHOÀN TẤT 2.3.4")