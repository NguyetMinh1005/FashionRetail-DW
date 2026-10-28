USE Fashion_DW;
GO

/* ============================================================
   23 - LOAD DIM PROMOTION
   Dự án: Fashion Retail Data Warehouse

   Nguồn:
       Fashion_Staging.stg.discounts

   Đích:
       Fashion_DW.dbo.Dim_Promotion

   Business Key:
       Start_Date
       End_Date
       Discount_Rate
       Category
       Sub_Category

   Surrogate Key:
       Promotion_Key

   Bản ghi đặc biệt:
       1. Unknown
       2. No Promotion

   Cấu trúc STG thực tế:
       Start
       End
       Discount
       Description
       Category
       Sub_Category
       Source_File
       Load_Date

   Lưu ý nghiệp vụ:
       Trong STG, 10 dòng khuyến mãi toàn cục đã bị
       chuẩn hóa từ NULL/blank thành:
           Category = 'Unknown'
           Sub_Category = 'Unknown'

       Khi nạp DW, các cặp Unknown/Unknown này phải
       được phục hồi thành NULL/NULL để biểu thị:
           ÁP DỤNG CHO MỌI NHÓM HÀNG.
   ============================================================ */


/* ============================================================
   1. KIỂM TRA FACT TRƯỚC KHI RELOAD DIM
   ============================================================ */

IF EXISTS (SELECT 1 FROM dbo.Fact_Sales)
BEGIN
    THROW 50007,
          N'Fact_Sales đã có dữ liệu. Không được reload Dim_Promotion trước khi xử lý Fact.',
          1;
END;
GO


/* ============================================================
   2. XÓA DỮ LIỆU DIM PROMOTION CŨ
   ============================================================ */

/*
   Không dùng TRUNCATE vì Dim_Promotion đang được
   Fact_Sales tham chiếu bằng FOREIGN KEY.
*/

DELETE FROM dbo.Dim_Promotion;
GO

DBCC CHECKIDENT ('dbo.Dim_Promotion', RESEED, 0);
GO


/* ============================================================
   3. TẠO BẢN GHI UNKNOWN PROMOTION
   ============================================================ */

/*
   Unknown dùng cho:
   - lookup promotion thất bại;
   - chưa xác định được chương trình;
   - Return chưa liên kết được với chương trình Sale gốc.
*/

INSERT INTO dbo.Dim_Promotion
(
    Start_Date,
    End_Date,
    Discount_Rate,
    Promotion_Name,
    Category,
    Sub_Category
)
VALUES
(
    NULL,
    NULL,
    NULL,
    N'Unknown',
    N'Unknown',
    N'Unknown'
);
GO


/* ============================================================
   4. TẠO BẢN GHI NO PROMOTION
   ============================================================ */

/*
   No Promotion dùng cho giao dịch hợp lệ nhưng
   không thuộc chương trình khuyến mãi nào.
*/

INSERT INTO dbo.Dim_Promotion
(
    Start_Date,
    End_Date,
    Discount_Rate,
    Promotion_Name,
    Category,
    Sub_Category
)
VALUES
(
    NULL,
    NULL,
    0.00,
    N'No Promotion',
    N'Not Applicable',
    N'Not Applicable'
);
GO


/* ============================================================
   5. NẠP PROMOTION TỪ STAGING
   ============================================================ */

INSERT INTO dbo.Dim_Promotion
(
    Start_Date,
    End_Date,
    Discount_Rate,
    Promotion_Name,
    Category,
    Sub_Category
)
SELECT
    /* Ngày bắt đầu */
    TRY_CONVERT(DATE, [Start])
        AS Start_Date,

    /* Ngày kết thúc */
    TRY_CONVERT(DATE, [End])
        AS End_Date,

    /* STG thực tế dùng tên Discount */
    TRY_CONVERT(DECIMAL(4,2), Discount)
        AS Discount_Rate,

    /* Tên chương trình */
    CASE
        WHEN NULLIF(LTRIM(RTRIM(Description)), '') IS NULL
            THEN N'Unknown'
        ELSE LTRIM(RTRIM(Description))
    END AS Promotion_Name,


    /* ========================================================
       CATEGORY

       Nếu STG có:
           Unknown + Unknown

       thì phục hồi về NULL + NULL vì đây là
       global promotion áp dụng mọi nhóm hàng.
       ======================================================== */

    CASE
        WHEN
            UPPER(LTRIM(RTRIM(Category))) = 'UNKNOWN'
            AND
            UPPER(LTRIM(RTRIM(Sub_Category))) = 'UNKNOWN'
            THEN NULL

        WHEN NULLIF(LTRIM(RTRIM(Category)), '') IS NULL
            THEN NULL

        ELSE LTRIM(RTRIM(Category))
    END AS Category,


    /* ========================================================
       SUB CATEGORY
       ======================================================== */

    CASE
        WHEN
            UPPER(LTRIM(RTRIM(Category))) = 'UNKNOWN'
            AND
            UPPER(LTRIM(RTRIM(Sub_Category))) = 'UNKNOWN'
            THEN NULL

        WHEN NULLIF(LTRIM(RTRIM(Sub_Category)), '') IS NULL
            THEN NULL

        ELSE LTRIM(RTRIM(Sub_Category))
    END AS Sub_Category

