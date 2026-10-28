USE Fashion_DW;
GO

/* ============================================================
   19 - LOAD DIM PRODUCT
   ============================================================ */

TRUNCATE TABLE dbo.Dim_Product;
GO

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
    Color,
    Sizes,
    Production_Cost
)
SELECT
    Product_ID,
    Category,
    Sub_Category,
    Description_PT,
    Description_DE,
    Description_FR,
    Description_ES,
    Description_EN,
    Description_ZH,
    Color,
    Sizes,
    TRY_CONVERT(DECIMAL(18,2), Production_Cost)
FROM Fashion_Staging.stg.products;
GO

/* Kiểm tra số dòng */
SELECT COUNT(*) AS SoDong
FROM dbo.Dim_Product;
GO

/* Xem dữ liệu mẫu */
SELECT TOP 10 *
FROM dbo.Dim_Product
ORDER BY Product_Key;
GO