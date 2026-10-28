USE Fashion_DW;
GO

/* =========================================================
   DIM CUSTOMER
   ========================================================= */

IF OBJECT_ID('dbo.Dim_Customer', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Customer;
GO

CREATE TABLE dbo.Dim_Customer
(
    Customer_Key INT IDENTITY(1,1) PRIMARY KEY,
    Customer_ID NVARCHAR(50) NOT NULL,
    Customer_Name NVARCHAR(150) NULL,
    Email NVARCHAR(200) NULL,
    Telephone NVARCHAR(80) NULL,
    City NVARCHAR(100) NULL,
    Country NVARCHAR(100) NULL,
    Gender NVARCHAR(20) NULL,
    Date_Of_Birth DATE NULL,
    Job_Title NVARCHAR(255) NULL,
    Age INT NULL,
    Age_Group NVARCHAR(30) NULL
);
GO


/* =========================================================
   DIM PRODUCT
   ========================================================= */

IF OBJECT_ID('dbo.Dim_Product', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Product;
GO

CREATE TABLE dbo.Dim_Product
(
    Product_Key INT IDENTITY(1,1) PRIMARY KEY,
    Product_ID NVARCHAR(50) NOT NULL,
    Category NVARCHAR(100) NULL,
    Sub_Category NVARCHAR(100) NULL,
    Description_PT NVARCHAR(500) NULL,
    Description_DE NVARCHAR(500) NULL,
    Description_FR NVARCHAR(500) NULL,
    Description_ES NVARCHAR(500) NULL,
    Description_EN NVARCHAR(500) NULL,
    Description_ZH NVARCHAR(500) NULL,
    Color NVARCHAR(100) NULL,
    Sizes NVARCHAR(100) NULL,
    Production_Cost DECIMAL(18,2) NULL
);
GO


/* =========================================================
   DIM STORE
   ========================================================= */

IF OBJECT_ID('dbo.Dim_Store', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Store;
GO

CREATE TABLE dbo.Dim_Store
(
    Store_Key INT IDENTITY(1,1) PRIMARY KEY,
    Store_ID NVARCHAR(50) NOT NULL,
    Country NVARCHAR(100) NULL,
    City NVARCHAR(100) NULL,
    Store_Name NVARCHAR(150) NULL,
    Number_Of_Employees INT NULL,
    ZIP_Code NVARCHAR(50) NULL,
    Latitude DECIMAL(18,8) NULL,
    Longitude DECIMAL(18,8) NULL,
    Country_Original NVARCHAR(100) NULL,
    Country_Code NVARCHAR(50) NULL,
    Country_Name_EN NVARCHAR(100) NULL,
    Country_Name_VI NVARCHAR(100) NULL,
    Expected_Currency NVARCHAR(50) NULL
);
GO


/* =========================================================
   DIM EMPLOYEE
   ========================================================= */

IF OBJECT_ID('dbo.Dim_Employee', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Employee;
GO

CREATE TABLE dbo.Dim_Employee
(
    Employee_Key INT IDENTITY(1,1) PRIMARY KEY,
    Employee_ID NVARCHAR(50) NOT NULL,
    Store_ID NVARCHAR(50) NULL,
    Employee_Name NVARCHAR(150) NULL,
    Position NVARCHAR(100) NULL
);
GO


/* =========================================================
   DIM DATE
   ========================================================= */

IF OBJECT_ID('dbo.Dim_Date', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Date;
GO

CREATE TABLE dbo.Dim_Date
(
    Date_Key INT PRIMARY KEY,
    Full_Date DATE NOT NULL,
    Day_Number INT NOT NULL,
    Day_Name NVARCHAR(20) NOT NULL,
    Month_Number INT NOT NULL,
    Month_Name NVARCHAR(20) NOT NULL,
    Quarter_Number INT NOT NULL,
    Year_Number INT NOT NULL,
    Week_Number INT NULL,
    Is_Weekend BIT NULL
);
GO

USE Fashion_DW;
GO

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
  AND TABLE_NAME LIKE 'Dim_%'
ORDER BY TABLE_NAME;
GO