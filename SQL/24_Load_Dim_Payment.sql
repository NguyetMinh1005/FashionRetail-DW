USE Fashion_DW;
GO

/* ============================================================
   24 - LOAD DIM PAYMENT
   Dự án: Fashion Retail Data Warehouse

   Nguồn:
       Fashion_Staging.stg.transactions

   Đích:
       Fashion_DW.dbo.Dim_Payment

   Business Key:
       Payment_Method
       Transaction_Type

   Surrogate Key:
       Payment_Key

   Loại Dimension:
       Junk Dimension

   Bản ghi đặc biệt:
       Unknown
   ============================================================ */


/* ============================================================
   1. KIỂM TRA FACT TRƯỚC KHI RELOAD DIM
   ============================================================ */

IF EXISTS (SELECT 1 FROM dbo.Fact_Sales)
BEGIN
    THROW 50008,
          N'Fact_Sales đã có dữ liệu. Không được reload Dim_Payment trước khi xử lý Fact.',
          1;
END;
GO


/* ============================================================
   2. XÓA DỮ LIỆU DIM PAYMENT CŨ
   ============================================================ */

/*
   Không dùng TRUNCATE vì Dim_Payment đang được
   Fact_Sales tham chiếu bằng FOREIGN KEY.
*/

DELETE FROM dbo.Dim_Payment;
GO

DBCC CHECKIDENT ('dbo.Dim_Payment', RESEED, 0);
GO


/* ============================================================
   3. TẠO BẢN GHI UNKNOWN
   ============================================================ */

/*
   Unknown được dùng nếu:
   - Payment Method không xác định;
   - Transaction Type không xác định;
   - lookup Payment_Key thất bại.
*/

INSERT INTO dbo.Dim_Payment
(
    Payment_Method,
    Transaction_Type
)
VALUES
(
    N'Unknown',
    N'Unknown'
);
GO


/* ============================================================
   4. NẠP CÁC TỔ HỢP PAYMENT TỪ TRANSACTIONS
   ============================================================ */

/*
   Dùng DISTINCT vì Fact có hàng triệu dòng,
   trong khi Dim_Payment chỉ cần các tổ hợp khác nhau.

   Chuẩn hóa:
   - trim khoảng trắng;
   - giá trị rỗng -> Unknown.
*/

INSERT INTO dbo.Dim_Payment
(
    Payment_Method,
    Transaction_Type
)
SELECT DISTINCT

    CASE
        WHEN NULLIF(LTRIM(RTRIM(Payment_Method)), '') IS NULL
            THEN N'Unknown'
        ELSE LTRIM(RTRIM(Payment_Method))
    END AS Payment_Method,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(Transaction_Type)), '') IS NULL
            THEN N'Unknown'
        ELSE LTRIM(RTRIM(Transaction_Type))
    END AS Transaction_Type

FROM Fashion_Staging.stg.transactions

WHERE NOT
(
    NULLIF(LTRIM(RTRIM(Payment_Method)), '') IS NULL
    AND
    NULLIF(LTRIM(RTRIM(Transaction_Type)), '') IS NULL
);
GO


/* ============================================================
   5. KIỂM TRA TỔNG SỐ DÒNG
   ============================================================ */

SELECT
    COUNT(*) AS Total_Dim_Payment
FROM dbo.Dim_Payment;
GO


/* ============================================================
   6. KIỂM TRA BẢN GHI UNKNOWN

   Mong đợi:
       1 dòng
   ============================================================ */

SELECT
    Payment_Key,
    Payment_Method,
    Transaction_Type

FROM dbo.Dim_Payment

WHERE Payment_Method = N'Unknown'
  AND Transaction_Type = N'Unknown';
GO


/* ============================================================
   7. KIỂM TRA BUSINESS KEY TRÙNG

   Mong đợi:
       0 dòng
   ============================================================ */

SELECT
    Payment_Method,
    Transaction_Type,
    COUNT(*) AS SoLanXuatHien

FROM dbo.Dim_Payment

GROUP BY
    Payment_Method,
    Transaction_Type

HAVING COUNT(*) > 1;
GO


/* ============================================================
   8. KIỂM TRA PAYMENT METHOD NULL

   Mong đợi:
       0
   ============================================================ */

SELECT
    COUNT(*) AS Null_Payment_Method
FROM dbo.Dim_Payment
WHERE Payment_Method IS NULL;
GO


/* ============================================================
   9. KIỂM TRA TRANSACTION TYPE NULL

   Mong đợi:
       0
   ============================================================ */

