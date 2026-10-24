# -*- coding: utf-8 -*-import pandas as pd
import pandas as pd
import numpy as np
from pathlib import Path
import os


# ============================================================
# 2.3.5. PHÂN LOẠI VALID / ERROR / REVIEW
# ============================================================

THU_MUC_GOC = Path(__file__).resolve().parents[2]

THU_MUC_PROCESSED = (
    THU_MUC_GOC / "data" / "processed"
)

THU_MUC_REJECT = (
    THU_MUC_GOC / "data" / "reject"
)

THU_MUC_REVIEW = (
    THU_MUC_GOC / "data" / "review"
)

THU_MUC_KET_QUA = (
    THU_MUC_GOC
    / "data"
    / "ket_qua_tien_xu_ly"
)


for thu_muc in [
    THU_MUC_REJECT,
    THU_MUC_REVIEW,
    THU_MUC_KET_QUA
]:
    thu_muc.mkdir(
        parents=True,
        exist_ok=True
    )


print("=" * 90)
print("2.3.5 - Phan loai du lieu VALID / ERROR / REVIEW")
print("=" * 90)


# ============================================================
# 1. ĐỌC CÁC BẢNG THAM CHIẾU
# ============================================================

print("\nBƯỚC 1/4 - Đọc các bảng tham chiếu...")


customers = pd.read_csv(
    THU_MUC_PROCESSED / "customers.csv",
    usecols=["Customer ID"],
    dtype=str,
    keep_default_na=False
)

products = pd.read_csv(
    THU_MUC_PROCESSED / "products.csv",
    usecols=["Product ID"],
    dtype=str,
    keep_default_na=False
)

stores = pd.read_csv(
    THU_MUC_PROCESSED / "stores.csv",
    usecols=["Store ID"],
    dtype=str,
    keep_default_na=False
)

employees = pd.read_csv(
    THU_MUC_PROCESSED / "employees.csv",
    usecols=[
        "Employee ID",
        "Store ID"
    ],
    dtype=str,
    keep_default_na=False
)


def trim(series):
    return (
        series
        .astype("string")
        .str.strip()
    )


customers["Customer ID"] = trim(
    customers["Customer ID"]
)

products["Product ID"] = trim(
    products["Product ID"]
)

stores["Store ID"] = trim(
    stores["Store ID"]
)

employees["Employee ID"] = trim(
    employees["Employee ID"]
)

employees["Store ID"] = trim(
    employees["Store ID"]
)


tap_customer = set(
    customers["Customer ID"]
)

tap_product = set(
    products["Product ID"]
)

tap_store = set(
    stores["Store ID"]
)

tap_employee = set(
    employees["Employee ID"]
)


employee_store = dict(
    zip(
        employees["Employee ID"],
        employees["Store ID"]
    )
)


# ============================================================
# 2. QUALITY GATE CHO TRANSACTIONS
# ============================================================

print(
    "\nBƯỚC 2/4 - "
    "Kiểm tra transactions.csv..."
)


file_transactions = (
    THU_MUC_PROCESSED
    / "transactions.csv"
)

file_temp_valid = (
    THU_MUC_PROCESSED
    / "__temp_valid_transactions.csv"
)

file_error_transactions = (
    THU_MUC_REJECT
    / "transactions_error.csv"
)


for f in [
    file_temp_valid,
    file_error_transactions
]:
    if f.exists():
        f.unlink()


dem_rule = {
    "R1": 0,
    "R2": 0,
    "R3": 0,
    "R4": 0,
    "R5": 0,
    "R6": 0,
    "R7": 0,
    "R8": 0,
    "R11": 0,
    "R12": 0
}


tong_dong = 0
tong_valid = 0
tong_error = 0

ghi_header_valid = True
ghi_header_error = True

danh_sach_cot = None


