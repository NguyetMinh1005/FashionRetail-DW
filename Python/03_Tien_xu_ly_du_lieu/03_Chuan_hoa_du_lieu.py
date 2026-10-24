import pandas as pd
from pathlib import Path
import os


# ============================================================
# 2.3.3. CHUẨN HÓA VÀ CHUYỂN ĐỔI DỮ LIỆU
#
# Mục tiêu:
# - Trim chuỗi
# - Sửa tên cột Discont -> Discount
# - Chuẩn hóa số
# - Chuẩn hóa ngày tháng
# - Không làm thay đổi số dòng
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


print("=" * 85)
print("2.3.3 - CHUẨN HÓA VÀ CHUYỂN ĐỔI DỮ LIỆU")
print("=" * 85)


# ============================================================
# 2. KHAI BÁO KIỂU DỮ LIỆU CẦN CHUẨN HÓA
# ============================================================

CAU_HINH = {

    "transactions.csv": {

        "integer": [
            "Line",
            "Quantity"
        ],

        "float": [
            "Unit Price",
            "Discount",
            "Line Total",
            "Invoice Total"
        ],

        "datetime": [
            "Date"
        ]
    },

    "customers.csv": {

        "integer": [],

        "float": [],

        "datetime": [
            "Date Of Birth"
        ]
    },

    "products.csv": {

        "integer": [],

        "float": [
            "Production Cost"
        ],

        "datetime": []
    },

    "stores.csv": {

        "integer": [
            "Number of Employees"
        ],

        "float": [
            "Latitude",
            "Longitude"
        ],

        "datetime": []
    },

    "employees.csv": {

        "integer": [],

        "float": [],

        "datetime": []
    },

    "discounts.csv": {

        "integer": [],

        "float": [
            "Discount"
        ],

        "datetime": [
            "Start",
            "End"
        ]
    }
}


# ============================================================
# 3. HÀM TRIM TOÀN BỘ CỘT TEXT
# ============================================================

def trim_cot_text(df):

    cot_text = df.select_dtypes(
        include=["object", "string"]
    ).columns

    for cot in cot_text:

        df[cot] = (
            df[cot]
            .astype("string")
            .str.strip()
        )

    return df


# ============================================================
# 4. HÀM CHUYỂN SỐ NGUYÊN
# ============================================================

def chuyen_integer(df, cot, ten_file):

    if cot not in df.columns:
        return df, 0

    # Giữ Unknown nếu có
    mask_unknown = (
        df[cot]
        .astype("string")
        .str.strip()
        .eq("Unknown")
    )

    converted = pd.to_numeric(
        df[cot].where(~mask_unknown, pd.NA),
        errors="coerce"
    )

    so_loi = int(
        (
            converted.isna()
            & ~mask_unknown
            & df[cot].notna()
        ).sum()
    )

    # Kiểm tra có số thập phân không
    valid = converted.dropna()

    if not valid.empty:

        so_khong_nguyen = int(
            (valid % 1 != 0).sum()
        )

        so_loi += so_khong_nguyen

    # Chuyển về Int64
    converted = converted.round().astype("Int64")

    # Trả Unknown về nguyên trạng
    df[cot] = converted.astype("string")

    df.loc[
        mask_unknown,
        cot
    ] = "Unknown"

    return df, so_loi


# ============================================================
# 5. HÀM CHUYỂN SỐ THỰC
# ============================================================

def chuyen_float(df, cot):

    if cot not in df.columns:
        return df, 0

    mask_unknown = (
        df[cot]
        .astype("string")
        .str.strip()
        .eq("Unknown")
    )

    converted = pd.to_numeric(
        df[cot].where(~mask_unknown, pd.NA),
        errors="coerce"
    )

    so_loi = int(
        (
            converted.isna()
            & ~mask_unknown
            & df[cot].notna()
        ).sum()
    )

    df[cot] = converted.astype("Float64").astype("string")

    df.loc[
        mask_unknown,
        cot
    ] = "Unknown"

    return df, so_loi


# ============================================================
# 6. HÀM CHUYỂN NGÀY THÁNG
# ============================================================

def chuyen_datetime(df, cot):

    if cot not in df.columns:
        return df, 0

    mask_unknown = (
        df[cot]
        .astype("string")
        .str.strip()
        .eq("Unknown")
    )

    converted = pd.to_datetime(
        df[cot].where(~mask_unknown, pd.NA),
        errors="coerce"
    )

    so_loi = int(
        (
            converted.isna()
            & ~mask_unknown
            & df[cot].notna()
        ).sum()
    )

    # Nếu là transactions.Date thì giữ cả giờ
    if cot == "Date":

        ket_qua = (
            converted
            .dt.strftime(
                "%Y-%m-%d %H:%M:%S"
            )
        )

    else:

        ket_qua = (
            converted
            .dt.strftime(
                "%Y-%m-%d"
            )
        )

    df[cot] = ket_qua.astype("string")

    df.loc[
        mask_unknown,
        cot
    ] = "Unknown"

    return df, so_loi


