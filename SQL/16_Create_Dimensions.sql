USE Fashion_DW;
GO

/* ============================================================
   16 - CREATE DIMENSIONS
   Dự án: Fashion Retail Data Warehouse

   Gồm 8 Dimension:
   1. Dim_Customer
   2. Dim_Product
   3. Dim_Store
   4. Dim_Employee
   5. Dim_Date
   6. Dim_Promotion
   7. Dim_Payment
   8. Dim_Currency
   ============================================================ */


/* ============================================================
   LƯU Ý TRƯỚC KHI CHẠY
   ============================================================

   Nếu Fact_Sales đã tồn tại và đã có FOREIGN KEY tới các DIM,
   cần DROP Fact_Sales trước hoặc chạy lại quy trình tạo DW
   theo đúng thứ tự:

   16_Create_Dimensions.sql
   17_Create_Fact_Sales.sql
   sau đó mới Load DIM và FACT.

   ============================================================ */


/* ============================================================
   1. DIM CUSTOMER
   ============================================================ */

IF OBJECT_ID('dbo.Dim_Customer', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Customer;
GO

CREATE TABLE dbo.Dim_Customer
(
    /* Surrogate Key */
    Customer_Key INT IDENTITY(1,1) NOT NULL,

    /* Business Key từ nguồn */
    Customer_ID INT NOT NULL,

    /* Thuộc tính phục vụ phân tích khách hàng */
    Gender CHAR(1) NULL,
    Date_Of_Birth DATE NULL,
    Age INT NULL,
    Age_Group NVARCHAR(30) NULL,

    City NVARCHAR(100) NULL,
    Country NVARCHAR(100) NULL,
    Job_Title NVARCHAR(255) NULL,

    CONSTRAINT PK_Dim_Customer
        PRIMARY KEY (Customer_Key),

    CONSTRAINT UQ_Dim_Customer_Customer_ID
        UNIQUE (Customer_ID)
);
GO


/* ============================================================
   2. DIM PRODUCT
   ============================================================ */

IF OBJECT_ID('dbo.Dim_Product', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Product;
GO

CREATE TABLE dbo.Dim_Product
(
    /* Surrogate Key */
    Product_Key INT IDENTITY(1,1) NOT NULL,

    /* Business Key */
    Product_ID INT NOT NULL,

    /* Phân loại sản phẩm */
    Category NVARCHAR(100) NULL,
    Sub_Category NVARCHAR(100) NULL,

    /* Mô tả đa ngôn ngữ */
    Description_PT NVARCHAR(500) NULL,
    Description_DE NVARCHAR(500) NULL,
    Description_FR NVARCHAR(500) NULL,
    Description_ES NVARCHAR(500) NULL,
    Description_EN NVARCHAR(500) NULL,
    Description_ZH NVARCHAR(500) NULL,

    /* Chi phí sản xuất */
    Production_Cost DECIMAL(18,2) NULL,

    CONSTRAINT PK_Dim_Product
        PRIMARY KEY (Product_Key),

    CONSTRAINT UQ_Dim_Product_Product_ID
        UNIQUE (Product_ID)
);
GO


/* ============================================================
   3. DIM STORE
   ============================================================ */

IF OBJECT_ID('dbo.Dim_Store', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Store;
GO

CREATE TABLE dbo.Dim_Store
(
    /* Surrogate Key */
    Store_Key INT IDENTITY(1,1) NOT NULL,

    /* Business Key */
    Store_ID INT NOT NULL,

    /* Thông tin cửa hàng */
    Store_Name NVARCHAR(150) NULL,

    /* Địa lý */
    City NVARCHAR(100) NULL,
    Country NVARCHAR(100) NULL,
    Country_Code NVARCHAR(20) NULL,
    ZIP_Code NVARCHAR(20) NULL,

    Latitude DECIMAL(9,4) NULL,
    Longitude DECIMAL(9,4) NULL,

    /*
       Số nhân viên được tính từ employees,
       KHÔNG lấy trực tiếp Number Of Employees từ stores.
    */
    Employee_Count INT NULL,

    CONSTRAINT PK_Dim_Store
        PRIMARY KEY (Store_Key),

    CONSTRAINT UQ_Dim_Store_Store_ID
        UNIQUE (Store_ID)
);
GO


/* ============================================================
   4. DIM EMPLOYEE
   ============================================================ */

IF OBJECT_ID('dbo.Dim_Employee', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Employee;
GO

CREATE TABLE dbo.Dim_Employee
(
    /* Surrogate Key */
    Employee_Key INT IDENTITY(1,1) NOT NULL,

    /* Business Key */
    Employee_ID INT NOT NULL,

    /*
       Store_ID giữ lại để biết nhân viên thuộc cửa hàng nào.
       Không dùng Employee_Name làm khóa.
    */
    Store_ID INT NULL,

    Employee_Name NVARCHAR(150) NULL,
    Position NVARCHAR(100) NULL,

    CONSTRAINT PK_Dim_Employee
        PRIMARY KEY (Employee_Key),

    CONSTRAINT UQ_Dim_Employee_Employee_ID
        UNIQUE (Employee_ID)
);
GO


/* ============================================================
   5. DIM DATE
   ============================================================ */

IF OBJECT_ID('dbo.Dim_Date', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Date;
GO

CREATE TABLE dbo.Dim_Date
(
    /*
       Date_Key dạng YYYYMMDD.
       Ví dụ: 20250318
    */
    Date_Key INT NOT NULL,

    Full_Date DATE NOT NULL,

    Day_Number TINYINT NOT NULL,
    Day_Name NVARCHAR(20) NOT NULL,

    Day_Of_Week TINYINT NULL,
    Week_Number TINYINT NULL,

    Month_Number TINYINT NOT NULL,
    Month_Name NVARCHAR(20) NOT NULL,

    Quarter_Number TINYINT NOT NULL,
    Year_Number SMALLINT NOT NULL,

    Is_Weekend BIT NOT NULL,

    /*
       Mùa dùng cho phân tích tính mùa vụ.
       Quy ước theo bán cầu Bắc.
    */
    Season NVARCHAR(20) NULL,

    CONSTRAINT PK_Dim_Date
        PRIMARY KEY (Date_Key),

    CONSTRAINT UQ_Dim_Date_Full_Date
        UNIQUE (Full_Date)
);
GO


/* ============================================================
   6. DIM PROMOTION
   ============================================================ */

IF OBJECT_ID('dbo.Dim_Promotion', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Promotion;
GO

CREATE TABLE dbo.Dim_Promotion
(
    /* Surrogate Key */
    Promotion_Key INT IDENTITY(1,1) NOT NULL,

    Start_Date DATE NULL,
    End_Date DATE NULL,

    /* Mức giảm từ 0 đến 1 */
    Discount_Rate DECIMAL(4,2) NULL,

    Promotion_Name NVARCHAR(150) NULL,

    /*
       Category / Sub_Category có thể NULL
       đối với chương trình áp dụng toàn bộ nhóm hàng.
    */
    Category NVARCHAR(100) NULL,
    Sub_Category NVARCHAR(100) NULL,

    CONSTRAINT PK_Dim_Promotion
        PRIMARY KEY (Promotion_Key)
);
GO


/* ============================================================
   7. DIM PAYMENT
   ============================================================ */

IF OBJECT_ID('dbo.Dim_Payment', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Payment;
GO

CREATE TABLE dbo.Dim_Payment
(
    /* Surrogate Key */
    Payment_Key INT IDENTITY(1,1) NOT NULL,

    /*
       Junk Dimension:
       kết hợp Payment Method + Transaction Type.
    */
    Payment_Method NVARCHAR(50) NOT NULL,
    Transaction_Type NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_Dim_Payment
        PRIMARY KEY (Payment_Key),

    CONSTRAINT UQ_Dim_Payment
        UNIQUE (Payment_Method, Transaction_Type)
);
GO


/* ============================================================
   8. DIM CURRENCY
   ============================================================ */

IF OBJECT_ID('dbo.Dim_Currency', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Currency;
GO

CREATE TABLE dbo.Dim_Currency
(
    /* Surrogate Key */
    Currency_Key INT IDENTITY(1,1) NOT NULL,

    /*
       Có 4 Currency chính:
       USD, EUR, GBP, CNY
    */
    Currency_Code CHAR(3) NOT NULL,
    Currency_Symbol NVARCHAR(5) NULL,

    CONSTRAINT PK_Dim_Currency
        PRIMARY KEY (Currency_Key),

    CONSTRAINT UQ_Dim_Currency_Currency_Code
        UNIQUE (Currency_Code)
);
GO


/* ============================================================
   KIỂM TRA CÁC DIMENSION ĐÃ TẠO
   ============================================================ */

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
  AND TABLE_NAME LIKE 'Dim_%'
ORDER BY TABLE_NAME;
GO


/* ============================================================
   KIỂM TRA CẤU TRÚC TỪNG DIMENSION
   ============================================================ */

SELECT
    TABLE_NAME,
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN
(
    'Dim_Customer',
    'Dim_Product',
    'Dim_Store',
    'Dim_Employee',
    'Dim_Date',
    'Dim_Promotion',
    'Dim_Payment',
    'Dim_Currency'
)
ORDER BY TABLE_NAME, ORDINAL_POSITION;
GO


------------------------
