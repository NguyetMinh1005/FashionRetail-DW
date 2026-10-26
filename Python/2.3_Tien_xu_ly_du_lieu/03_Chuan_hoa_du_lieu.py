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
# - Chuẩn hóa thông tin quốc gia
# - Chuẩn hóa mã tiền tệ
# - Không làm thay đổi số dòng
#
# Bổ sung cho dữ liệu đa quốc gia:
# - Giữ Country gốc
# - Thêm Country_Code
# - Thêm Country_Name_EN
# - Thêm Country_Name_VI
# - Thêm Expected_Currency
# - Chuẩn hóa Currency trong transactions.csv
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

THU_MUC_REFERENCE = (
    THU_MUC_GOC
    / "data"
    / "reference"
)

FILE_COUNTRY_MAPPING = (
    THU_MUC_REFERENCE
    / "country_mapping.csv"
)


THU_MUC_KET_QUA.mkdir(
    parents=True,
    exist_ok=True
)


print("=" * 95)
print("2.3.3 - CHUẨN HÓA VÀ CHUYỂN ĐỔI DỮ LIỆU")
print("=" * 95)


# ============================================================
# 2. KIỂM TRA VÀ ĐỌC COUNTRY MAPPING
# ============================================================

if not FILE_COUNTRY_MAPPING.exists():

    raise FileNotFoundError(
        "\nKHÔNG TÌM THẤY FILE COUNTRY MAPPING:\n"
        f"{FILE_COUNTRY_MAPPING}\n\n"
        "Hãy kiểm tra lại file:\n"
        "data/reference/country_mapping.csv"
    )


country_mapping = pd.read_csv(
    FILE_COUNTRY_MAPPING,
    dtype=str,
    encoding="utf-8-sig",
    keep_default_na=False,
    sep=";"
)
country_mapping.columns = (
    country_mapping.columns
    .astype(str)
    .str.strip()
)


# ------------------------------------------------------------
# Kiểm tra cấu trúc file mapping
# ------------------------------------------------------------

CAC_COT_MAPPING_BAT_BUOC = [
    "Country_Original",
    "Country_Code",
    "Country_Name_EN",
    "Country_Name_VI",
    "Expected_Currency"
]


cot_mapping_thieu = [
    cot
    for cot in CAC_COT_MAPPING_BAT_BUOC
    if cot not in country_mapping.columns
]


if cot_mapping_thieu:

    raise ValueError(
        "File country_mapping.csv thiếu các cột: "
        + ", ".join(cot_mapping_thieu)
    )


# ------------------------------------------------------------
# Trim dữ liệu mapping
# ------------------------------------------------------------

for cot in CAC_COT_MAPPING_BAT_BUOC:

    country_mapping[cot] = (
        country_mapping[cot]
        .astype("string")
        .str.strip()
    )


# ------------------------------------------------------------
# Chuẩn hóa mã
# ------------------------------------------------------------

country_mapping["Country_Code"] = (
    country_mapping["Country_Code"]
    .str.upper()
)

country_mapping["Expected_Currency"] = (
    country_mapping["Expected_Currency"]
    .str.upper()
)


# ------------------------------------------------------------
# Kiểm tra Country_Original có bị trùng không
# ------------------------------------------------------------

mapping_trung = (
    country_mapping[
        "Country_Original"
    ]
    .duplicated(
        keep=False
    )
)


if mapping_trung.any():

    print("\nLỖI: Country_Original bị trùng trong mapping:")

    print(
        country_mapping.loc[
            mapping_trung,
            CAC_COT_MAPPING_BAT_BUOC
        ].to_string(
            index=False
        )
    )

    raise ValueError(
        "Country_Original trong country_mapping.csv "
        "phải là duy nhất."
    )


print("\nĐã đọc bảng chuẩn hóa quốc gia:")
print(FILE_COUNTRY_MAPPING)

print(
    f"Số quốc gia trong mapping: "
    f"{len(country_mapping):,}"
)


print("\nDanh sách chuẩn hóa quốc gia:")

print(
    country_mapping[
        CAC_COT_MAPPING_BAT_BUOC
    ]
    .sort_values(
        "Country_Code"
    )
    .to_string(
        index=False
    )
)


# ============================================================
# 3. KHAI BÁO KIỂU DỮ LIỆU CẦN CHUẨN HÓA
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
# 4. HÀM TRIM TOÀN BỘ CỘT TEXT
# ============================================================

def trim_cot_text(df):

    cot_text = df.select_dtypes(
        include=[
            "object",
            "string"
        ]
    ).columns

    for cot in cot_text:

        df[cot] = (
            df[cot]
            .astype("string")
            .str.strip()
        )

    return df


