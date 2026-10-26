USE Fashion_Staging;
GO
ALTER DATABASE Fashion_Staging SET RECOVERY SIMPLE;
GO
IF SCHEMA_ID('stg') IS NULL EXEC('CREATE SCHEMA stg');
GO

CREATE TABLE stg.transactions (
    Stg_Row_ID        BIGINT IDENTITY(1,1) PRIMARY KEY,
    Invoice_ID        NVARCHAR(50),
    Line              NVARCHAR(20),
    Customer_ID       NVARCHAR(20),
    Product_ID        NVARCHAR(20),
    Size              NVARCHAR(20),
    Color             NVARCHAR(50),
    Unit_Price        NVARCHAR(30),
    Quantity          NVARCHAR(20),
    [Date]            NVARCHAR(30),
    Discount          NVARCHAR(20),
    Line_Total        NVARCHAR(30),
    Store_ID          NVARCHAR(20),
    Employee_ID       NVARCHAR(20),
    Currency          NVARCHAR(10),
    Currency_Symbol   NVARCHAR(10),
    SKU               NVARCHAR(100),
    Transaction_Type  NVARCHAR(20),
    Payment_Method    NVARCHAR(30),
    Invoice_Total     NVARCHAR(30),
    Transaction_Date  NVARCHAR(20),
    Transaction_Time  NVARCHAR(20),
    Is_Return         NVARCHAR(5),
    Net_Amount        NVARCHAR(30),
    Sales_Quantity    NVARCHAR(20),
    Return_Quantity   NVARCHAR(20),
    Is_Review         BIT NOT NULL DEFAULT 0,
    Source_File       NVARCHAR(100) DEFAULT 'cleaned_transactions.csv',
    Load_Date         DATETIME2(0) DEFAULT SYSDATETIME()
);

CREATE TABLE stg.customers (
    Customer_ID    NVARCHAR(20),
    Name           NVARCHAR(100),
    Email          NVARCHAR(150),
    Telephone      NVARCHAR(50),
    City           NVARCHAR(100),
    Country        NVARCHAR(100),
    Gender         NVARCHAR(5),
    Date_Of_Birth  NVARCHAR(20),
    Job_Title      NVARCHAR(100),
    Age            NVARCHAR(10),
    Age_Group      NVARCHAR(20),
    Source_File    NVARCHAR(100) DEFAULT 'cleaned_customers.csv',
    Load_Date      DATETIME2(0) DEFAULT SYSDATETIME()
);

CREATE TABLE stg.products (
    Product_ID       NVARCHAR(20),
    Category         NVARCHAR(60),
    Sub_Category     NVARCHAR(60),
    Description_PT   NVARCHAR(500),
    Description_DE   NVARCHAR(500),
    Description_FR   NVARCHAR(500),
    Description_ES   NVARCHAR(500),
    Description_EN   NVARCHAR(500),
    Description_ZH   NVARCHAR(500),
    Color            NVARCHAR(50),
    Sizes            NVARCHAR(100),
    Production_Cost  NVARCHAR(30),
    Source_File      NVARCHAR(100) DEFAULT 'cleaned_products.csv',
    Load_Date        DATETIME2(0) DEFAULT SYSDATETIME()
);

CREATE TABLE stg.stores (
    Store_ID             NVARCHAR(20),
    Country              NVARCHAR(100),
    City                 NVARCHAR(100),
    Store_Name           NVARCHAR(100),
    Number_of_Employees  NVARCHAR(10),
    ZIP_Code             NVARCHAR(20),
    Latitude             NVARCHAR(30),
    Longitude            NVARCHAR(30),
    Source_File          NVARCHAR(100) DEFAULT 'cleaned_stores.csv',
    Load_Date            DATETIME2(0) DEFAULT SYSDATETIME()
);

CREATE TABLE stg.employees (
    Employee_ID  NVARCHAR(20),
    Store_ID     NVARCHAR(20),
    Name         NVARCHAR(100),
    Position     NVARCHAR(50),
    Source_File  NVARCHAR(100) DEFAULT 'cleaned_employees.csv',
    Load_Date    DATETIME2(0) DEFAULT SYSDATETIME()
);

-- Bản tạm: chờ xác nhận tiêu đề cleaned_discounts.csv
CREATE TABLE stg.discounts (
    [Start]       NVARCHAR(30),
    [End]         NVARCHAR(30),
    Discount      NVARCHAR(10),
    Description   NVARCHAR(100),
    Category      NVARCHAR(60),
    Sub_Category  NVARCHAR(60),
    Source_File   NVARCHAR(100) DEFAULT 'cleaned_discounts.csv',
    Load_Date     DATETIME2(0) DEFAULT SYSDATETIME()
);