FROM Fashion_Staging.stg.discounts;
GO


/* ============================================================
   6. KIỂM TRA TỔNG SỐ DÒNG

   Mong đợi:
       181 dòng nguồn
       + 2 dòng đặc biệt
       = 183
   ============================================================ */

SELECT
    COUNT(*) AS Total_Dim_Promotion
FROM dbo.Dim_Promotion;
GO


/* ============================================================
   7. KIỂM TRA 2 BẢN GHI ĐẶC BIỆT
   ============================================================ */

SELECT
    Promotion_Key,
    Start_Date,
    End_Date,
    Discount_Rate,
    Promotion_Name,
    Category,
    Sub_Category

FROM dbo.Dim_Promotion

WHERE Promotion_Name IN
(
    N'Unknown',
    N'No Promotion'
)

ORDER BY Promotion_Key;
GO


/* ============================================================
   8. KIỂM TRA BUSINESS KEY TRÙNG

   Business Key:
       Start_Date
       End_Date
       Discount_Rate
       Category
       Sub_Category

   Mong đợi: 0 dòng
   ============================================================ */

SELECT
    Start_Date,
    End_Date,
    Discount_Rate,
    Category,
    Sub_Category,
    COUNT(*) AS SoLanXuatHien

FROM dbo.Dim_Promotion

WHERE Promotion_Name NOT IN
(
    N'Unknown',
    N'No Promotion'
)

GROUP BY
    Start_Date,
    End_Date,
    Discount_Rate,
    Category,
    Sub_Category

HAVING COUNT(*) > 1;
GO


/* ============================================================
   9. KIỂM TRA NGÀY KHÔNG HỢP LỆ

   Mong đợi: 0 dòng
   ============================================================ */

SELECT
    Promotion_Key,
    Start_Date,
    End_Date,
    Promotion_Name

FROM dbo.Dim_Promotion

WHERE Promotion_Name NOT IN
(
    N'Unknown',
    N'No Promotion'
)

AND
(
    Start_Date IS NULL
    OR End_Date IS NULL
    OR Start_Date > End_Date
);
GO


/* ============================================================
   10. KIỂM TRA DISCOUNT RATE

   Mong đợi:
       Discount_Rate > 0
       Discount_Rate <= 1

   Kết quả mong đợi: 0 dòng
   ============================================================ */

SELECT
    Promotion_Key,
    Discount_Rate,
    Promotion_Name

FROM dbo.Dim_Promotion

WHERE Promotion_Name NOT IN
(
    N'Unknown',
    N'No Promotion'
)

AND
(
    Discount_Rate IS NULL
    OR Discount_Rate <= 0
    OR Discount_Rate > 1
);
GO


/* ============================================================
   11. KIỂM TRA GLOBAL PROMOTION

   Global promotion:
       Category IS NULL
       Sub_Category IS NULL

   Mong đợi: 10 dòng
   ============================================================ */

SELECT
    COUNT(*) AS Global_Promotion_Rows

FROM dbo.Dim_Promotion

WHERE Promotion_Name NOT IN
(
    N'Unknown',
    N'No Promotion'
)

AND Category IS NULL
AND Sub_Category IS NULL;
GO


/* ============================================================
   12. XEM CÁC GLOBAL PROMOTION
   ============================================================ */

SELECT
    Promotion_Key,
    Start_Date,
    End_Date,
    Discount_Rate,
    Promotion_Name,
    Category,
    Sub_Category

FROM dbo.Dim_Promotion

WHERE Promotion_Name NOT IN
(
    N'Unknown',
    N'No Promotion'
)

AND Category IS NULL
AND Sub_Category IS NULL

ORDER BY
    Start_Date,
    Promotion_Name;
GO


/* ============================================================
   13. KIỂM TRA SỐ LOẠI CHƯƠNG TRÌNH

   Mong đợi: 7
   ============================================================ */

SELECT
    COUNT(DISTINCT Promotion_Name)
        AS So_Loai_Chuong_Trinh

FROM dbo.Dim_Promotion

WHERE Promotion_Name NOT IN
(
    N'Unknown',
    N'No Promotion'
);
GO


/* ============================================================
   14. DANH SÁCH CÁC LOẠI CHƯƠNG TRÌNH
   ============================================================ */

SELECT
    Promotion_Name,
    COUNT(*) AS So_Dong

FROM dbo.Dim_Promotion

