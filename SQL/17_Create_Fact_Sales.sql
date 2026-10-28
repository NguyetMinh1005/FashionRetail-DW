USE Fashion_DW;
GO

/* ============================================================
   17 - CREATE FACT SALES
   ============================================================ */

IF OBJECT_ID('dbo.Fact_Sales', 'U') IS NOT NULL
    DROP TABLE dbo.Fact_Sales;
GO

CREATE TABLE dbo.Fact_Sales
(
    Sales_Key BIGINT IDENTITY(1,1) PRIMARY KEY,

    /* Khóa liên kết Dimension */
    Customer_Key INT NULL,
    Product_Key INT NOT NULL,
    Store_Key INT NOT NULL,
    Employee_Key INT NULL,
    Date_Key INT NOT NULL,

    /* Degenerate Dimension */
    Invoice_ID NVARCHAR(100) NOT NULL,
    Line NVARCHAR(50) NULL,

    /* Thông tin sản phẩm tại thời điểm giao dịch */
    Size NVARCHAR(50) NULL,
    Color NVARCHAR(50) NULL,
    SKU NVARCHAR(200) NULL,

    /* Thông tin giao dịch */
    Transaction_Type NVARCHAR(50) NULL,
    Payment_Method NVARCHAR(50) NULL,
    Currency NVARCHAR(50) NULL,
    Currency_Symbol NVARCHAR(20) NULL,

    /* Measures */
    Unit_Price DECIMAL(18,2) NULL,
    Quantity INT NULL,
    Discount DECIMAL(18,4) NULL,
    Line_Total DECIMAL(18,2) NULL,
    Invoice_Total DECIMAL(18,2) NULL,

    Net_Amount DECIMAL(18,2) NULL,
    Sales_Quantity INT NULL,
    Return_Quantity INT NULL,

    Is_Return BIT NULL,

    /* Quy đổi tiền tệ */
    Net_Amount_Local DECIMAL(18,2) NULL,
    Exchange_Rate_To_USD DECIMAL(18,8) NULL,
    Net_Amount_USD DECIMAL(18,2) NULL,

    /* Giá vốn */
    Production_Cost DECIMAL(18,2) NULL
);
GO

------------------
SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME = 'Fact_Sales';
GO
---------------------------------------------
SELECT
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Fact_Sales'
ORDER BY ORDINAL_POSITION;
GO