# ============================================================
# 5. HÀM CHUYỂN SỐ NGUYÊN
# ============================================================

def chuyen_integer(
    df,
    cot,
    ten_file
):

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
        df[cot].where(
            ~mask_unknown,
            pd.NA
        ),
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
            (
                valid % 1 != 0
            ).sum()
        )

        so_loi += so_khong_nguyen

    # Chuyển về Int64
    converted = (
        converted
        .round()
        .astype("Int64")
    )

    # Đưa về string để ghi CSV ổn định
    df[cot] = (
        converted
        .astype("string")
    )

    # Trả Unknown về nguyên trạng
    df.loc[
        mask_unknown,
        cot
    ] = "Unknown"

    return df, so_loi


# ============================================================
# 6. HÀM CHUYỂN SỐ THỰC
# ============================================================

def chuyen_float(
    df,
    cot
):

    if cot not in df.columns:
        return df, 0

    mask_unknown = (
        df[cot]
        .astype("string")
        .str.strip()
        .eq("Unknown")
    )

    converted = pd.to_numeric(
        df[cot].where(
            ~mask_unknown,
            pd.NA
        ),
        errors="coerce"
    )

    so_loi = int(
        (
            converted.isna()
            & ~mask_unknown
            & df[cot].notna()
        ).sum()
    )

    df[cot] = (
        converted
        .astype("Float64")
        .astype("string")
    )

    df.loc[
        mask_unknown,
        cot
    ] = "Unknown"

    return df, so_loi


# ============================================================
# 7. HÀM CHUYỂN NGÀY THÁNG
# ============================================================

def chuyen_datetime(
    df,
    cot
):

    if cot not in df.columns:
        return df, 0

    mask_unknown = (
        df[cot]
        .astype("string")
        .str.strip()
        .eq("Unknown")
    )

    converted = pd.to_datetime(
        df[cot].where(
            ~mask_unknown,
            pd.NA
        ),
        errors="coerce"
    )

    so_loi = int(
        (
            converted.isna()
            & ~mask_unknown
            & df[cot].notna()
        ).sum()
    )

    # transactions.Date giữ cả ngày và giờ
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

    df[cot] = (
        ket_qua
        .astype("string")
    )

    df.loc[
        mask_unknown,
        cot
    ] = "Unknown"

    return df, so_loi


# ============================================================
# 8. HÀM CHUẨN HÓA QUỐC GIA
# ============================================================

def chuan_hoa_quoc_gia(
    df
):

    if "Country" not in df.columns:

        raise ValueError(
            "stores.csv không có cột Country."
        )


    # --------------------------------------------------------
    # Nếu chạy lại script trên file đã được chuẩn hóa trước đó,
    # xóa các cột dẫn xuất cũ để tránh merge sinh _x / _y
    # --------------------------------------------------------

    cot_country_da_tao = [
        "Country_Original",
        "Country_Code",
        "Country_Name_EN",
        "Country_Name_VI",
        "Expected_Currency"
    ]

    cot_can_xoa = [
        cot
        for cot in cot_country_da_tao
        if cot in df.columns
    ]

    if cot_can_xoa:

        df = df.drop(
            columns=cot_can_xoa
        )


    # --------------------------------------------------------
    # Chuẩn hóa Country nguồn
    # --------------------------------------------------------

    df["Country"] = (
        df["Country"]
        .astype("string")
        .str.strip()
    )


    # --------------------------------------------------------
    # Giữ giá trị quốc gia nguồn để đối soát
    # --------------------------------------------------------

    df["Country_Original"] = (
        df["Country"]
    )


    # --------------------------------------------------------
    # Lookup mapping
    # --------------------------------------------------------

    df = df.merge(
        country_mapping,
        how="left",
        on="Country_Original",
        validate="many_to_one"
    )


    # --------------------------------------------------------
    # Kiểm tra Country chưa mapping
    # --------------------------------------------------------

    mask_khong_mapping = (
        df["Country_Code"]
        .isna()
    )


    so_loi_mapping = int(
        mask_khong_mapping.sum()
    )


    if so_loi_mapping > 0:

        print(
            "\nLỖI: Có Country chưa tồn tại "
            "trong country_mapping.csv"
        )

        print(
            df.loc[
                mask_khong_mapping,
                [
                    "Store ID",
                    "Country_Original"
                ]
            ]
            .drop_duplicates()
            .to_string(
                index=False
            )
        )


    return (
        df,
        so_loi_mapping
    )


# ============================================================
# 9. HÀM CHUẨN HÓA TIỀN TỆ
# ============================================================