for chunk in pd.read_csv(
    file_transactions,
    chunksize=100000,
    dtype=str,
    keep_default_na=False,
    low_memory=False
):

    tong_dong += len(chunk)

    if danh_sach_cot is None:
        danh_sach_cot = list(
            chunk.columns
        )


    # --------------------------------------------------------
    # Chuẩn hóa các khóa
    # --------------------------------------------------------

    for cot in [
        "Customer ID",
        "Product ID",
        "Store ID",
        "Employee ID",
        "Transaction Type"
    ]:
        chunk[cot] = trim(
            chunk[cot]
        )


    quantity = pd.to_numeric(
        chunk["Quantity"],
        errors="coerce"
    )

    unit_price = pd.to_numeric(
        chunk["Unit Price"],
        errors="coerce"
    )

    discount = pd.to_numeric(
        chunk["Discount"],
        errors="coerce"
    )

    line_total = pd.to_numeric(
        chunk["Line Total"],
        errors="coerce"
    )


    # ========================================================
    # R1 - Quantity > 0
    # ========================================================

    r1 = (
        quantity.isna()
        | (quantity <= 0)
    )


    # ========================================================
    # R2 - Unit Price > 0
    # ========================================================

    r2 = (
        unit_price.isna()
        | (unit_price <= 0)
    )


    # ========================================================
    # R3 - Discount thuộc [0,1]
    # ========================================================

    r3 = (
        discount.isna()
        | (discount < 0)
        | (discount > 1)
    )


    # ========================================================
    # R4 - Product ID tồn tại
    # ========================================================

    r4 = (
        ~chunk["Product ID"]
        .isin(tap_product)
    )


    # ========================================================
    # R5 - Store ID tồn tại
    # ========================================================

    r5 = (
        ~chunk["Store ID"]
        .isin(tap_store)
    )


    # ========================================================
    # R6 - Employee ID tồn tại
    # ========================================================

    r6 = (
        ~chunk["Employee ID"]
        .isin(tap_employee)
    )


    # ========================================================
    # R7 - Customer ID tồn tại
    # ========================================================

    r7 = (
        ~chunk["Customer ID"]
        .isin(tap_customer)
    )


    # ========================================================
    # R8 - Employee thuộc đúng Store
    # ========================================================

    store_cua_employee = (
        chunk["Employee ID"]
        .map(employee_store)
    )


    r8 = (
        store_cua_employee.notna()
        &
        (
            store_cua_employee
            != chunk["Store ID"]
        )
    )


    # ========================================================
    # R11 - Sale / Return
    # ========================================================

    r11 = (
        ~chunk["Transaction Type"]
        .isin(
            [
                "Sale",
                "Return"
            ]
        )
    )


    # ========================================================
    # R12 - Sale dương / Return âm
    # ========================================================

    sai_sale = (
        chunk["Transaction Type"]
        .eq("Sale")
        &
        (
            line_total.isna()
            | (line_total <= 0)
        )
    )


    sai_return = (
        chunk["Transaction Type"]
        .eq("Return")
        &
        (
            line_total.isna()
            | (line_total >= 0)
        )
    )


    r12 = (
        sai_sale
        | sai_return
    )


    cac_rule = {
        "R1": r1,
        "R2": r2,
        "R3": r3,
        "R4": r4,
        "R5": r5,
        "R6": r6,
        "R7": r7,
        "R8": r8,
        "R11": r11,
        "R12": r12
    }


    # --------------------------------------------------------
    # Đếm số vi phạm từng rule
    # --------------------------------------------------------

    for ma_rule, mask in cac_rule.items():

        dem_rule[ma_rule] += int(
            mask.sum()
        )


    # --------------------------------------------------------
    # Tạo cột Error_Rules
    # --------------------------------------------------------

    error_rules = np.full(
        len(chunk),
        "",
        dtype=object
    )


    for ma_rule, mask in cac_rule.items():

        vi_tri = mask.to_numpy()

        error_rules[vi_tri] = np.where(
            error_rules[vi_tri] == "",
            ma_rule,
            error_rules[vi_tri]
            + ";"
            + ma_rule
        )


    mask_error = (
        error_rules != ""
    )

    mask_valid = (
        ~mask_error
    )


    # ========================================================
    # VALID
    # ========================================================

    chunk_valid = (
        chunk.loc[
            mask_valid
        ]
        .copy()
    )


    tong_valid += len(
        chunk_valid
    )


    chunk_valid.to_csv(
        file_temp_valid,
        mode=(
            "w"
            if ghi_header_valid
            else "a"
        ),
        index=False,
        header=ghi_header_valid,
        encoding=(
            "utf-8-sig"
            if ghi_header_valid
            else "utf-8"
        )
    )


    ghi_header_valid = False


    # ========================================================
    # ERROR
    # ========================================================

    chunk_error = (
        chunk.loc[
            mask_error
        ]
        .copy()
    )


    if len(chunk_error) > 0:

        chunk_error["Error_Rules"] = (
            error_rules[
                mask_error
            ]
        )


        chunk_error.to_csv(
            file_error_transactions,
            mode=(
                "w"
                if ghi_header_error
                else "a"
            ),
            index=False,
            header=ghi_header_error,
            encoding=(
                "utf-8-sig"
                if ghi_header_error
                else "utf-8"
            )
        )


        ghi_header_error = False


        tong_error += len(
            chunk_error
        )


