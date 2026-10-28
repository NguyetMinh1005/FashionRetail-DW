USE Fashion_Staging;
GO

SET NOCOUNT ON;
GO

/* ============================================================
   NẠP LẠI CLEANED_TRANSACTIONS.CSV VÀO STG.TRANSACTIONS

   File:
   E:\FashionRetail-DW\data\cleaned\cleaned_transactions.csv

   Kỳ vọng:
   CSV                = 6,415,456 dòng
   stg.transactions   = 6,415,456 dòng
   ============================================================ */


/* ============================================================
   1. LÀM SẠCH BẢNG STG TRƯỚC KHI NẠP LẠI
   ============================================================ */

TRUNCATE TABLE stg.transactions;
GO

SELECT COUNT_BIG(*) AS STG_Truoc_Khi_Nap
FROM stg.transactions;
GO


/* ============================================================
   2. XÓA BẢNG TẠM NẾU ĐÃ TỒN TẠI
   ============================================================ */

IF OBJECT_ID('dbo.tmp_transactions_import', 'U') IS NOT NULL
    DROP TABLE dbo.tmp_transactions_import;
GO


/* ============================================================
   3. TẠO BẢNG TẠM

   Tạm thời để NVARCHAR để BULK INSERT an toàn.
   Sau đó mới TRY_CONVERT khi chuyển sang STG.
   ============================================================ */

CREATE TABLE dbo.tmp_transactions_import
(
    Invoice_ID               NVARCHAR(100) NULL,
    Line                     NVARCHAR(50)  NULL,
    Customer_ID              NVARCHAR(50)  NULL,
    Product_ID               NVARCHAR(50)  NULL,
    Size                     NVARCHAR(50)  NULL,
    Color                    NVARCHAR(100) NULL,
    Unit_Price               NVARCHAR(50)  NULL,
    Quantity                 NVARCHAR(50)  NULL,
    [Date]                   NVARCHAR(50)  NULL,
    Discount                 NVARCHAR(50)  NULL,
    Line_Total               NVARCHAR(50)  NULL,
    Store_ID                 NVARCHAR(50)  NULL,
    Employee_ID              NVARCHAR(50)  NULL,
    Currency                 NVARCHAR(20)  NULL,
    Currency_Symbol          NVARCHAR(20)  NULL,
    SKU                      NVARCHAR(255) NULL,
    Transaction_Type         NVARCHAR(50)  NULL,
    Payment_Method           NVARCHAR(100) NULL,
    Invoice_Total            NVARCHAR(50)  NULL,
    Country_Code             NVARCHAR(20)  NULL,
    Expected_Currency        NVARCHAR(20)  NULL,
    Currency_Match           NVARCHAR(20)  NULL,
    Transaction_Date         NVARCHAR(50)  NULL,
    Transaction_Time         NVARCHAR(50)  NULL,
    Is_Return                NVARCHAR(50)  NULL,
    Net_Amount               NVARCHAR(50)  NULL,
    Sales_Quantity           NVARCHAR(50)  NULL,
    Return_Quantity          NVARCHAR(50)  NULL,
    Exchange_Rate_To_USD     NVARCHAR(50)  NULL,
    Exchange_Rate_Date       NVARCHAR(50)  NULL,
    Exchange_Rate_Source     NVARCHAR(100) NULL,
    Net_Amount_Local         NVARCHAR(50)  NULL,
    Net_Amount_USD           NVARCHAR(50)  NULL
);
GO


/* ============================================================
   4. BULK INSERT CSV VÀO BẢNG TẠM
   ============================================================ */

BULK INSERT dbo.tmp_transactions_import
FROM 'E:\FashionRetail-DW\data\cleaned\cleaned_transactions.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,

    FIELDQUOTE = '"',

    CODEPAGE = '65001',

    TABLOCK,

    KEEPNULLS
);
GO


/* ============================================================
   5. KIỂM TRA SỐ DÒNG BẢNG TẠM
   ============================================================ */

SELECT
    COUNT_BIG(*) AS So_Dong_Bang_Tam
FROM dbo.tmp_transactions_import;
GO

/*
KỲ VỌNG:

So_Dong_Bang_Tam
----------------
6415456
*/


/* ============================================================
   6. KIỂM TRA NHANH DỮ LIỆU
   ============================================================ */

SELECT TOP 20 *
FROM dbo.tmp_transactions_import;
GO


