import pandas as pd
from pathlib import Path
import shutil
import gc


# ============================================================
# 2.3.1. XỬ LÝ DỮ LIỆU TRÙNG LẶP
#
# Quy tắc:
# - Chỉ xóa các dòng TRÙNG HOÀN TOÀN
# - Không tự động xóa các dòng cùng
#   (Invoice ID, Line) nhưng khác nội dung
#
# RAW luôn được giữ nguyên.
# ============================================================


# ------------------------------------------------------------
# 1. XÁC ĐỊNH THƯ MỤC
# ------------------------------------------------------------

THU_MUC_GOC = Path(__file__).resolve().parents[2]

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
    THU_MUC_PROCESSED,
    THU_MUC_REVIEW,
    THU_MUC_KET_QUA
]:
    thu_muc.mkdir(
        parents=True,
        exist_ok=True
    )


print("=" * 80)
print("2.3.1 - XỬ LÝ DỮ LIỆU TRÙNG LẶP")
print("=" * 80)


# ============================================================
# 2. FILE TRANSACTIONS
# ============================================================

FILE_TRANSACTIONS = (
    THU_MUC_RAW
    / "transactions.csv"
)


# ============================================================
# 3. LẦN ĐỌC THỨ NHẤT
#
# Chỉ tạo HASH:
# - hash toàn bộ dòng
# - hash khóa Invoice ID + Line
#
# Không giữ toàn bộ DataFrame 6,4 triệu dòng trong RAM.
# ============================================================

print(
    "\nBƯỚC 1/3 - "
    "Đang phân tích duplicate..."
)


ds_hash_toan_dong = []
ds_hash_khoa = []

tong_dong_ban_dau = 0


for chunk in pd.read_csv(
    FILE_TRANSACTIONS,
    chunksize=100000,
    dtype=str,
    keep_default_na=False,
    low_memory=False
):

    tong_dong_ban_dau += len(chunk)

    # Hash toàn bộ 19 cột
    hash_dong = pd.util.hash_pandas_object(
        chunk,
        index=False
    )

    ds_hash_toan_dong.append(
        hash_dong.reset_index(drop=True)
    )


    # Hash khóa nghiệp vụ
    hash_khoa = pd.util.hash_pandas_object(
        chunk[
            [
                "Invoice ID",
                "Line"
            ]
        ],
        index=False
    )

    ds_hash_khoa.append(
        hash_khoa.reset_index(drop=True)
    )


hash_toan_dong = pd.concat(
    ds_hash_toan_dong,
    ignore_index=True
)

hash_khoa = pd.concat(
    ds_hash_khoa,
    ignore_index=True
)


del ds_hash_toan_dong
del ds_hash_khoa

gc.collect()


# ============================================================
# 4. XÁC ĐỊNH HASH TRÙNG HOÀN TOÀN
# ============================================================

tan_suat_dong = (
    hash_toan_dong
    .value_counts()
)

hash_trung_hoan_toan = set(
    tan_suat_dong[
        tan_suat_dong > 1
    ].index.tolist()
)


so_nhom_trung_hoan_toan = len(
    hash_trung_hoan_toan
)

so_dong_trung_hoan_toan_du = int(
    (
        tan_suat_dong[
            tan_suat_dong > 1
        ] - 1
    ).sum()
)


# ============================================================
# 5. XÁC ĐỊNH HASH KHÓA NGHIỆP VỤ TRÙNG
# ============================================================

tan_suat_khoa = (
    hash_khoa
    .value_counts()
)

hash_khoa_trung = set(
    tan_suat_khoa[
        tan_suat_khoa > 1
    ].index.tolist()
)


so_nhom_trung_khoa = len(
    hash_khoa_trung
)

so_dong_trong_nhom_trung_khoa = int(
    tan_suat_khoa[
        tan_suat_khoa > 1
    ].sum()
)

so_dong_du_theo_khoa = int(
    (
        tan_suat_khoa[
            tan_suat_khoa > 1
        ] - 1
    ).sum()
)


del hash_toan_dong
del hash_khoa
del tan_suat_dong
del tan_suat_khoa

gc.collect()


# ============================================================
# 6. LẦN ĐỌC THỨ HAI
#
# - Giữ lần xuất hiện đầu tiên của exact duplicate
# - Xóa các lần xuất hiện dư
# - Ghi dữ liệu sau xử lý vào processed
# - Ghi các nhóm trùng khóa vào review
# ============================================================

print(
    "\nBƯỚC 2/3 - "
    "Đang loại dòng trùng hoàn toàn..."
)


FILE_OUTPUT = (
    THU_MUC_PROCESSED
    / "transactions.csv"
)

FILE_REVIEW = (
    THU_MUC_REVIEW
    / "transactions_trung_khoa_can_kiem_tra.csv"
)


# Xóa file output cũ nếu có
if FILE_OUTPUT.exists():
    FILE_OUTPUT.unlink()

if FILE_REVIEW.exists():
    FILE_REVIEW.unlink()


# Chỉ cần nhớ những exact hash đã xuất hiện
# Vì duplicate exact chỉ có rất ít nhóm
seen_duplicate_hash = set()


ghi_header_output = True
ghi_header_review = True

tong_dong_sau_xu_ly = 0
tong_dong_da_loai = 0
tong_dong_review = 0


