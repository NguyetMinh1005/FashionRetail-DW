# -*- coding: utf-8 -*-

import pandas as pd
import numpy as np
from pathlib import Path
import os


# ============================================================
# 2.3.5. PHÂN LOẠI VALID / ERROR / REVIEW
#
# TRANSACTIONS:
#
# R1  : Quantity > 0
# R2  : Unit Price > 0
# R3  : 0 <= Discount <= 1
# R4  : Product ID tồn tại
# R5  : Store ID tồn tại
# R6  : Employee ID tồn tại
# R7  : Customer ID tồn tại
# R8  : Employee thuộc đúng Store
# R11 : Transaction Type IN ('Sale', 'Return')
# R12 : Sale Line Total > 0 / Return Line Total < 0
#
# BỔ SUNG DỮ LIỆU ĐA QUỐC GIA:
#
# R14 : Country_Code phải xác định được
# R15 : Currency thuộc USD / CNY / EUR / GBP
# R16 : Currency = Expected_Currency
# R17 : Exchange_Rate_To_USD > 0
# R18 : Mọi giao dịch phải có tỷ giá
#
# DISCOUNTS:
#
# R9  : Start <= End
# R10 : 0 <= Discount <= 1
#
# REVIEW:
#
# R13 : (Invoice ID, Line) còn trùng
#
# Lưu ý:
# - R13 chỉ REVIEW, KHÔNG ERROR.
# - R14 -> R18 là ERROR nếu vi phạm.
# ============================================================


# ============================================================
# 1. THƯ MỤC
# ============================================================

THU_MUC_GOC = (
    Path(__file__)
    .resolve()
    .parents[2]
)


