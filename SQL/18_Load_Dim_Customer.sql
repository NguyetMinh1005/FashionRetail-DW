USE Fashion_DW;
GO

/* ============================================================
   18 - LOAD DIM CUSTOMER
   Dự án: Fashion Retail Data Warehouse

   Nguồn:
       Fashion_Staging.stg.customers

   Đích:
       Fashion_DW.dbo.Dim_Customer

   Business Key:
       Customer_ID

   Surrogate Key:
       Customer_Key
   ============================================================ */


/* ============================================================
   1. XÓA DỮ LIỆU DIM CUSTOMER CŨ
   ============================================================ */

/*
   KHÔNG dùng TRUNCATE vì Dim_Customer đang được
   Fact_Sales tham chiếu bằng FOREIGN KEY.

   File này phải được chạy trước khi nạp dữ liệu Fact_Sales.
*/

IF EXISTS (SELECT 1 FROM dbo.Fact_Sales)
BEGIN
    THROW 50001,
          N'Fact_Sales đã có dữ liệu. Không được reload Dim_Customer trước khi xử lý Fact.',
          1;
END;
GO

DELETE FROM dbo.Dim_Customer;
GO

/* Đưa Identity về lại từ đầu */
DBCC CHECKIDENT ('dbo.Dim_Customer', RESEED, 0);
GO


/* ============================================================
   2. TẠO BẢN GHI UNKNOWN / WALK-IN CUSTOMER
   ============================================================ */

/*
   Dữ liệu hiện tại đã kiểm tra không có Customer_ID
   bị thiếu liên kết.

   Tuy nhiên vẫn tạo một dòng Unknown để đảm bảo:
   - Fact_Sales không phải chứa Customer_Key NULL.
   - ETL vẫn xử lý được nếu sau này có khách không xác định.
   - SSAS / Power BI không sinh nhóm (Blank).
*/

SET IDENTITY_INSERT dbo.Dim_Customer OFF;
GO

INSERT INTO dbo.Dim_Customer
(
    Customer_ID,
    Gender,
    Date_Of_Birth,
    Age,
    Age_Group,
    City,
    Country,
    Job_Title
)
VALUES
(
    -1,                     -- Business Key đặc biệt
    'U',                    -- Unknown gender
    NULL,
    NULL,
    N'Unknown',
    N'Unknown',
    N'Unknown',
    N'Unknown'
);
GO


/* ============================================================
   3. NẠP KHÁCH HÀNG TỪ STAGING
   ============================================================ */

INSERT INTO dbo.Dim_Customer
(
    Customer_ID,
    Gender,
    Date_Of_Birth,
    Age,
    Age_Group,
    City,
    Country,
    Job_Title
)
SELECT
    TRY_CONVERT(INT, Customer_ID) AS Customer_ID,

    /* Chuẩn hóa Gender về 1 ký tự */
    CASE
        WHEN NULLIF(LTRIM(RTRIM(Gender)), '') IS NULL
            THEN 'U'
        ELSE UPPER(LEFT(LTRIM(RTRIM(Gender)), 1))
    END AS Gender,

    TRY_CONVERT(DATE, Date_Of_Birth) AS Date_Of_Birth,

    /*
       Age đã được xử lý tại STG.
       Chuyển về INT khi nạp DW.
    */
    TRY_CONVERT(INT, Age) AS Age,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(Age_Group)), '') IS NULL
            THEN N'Unknown'
        ELSE LTRIM(RTRIM(Age_Group))
    END AS Age_Group,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(City)), '') IS NULL
            THEN N'Unknown'
        ELSE LTRIM(RTRIM(City))
    END AS City,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(Country)), '') IS NULL
            THEN N'Unknown'
        ELSE LTRIM(RTRIM(Country))
    END AS Country,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(Job_Title)), '') IS NULL
            THEN N'Unknown'
        ELSE LTRIM(RTRIM(Job_Title))
    END AS Job_Title

FROM Fashion_Staging.stg.customers

WHERE TRY_CONVERT(INT, Customer_ID) IS NOT NULL;
GO


/* ============================================================
   4. KIỂM TRA SỐ DÒNG
   ============================================================ */

SELECT
    COUNT(*) AS Total_Dim_Customer
FROM dbo.Dim_Customer;
GO


/* ============================================================
   5. KIỂM TRA CUSTOMER_ID BỊ TRÙNG
   Kết quả mong đợi: 0 dòng
   ============================================================ */

SELECT
    Customer_ID,
    COUNT(*) AS SoLanXuatHien
FROM dbo.Dim_Customer
GROUP BY Customer_ID
HAVING COUNT(*) > 1;
GO


/* ============================================================
   6. KIỂM TRA BUSINESS KEY NULL
   Kết quả mong đợi: 0
   ============================================================ */

SELECT
    COUNT(*) AS Null_Customer_ID
FROM dbo.Dim_Customer
WHERE Customer_ID IS NULL;
GO


/* ============================================================
   7. KIỂM TRA BẢN GHI UNKNOWN
   Kết quả mong đợi: 1 dòng
   ============================================================ */

SELECT *
FROM dbo.Dim_Customer
WHERE Customer_ID = -1;
GO


/* ============================================================
   8. XEM DỮ LIỆU MẪU
   ============================================================ */

SELECT TOP (20)
    Customer_Key,
    Customer_ID,
    Gender,
    Date_Of_Birth,
    Age,
    Age_Group,
    City,
    Country,
    Job_Title
FROM dbo.Dim_Customer
ORDER BY Customer_Key;
GO


/* ============================================================
   9. ĐỐI SOÁT SỐ LƯỢNG STG → DIM
   ============================================================ */

SELECT
    (SELECT COUNT(*)
     FROM Fashion_Staging.stg.customers) AS STG_Customers,

    (SELECT COUNT(*)
     FROM dbo.Dim_Customer
     WHERE Customer_ID <> -1) AS DW_Customers,

    (SELECT COUNT(*)
     FROM dbo.Dim_Customer) AS DW_Including_Unknown;
GO