def chuan_hoa_tien_te(
    df
):

    so_loi_currency = 0


    # --------------------------------------------------------
    # Currency
    # --------------------------------------------------------

    if "Currency" not in df.columns:

        print(
            "\nCẢNH BÁO: transactions.csv "
            "không có cột Currency."
        )

        return (
            df,
            1
        )


    df["Currency"] = (
        df["Currency"]
        .astype("string")
        .str.strip()
        .str.upper()
    )


    # --------------------------------------------------------
    # Currency Symbol
    # --------------------------------------------------------

    if "Currency Symbol" in df.columns:

        df["Currency Symbol"] = (
            df["Currency Symbol"]
            .astype("string")
            .str.strip()
        )


    # --------------------------------------------------------
    # Chỉ kiểm tra Currency có rỗng hay không.
    # Việc Country ↔ Currency có đúng hay không
    # sẽ kiểm tra ở Quality Gate bước 2.3.5.
    # --------------------------------------------------------

    mask_currency_rong = (
        df["Currency"].isna()
        |
        df["Currency"].eq("")
        |
        df["Currency"].eq("Unknown")
    )


    so_loi_currency = int(
        mask_currency_rong.sum()
    )


    return (
        df,
        so_loi_currency
    )


# ============================================================
# 10. XỬ LÝ TỪNG FILE
# ============================================================

ket_qua_tong_hop = []

# Lưu để hiển thị cuối chương trình
danh_sach_country_ket_qua = None

# Lưu Currency distinct sau khi chuẩn hóa
tap_currency = set()


for ten_file, cau_hinh in CAU_HINH.items():

    file_goc = (
        THU_MUC_PROCESSED
        / ten_file
    )

    file_tam = (
        THU_MUC_PROCESSED
        / f"__temp_{ten_file}"
    )


    print(
        "\n"
        + "-"
        * 95
    )

    print(
        f"Đang chuẩn hóa: "
        f"{ten_file}"
    )


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

    loi_integer = 0
    loi_float = 0
    loi_datetime = 0

    loi_country_mapping = 0
    loi_currency = 0

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

        tong_dong_truoc += len(
            chunk
        )


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
            ten_file
            == "discounts.csv"
            and "Discont"
            in chunk.columns
        ):

            chunk = chunk.rename(
                columns={
                    "Discont":
                        "Discount"
                }
            )


        # ----------------------------------------------------
        # C. CHUẨN HÓA COUNTRY
        # Chỉ áp dụng stores.csv
        # ----------------------------------------------------

        if (
            ten_file
            == "stores.csv"
        ):

            (
                chunk,
                so_loi_country
            ) = chuan_hoa_quoc_gia(
                chunk
            )

            loi_country_mapping += (
                so_loi_country
            )


            # Lưu danh sách Country phục vụ in kết quả
            country_hien_tai = (
                chunk[
                    [
                        "Country_Original",
                        "Country_Code",
                        "Country_Name_EN",
                        "Country_Name_VI",
                        "Expected_Currency"
                    ]
                ]
                .drop_duplicates()
            )

            if (
                danh_sach_country_ket_qua
                is None
            ):

                danh_sach_country_ket_qua = (
                    country_hien_tai
                )

            else:

                danh_sach_country_ket_qua = (
                    pd.concat(
                        [
                            danh_sach_country_ket_qua,
                            country_hien_tai
                        ],
                        ignore_index=True
                    )
                    .drop_duplicates()
                )


        # ----------------------------------------------------
        # D. CHUẨN HÓA CURRENCY
        # Chỉ áp dụng transactions.csv
        # ----------------------------------------------------

        if (
            ten_file
            == "transactions.csv"
        ):

            (
                chunk,
                so_loi_currency
            ) = chuan_hoa_tien_te(
                chunk
            )

            loi_currency += (
                so_loi_currency
            )


            # Thu thập Currency distinct
            if "Currency" in chunk.columns:

                currency_values = (
                    chunk["Currency"]
                    .dropna()
                    .astype(str)
                    .str.strip()
                    .unique()
                    .tolist()
                )

                tap_currency.update(
                    currency_values
                )


        # ----------------------------------------------------
        # E. INTEGER
        # ----------------------------------------------------

        for cot in cau_hinh[
            "integer"
        ]:

            (
                chunk,
                so_loi
            ) = chuyen_integer(
                chunk,
                cot,
                ten_file
            )

            loi_integer += (
                so_loi
            )


        # ----------------------------------------------------
        # F. FLOAT
        # ----------------------------------------------------

        for cot in cau_hinh[
            "float"
        ]:

            (
                chunk,
                so_loi
            ) = chuyen_float(
                chunk,
                cot
            )

            loi_float += (
                so_loi
            )


        # ----------------------------------------------------
        # G. DATETIME
        # ----------------------------------------------------

        for cot in cau_hinh[
            "datetime"
        ]:

            (
                chunk,
                so_loi
            ) = chuyen_datetime(
                chunk,
                cot
            )

            loi_datetime += (
                so_loi
            )


        tong_dong_sau += len(
            chunk
        )


        # ----------------------------------------------------
        # H. GHI FILE TẠM
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
    # 11. KIỂM TRA TRƯỚC KHI THAY FILE CŨ
    # ========================================================

    doi_soat = (
        tong_dong_truoc
        ==
        tong_dong_sau
    )


    # Nếu Country chưa mapping được thì KHÔNG thay file cũ
    if (
        loi_country_mapping
        > 0
    ):

        if file_tam.exists():

            file_tam.unlink()

        raise ValueError(
            "\nDỪNG XỬ LÝ.\n"
            f"Có {loi_country_mapping:,} dòng "
            "Country chưa mapping được.\n"
            "File processed cũ được giữ nguyên."
        )


    # ========================================================
    # 12. THAY FILE CŨ
    # ========================================================

    os.replace(
        file_tam,
        file_goc
    )


    tong_loi = (
        loi_integer
        + loi_float
        + loi_datetime
        + loi_country_mapping
        + loi_currency
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


    if (
        ten_file
        == "stores.csv"
    ):

        print(
            f"Country chưa mapping: "
            f"{loi_country_mapping:,}"
        )


    if (
        ten_file
        == "transactions.csv"
    ):

        print(
            f"Currency thiếu/rỗng : "
            f"{loi_currency:,}"
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

        "Loi_country_mapping":
            loi_country_mapping,

        "Loi_currency":
            loi_currency,

        "Tong_loi_chuyen_doi":
            tong_loi,

        "Doi_soat":
            (
                "DAT"
                if doi_soat
                else "KHONG_DAT"
            )
    })


