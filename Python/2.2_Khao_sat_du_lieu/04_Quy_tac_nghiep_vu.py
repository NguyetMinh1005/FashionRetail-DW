import pandas as pd
from pathlib import Path


# ============================================================
# 2.2.4. XÁC ĐỊNH QUY TẮC NGHIỆP VỤ ĐỐI VỚI DỮ LIỆU
#
# Chỉ kiểm tra và thống kê số dòng vi phạm.
# KHÔNG sửa hoặc xóa dữ liệu trong bước 2.2.
# ============================================================


# ------------------------------------------------------------
# 1. THƯ MỤC
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


print("=" * 80)
print("2.2.4 - XÁC ĐỊNH QUY TẮC NGHIỆP VỤ")
print("=" * 80)


# ============================================================
# 2. ĐỌC CÁC BẢNG THAM CHIẾU
# ============================================================

print("\nĐang đọc các bảng tham chiếu...")


customers = pd.read_csv(
    THU_MUC_RAW / "customers.csv",
    usecols=["Customer ID"],
    dtype=str,
    low_memory=False
)

products = pd.read_csv(
    THU_MUC_RAW / "products.csv",
    usecols=["Product ID"],
    dtype=str,
    low_memory=False
)

stores = pd.read_csv(
    THU_MUC_RAW / "stores.csv",
    dtype=str,
    low_memory=False
)

employees = pd.read_csv(
    THU_MUC_RAW / "employees.csv",
    dtype=str,
    low_memory=False
)

discounts = pd.read_csv(
    THU_MUC_RAW / "discounts.csv",
    dtype=str,
    low_memory=False
)


# ------------------------------------------------------------
# Chuẩn hóa khoảng trắng cho ID
# ------------------------------------------------------------

customers["Customer ID"] = (
    customers["Customer ID"]
    .astype(str)
    .str.strip()
)

products["Product ID"] = (
    products["Product ID"]
    .astype(str)
    .str.strip()
)

stores["Store ID"] = (
    stores["Store ID"]
    .astype(str)
    .str.strip()
)

employees["Employee ID"] = (
    employees["Employee ID"]
    .astype(str)
    .str.strip()
)

employees["Store ID"] = (
    employees["Store ID"]
    .astype(str)
    .str.strip()
)


# ------------------------------------------------------------
# Tạo tập giá trị để kiểm tra khóa ngoại nhanh hơn
# ------------------------------------------------------------

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


# Employee ID -> Store ID
employee_store = dict(
    zip(
        employees["Employee ID"],
        employees["Store ID"]
    )
)


print("Đã đọc xong các bảng tham chiếu.")


# ============================================================
# 3. KHỞI TẠO BIẾN ĐẾM
# ============================================================

