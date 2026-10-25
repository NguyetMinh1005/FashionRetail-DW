
# 🛍️ FashionRetail-DW: Hệ thống Kho dữ liệu và Hỗ trợ ra quyết định (BI/DSS) cho Chuỗi Cửa hàng Thời trang

> **Đồ án môn học:** Kho dữ liệu và Hệ thống hỗ trợ ra quyết định (Data Warehouse & Decision Support System)  
> **Đề tài:** Xây dựng kho dữ liệu và hệ thống hỗ trợ ra quyết định phân tích hoạt động bán hàng và tiêu dùng cho chuỗi cửa hàng thời trang (*Global Fashion Retail Sales*).

---

## 📌 1. Giới thiệu dự án

Dự án **FashionRetail-DW** tập trung xây dựng một đường ống dữ liệu (Data Pipeline) hoàn chỉnh từ việc khảo sát, làm sạch dữ liệu thô quy mô lớn (hơn **6,4 triệu bản ghi** giao dịch), tích hợp dữ liệu qua quy trình **ETL (SSIS)** vào Kho dữ liệu (**SQL Server**) theo mô hình **Star Schema**, cho đến việc xây dựng các báo cáo trực quan và phân tích kịch bản (*What-if Analysis*) trên **Power BI**.

Hệ thống giúp nhà quản lý giải quyết các bài toán cốt lõi:
* Theo dõi doanh thu thuần (*Net Revenue*), giá trị đơn hàng trung bình (**AOV**) và số sản phẩm trên mỗi đơn (**UPT**) theo thời gian, quốc gia và danh mục.
* Đánh giá hiệu suất hoạt động của cửa hàng và doanh thu trung bình trên mỗi nhân viên.
* Phân tích sản phẩm bán chạy theo quy tắc Pareto (80/20), xu hướng tiêu dùng theo kích cỡ (*Size*) và màu sắc (*Color*).
* Kiểm soát tỷ lệ trả hàng (*Return Rate*) và đánh giá tác động của các chương trình khuyến mãi đến sản lượng bán.
* Phân tích nhân khẩu học khách hàng (độ tuổi, giới tính, quốc gia) và tần suất mua lặp lại.

---

## 📊 2. Tổng quan Bộ dữ liệu (Dataset)

Bộ dữ liệu **Global Fashion Retail Sales** ghi nhận hoạt động bán lẻ từ `01/01/2023` đến `18/03/2025` tại **35 cửa hàng** thuộc **7 quốc gia** (Mỹ, Anh, Pháp, Đức, Tây Ban Nha, Bồ Đào Nha, Trung Quốc).

| Tệp dữ liệu | Số dòng gốc | Số cột | Số dòng sau làm sạch | Mô tả nội dung |
| :--- | :---: | :---: | :---: | :--- |
| `transactions.csv` | 6.416.827 | 19 | **6.416.029** | Lịch sử giao dịch bán hàng (`Sale` - 94,7%) và trả hàng (`Return` - 5,3%). Đã loại bỏ 798 dòng trùng hoàn toàn. |
| `customers.csv` | 1.643.306 | 9 | **1.643.306** | Thông tin khách hàng, ngày sinh, nghề nghiệp, quốc gia. |
| `products.csv` | 17.940 | 12 | **17.940** | Danh mục sản phẩm, giá vốn (`Production Cost`), kích cỡ, màu sắc. |
| `employees.csv` | 404 | 4 | **404** | Danh sách nhân viên bán hàng và cửa hàng trực thuộc. |
| `discounts.csv` | 181 | 6 | **181** | Chương trình khuyến mãi theo thời gian và danh mục sản phẩm. |
| `stores.csv` | 35 | 8 | **35** | Thông tin hệ thống cửa hàng, tọa độ địa lý và số lượng nhân sự. |

---

## 🏗️ 3. Kiến trúc Hệ thống & Mô hình Dữ liệu

