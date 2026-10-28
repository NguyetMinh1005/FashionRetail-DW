USE Fashion_DW;
GO

/* ============================================================
   19 - LOAD DIM PRODUCT
   Dự án: Fashion Retail Data Warehouse

   Nguồn:
       Fashion_Staging.stg.products

   Đích:
       Fashion_DW.dbo.Dim_Product

   Business Key:
       Product_ID

   Surrogate Key:
       Product_Key
   ============================================================ */


/* ============================================================
   1. KIỂM TRA FACT TRƯỚC KHI RELOAD DIM
   ============================================================ */

IF EXISTS (SELECT 1 FROM dbo.Fact_Sales)
BEGIN
    THROW 50002,
          N'Fact_Sales đã có dữ liệu. Không được reload Dim_Product trước khi xử lý Fact.',
          1;
END;
GO


/* ============================================================
   2. XÓA DỮ LIỆU DIM PRODUCT CŨ
   ============================================================ */

/*
   Không dùng TRUNCATE vì Dim_Product đang được Fact_Sales
   tham chiếu bằng FOREIGN KEY.
*/

DELETE FROM dbo.Dim_Product;
GO

DBCC CHECKIDENT ('dbo.Dim_Product', RESEED, 0);
GO


/* ============================================================
   3. TẠO BẢN GHI UNKNOWN PRODUCT
   ============================================================ */

/*
   Product_ID = -1 dùng làm business key đặc biệt.

   Bản ghi này được sử dụng khi ETL không tìm được Product_ID
   tương ứng trong Dim_Product.

   Hiện tại profiling cho thấy các Product_ID trong transaction
   đều tìm thấy trong products, nhưng vẫn tạo Unknown để bảo vệ ETL.
*/

INSERT INTO dbo.Dim_Product
(
    Product_ID,
    Category,
    Sub_Category,
    Description_PT,
    Description_DE,
    Description_FR,
    Description_ES,
    Description_EN,
    Description_ZH,
    Production_Cost
)
VALUES
(
    -1,
    N'Unknown',
    N'Unknown',
    N'Unknown',
    N'Unknown',
    N'Unknown',
    N'Unknown',
    N'Unknown',
    N'Unknown',
    NULL
);
GO


/* ============================================================
   4. NẠP SẢN PHẨM TỪ STAGING
   ============================================================ */

INSERT INTO dbo.Dim_Product
(
    Product_ID,
    Category,
    Sub_Category,
    Description_PT,
    Description_DE,
    Description_FR,
    Description_ES,
    Description_EN,
    Description_ZH,
    Production_Cost
)
SELECT
    TRY_CONVERT(INT, Product_ID) AS Product_ID,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(Category)), '') IS NULL
            THEN N'Unknown'
        ELSE LTRIM(RTRIM(Category))
    END AS Category,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(Sub_Category)), '') IS NULL
            THEN N'Unknown'
        ELSE LTRIM(RTRIM(Sub_Category))
    END AS Sub_Category,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(Description_PT)), '') IS NULL
            THEN N'Unknown'
        ELSE LTRIM(RTRIM(Description_PT))
    END AS Description_PT,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(Description_DE)), '') IS NULL
            THEN N'Unknown'
        ELSE LTRIM(RTRIM(Description_DE))
    END AS Description_DE,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(Description_FR)), '') IS NULL
            THEN N'Unknown'
        ELSE LTRIM(RTRIM(Description_FR))
    END AS Description_FR,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(Description_ES)), '') IS NULL
            THEN N'Unknown'
        ELSE LTRIM(RTRIM(Description_ES))
    END AS Description_ES,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(Description_EN)), '') IS NULL
            THEN N'Unknown'
        ELSE LTRIM(RTRIM(Description_EN))
    END AS Description_EN,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(Description_ZH)), '') IS NULL
            THEN N'Unknown'
        ELSE LTRIM(RTRIM(Description_ZH))
    END AS Description_ZH,

    TRY_CONVERT(DECIMAL(18,2), Production_Cost)
        AS Production_Cost

FROM Fashion_Staging.stg.products

WHERE TRY_CONVERT(INT, Product_ID) IS NOT NULL;
GO


/* ============================================================
   5. KIỂM TRA TỔNG SỐ DÒNG
   ============================================================ */

SELECT
    COUNT(*) AS Total_Dim_Product
FROM dbo.Dim_Product;
GO


/* ============================================================
   6. KIỂM TRA PRODUCT_ID TRÙNG
   Kết quả mong đợi: 0 dòng
   ============================================================ */

SELECT
    Product_ID,
    COUNT(*) AS SoLanXuatHien
FROM dbo.Dim_Product
GROUP BY Product_ID
HAVING COUNT(*) > 1;
GO


/* ============================================================
   7. KIỂM TRA PRODUCT_ID NULL
   Kết quả mong đợi: 0
   ============================================================ */

SELECT
    COUNT(*) AS Null_Product_ID
FROM dbo.Dim_Product
WHERE Product_ID IS NULL;
GO


/* ============================================================
   8. KIỂM TRA BẢN GHI UNKNOWN
   Kết quả mong đợi: 1 dòng
   ============================================================ */

SELECT *
FROM dbo.Dim_Product
WHERE Product_ID = -1;
GO


/* ============================================================
   9. KIỂM TRA PRODUCTION COST
   ============================================================ */

SELECT
    COUNT(*) AS Null_Production_Cost
FROM dbo.Dim_Product
WHERE Product_ID <> -1
  AND Production_Cost IS NULL;
GO


/* ============================================================
   10. KIỂM TRA CATEGORY / SUB CATEGORY
   ============================================================ */

SELECT
    COUNT(DISTINCT Category) AS So_Category,
    COUNT(DISTINCT Sub_Category) AS So_Sub_Category
FROM dbo.Dim_Product
WHERE Product_ID <> -1;
GO


/* ============================================================
   11. XEM DỮ LIỆU MẪU
   ============================================================ */

SELECT TOP (20)
    Product_Key,
    Product_ID,
    Category,
    Sub_Category,
    Description_EN,
    Production_Cost
FROM dbo.Dim_Product
ORDER BY Product_Key;
GO


/* ============================================================
   12. ĐỐI SOÁT STG -> DW
   ============================================================ */

SELECT
    (SELECT COUNT(*)
     FROM Fashion_Staging.stg.products)
        AS STG_Products,

    (SELECT COUNT(*)
     FROM dbo.Dim_Product
     WHERE Product_ID <> -1)
        AS DW_Products,

    (SELECT COUNT(*)
     FROM dbo.Dim_Product)
        AS DW_Including_Unknown;
GO