vi_pham = {
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

tong_giao_dich = 0


# ============================================================
# 4. KIỂM TRA TRANSACTIONS THEO CHUNK
# ============================================================

print("\nĐang kiểm tra transactions.csv...")


duong_dan_transactions = (
    THU_MUC_RAW
    / "transactions.csv"
)


for chunk in pd.read_csv(
    duong_dan_transactions,
    chunksize=100000,
    dtype=str,
    low_memory=False
):

    tong_giao_dich += len(chunk)


    # --------------------------------------------------------
    # Chuẩn hóa khoảng trắng ở các trường cần kiểm tra
    # --------------------------------------------------------

    for cot in [
        "Customer ID",
        "Product ID",
        "Store ID",
        "Employee ID",
        "Transaction Type"
    ]:

        chunk[cot] = (
            chunk[cot]
            .astype(str)
            .str.strip()
        )


    # --------------------------------------------------------
    # Chuyển các cột số để phục vụ kiểm tra
    # --------------------------------------------------------

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
    # R1. QUANTITY > 0
    # ========================================================

    vi_pham["R1"] += int(
        (
            quantity.isna()
            | (quantity <= 0)
        ).sum()
    )


    # ========================================================
    # R2. UNIT PRICE > 0
    # ========================================================

    vi_pham["R2"] += int(
        (
            unit_price.isna()
            | (unit_price <= 0)
        ).sum()
    )


    # ========================================================
    # R3. DISCOUNT NẰM TRONG [0,1]
    # ========================================================

    vi_pham["R3"] += int(
        (
            discount.isna()
            | (discount < 0)
            | (discount > 1)
        ).sum()
    )


    # ========================================================
    # R4. PRODUCT ID PHẢI TỒN TẠI TRONG PRODUCTS
    # ========================================================

    vi_pham["R4"] += int(
        (
            ~chunk["Product ID"].isin(
                tap_product
            )
        ).sum()
    )


    # ========================================================
    # R5. STORE ID PHẢI TỒN TẠI TRONG STORES
    # ========================================================

    vi_pham["R5"] += int(
        (
            ~chunk["Store ID"].isin(
                tap_store
            )
        ).sum()
    )


    # ========================================================
    # R6. EMPLOYEE ID PHẢI TỒN TẠI TRONG EMPLOYEES
    # ========================================================

    vi_pham["R6"] += int(
        (
            ~chunk["Employee ID"].isin(
                tap_employee
            )
        ).sum()
    )


    # ========================================================
    # R7. CUSTOMER ID PHẢI TỒN TẠI TRONG CUSTOMERS
    # ========================================================

    vi_pham["R7"] += int(
        (
            ~chunk["Customer ID"].isin(
                tap_customer
            )
        ).sum()
    )


    # ========================================================
    # R8. EMPLOYEE PHẢI THUỘC ĐÚNG STORE
    # ========================================================

    store_theo_employee = (
        chunk["Employee ID"]
        .map(employee_store)
    )

    vi_pham["R8"] += int(
        (
            store_theo_employee.notna()
            &
            (
                store_theo_employee
                != chunk["Store ID"]
            )
        ).sum()
    )


    # ========================================================
    # R11. TRANSACTION TYPE CHỈ GỒM SALE / RETURN
    # ========================================================

    vi_pham["R11"] += int(
        (
            ~chunk["Transaction Type"].isin(
                ["Sale", "Return"]
            )
        ).sum()
    )


    # ========================================================
    # R12.
    # SALE   -> LINE TOTAL > 0
    # RETURN -> LINE TOTAL < 0
    # ========================================================

    sai_sale = (
        (chunk["Transaction Type"] == "Sale")
        &
        (
            line_total.isna()
            | (line_total <= 0)
        )
    )

    sai_return = (
        (chunk["Transaction Type"] == "Return")
        &
        (
            line_total.isna()
            | (line_total >= 0)
        )
    )

    vi_pham["R12"] += int(
        (
            sai_sale
            | sai_return
        ).sum()
    )


print(
    f"Đã kiểm tra "
    f"{tong_giao_dich:,} dòng transactions."
)


# ============================================================
# 5. R9 - START <= END TRONG DISCOUNTS
# ============================================================

start_date = pd.to_datetime(
    discounts["Start"],
    errors="coerce"
)

end_date = pd.to_datetime(
    discounts["End"],
    errors="coerce"
)


vi_pham_r9 = int(
    (
        start_date.isna()
        | end_date.isna()
        | (start_date > end_date)
    ).sum()
)


# ============================================================
# 6. R10 - DISCONT NẰM TRONG [0,1]
# ============================================================

discont = pd.to_numeric(
    discounts["Discont"],
    errors="coerce"
)


vi_pham_r10 = int(
    (
        discont.isna()
        | (discont < 0)
        | (discont > 1)
    ).sum()
)


# ============================================================
# 7. R13 - (INVOICE ID, LINE) PHẢI DUY NHẤT
#
# Lấy trực tiếp kết quả từ bước 2.2.3
# để không phải tính duplicate lần nữa.
# ============================================================

file_trung_lap = (
    THU_MUC_KET_QUA
    / "03_Ket_qua_trung_lap.csv"
)


vi_pham_r13 = None


if file_trung_lap.exists():

    bang_trung = pd.read_csv(
        file_trung_lap
    )

    dong_transactions = bang_trung[
        bang_trung["Tep_du_lieu"]
        == "transactions.csv"
    ]

    if not dong_transactions.empty:

        vi_pham_r13 = int(
            dong_transactions.iloc[0][
                "So_dong_du_theo_khoa"
            ]
        )


if vi_pham_r13 is None:

    vi_pham_r13 = 0

    print(
        "\nCẢNH BÁO: "
        "Không đọc được kết quả 2.2.3."
    )


# ============================================================
# 8. TẠO BẢNG QUY TẮC NGHIỆP VỤ
# ============================================================

danh_sach_quy_tac = [

    {
        "Quy_tac": "R1",
        "Dieu_kien": "Quantity > 0",
        "So_dong_vi_pham": vi_pham["R1"],
        "Y_nghia_xu_ly":
            "Loại các bản ghi có số lượng giao dịch không hợp lệ"
    },

    {
        "Quy_tac": "R2",
        "Dieu_kien": "Unit Price > 0",
        "So_dong_vi_pham": vi_pham["R2"],
        "Y_nghia_xu_ly":
            "Loại các bản ghi có đơn giá không hợp lệ"
    },

    {
        "Quy_tac": "R3",
        "Dieu_kien": "0 <= Discount <= 1",
        "So_dong_vi_pham": vi_pham["R3"],
        "Y_nghia_xu_ly":
            "Đảm bảo mức giảm giá giao dịch hợp lệ"
    },

    {
        "Quy_tac": "R4",
        "Dieu_kien":
            "Product ID tồn tại trong products",
        "So_dong_vi_pham": vi_pham["R4"],
        "Y_nghia_xu_ly":
            "Đảm bảo giao dịch tham chiếu sản phẩm hợp lệ"
    },

    {
        "Quy_tac": "R5",
        "Dieu_kien":
            "Store ID tồn tại trong stores",
        "So_dong_vi_pham": vi_pham["R5"],
        "Y_nghia_xu_ly":
            "Đảm bảo giao dịch thuộc cửa hàng hợp lệ"
    },

    {
        "Quy_tac": "R6",
        "Dieu_kien":
            "Employee ID tồn tại trong employees",
        "So_dong_vi_pham": vi_pham["R6"],
        "Y_nghia_xu_ly":
            "Đảm bảo giao dịch tham chiếu nhân viên hợp lệ"
    },

    {
        "Quy_tac": "R7",
        "Dieu_kien":
            "Customer ID tồn tại trong customers",
        "So_dong_vi_pham": vi_pham["R7"],
        "Y_nghia_xu_ly":
            "Đảm bảo giao dịch tham chiếu khách hàng hợp lệ"
    },

    {
        "Quy_tac": "R8",
        "Dieu_kien":
            "Employee thuộc đúng Store",
        "So_dong_vi_pham": vi_pham["R8"],
        "Y_nghia_xu_ly":
            "Đảm bảo nhân viên thực hiện giao dịch thuộc đúng cửa hàng"
    },

    {
        "Quy_tac": "R9",
        "Dieu_kien": "Start <= End",
        "So_dong_vi_pham": vi_pham_r9,
        "Y_nghia_xu_ly":
            "Đảm bảo thời gian chương trình khuyến mãi hợp lệ"
    },

    {
        "Quy_tac": "R10",
        "Dieu_kien":
            "0 <= Discont <= 1",
        "So_dong_vi_pham": vi_pham_r10,
        "Y_nghia_xu_ly":
            "Đảm bảo mức giảm giá chương trình hợp lệ"
    },

    {
        "Quy_tac": "R11",
        "Dieu_kien":
            "Transaction Type thuộc Sale hoặc Return",
        "So_dong_vi_pham": vi_pham["R11"],
        "Y_nghia_xu_ly":
            "Đảm bảo loại giao dịch hợp lệ"
    },

    {
        "Quy_tac": "R12",
        "Dieu_kien":
            "Sale: Line Total > 0; Return: Line Total < 0",
        "So_dong_vi_pham": vi_pham["R12"],
        "Y_nghia_xu_ly":
            "Đảm bảo dấu giá trị phù hợp loại giao dịch"
    },

    {
        "Quy_tac": "R13",
        "Dieu_kien":
            "(Invoice ID, Line) là duy nhất",
        "So_dong_vi_pham": vi_pham_r13,
        "Y_nghia_xu_ly":
            "Phát hiện các giao dịch trùng khóa nghiệp vụ"
    }
]


bang_quy_tac = pd.DataFrame(
    danh_sach_quy_tac
)


# ============================================================
# 9. HIỂN THỊ KẾT QUẢ DỄ ĐỌC
# ============================================================

print("\n")
print("=" * 80)
print("KẾT QUẢ KIỂM TRA QUY TẮC NGHIỆP VỤ")
print("=" * 80)


for _, dong in bang_quy_tac.iterrows():

    ket_luan = (
        "ĐẠT"
        if dong["So_dong_vi_pham"] == 0
        else "CÓ VI PHẠM"
    )

    print(
        f"{dong['Quy_tac']:<4} | "
        f"Vi phạm: "
        f"{dong['So_dong_vi_pham']:,} | "
        f"{ket_luan}"
    )

    print(
        f"     Điều kiện: "
        f"{dong['Dieu_kien']}"
    )


# ============================================================
# 10. LƯU KẾT QUẢ RA CSV
# ============================================================

file_ket_qua = (
    THU_MUC_KET_QUA
    / "04_Ket_qua_quy_tac_nghiep_vu.csv"
)


bang_quy_tac.to_csv(
    file_ket_qua,
    index=False,
    encoding="utf-8-sig"
)


print("\n" + "=" * 80)
print("Đã lưu kết quả tại:")
print(file_ket_qua)

print("\nHOÀN TẤT 2.2.4")