for chunk in pd.read_csv(
    FILE_TRANSACTIONS,
    chunksize=100000,
    dtype=str,
    keep_default_na=False,
    low_memory=False
):

    # --------------------------------------------------------
    # HASH TOÀN BỘ DÒNG
    # --------------------------------------------------------

    hash_dong = pd.util.hash_pandas_object(
        chunk,
        index=False
    )


    # --------------------------------------------------------
    # XÁC ĐỊNH DÒNG CẦN GIỮ
    # --------------------------------------------------------

    giu_lai = []

    for h in hash_dong:

        # Không phải exact duplicate
        if h not in hash_trung_hoan_toan:

            giu_lai.append(True)

        else:

            # Lần xuất hiện đầu tiên
            if h not in seen_duplicate_hash:

                seen_duplicate_hash.add(h)
                giu_lai.append(True)

            # Các lần xuất hiện sau -> loại
            else:

                giu_lai.append(False)
                tong_dong_da_loai += 1


    giu_lai = pd.Series(
        giu_lai,
        index=chunk.index
    )


    chunk_sach = chunk[
        giu_lai
    ].copy()


    tong_dong_sau_xu_ly += len(
        chunk_sach
    )


    # --------------------------------------------------------
    # GHI FILE PROCESSED
    # --------------------------------------------------------

    chunk_sach.to_csv(
        FILE_OUTPUT,
        mode="a",
        index=False,
        header=ghi_header_output,
        encoding="utf-8-sig"
    )

    ghi_header_output = False


    # --------------------------------------------------------
    # TÌM CÁC DÒNG CÓ KHÓA NGHIỆP VỤ TRÙNG
    #
    # Lưu riêng để REVIEW
    # Không xem đây là Error.
    # --------------------------------------------------------

    hash_khoa_chunk = (
        pd.util.hash_pandas_object(
            chunk_sach[
                [
                    "Invoice ID",
                    "Line"
                ]
            ],
            index=False
        )
    )


    mask_review = (
        hash_khoa_chunk
        .isin(hash_khoa_trung)
    )


    chunk_review = (
        chunk_sach[
            mask_review.values
        ]
        .copy()
    )


    if len(chunk_review) > 0:

        chunk_review.to_csv(
            FILE_REVIEW,
            mode="a",
            index=False,
            header=ghi_header_review,
            encoding="utf-8-sig"
        )

        ghi_header_review = False

        tong_dong_review += len(
            chunk_review
        )


# ============================================================
# 7. COPY 5 FILE CÒN LẠI SANG PROCESSED
#
# Vì 2.2.3 xác nhận không có exact duplicate cần xóa.
# ============================================================

print(
    "\nBƯỚC 3/3 - "
    "Đang chuẩn bị 5 file còn lại..."
)


CAC_FILE_CON_LAI = [
    "customers.csv",
    "products.csv",
    "stores.csv",
    "employees.csv",
    "discounts.csv"
]


for ten_file in CAC_FILE_CON_LAI:

    nguon = (
        THU_MUC_RAW
        / ten_file
    )

    dich = (
        THU_MUC_PROCESSED
        / ten_file
    )

    shutil.copy2(
        nguon,
        dich
    )

    print(
        f"Đã copy: {ten_file}"
    )


# ============================================================
# 8. KIỂM TRA ĐỐI SOÁT
# ============================================================

doi_soat = (
    tong_dong_ban_dau
    ==
    tong_dong_sau_xu_ly
    +
    tong_dong_da_loai
)


print("\n")
print("=" * 80)
print("KẾT QUẢ 2.3.1")
print("=" * 80)

print(
    f"Số dòng ban đầu               : "
    f"{tong_dong_ban_dau:,}"
)

print(
    f"Số nhóm trùng khóa            : "
    f"{so_nhom_trung_khoa:,}"
)

print(
    f"Số dòng trong nhóm trùng khóa : "
    f"{so_dong_trong_nhom_trung_khoa:,}"
)

print(
    f"Số dòng dư theo khóa          : "
    f"{so_dong_du_theo_khoa:,}"
)

print(
    f"Số nhóm trùng hoàn toàn       : "
    f"{so_nhom_trung_hoan_toan:,}"
)

print(
    f"Số dòng exact duplicate đã xóa: "
    f"{tong_dong_da_loai:,}"
)

print(
    f"Số dòng sau xử lý             : "
    f"{tong_dong_sau_xu_ly:,}"
)

print(
    f"Số dòng đưa vào REVIEW        : "
    f"{tong_dong_review:,}"
)

print(
    f"Đối soát                      : "
    f"{'ĐẠT' if doi_soat else 'KHÔNG ĐẠT'}"
)


# ============================================================
# 9. LƯU KẾT QUẢ NHỎ ĐỂ ĐƯA VÀO BÁO CÁO
# ============================================================

bang_ket_qua = pd.DataFrame(
    [
        {
            "Tep_du_lieu":
                "transactions.csv",

            "So_dong_ban_dau":
                tong_dong_ban_dau,

            "So_nhom_trung_khoa":
                so_nhom_trung_khoa,

            "So_dong_du_theo_khoa":
                so_dong_du_theo_khoa,

            "So_nhom_trung_hoan_toan":
                so_nhom_trung_hoan_toan,

            "So_dong_trung_hoan_toan_da_loai":
                tong_dong_da_loai,

            "So_dong_sau_xu_ly":
                tong_dong_sau_xu_ly,

            "So_dong_review":
                tong_dong_review,

            "Doi_soat":
                "DAT"
                if doi_soat
                else "KHONG_DAT"
        }
    ]
)


FILE_KET_QUA = (
    THU_MUC_KET_QUA
    / "01_Ket_qua_xu_ly_trung_lap.csv"
)


bang_ket_qua.to_csv(
    FILE_KET_QUA,
    index=False,
    encoding="utf-8-sig"
)


print("\nĐã lưu dữ liệu sau xử lý:")
print(FILE_OUTPUT)

print("\nĐã lưu dữ liệu cần review:")
print(FILE_REVIEW)

print("\nĐã lưu bảng kết quả:")
print(FILE_KET_QUA)

print("\nHOÀN TẤT 2.3.1")