THU_MUC_PROCESSED = (
    THU_MUC_GOC
    / "data"
    / "processed"
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


for thu_muc in [
    THU_MUC_REJECT,
    THU_MUC_REVIEW,
    THU_MUC_KET_QUA
]:

    thu_muc.mkdir(
        parents=True,
        exist_ok=True
    )


print("=" * 95)
print(
    "2.3.5 - PHÂN LOẠI DỮ LIỆU "
    "VALID / ERROR / REVIEW"
)
print("=" * 95)


# ============================================================
# 2. HÀM TRIM
# ============================================================

def trim(series):

    return (
        series
        .astype("string")
        .str.strip()
    )


# ============================================================
# 3. ĐỌC CÁC BẢNG THAM CHIẾU
# ============================================================

print(
    "\nBƯỚC 1/4 - "
    "Đọc các bảng tham chiếu..."
)


customers = pd.read_csv(
    THU_MUC_PROCESSED / "customers.csv",
    usecols=[
        "Customer ID"
    ],
    dtype=str,
    keep_default_na=False
)


products = pd.read_csv(
    THU_MUC_PROCESSED / "products.csv",
    usecols=[
        "Product ID"
    ],
    dtype=str,
    keep_default_na=False
)


stores = pd.read_csv(
    THU_MUC_PROCESSED / "stores.csv",
    usecols=[
        "Store ID"
    ],
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


# ------------------------------------------------------------
# Chuẩn hóa khóa
# ------------------------------------------------------------

customers[
    "Customer ID"
] = trim(
    customers[
        "Customer ID"
    ]
)


products[
    "Product ID"
] = trim(
    products[
        "Product ID"
    ]
)


stores[
    "Store ID"
] = trim(
    stores[
        "Store ID"
    ]
)


employees[
    "Employee ID"
] = trim(
    employees[
        "Employee ID"
    ]
)


employees[
    "Store ID"
] = trim(
    employees[
        "Store ID"
    ]
)


# ------------------------------------------------------------
# Tạo tập khóa
# ------------------------------------------------------------

tap_customer = set(
    customers[
        "Customer ID"
    ]
)


tap_product = set(
    products[
        "Product ID"
    ]
)


tap_store = set(
    stores[
        "Store ID"
    ]
)


tap_employee = set(
    employees[
        "Employee ID"
    ]
)


# Employee -> Store
employee_store = dict(
    zip(
        employees[
            "Employee ID"
        ],
        employees[
            "Store ID"
        ]
    )
)


print(
    f"Số Customer tham chiếu : "
    f"{len(tap_customer):,}"
)

print(
    f"Số Product tham chiếu  : "
    f"{len(tap_product):,}"
)

print(
    f"Số Store tham chiếu    : "
    f"{len(tap_store):,}"
)

print(
    f"Số Employee tham chiếu : "
    f"{len(tap_employee):,}"
)


# ============================================================
# 4. QUALITY GATE CHO TRANSACTIONS
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


# ------------------------------------------------------------
# Bộ đếm rule
# ------------------------------------------------------------

dem_rule = {

    "R1": 0,
    "R2": 0,
    "R3": 0,
    "R4": 0,
    "R5": 0,
    "R6": 0,
    "R7": 0,
    "R8": 0,

    "R9": 0,
    "R10": 0,

    "R11": 0,
    "R12": 0,

    # R13 là REVIEW

    "R14": 0,
    "R15": 0,
    "R16": 0,
    "R17": 0,
    "R18": 0
}


tong_dong = 0
tong_valid = 0
tong_error = 0

ghi_header_valid = True
ghi_header_error = True

danh_sach_cot = None


# Currency hợp lệ trong dataset
VALID_CURRENCIES = {
    "USD",
    "CNY",
    "EUR",
    "GBP"
}


# ============================================================
# 5. ĐỌC TRANSACTIONS THEO CHUNK
# ============================================================

for chunk in pd.read_csv(
    file_transactions,
    chunksize=100000,
    dtype=str,
    keep_default_na=False,
    low_memory=False
):

    tong_dong += len(
        chunk
    )


    if danh_sach_cot is None:

        danh_sach_cot = list(
            chunk.columns
        )


    # ========================================================
    # A. KIỂM TRA CÁC CỘT BẮT BUỘC
    # ========================================================

    CAC_COT_BAT_BUOC = [

        "Customer ID",
        "Product ID",
        "Store ID",
        "Employee ID",

        "Quantity",
        "Unit Price",
        "Discount",
        "Line Total",

        "Transaction Type",

        # Bổ sung từ 2.3.3 / 2.3.4
        "Country_Code",
        "Currency",
        "Expected_Currency",

        # Bổ sung từ 2.3.4C
        "Exchange_Rate_To_USD"
    ]


    cot_thieu = [
        cot
        for cot in CAC_COT_BAT_BUOC
        if cot not in chunk.columns
    ]


    if cot_thieu:

        if file_temp_valid.exists():

            file_temp_valid.unlink()


        raise ValueError(

            "\ntransactions.csv thiếu các cột:\n"

            + ", ".join(
                cot_thieu
            )

            + "\n\nHãy kiểm tra đã chạy:"
            "\n03_Chuan_hoa_du_lieu.py"
            "\n04_Tao_thuoc_tinh_dan_xuat.py"
            "\n04C_Quy_doi_tien_te_USD.py"
        )


    # ========================================================
    # B. CHUẨN HÓA TEXT
    # ========================================================

    for cot in [

        "Customer ID",
        "Product ID",
        "Store ID",
        "Employee ID",
        "Transaction Type",

        "Country_Code",
        "Currency",
        "Expected_Currency"

    ]:

        chunk[cot] = trim(
            chunk[cot]
        )


    chunk[
        "Country_Code"
    ] = (
        chunk[
            "Country_Code"
        ]
        .str.upper()
    )


    chunk[
        "Currency"
    ] = (
        chunk[
            "Currency"
        ]
        .str.upper()
    )


    chunk[
        "Expected_Currency"
    ] = (
        chunk[
            "Expected_Currency"
        ]
        .str.upper()
    )


    # ========================================================
    # C. CHUYỂN DỮ LIỆU SỐ
    # ========================================================

    quantity = pd.to_numeric(
        chunk[
            "Quantity"
        ],
        errors="coerce"
    )


    unit_price = pd.to_numeric(
        chunk[
            "Unit Price"
        ],
        errors="coerce"
    )


    discount = pd.to_numeric(
        chunk[
            "Discount"
        ],
        errors="coerce"
    )


    line_total = pd.to_numeric(
        chunk[
            "Line Total"
        ],
        errors="coerce"
    )


    exchange_rate = pd.to_numeric(
        chunk[
            "Exchange_Rate_To_USD"
        ],
        errors="coerce"
    )


    # ========================================================
    # R1 - Quantity > 0
    # ========================================================

    r1 = (
        quantity.isna()
        |
        (
            quantity
            <= 0
        )
    )


    # ========================================================
    # R2 - Unit Price > 0
    # ========================================================

    r2 = (
        unit_price.isna()
        |
        (
            unit_price
            <= 0
        )
    )


    # ========================================================
    # R3 - Discount thuộc [0,1]
    # ========================================================

    r3 = (
        discount.isna()
        |
        (
            discount
            < 0
        )
        |
        (
            discount
            > 1
        )
    )


    # ========================================================
    # R4 - Product ID tồn tại
    # ========================================================

    r4 = (
        ~chunk[
            "Product ID"
        ]
        .isin(
            tap_product
        )
    )


    # ========================================================
    # R5 - Store ID tồn tại
    # ========================================================

    r5 = (
        ~chunk[
            "Store ID"
        ]
        .isin(
            tap_store
        )
    )


    # ========================================================
    # R6 - Employee ID tồn tại
    # ========================================================

    r6 = (
        ~chunk[
            "Employee ID"
        ]
        .isin(
            tap_employee
        )
    )


    # ========================================================
    # R7 - Customer ID tồn tại
    # ========================================================

    r7 = (
        ~chunk[
            "Customer ID"
        ]
        .isin(
            tap_customer
        )
    )


    # ========================================================
    # R8 - Employee thuộc đúng Store
    # ========================================================

    store_cua_employee = (
        chunk[
            "Employee ID"
        ]
        .map(
            employee_store
        )
    )


    r8 = (
        store_cua_employee.notna()
        &
        (
            store_cua_employee
            != chunk[
                "Store ID"
            ]
        )
    )


    # ========================================================
    # R11 - Transaction Type
    # ========================================================

    r11 = (

        ~chunk[
            "Transaction Type"
        ]
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

        chunk[
            "Transaction Type"
        ]
        .eq(
            "Sale"
        )

        &

        (
            line_total.isna()

            |

            (
                line_total
                <= 0
            )
        )
    )


    sai_return = (

        chunk[
            "Transaction Type"
        ]
        .eq(
            "Return"
        )

        &

        (
            line_total.isna()

            |

            (
                line_total
                >= 0
            )
        )
    )


    r12 = (
        sai_sale
        |
        sai_return
    )


    # ========================================================
    # R14 - Country_Code phải xác định được
    # ========================================================

    r14 = (

        chunk[
            "Country_Code"
        ]
        .isna()

        |

        chunk[
            "Country_Code"
        ]
        .eq(
            ""
        )

        |

        chunk[
            "Country_Code"
        ]
        .eq(
            "UNKNOWN"
        )
    )


    # ========================================================
    # R15 - Currency hợp lệ
    #
    # Chỉ chấp nhận:
    # USD / CNY / EUR / GBP
    # ========================================================

    r15 = (

        chunk[
            "Currency"
        ]
        .isna()

        |

        chunk[
            "Currency"
        ]
        .eq(
            ""
        )

        |

        ~chunk[
            "Currency"
        ]
        .isin(
            VALID_CURRENCIES
        )
    )


    # ========================================================
    # R16 - Currency phải phù hợp Country
    #
    # Currency thực tế
    # =
    # Expected_Currency theo Store/Country
    # ========================================================

    r16 = (

        chunk[
            "Expected_Currency"
        ]
        .isna()

        |

        chunk[
            "Expected_Currency"
        ]
        .eq(
            ""
        )

        |

        (
            chunk[
                "Currency"
            ]
            !=
            chunk[
                "Expected_Currency"
            ]
        )
    )


    # ========================================================
    # R18 - Mọi giao dịch phải có tỷ giá
    #
    # Đặt R18 trước R17 về mặt logic:
    # NaN / rỗng / không chuyển được sang số
    # ========================================================

    r18 = (
        exchange_rate.isna()
    )


    # ========================================================
    # R17 - Exchange Rate phải > 0
    #
    # Chỉ kiểm tra khi đã có tỷ giá.
    # Tránh 1 dòng vừa R17 vừa R18.
    # ========================================================

    r17 = (

        exchange_rate.notna()

        &

        (
            exchange_rate
            <= 0
        )
    )


    # ========================================================
    # D. TẬP HỢP RULE TRANSACTIONS
    # ========================================================

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
        "R12": r12,

        "R14": r14,
        "R15": r15,
        "R16": r16,
        "R17": r17,
        "R18": r18
    }


    # ========================================================
    # E. ĐẾM SỐ VI PHẠM TỪNG RULE
    # ========================================================

    for ma_rule, mask in (
        cac_rule.items()
    ):

        dem_rule[
            ma_rule
        ] += int(
            mask.sum()
        )


    # ========================================================
    # F. TẠO ERROR_RULES
    # ========================================================

    error_rules = np.full(
        len(
            chunk
        ),
        "",
        dtype=object
    )


    for ma_rule, mask in (
        cac_rule.items()
    ):

        vi_tri = (
            mask
            .to_numpy()
        )


        error_rules[
            vi_tri
        ] = np.where(

            error_rules[
                vi_tri
            ]
            ==
            "",

            ma_rule,

            (
                error_rules[
                    vi_tri
                ]
                + ";"
                + ma_rule
            )
        )


    mask_error = (
        error_rules
        != ""
    )


    mask_valid = (
        ~mask_error
    )


    # ========================================================
    # G. VALID
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


    if (
        len(
            chunk_valid
        )
        > 0
    ):

        chunk_valid.to_csv(

            file_temp_valid,

            mode=(
                "w"
                if ghi_header_valid
                else "a"
            ),

            index=False,

            header=(
                ghi_header_valid
            ),

            encoding=(
                "utf-8-sig"
                if ghi_header_valid
                else "utf-8"
            )
        )


        ghi_header_valid = False


    # ========================================================
    # H. ERROR
    # ========================================================

    chunk_error = (
        chunk.loc[
            mask_error
        ]
        .copy()
    )


    if (
        len(
            chunk_error
        )
        > 0
    ):

        chunk_error[
            "Error_Rules"
        ] = (
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

            header=(
                ghi_header_error
            ),

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


# ============================================================
# 6. TẠO FILE NẾU KHÔNG CÓ VALID / ERROR
# ============================================================

if tong_valid == 0:

    pd.DataFrame(
        columns=(
            danh_sach_cot
            if danh_sach_cot
            else []
        )
    ).to_csv(
        file_temp_valid,
        index=False,
        encoding="utf-8-sig"
    )


if tong_error == 0:

    pd.DataFrame(
        columns=(
            (
                danh_sach_cot
                if danh_sach_cot
                else []
            )
            +
            [
                "Error_Rules"
            ]
        )
    ).to_csv(
        file_error_transactions,
        index=False,
        encoding="utf-8-sig"
    )


# ============================================================
# 7. ĐỐI SOÁT TRANSACTIONS
# ============================================================

doi_soat_transactions = (

    tong_dong

    ==

    (
        tong_valid
        +
        tong_error
    )
)


if not doi_soat_transactions:

    if file_temp_valid.exists():

        file_temp_valid.unlink()


    raise ValueError(
        "Đối soát transactions KHÔNG ĐẠT."
    )


# ------------------------------------------------------------
# Processed chỉ giữ VALID
# ------------------------------------------------------------

os.replace(
    file_temp_valid,
    file_transactions
)


# ============================================================
# 8. R9 / R10 CHO DISCOUNTS
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
    discounts[
        "Start"
    ],
    errors="coerce"
)


end = pd.to_datetime(
    discounts[
        "End"
    ],
    errors="coerce"
)


discount_value = pd.to_numeric(
    discounts[
        "Discount"
    ],
    errors="coerce"
)


# ============================================================
# R9 - Start <= End
# ============================================================

r9 = (

    start.isna()

    |

    end.isna()

    |

    (
        start
        >
        end
    )
)


# ============================================================
# R10 - Discount thuộc [0,1]
# ============================================================

r10 = (

    discount_value.isna()

    |

    (
        discount_value
        < 0
    )

    |

    (
        discount_value
        > 1
    )
)


dem_rule[
    "R9"
] = int(
    r9.sum()
)


dem_rule[
    "R10"
] = int(
    r10.sum()
)


discount_error = (
    r9
    |
    r10
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


# ------------------------------------------------------------
# Error_Rules cho discounts
# ------------------------------------------------------------

if (
    len(
        discounts_error
    )
    > 0
):

    error_rules_discount = np.full(
        len(
            discounts
        ),
        "",
        dtype=object
    )


    mask_r9 = (
        r9
        .to_numpy()
    )


    mask_r10 = (
        r10
        .to_numpy()
    )


    error_rules_discount[
        mask_r9
    ] = "R9"


    error_rules_discount[
        mask_r10
    ] = np.where(

        error_rules_discount[
            mask_r10
        ]
        ==
        "",

        "R10",

        error_rules_discount[
            mask_r10
        ]
        +
        ";R10"
    )


    discounts_error[
        "Error_Rules"
    ] = (
        error_rules_discount[
            discount_error
            .to_numpy()
        ]
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


tong_discount = len(
    discounts
)


valid_discount = len(
    discounts_valid
)


error_discount = len(
    discounts_error
)


# ============================================================
# 9. R13 - REVIEW, KHÔNG ERROR
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


    # --------------------------------------------------------
    # Sau khi exact duplicate đã bị xóa,
    # chỉ giữ khóa thực sự còn trùng
    # --------------------------------------------------------

    mask_trung = (
        review
        .duplicated(
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


    if (
        so_dong_review
        > 0
    ):

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
# 10. ĐỐI SOÁT DISCOUNTS
# ============================================================

doi_soat_discounts = (

    tong_discount

    ==

    (
        valid_discount
        +
        error_discount
    )
)


# ============================================================
# 11. LƯU KẾT QUẢ
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

            "Review":
                so_dong_review,

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

            "Review":
                0,

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
# 12. LƯU CHI TIẾT RULE
# ============================================================

danh_sach_rule = []


for i in range(
    1,
    19
):

    rule = (
        f"R{i}"
    )


    if rule == "R13":

        so_vi_pham = (
            so_dong_review
        )


        ket_qua_rule = (
            "REVIEW"
        )

    else:

        so_vi_pham = (
            dem_rule.get(
                rule,
                0
            )
        )


        ket_qua_rule = (
            "DAT"
            if so_vi_pham == 0
            else "CO_VI_PHAM"
        )


    danh_sach_rule.append({

        "Rule":
            rule,

        "So_dong_vi_pham":
            so_vi_pham,

        "Ket_qua":
            ket_qua_rule
    })


bang_rule = pd.DataFrame(
    danh_sach_rule
)


file_ket_qua_rule = (
    THU_MUC_KET_QUA
    / "05_Ket_qua_chi_tiet_rule.csv"
)


bang_rule.to_csv(
    file_ket_qua_rule,
    index=False,
    encoding="utf-8-sig"
)


# ============================================================
# 13. HIỂN THỊ
# ============================================================

print("\n")
print("=" * 95)
print("KẾT QUẢ 2.3.5")
print("=" * 95)


print(
    "\nTRANSACTIONS"
)


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


print(
    "\nDISCOUNTS"
)


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


print(
    f"Đối soát    : "
    f"{'ĐẠT' if doi_soat_discounts else 'KHÔNG ĐẠT'}"
)


print(
    "\nR13 - REVIEW"
)


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


# ============================================================
# 14. CHI TIẾT RULE
# ============================================================

print("\n")
print("=" * 95)
print("CHI TIẾT RULE")
print("=" * 95)


for i in range(
    1,
    19
):

    rule = (
        f"R{i}"
    )


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


# ============================================================
# 15. HIỂN THỊ RIÊNG RULE TIỀN TỆ
# ============================================================

print("\n")
print("=" * 95)
print("KIỂM TRA QUỐC GIA VÀ TIỀN TỆ")
print("=" * 95)


print(
    "R14 - Country_Code thiếu          : "
    f"{dem_rule['R14']:,}"
)


print(
    "R15 - Currency không hợp lệ       : "
    f"{dem_rule['R15']:,}"
)


print(
    "R16 - Currency không khớp Country : "
    f"{dem_rule['R16']:,}"
)


print(
    "R17 - Exchange Rate <= 0          : "
    f"{dem_rule['R17']:,}"
)


print(
    "R18 - Exchange Rate bị thiếu      : "
    f"{dem_rule['R18']:,}"
)


print("\nĐã lưu kết quả tại:")

print(
    file_ket_qua
)

print(
    file_ket_qua_rule
)


if (
    doi_soat_transactions
    and doi_soat_discounts
):

    print(
        "\nĐối soát toàn bộ: ĐẠT"
    )

else:

    print(
        "\nĐối soát toàn bộ: KHÔNG ĐẠT"
    )


print(
    "\nHOÀN TẤT 2.3.5"
)