WHERE Promotion_Name NOT IN
(
    N'Unknown',
    N'No Promotion'
)

GROUP BY Promotion_Name

ORDER BY Promotion_Name;
GO


/* ============================================================
   15. KIỂM TRA CÁC MỨC DISCOUNT

   Mong đợi:
       0.20
       0.25
       0.35
       0.40
       0.45
       0.50
       0.60
   ============================================================ */

SELECT
    Discount_Rate,
    COUNT(*) AS So_Dong

FROM dbo.Dim_Promotion

WHERE Promotion_Name NOT IN
(
    N'Unknown',
    N'No Promotion'
)

GROUP BY Discount_Rate

ORDER BY Discount_Rate;
GO


/* ============================================================
   16. KIỂM TRA KHOẢNG THỜI GIAN PROMOTION

   Mong đợi:
       Min = 2020-01-01
       Max = 2025-03-31
   ============================================================ */

SELECT
    MIN(Start_Date) AS Promotion_Start_Min,
    MAX(End_Date) AS Promotion_End_Max

FROM dbo.Dim_Promotion

WHERE Promotion_Name NOT IN
(
    N'Unknown',
    N'No Promotion'
);
GO


/* ============================================================
   17. KIỂM TRA CATEGORY / SUB CATEGORY
   ============================================================ */

SELECT
    Category,
    Sub_Category,
    COUNT(*) AS So_Chuong_Trinh

FROM dbo.Dim_Promotion

WHERE Promotion_Name NOT IN
(
    N'Unknown',
    N'No Promotion'
)

GROUP BY
    Category,
    Sub_Category

ORDER BY
    Category,
    Sub_Category;
GO


/* ============================================================
   18. KIỂM TRA CATEGORY / SUB_CATEGORY CÓ TỒN TẠI
       TRONG DIM_PRODUCT

   Global promotion NULL/NULL được bỏ qua.

   Mong đợi: 0 dòng
   ============================================================ */

SELECT DISTINCT
    p.Promotion_Key,
    p.Category,
    p.Sub_Category

FROM dbo.Dim_Promotion AS p

LEFT JOIN dbo.Dim_Product AS d
    ON p.Category = d.Category
   AND p.Sub_Category = d.Sub_Category

WHERE
    p.Promotion_Name NOT IN
    (
        N'Unknown',
        N'No Promotion'
    )

    AND p.Category IS NOT NULL

    AND d.Product_Key IS NULL;
GO


/* ============================================================
   19. ĐỐI SOÁT STG -> DW

   Mong đợi:
       STG_Promotions       = 181
       DW_Promotions        = 181
       DW_Including_Special = 183
   ============================================================ */

SELECT
    (
        SELECT COUNT(*)
        FROM Fashion_Staging.stg.discounts
    ) AS STG_Promotions,

    (
        SELECT COUNT(*)
        FROM dbo.Dim_Promotion
        WHERE Promotion_Name NOT IN
        (
            N'Unknown',
            N'No Promotion'
        )
    ) AS DW_Promotions,

    (
        SELECT COUNT(*)
        FROM dbo.Dim_Promotion
    ) AS DW_Including_Special;
GO


/* ============================================================
   20. KIỂM TRA RIÊNG DÒNG UNKNOWN/UNKNOWN TRONG STAGING

   Mong đợi: 10 dòng
   ============================================================ */

SELECT
    COUNT(*) AS STG_Global_Promotion_Rows

FROM Fashion_Staging.stg.discounts

WHERE
    UPPER(LTRIM(RTRIM(Category))) = 'UNKNOWN'
    AND
    UPPER(LTRIM(RTRIM(Sub_Category))) = 'UNKNOWN';
GO


/* ============================================================
   21. ĐỐI CHIẾU GLOBAL PROMOTION STG -> DW

   Hai giá trị phải bằng nhau:
       STG = 10
       DW  = 10
   ============================================================ */

SELECT
    (
        SELECT COUNT(*)
        FROM Fashion_Staging.stg.discounts
        WHERE
            UPPER(LTRIM(RTRIM(Category))) = 'UNKNOWN'
            AND
            UPPER(LTRIM(RTRIM(Sub_Category))) = 'UNKNOWN'
    ) AS STG_Global_Promotions,

    (
        SELECT COUNT(*)
        FROM dbo.Dim_Promotion
        WHERE
            Promotion_Name NOT IN
            (
                N'Unknown',
                N'No Promotion'
            )
            AND Category IS NULL
            AND Sub_Category IS NULL
    ) AS DW_Global_Promotions;
GO


/* ============================================================
   22. XEM DỮ LIỆU MẪU
   ============================================================ */

SELECT TOP (30)
    Promotion_Key,
    Start_Date,
    End_Date,
    Discount_Rate,
    Promotion_Name,
    Category,
    Sub_Category

FROM dbo.Dim_Promotion

ORDER BY Promotion_Key;
GO