# ============================================================
# 7. XỬ LÝ TỪNG FILE
# ============================================================

ket_qua_tong_hop = []


for ten_file, cau_hinh in CAU_HINH.items():

    file_goc = (
        THU_MUC_PROCESSED
        / ten_file
    )

    file_tam = (
        THU_MUC_PROCESSED
        / f"__temp_{ten_file}"
    )


    print("\n" + "-" * 85)
    print(f"Đang chuẩn hóa: {ten_file}")


    if not file_goc.exists():

        print(
            f"KHÔNG TÌM THẤY FILE: "
            f"{file_goc}"
        )

        continue


    if file_tam.exists():
        file_tam.unlink()


    tong_dong_truoc = 0
    tong_dong_sau = 0
    tong_loi = 0

    loi_integer = 0
    loi_float = 0
    loi_datetime = 0

    ghi_header = True


    # ========================================================
    # ĐỌC THEO CHUNK
    # ========================================================

    for chunk in pd.read_csv(
        file_goc,
        chunksize=100000,
        dtype=str,
        keep_default_na=True,
        low_memory=False
    ):

        tong_dong_truoc += len(chunk)


        # ----------------------------------------------------
        # A. TRIM TOÀN BỘ CỘT TEXT
        # ----------------------------------------------------

        chunk = trim_cot_text(
            chunk
        )


        # ----------------------------------------------------
        # B. SỬA TÊN CỘT DISCONT -> DISCOUNT
        # Chỉ áp dụng discounts.csv
        # ----------------------------------------------------

        if (
            ten_file == "discounts.csv"
            and "Discont" in chunk.columns
        ):

            chunk = chunk.rename(
                columns={
                    "Discont": "Discount"
                }
            )


        # ----------------------------------------------------
        # C. INTEGER
        # ----------------------------------------------------

        for cot in cau_hinh["integer"]:

            chunk, so_loi = chuyen_integer(
                chunk,
                cot,
                ten_file
            )

            loi_integer += so_loi


        # ----------------------------------------------------
        # D. FLOAT
        # ----------------------------------------------------

        for cot in cau_hinh["float"]:

            chunk, so_loi = chuyen_float(
                chunk,
                cot
            )

            loi_float += so_loi


        # ----------------------------------------------------
        # E. DATETIME
        # ----------------------------------------------------

        for cot in cau_hinh["datetime"]:

            chunk, so_loi = chuyen_datetime(
                chunk,
                cot
            )

            loi_datetime += so_loi


        tong_dong_sau += len(
            chunk
        )


        # ----------------------------------------------------
        # F. GHI FILE TẠM
        # ----------------------------------------------------

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
    # 8. THAY FILE CŨ
    # ========================================================

    os.replace(
        file_tam,
        file_goc
    )


    tong_loi = (
        loi_integer
        + loi_float
        + loi_datetime
    )


    doi_soat = (
        tong_dong_truoc
        ==
        tong_dong_sau
    )


    print(
        f"Số dòng trước xử lý : "
        f"{tong_dong_truoc:,}"
    )

    print(
        f"Số dòng sau xử lý   : "
        f"{tong_dong_sau:,}"
    )

    print(
        f"Lỗi integer         : "
        f"{loi_integer:,}"
    )

    print(
        f"Lỗi float           : "
        f"{loi_float:,}"
    )

    print(
        f"Lỗi datetime        : "
        f"{loi_datetime:,}"
    )

    print(
        f"Đối soát số dòng    : "
        f"{'ĐẠT' if doi_soat else 'KHÔNG ĐẠT'}"
    )


    ket_qua_tong_hop.append({

        "Tep_du_lieu":
            ten_file,

        "So_dong_truoc":
            tong_dong_truoc,

        "So_dong_sau":
            tong_dong_sau,

        "Loi_integer":
            loi_integer,

        "Loi_float":
            loi_float,

        "Loi_datetime":
            loi_datetime,

        "Tong_loi_chuyen_doi":
            tong_loi,

        "Doi_soat":
            "DAT"
            if doi_soat
            else "KHONG_DAT"
    })


# ============================================================
# 9. LƯU BẢNG KẾT QUẢ
# ============================================================

bang_ket_qua = pd.DataFrame(
    ket_qua_tong_hop
)


FILE_KET_QUA = (
    THU_MUC_KET_QUA
    / "03_Ket_qua_chuan_hoa_du_lieu.csv"
)


bang_ket_qua.to_csv(
    FILE_KET_QUA,
    index=False,
    encoding="utf-8-sig"
)


# ============================================================
# 10. HIỂN THỊ TỔNG HỢP
# ============================================================

print("\n")
print("=" * 85)
print("KẾT QUẢ 2.3.3")
print("=" * 85)

print(
    bang_ket_qua[
        [
            "Tep_du_lieu",
            "So_dong_truoc",
            "So_dong_sau",
            "Tong_loi_chuyen_doi",
            "Doi_soat"
        ]
    ].to_string(
        index=False
    )
)


print("\nĐã lưu kết quả tại:")
print(FILE_KET_QUA)

print("\nHOÀN TẤT 2.3.3")