# Nếu không có Error vẫn tạo file header
if tong_error == 0:

    pd.DataFrame(
        columns=(
            danh_sach_cot
            + ["Error_Rules"]
        )
    ).to_csv(
        file_error_transactions,
        index=False,
        encoding="utf-8-sig"
    )


# processed chỉ giữ dữ liệu hợp lệ
os.replace(
    file_temp_valid,
    file_transactions
)


# ============================================================
# 3. R9 / R10 CHO DISCOUNTS
# ============================================================

print(
    "\nBƯỚC 3/4 - "
    "Kiểm tra discounts.csv..."
)


file_discounts = (
    THU_MUC_PROCESSED
    / "discounts.csv"
)


discounts = pd.read_csv(
    file_discounts,
    dtype=str,
    keep_default_na=False
)


start = pd.to_datetime(
    discounts["Start"],
    errors="coerce"
)

end = pd.to_datetime(
    discounts["End"],
    errors="coerce"
)

discount_value = pd.to_numeric(
    discounts["Discount"],
    errors="coerce"
)


# R9
r9 = (
    start.isna()
    | end.isna()
    | (start > end)
)


# R10
r10 = (
    discount_value.isna()
    | (discount_value < 0)
    | (discount_value > 1)
)


dem_rule["R9"] = int(
    r9.sum()
)

dem_rule["R10"] = int(
    r10.sum()
)


discount_error = (
    r9 | r10
)


discounts_valid = (
    discounts.loc[
        ~discount_error
    ]
    .copy()
)


discounts_error = (
    discounts.loc[
        discount_error
    ]
    .copy()
)


if len(discounts_error) > 0:

    discounts_error[
        "Error_Rules"
    ] = np.where(
        r9[discount_error],
        "R9",
        ""
    )

    discounts_error[
        "Error_Rules"
    ] += np.where(
        r10[discount_error],
        ";R10",
        ""
    )

    discounts_error[
        "Error_Rules"
    ] = (
        discounts_error[
            "Error_Rules"
        ]
        .str.strip(";")
    )


file_error_discounts = (
    THU_MUC_REJECT
    / "discounts_error.csv"
)


discounts_error.to_csv(
    file_error_discounts,
    index=False,
    encoding="utf-8-sig"
)


discounts_valid.to_csv(
    file_discounts,
    index=False,
    encoding="utf-8-sig"
)


tong_discount = len(discounts)

valid_discount = len(
    discounts_valid
)

error_discount = len(
    discounts_error
)


# ============================================================
# 4. R13 - REVIEW, KHÔNG ERROR
# ============================================================

print(
    "\nBƯỚC 4/4 - "
    "Kiểm tra lại dữ liệu Review R13..."
)