### 3.1. Luồng xử lý dữ liệu (Data Pipeline)
```text
[Dữ liệu nguồn (6 CSV)] 
       │
       ▼
[Python / Pandas] ──► Khảo sát (Profiling), Xử lý trùng lặp, Điền NULL ('Unknown'), 
       │              Chuẩn hóa kiểu dữ liệu, Tạo cột dẫn xuất & Kiểm tra 13 Rules (R1-R13)
       ▼
[Cleaned CSVs]    ──► Lưu tại data/cleaned/ (kèm luồng đối soát REVIEW / ERROR)
       │
       ▼
[SSIS Package]    ──► Extract từ CSV sạch ──► Nạp vào vùng đệm SQL Server (Fashion_Staging)
       │          ──► Transform & Lookup Surrogate Keys ──► Nạp vào Kho dữ liệu (Fashion_DW)
       ▼
[Power BI]        ──► Xây dựng Semantic Model (Star Schema), DAX Measures, Dashboard & What-If
```

### 3.2. Thiết kế Lược đồ Hình sao (Star Schema)
Mô hình Kho dữ liệu được thiết kế theo phương pháp luận **Bottom-up (Kimball)** gồm:
* **Bảng sự kiện trung tâm (`Fact_Sales`):** Lưu trữ ở mức độ chi tiết (*Grain*) là từng dòng sản phẩm trên hóa đơn (`Invoice_ID`, `Line`), chứa các chỉ số đo lường cộng được (*Additive Measures*) như `Sales_Quantity`, `Return_Quantity`, `Net_Amount`.
* **8 Bảng chiều (`Dimensions`):**
  1. `Dim_Date`: Chiều thời gian (Ngày, Tháng, Quý, Năm, Mùa).
  2. `Dim_Product`: Thông tin sản phẩm, Category, Sub_Category, Size, Color, Giá vốn.
  3. `Dim_Store`: Thông tin cửa hàng, Thành phố, Quốc gia.
  4. `Dim_Customer`: Thông tin khách hàng, Giới tính, Nhóm tuổi (`Age_Group`).
  5. `Dim_Employee`: Nhân viên thực hiện giao dịch và chức vụ.
  6. `Dim_Promotion`: Chương trình giảm giá áp dụng.
  7. `Dim_Payment`: Phương thức thanh toán.
  8. `Dim_Currency`: Đơn vị tiền tệ và tỷ giá quy đổi.

---

## 📁 4. Cấu trúc Thư mục Dự án (Repository Structure)

```text
FashionRetail-DW/
│
├── 📂 Docs/
│   └── 📂 diagrams/                 # Sơ đồ kiến trúc hệ thống, Star Schema, Bus Matrix
│
├── 📂 Python/
│   ├── 📂 02_Khao_sat_du_lieu/      # Scripts khảo sát chất lượng dữ liệu (Mục 2.2)
│   │   ├── 01_Khao_sat_tong_quan.py
│   │   ├── 02_Kiem_tra_du_lieu_thieu.py
│   │   ├── 03_Kiem_tra_trung_lap.py
│   │   ├── 04_Quy_tac_nghiep_vu.py
│   │   └── 05_Phan_tich_bat_thuong.py
│   │
│   └── 📂 03_Tien_xu_ly_du_lieu/    # Scripts làm sạch và tiền xử lý dữ liệu (Mục 2.3)
│       ├── 01_Xu_ly_trung_lap.py
│       ├── 02_Xu_ly_du_lieu_thieu.py
│       ├── 03_Chuan_hoa_du_lieu.py
│       ├── 04_Tao_thuoc_tinh_dan_xuat.py
│       ├── 05_Phan_loai_valid_error.py
│       └── 06_Xuat_du_lieu_sach.py
│
├── 📂 SQL/                          # Scripts T-SQL khởi tạo Database (RAW, Staging, DW) & Kiểm thử
├── 📂 SSIS/                         # Project Visual Studio chứa gói ETL (.dtsx)
├── 📂 data/                         # Thư mục lưu dữ liệu (được cấu hình trong .gitignore)
│   ├── raw/                         # 6 file CSV gốc từ Kaggle (Giữ nguyên trạng)
│   ├── processed/                   # Dữ liệu trung gian qua các bước 2.3.1 -> 2.3.5
│   ├── cleaned/                     # 6 file CSV sạch đầu ra phục vụ nạp SSIS
│   ├── ket_qua_khao_sat/            # File CSV thống kê kết quả mục 2.2
│   └── ket_qua_tien_xu_ly/          # File CSV thống kê đối soát mục 2.3
│
├── .gitignore                       # Bỏ qua các file dữ liệu nặng và file rác hệ thống
└── README.md                        # Tài liệu hướng dẫn dự án
```
Ý nghĩa:

- `raw`: tuyệt đối không sửa.
- `processed`: dữ liệu đang được xử lý qua từng bước 2.3.
- `review`: dữ liệu bất thường nhưng **chưa chắc sai**, cần giữ để kiểm tra.
- `reject`: dữ liệu chắc chắn không đạt rule.
- `cleaned`: đầu ra cuối cùng để SSIS đọc.
- `ket_qua_tien_xu_ly`: các bảng thống kê nhỏ để đưa vào báo cáo.

---

## 🛠️ 5. Công nghệ và Công cụ Sử dụng

* **Ngôn ngữ & Tiền xử lý dữ liệu:** Python 3.x (`pandas`, `ydata-profiling`)
* **Hệ quản trị Cơ sở dữ liệu:** Microsoft SQL Server & SQL Server Management Studio (SSMS)
* **Công cụ Tích hợp dữ liệu (ETL):** SQL Server Integration Services (SSIS) trên Visual Studio 2022
* **Trực quan hóa & Hỗ trợ ra quyết định:** Microsoft Power BI Desktop (DAX, What-If Parameters)

---

## 🚀 6. Hướng dẫn Cài đặt và Thực thi

### Bước 1: Chuẩn bị dữ liệu nguồn
1. Tải bộ dữ liệu **Global Fashion Retail Sales** từ Kaggle.
2. Đặt 6 tệp CSV gốc (`transactions.csv`, `customers.csv`, `products.csv`, `stores.csv`, `employees.csv`, `discounts.csv`) vào thư mục `data/raw/`.

### Bước 2: Chạy quy trình Khảo sát & Tiền xử lý bằng Python
Cài đặt thư viện cần thiết và chạy lần lượt các script:
```bash
pip install pandas ydata-profiling

# 1. Chạy khảo sát chất lượng dữ liệu (Mục 2.2)
python Python/02_Khao_sat_du_lieu/01_Khao_sat_tong_quan.py
# ... (chạy tiếp từ 02 đến 05)

# 2. Chạy tiền xử lý dữ liệu (Mục 2.3)
python Python/03_Tien_xu_ly_du_lieu/01_Xu_ly_trung_lap.py
# ... (chạy tiếp từ 02 đến 06 để xuất file ra data/cleaned/)
```

### Bước 3: Khởi tạo Database và Chạy gói ETL (SSIS)
1. Mở **SSMS**, thực thi các kịch bản trong thư mục `SQL/` để khởi tạo database `Fashion_Staging` và `Fashion_DW`.
2. Mở giải pháp trong thư mục `SSIS/` bằng **Visual Studio 2022**.
3. Cập nhật lại đường dẫn `Flat File Connection Manager` (trỏ tới `data/cleaned/`) và `OLE DB Connection Manager` (trỏ tới SQL Server Instance trên máy của bạn).
4. Thực thi gói SSIS (`Start`) để nạp dữ liệu tự động qua `Staging` -> `8 Dimensions` -> `Fact_Sales`.

### Bước 4: Khai thác Báo cáo trên Power BI
Mở tệp báo cáo Power BI (`.pbix`), đổi nguồn kết nối (`Data source settings`) về máy chủ SQL Server chứa `Fashion_DW` và nhấn **Refresh** để cập nhật dữ liệu.

---