# ============================================================
# 13. LƯU BẢNG KẾT QUẢ
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
# 14. LƯU KẾT QUẢ CHUẨN HÓA COUNTRY
# ============================================================

if (
    danh_sach_country_ket_qua
    is not None
):

    danh_sach_country_ket_qua = (
        danh_sach_country_ket_qua
        .drop_duplicates()
        .sort_values(
            "Country_Code"
        )
    )


    FILE_KET_QUA_COUNTRY = (
        THU_MUC_KET_QUA
        / "03_Ket_qua_chuan_hoa_quoc_gia.csv"
    )


    danh_sach_country_ket_qua.to_csv(
        FILE_KET_QUA_COUNTRY,
        index=False,
        encoding="utf-8-sig"
    )


# ============================================================
# 15. HIỂN THỊ TỔNG HỢP
# ============================================================

print("\n")
print("=" * 95)
print("KẾT QUẢ 2.3.3")
print("=" * 95)


print(
    bang_ket_qua[
        [
            "Tep_du_lieu",
            "So_dong_truoc",
            "So_dong_sau",
            "Loi_country_mapping",
            "Loi_currency",
            "Tong_loi_chuyen_doi",
            "Doi_soat"
        ]
    ].to_string(
        index=False
    )
)


# ============================================================
# 16. HIỂN THỊ COUNTRY SAU CHUẨN HÓA
# ============================================================

if (
    danh_sach_country_ket_qua
    is not None
):

    print("\n")
    print("=" * 95)
    print("KẾT QUẢ CHUẨN HÓA QUỐC GIA")
    print("=" * 95)


    print(
        danh_sach_country_ket_qua[
            [
                "Country_Original",
                "Country_Code",
                "Country_Name_EN",
                "Country_Name_VI",
                "Expected_Currency"
            ]
        ].to_string(
            index=False
        )
    )


    print(
        "\nSố quốc gia chưa mapping: 0"
    )


# ============================================================
# 17. HIỂN THỊ CURRENCY SAU CHUẨN HÓA
# ============================================================

print("\n")
print("=" * 95)
print("CÁC LOẠI TIỀN TỆ SAU CHUẨN HÓA")
print("=" * 95)


if tap_currency:

    for currency in sorted(
        tap_currency
    ):

        print(
            f"- {currency}"
        )

else:

    print(
        "Không ghi nhận Currency."
    )


print("\nĐã lưu kết quả tại:")
print(FILE_KET_QUA)


if (
    danh_sach_country_ket_qua
    is not None
):

    print(
        FILE_KET_QUA_COUNTRY
    )


print("\nHOÀN TẤT 2.3.3")