/* ============================================================
   7. KIỂM TRA CÁC CỘT SỐ CÓ CONVERT ĐƯỢC KHÔNG
   ============================================================ */

SELECT
    SUM(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(Customer_ID)), '') IS NOT NULL
             AND TRY_CONVERT(INT, Customer_ID) IS NULL
            THEN 1 ELSE 0
        END
    ) AS Loi_Customer_ID,

    SUM(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(Product_ID)), '') IS NOT NULL
             AND TRY_CONVERT(INT, Product_ID) IS NULL
            THEN 1 ELSE 0
        END
    ) AS Loi_Product_ID,

    SUM(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(Store_ID)), '') IS NOT NULL
             AND TRY_CONVERT(INT, Store_ID) IS NULL
            THEN 1 ELSE 0
        END
    ) AS Loi_Store_ID,

    SUM(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(Employee_ID)), '') IS NOT NULL
             AND TRY_CONVERT(INT, Employee_ID) IS NULL
            THEN 1 ELSE 0
        END
    ) AS Loi_Employee_ID,

    SUM(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(Quantity)), '') IS NOT NULL
             AND TRY_CONVERT(INT, Quantity) IS NULL
            THEN 1 ELSE 0
        END
    ) AS Loi_Quantity

FROM dbo.tmp_transactions_import;
GO

/*
Các giá trị trên nên = 0.
*/


/* ============================================================
   8. NẠP VÀO STG.TRANSACTIONS

   KHÔNG nạp Stg_Row_ID
   vì SQL Server tự sinh IDENTITY.

   Source_File và Load_Date được thêm tại đây.
   ============================================================ */

INSERT INTO stg.transactions WITH (TABLOCK)
(
    Invoice_ID,
    Line,
    Customer_ID,
    Product_ID,
    Size,
    Color,

    Unit_Price,
    Quantity,
    [Date],
    Discount,
    Line_Total,

    Store_ID,
    Employee_ID,

    Currency,
    Currency_Symbol,
    SKU,

    Transaction_Type,
    Payment_Method,
    Invoice_Total,

    Transaction_Date,
    Transaction_Time,

    Is_Return,
    Net_Amount,
    Sales_Quantity,
    Return_Quantity,

    Country_Code,
    Expected_Currency,
    Currency_Match,

    Exchange_Rate_To_USD,
    Exchange_Rate_Date,
    Exchange_Rate_Source,

    Net_Amount_Local,
    Net_Amount_USD,

    Source_File,
    Load_Date
)