SELECT
    COUNT(*) AS Null_Transaction_Type
FROM dbo.Dim_Payment
WHERE Transaction_Type IS NULL;
GO


/* ============================================================
   10. XEM CÁC TỔ HỢP PAYMENT

   Mong đợi dữ liệu thực:
       Cash + Sale
       Cash + Return
       Credit Card + Sale
       Credit Card + Return
   ============================================================ */

SELECT
    Payment_Key,
    Payment_Method,
    Transaction_Type

FROM dbo.Dim_Payment

ORDER BY
    Payment_Method,
    Transaction_Type;
GO


/* ============================================================
   11. KIỂM TRA SỐ PAYMENT METHOD
   Không tính Unknown
   ============================================================ */

SELECT
    COUNT(DISTINCT Payment_Method)
        AS So_Payment_Method

FROM dbo.Dim_Payment

WHERE Payment_Method <> N'Unknown';
GO


/* ============================================================
   12. KIỂM TRA SỐ TRANSACTION TYPE
   Không tính Unknown
   ============================================================ */

SELECT
    COUNT(DISTINCT Transaction_Type)
        AS So_Transaction_Type

FROM dbo.Dim_Payment

WHERE Transaction_Type <> N'Unknown';
GO


/* ============================================================
   13. KIỂM TRA GIÁ TRỊ PAYMENT METHOD
   ============================================================ */

SELECT
    Payment_Method,
    COUNT(*) AS So_To_Hop

FROM dbo.Dim_Payment

WHERE Payment_Method <> N'Unknown'

GROUP BY Payment_Method

ORDER BY Payment_Method;
GO


/* ============================================================
   14. KIỂM TRA GIÁ TRỊ TRANSACTION TYPE
   ============================================================ */

SELECT
    Transaction_Type,
    COUNT(*) AS So_To_Hop

FROM dbo.Dim_Payment

WHERE Transaction_Type <> N'Unknown'

GROUP BY Transaction_Type

ORDER BY Transaction_Type;
GO


/* ============================================================
   15. ĐỐI SOÁT CÁC TỔ HỢP TỪ STG -> DW
   ============================================================ */

SELECT DISTINCT
    LTRIM(RTRIM(Payment_Method))
        AS STG_Payment_Method,

    LTRIM(RTRIM(Transaction_Type))
        AS STG_Transaction_Type

FROM Fashion_Staging.stg.transactions

ORDER BY
    STG_Payment_Method,
    STG_Transaction_Type;
GO


/* ============================================================
   16. KIỂM TRA TỔ HỢP STG KHÔNG CÓ TRONG DIM

   Mong đợi:
       0 dòng
   ============================================================ */

SELECT DISTINCT
    LTRIM(RTRIM(t.Payment_Method))
        AS Payment_Method,

    LTRIM(RTRIM(t.Transaction_Type))
        AS Transaction_Type

FROM Fashion_Staging.stg.transactions AS t

LEFT JOIN dbo.Dim_Payment AS d
    ON
        d.Payment_Method =
            CASE
                WHEN NULLIF(
                    LTRIM(RTRIM(t.Payment_Method)),
                    ''
                ) IS NULL
                    THEN N'Unknown'
                ELSE LTRIM(RTRIM(t.Payment_Method))
            END

    AND

        d.Transaction_Type =
            CASE
                WHEN NULLIF(
                    LTRIM(RTRIM(t.Transaction_Type)),
                    ''
                ) IS NULL
                    THEN N'Unknown'
                ELSE LTRIM(RTRIM(t.Transaction_Type))
            END

WHERE d.Payment_Key IS NULL;
GO


/* ============================================================
   17. KIỂM TRA SỐ GIAO DỊCH THEO PAYMENT METHOD
   ============================================================ */

SELECT
    Payment_Method,
    COUNT_BIG(*) AS So_Giao_Dich

FROM Fashion_Staging.stg.transactions

GROUP BY Payment_Method

ORDER BY Payment_Method;
GO


/* ============================================================
   18. KIỂM TRA SỐ GIAO DỊCH THEO TRANSACTION TYPE
   ============================================================ */

SELECT
    Transaction_Type,
    COUNT_BIG(*) AS So_Giao_Dich

FROM Fashion_Staging.stg.transactions

GROUP BY Transaction_Type

ORDER BY Transaction_Type;
GO


/* ============================================================
   19. XEM DỮ LIỆU CUỐI
   ============================================================ */

SELECT
    Payment_Key,
    Payment_Method,
    Transaction_Type

FROM dbo.Dim_Payment

ORDER BY Payment_Key;
GO