file_review = (
    THU_MUC_REVIEW
    / "transactions_trung_khoa_can_kiem_tra.csv"
)


so_dong_review = 0
so_nhom_review = 0


if file_review.exists():

    review = pd.read_csv(
        file_review,
        dtype=str,
        keep_default_na=False
    )


    # Sau khi đã xóa exact duplicate,
    # kiểm tra lại khóa nào THỰC SỰ còn trùng
    mask_trung = (
        review.duplicated(
            subset=[
                "Invoice ID",
                "Line"
            ],
            keep=False
        )
    )


    review = (
        review.loc[
            mask_trung
        ]
        .copy()
    )


    so_dong_review = len(
        review
    )


    if so_dong_review > 0:

        so_nhom_review = (
            review[
                [
                    "Invoice ID",
                    "Line"
                ]
            ]
            .drop_duplicates()
            .shape[0]
        )


    review.to_csv(
        file_review,
        index=False,
        encoding="utf-8-sig"
    )


# ============================================================
# 5. ĐỐI SOÁT
# ============================================================

doi_soat_transactions = (
    tong_dong
    ==
    tong_valid
    + tong_error
)


doi_soat_discounts = (
    tong_discount
    ==
    valid_discount
    + error_discount
)


# ============================================================
# 6. LƯU KẾT QUẢ
# ============================================================

bang_tong_hop = pd.DataFrame(
    [
        {
            "Tep_du_lieu":
                "transactions.csv",

            "So_dong_vao":
                tong_dong,

            "Valid":
                tong_valid,

            "Error":
                tong_error,

            "Doi_soat":
                (
                    "DAT"
                    if doi_soat_transactions
                    else "KHONG_DAT"
                )
        },

        {
            "Tep_du_lieu":
                "discounts.csv",

            "So_dong_vao":
                tong_discount,

            "Valid":
                valid_discount,

            "Error":
                error_discount,

            "Doi_soat":
                (
                    "DAT"
                    if doi_soat_discounts
                    else "KHONG_DAT"
                )
        }
    ]
)


file_ket_qua = (
    THU_MUC_KET_QUA
    / "05_Ket_qua_phan_loai_valid_error.csv"
)


bang_tong_hop.to_csv(
    file_ket_qua,
    index=False,
    encoding="utf-8-sig"
)


# ============================================================
# 7. HIỂN THỊ
# ============================================================

print("\n")
print("=" * 90)
print("KẾT QUẢ 2.3.5")
print("=" * 90)


print("\nTRANSACTIONS")

print(
    f"Số dòng vào : "
    f"{tong_dong:,}"
)

print(
    f"Valid       : "
    f"{tong_valid:,}"
)

print(
    f"Error       : "
    f"{tong_error:,}"
)

print(
    f"Đối soát    : "
    f"{'ĐẠT' if doi_soat_transactions else 'KHÔNG ĐẠT'}"
)


print("\nDISCOUNTS")

print(
    f"Số dòng vào : "
    f"{tong_discount:,}"
)

print(
    f"Valid       : "
    f"{valid_discount:,}"
)

print(
    f"Error       : "
    f"{error_discount:,}"
)


print("\nR13 - REVIEW")

print(
    f"Số nhóm khóa còn trùng : "
    f"{so_nhom_review:,}"
)

print(
    f"Số dòng cần review     : "
    f"{so_dong_review:,}"
)


print(
    "\nLưu ý: Review là tập con của Valid, "
    "không cộng vào tổng dòng."
)


print("\nCHI TIẾT RULE")


for i in range(
    1,
    14
):

    rule = f"R{i}"


    if rule == "R13":

        print(
            f"{rule:<4}: "
            f"{so_dong_review:,} dòng REVIEW"
        )

    else:

        print(
            f"{rule:<4}: "
            f"{dem_rule.get(rule, 0):,} vi phạm"
        )


print("\nĐã lưu kết quả tại:")
print(file_ket_qua)

print("\nHOÀN TẤT 2.3.5")