SELECT
    NULLIF(LTRIM(RTRIM(Invoice_ID)), ''),

    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(Line)), '')),

    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(Customer_ID)), '')),

    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(Product_ID)), '')),

    NULLIF(LTRIM(RTRIM(Size)), ''),

    NULLIF(LTRIM(RTRIM(Color)), ''),


    TRY_CONVERT(
        DECIMAL(18,2),
        NULLIF(LTRIM(RTRIM(Unit_Price)), '')
    ),

    TRY_CONVERT(
        INT,
        NULLIF(LTRIM(RTRIM(Quantity)), '')
    ),

    TRY_CONVERT(
        DATE,
        NULLIF(LTRIM(RTRIM([Date])), '')
    ),

    TRY_CONVERT(
        DECIMAL(18,4),
        NULLIF(LTRIM(RTRIM(Discount)), '')
    ),

    TRY_CONVERT(
        DECIMAL(18,2),
        NULLIF(LTRIM(RTRIM(Line_Total)), '')
    ),


    TRY_CONVERT(
        INT,
        NULLIF(LTRIM(RTRIM(Store_ID)), '')
    ),

    TRY_CONVERT(
        INT,
        NULLIF(LTRIM(RTRIM(Employee_ID)), '')
    ),


    NULLIF(LTRIM(RTRIM(Currency)), ''),

    NULLIF(LTRIM(RTRIM(Currency_Symbol)), ''),

    NULLIF(LTRIM(RTRIM(SKU)), ''),


    NULLIF(LTRIM(RTRIM(Transaction_Type)), ''),

    NULLIF(LTRIM(RTRIM(Payment_Method)), ''),

    TRY_CONVERT(
        DECIMAL(18,2),
        NULLIF(LTRIM(RTRIM(Invoice_Total)), '')
    ),


    TRY_CONVERT(
        DATE,
        NULLIF(LTRIM(RTRIM(Transaction_Date)), '')
    ),

    TRY_CONVERT(
        TIME(0),
        NULLIF(LTRIM(RTRIM(Transaction_Time)), '')
    ),


    TRY_CONVERT(
        BIT,
        NULLIF(LTRIM(RTRIM(Is_Return)), '')
    ),

    TRY_CONVERT(
        DECIMAL(18,2),
        NULLIF(LTRIM(RTRIM(Net_Amount)), '')
    ),

    TRY_CONVERT(
        INT,
        NULLIF(LTRIM(RTRIM(Sales_Quantity)), '')
    ),

    TRY_CONVERT(
        INT,
        NULLIF(LTRIM(RTRIM(Return_Quantity)), '')
    ),


    NULLIF(LTRIM(RTRIM(Country_Code)), ''),

    NULLIF(LTRIM(RTRIM(Expected_Currency)), ''),

    CASE
        WHEN LOWER(LTRIM(RTRIM(Currency_Match))) IN
             ('true', '1', 'yes')
            THEN 1

        WHEN LOWER(LTRIM(RTRIM(Currency_Match))) IN
             ('false', '0', 'no')
            THEN 0

        ELSE NULL
    END,


    TRY_CONVERT(
        DECIMAL(18,8),
        NULLIF(LTRIM(RTRIM(Exchange_Rate_To_USD)), '')
    ),

    TRY_CONVERT(
        DATE,
        NULLIF(LTRIM(RTRIM(Exchange_Rate_Date)), '')
    ),

    NULLIF(
        LTRIM(RTRIM(Exchange_Rate_Source)),
        ''
    ),


    TRY_CONVERT(
        DECIMAL(18,2),
        NULLIF(LTRIM(RTRIM(Net_Amount_Local)), '')
    ),

    TRY_CONVERT(
        DECIMAL(18,4),
        NULLIF(LTRIM(RTRIM(Net_Amount_USD)), '')
    ),


    N'cleaned_transactions.csv',

    GETDATE()

FROM dbo.tmp_transactions_import;
GO


/* ============================================================
   9. ĐỐI SOÁT STG
   ============================================================ */

SELECT
    COUNT_BIG(*) AS STG_Transactions
FROM stg.transactions;
GO

/*
KỲ VỌNG:

6415456
*/


/* ============================================================
   10. ĐỐI SOÁT CSV -> STG
   ============================================================ */

SELECT

    (
        SELECT COUNT_BIG(*)
        FROM dbo.tmp_transactions_import
    ) AS CSV_Rows,

    (
        SELECT COUNT_BIG(*)
        FROM stg.transactions
    ) AS STG_Rows,

    (
        SELECT COUNT_BIG(*)
        FROM dbo.tmp_transactions_import
    )
    -
    (
        SELECT COUNT_BIG(*)
        FROM stg.transactions
    ) AS Difference;
GO

/*
KỲ VỌNG:

CSV_Rows     = 6415456
STG_Rows     = 6415456
Difference   = 0
*/


/* ============================================================
   11. KIỂM TRA STG_ROW_ID
   ============================================================ */

SELECT
    MIN(Stg_Row_ID) AS Min_Stg_Row_ID,
    MAX(Stg_Row_ID) AS Max_Stg_Row_ID,
    COUNT_BIG(*)    AS Total_Rows
FROM stg.transactions;
GO

/*
Nếu vừa TRUNCATE:

Min_Stg_Row_ID = 1
Max_Stg_Row_ID = 6415456
Total_Rows     = 6415456
*/


/* ============================================================
   12. XEM MẪU SAU KHI NẠP
   ============================================================ */

SELECT TOP 50 *
FROM stg.transactions
ORDER BY Stg_Row_ID;
GO


/* ============================================================
   13. XÓA BẢNG TẠM
   ============================================================ */

DROP TABLE dbo.tmp_transactions_import;
GO


/* ============================================================
   14. THÔNG BÁO HOÀN TẤT
   ============================================================ */

PRINT N'===============================================';
PRINT N'HOÀN TẤT NẠP CLEANED_TRANSACTIONS VÀO STG';
PRINT N'Kỳ vọng: 6,415,456 dòng';
PRINT N'Tiếp theo: chạy 26_Load_Fact_Sales.sql';
PRINT N'Sau đó: chạy 27_Validation_DW.sql';
PRINT N'===============================================';
GO