USE Fashion_DW;
GO

/* ============================================================
   17 - CREATE FACT SALES
   Dự án: Fashion Retail Data Warehouse

   Grain:
   Một dòng Fact_Sales tương ứng với một sản phẩm,
   một Size và Color cụ thể trên một dòng hóa đơn
   bán hoặc trả hàng.

   Fact liên kết với 8 Dimension:
   1. Dim_Date
   2. Dim_Product
   3. Dim_Store
   4. Dim_Customer
   5. Dim_Employee
   6. Dim_Promotion
   7. Dim_Payment
   8. Dim_Currency
   ============================================================ */


/* ============================================================
   1. XÓA FACT CŨ NẾU ĐÃ TỒN TẠI
   ============================================================ */

IF OBJECT_ID('dbo.Fact_Sales', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Fact_Sales;
    PRINT N'Đã xóa bảng Fact_Sales cũ.';
END;
GO


/* ============================================================
   2. TẠO FACT_SALES
   ============================================================ */

CREATE TABLE dbo.Fact_Sales
(
    /* ========================================================
       KHÓA CHÍNH - SURROGATE KEY
       ======================================================== */

    Sales_Key BIGINT IDENTITY(1,1) NOT NULL,


    /* ========================================================
       8 KHÓA NGOẠI TỚI DIMENSION
       ======================================================== */

    Date_Key INT NOT NULL,
    Product_Key INT NOT NULL,
    Store_Key INT NOT NULL,
    Customer_Key INT NOT NULL,
    Employee_Key INT NOT NULL,
    Promotion_Key INT NOT NULL,
    Payment_Key INT NOT NULL,
    Currency_Key INT NOT NULL,


    /* ========================================================
       THUỘC TÍNH Ở MỨC DÒNG GIAO DỊCH
       ======================================================== */

    /*
       Invoice_ID và Line_Number dùng để truy vết
       về giao dịch nguồn.

       Không dùng cặp này làm Primary Key vì nguồn
       có các trường hợp trùng.
    */
    Invoice_ID NVARCHAR(30) NOT NULL,
    Line_Number INT NOT NULL,

    /*
       Size, Color, SKU lấy từ transaction,
       không lấy từ Dim_Product.
    */
    Size NVARCHAR(20) NULL,
    Color NVARCHAR(20) NULL,
    SKU NVARCHAR(60) NULL,

    /*
       Giờ phát sinh giao dịch.
       Date_Key chỉ lưu đến cấp ngày.
       Hour_Of_Day giữ lại để có thể phân tích theo giờ.
    */
    Hour_Of_Day TINYINT NULL,


    /* ========================================================
       CÁC ĐỘ ĐO / MEASURE
       ======================================================== */

    /*
       +1 = Sale
       -1 = Return

       Dùng để chuẩn hóa dấu giữa bán và trả hàng.
    */
    Sign_Flag SMALLINT NOT NULL,

    /*
       Đơn giá một sản phẩm trước giảm giá.
       Không cộng trực tiếp Unit_Price.
    */
    Unit_Price DECIMAL(18,2) NULL,

    /*
       Tỷ lệ giảm giá từ 0 đến 1.
       Ví dụ: 0.20 = giảm 20%.
    */
    Discount_Rate DECIMAL(4,2) NULL,

    /*
       Quantity là số lượng tuyệt đối.
       Theo dữ liệu nguồn Quantity luôn dương
       kể cả dòng Return.
    */
    Quantity INT NOT NULL,

    /*
       Net_Quantity:
       Sale   -> Quantity dương
       Return -> Quantity âm

       Công thức:
       Sign_Flag * Quantity
    */
    Net_Quantity INT NOT NULL,

    /*
       Gross_Amount:
       giá trị trước giảm giá, đã mang dấu Sale/Return.

       Sign_Flag * Unit_Price * Quantity
    */
    Gross_Amount DECIMAL(18,2) NULL,

    /*
       Net_Amount:
       doanh thu thuần của dòng giao dịch
       theo đồng tiền gốc.

       Sale   -> dương
       Return -> âm

       Lấy từ dấu của Line_Total nguồn.
    */
    Net_Amount DECIMAL(18,2) NOT NULL,

    /*
       Discount_Amount:
       tiền giảm giá.

       Với KPI giảm giá chỉ sử dụng các dòng Sale.
    */
    Discount_Amount DECIMAL(18,2) NULL,


    /* ========================================================
       QUY ĐỔI TIỀN TỆ
       ======================================================== */

    Net_Amount_Local DECIMAL(18,2) NULL,
    Exchange_Rate_To_USD DECIMAL(18,8) NULL,
    Exchange_Rate_Date DATE NULL,
    Exchange_Rate_Source NVARCHAR(100) NULL,
    Net_Amount_USD DECIMAL(18,4) NULL,

    /*
       Doanh thu sau quy đổi sang đồng tiền báo cáo.
       Chỉ có giá trị khi nhóm có nguồn tỷ giá được xác nhận.
    */
    Net_Amount_Report DECIMAL(18,2) NULL,


    /* ========================================================
       GIÁ VỐN ƯỚC TÍNH
       ======================================================== */

    /*
       Cost_Amount =
       Net_Quantity * Production_Cost

       Chỉ dùng để tính lợi nhuận gộp ước tính khi
       Production_Cost và doanh thu có đơn vị tiền phù hợp.
    */
    Cost_Amount DECIMAL(18,2) NULL,


    /* ========================================================
       PRIMARY KEY
       ======================================================== */

    CONSTRAINT PK_Fact_Sales
        PRIMARY KEY (Sales_Key),


    /* ========================================================
       FOREIGN KEY -> DIM_DATE
       ======================================================== */

    CONSTRAINT FK_Fact_Sales_Dim_Date
        FOREIGN KEY (Date_Key)
        REFERENCES dbo.Dim_Date(Date_Key),


    /* ========================================================
       FOREIGN KEY -> DIM_PRODUCT
       ======================================================== */

    CONSTRAINT FK_Fact_Sales_Dim_Product
        FOREIGN KEY (Product_Key)
        REFERENCES dbo.Dim_Product(Product_Key),


    /* ========================================================
       FOREIGN KEY -> DIM_STORE
       ======================================================== */

    CONSTRAINT FK_Fact_Sales_Dim_Store
        FOREIGN KEY (Store_Key)
        REFERENCES dbo.Dim_Store(Store_Key),


    /* ========================================================
       FOREIGN KEY -> DIM_CUSTOMER
       ======================================================== */

    CONSTRAINT FK_Fact_Sales_Dim_Customer
        FOREIGN KEY (Customer_Key)
        REFERENCES dbo.Dim_Customer(Customer_Key),


    /* ========================================================
       FOREIGN KEY -> DIM_EMPLOYEE
       ======================================================== */

    CONSTRAINT FK_Fact_Sales_Dim_Employee
        FOREIGN KEY (Employee_Key)
        REFERENCES dbo.Dim_Employee(Employee_Key),


    /* ========================================================
       FOREIGN KEY -> DIM_PROMOTION
       ======================================================== */

    CONSTRAINT FK_Fact_Sales_Dim_Promotion
        FOREIGN KEY (Promotion_Key)
        REFERENCES dbo.Dim_Promotion(Promotion_Key),


    /* ========================================================
       FOREIGN KEY -> DIM_PAYMENT
       ======================================================== */

    CONSTRAINT FK_Fact_Sales_Dim_Payment
        FOREIGN KEY (Payment_Key)
        REFERENCES dbo.Dim_Payment(Payment_Key),


    /* ========================================================
       FOREIGN KEY -> DIM_CURRENCY
       ======================================================== */

    CONSTRAINT FK_Fact_Sales_Dim_Currency
        FOREIGN KEY (Currency_Key)
        REFERENCES dbo.Dim_Currency(Currency_Key),


    /* ========================================================
       CHECK CONSTRAINTS
       ======================================================== */

    CONSTRAINT CK_Fact_Sales_Sign_Flag
        CHECK (Sign_Flag IN (-1, 1)),

    CONSTRAINT CK_Fact_Sales_Quantity
        CHECK (Quantity > 0),

    CONSTRAINT CK_Fact_Sales_Discount_Rate
        CHECK
        (
            Discount_Rate IS NULL
            OR Discount_Rate BETWEEN 0 AND 1
        ),

    CONSTRAINT CK_Fact_Sales_Hour
        CHECK
        (
            Hour_Of_Day IS NULL
            OR Hour_Of_Day BETWEEN 0 AND 23
        )
);
GO


/* ============================================================
   3. KIỂM TRA FACT ĐÃ ĐƯỢC TẠO
   ============================================================ */

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Fact_Sales';
GO


/* ============================================================
   4. KIỂM TRA CẤU TRÚC FACT
   ============================================================ */

SELECT
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Fact_Sales'
ORDER BY ORDINAL_POSITION;
GO


/* ============================================================
   5. KIỂM TRA FOREIGN KEY
   ============================================================ */

SELECT
    fk.name AS Foreign_Key_Name,
    OBJECT_NAME(fk.parent_object_id) AS Fact_Table,
    COL_NAME(fkc.parent_object_id,
             fkc.parent_column_id) AS Fact_Column,
    OBJECT_NAME(fk.referenced_object_id) AS Dimension_Table,
    COL_NAME(fkc.referenced_object_id,
             fkc.referenced_column_id) AS Dimension_Column
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc
    ON fk.object_id = fkc.constraint_object_id
WHERE fk.parent_object_id = OBJECT_ID('dbo.Fact_Sales')
ORDER BY fk.name;
GO


/* ============================================================
   6. KIỂM TRA SỐ FOREIGN KEY

   Kết quả mong đợi = 8
   ============================================================ */

SELECT
    COUNT(*) AS Number_Of_Foreign_Keys
FROM sys.foreign_keys
WHERE parent_object_id = OBJECT_ID('dbo.Fact_Sales');
GO