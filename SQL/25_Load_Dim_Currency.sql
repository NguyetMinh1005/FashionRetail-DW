USE Fashion_DW;
GO

/* ============================================================
   25 - LOAD DIM CURRENCY
   Dự án: Fashion Retail Data Warehouse

   Nguồn:
       Fashion_Staging.stg.transactions

   Đích:
       Fashion_DW.dbo.Dim_Currency

   Business Key:
       Currency_Code

   Surrogate Key:
       Currency_Key

   Dữ liệu dự kiến:
       USD
       EUR
       GBP
       CNY

   Bản ghi đặc biệt:
       Unknown

   Lưu ý:
       Chưa bổ sung Exchange Rate tại bước này vì
       bộ dữ liệu Kaggle không cung cấp nguồn tỷ giá
       được xác nhận.
   ============================================================ */


/* ============================================================
   1. KIỂM TRA FACT TRƯỚC KHI RELOAD DIM
   ============================================================ */

IF EXISTS (SELECT 1 FROM dbo.Fact_Sales)
BEGIN
    THROW 50009,
          N'Fact_Sales đã có dữ liệu. Không được reload Dim_Currency trước khi xử lý Fact.',
          1;
END;
GO


/* ============================================================
   2. XÓA DỮ LIỆU DIM CURRENCY CŨ
   ============================================================ */

/*
   Không dùng TRUNCATE vì Dim_Currency đang được
   Fact_Sales tham chiếu bằng FOREIGN KEY.
*/

DELETE FROM dbo.Dim_Currency;
GO

DBCC CHECKIDENT ('dbo.Dim_Currency', RESEED, 0);
GO


/* ============================================================
   3. TẠO BẢN GHI UNKNOWN
   ============================================================ */

INSERT INTO dbo.Dim_Currency
(
    Currency_Code,
    Currency_Symbol
)
VALUES
(
    'UNK',
    N'?'
);
GO


/* ============================================================
   4. NẠP CURRENCY TỪ STAGING
   ============================================================ */

/*
   Dùng DISTINCT vì transactions có hàng triệu dòng
   nhưng chỉ có một số ít loại tiền.

   Chuẩn hóa:
   - Currency viết hoa.
   - Trim khoảng trắng.
   - Không nạp Currency NULL/rỗng vào dữ liệu thực.
*/

INSERT INTO dbo.Dim_Currency
(
    Currency_Code,
    Currency_Symbol
)
SELECT DISTINCT

    UPPER(
        LTRIM(RTRIM(Currency))
    ) AS Currency_Code,

    CASE
        WHEN NULLIF(
            LTRIM(RTRIM(Currency_Symbol)),
            ''
        ) IS NULL
            THEN N'?'

        ELSE LTRIM(RTRIM(Currency_Symbol))
    END AS Currency_Symbol

FROM Fashion_Staging.stg.transactions

WHERE
    NULLIF(
        LTRIM(RTRIM(Currency)),
        ''
    ) IS NOT NULL;
GO


/* ============================================================
   5. KIỂM TRA TỔNG SỐ DÒNG

   Mong đợi:
       4 currency thực
       + 1 Unknown
       = 5
   ============================================================ */

SELECT
    COUNT(*) AS Total_Dim_Currency
FROM dbo.Dim_Currency;
GO


/* ============================================================
   6. KIỂM TRA BẢN GHI UNKNOWN

   Mong đợi:
       1 dòng
   ============================================================ */

SELECT
    Currency_Key,
    Currency_Code,
    Currency_Symbol

FROM dbo.Dim_Currency

WHERE Currency_Code = 'UNK';
GO


/* ============================================================
   7. KIỂM TRA BUSINESS KEY TRÙNG

   Currency_Code là Business Key.

   Mong đợi:
       0 dòng
   ============================================================ */

SELECT
    Currency_Code,
    COUNT(*) AS SoLanXuatHien

FROM dbo.Dim_Currency

GROUP BY Currency_Code

HAVING COUNT(*) > 1;
GO


/* ============================================================
   8. KIỂM TRA CURRENCY CODE NULL

   Mong đợi:
       0
   ============================================================ */

SELECT
    COUNT(*) AS Null_Currency_Code

FROM dbo.Dim_Currency

WHERE Currency_Code IS NULL;
GO


/* ============================================================
   9. KIỂM TRA CURRENCY SYMBOL NULL

   Mong đợi:
       0
   ============================================================ */

SELECT
    COUNT(*) AS Null_Currency_Symbol

FROM dbo.Dim_Currency

WHERE Currency_Symbol IS NULL;
GO


/* ============================================================
   10. XEM DANH SÁCH CURRENCY

   Mong đợi:
       CNY
       EUR
       GBP
       USD
       UNK
   ============================================================ */

SELECT
    Currency_Key,
    Currency_Code,
    Currency_Symbol

FROM dbo.Dim_Currency

ORDER BY Currency_Code;
GO


/* ============================================================
   11. KIỂM TRA SỐ CURRENCY THỰC

   Không tính Unknown.

   Mong đợi:
       4
   ============================================================ */

SELECT
    COUNT(*) AS So_Currency

FROM dbo.Dim_Currency

WHERE Currency_Code <> 'UNK';
GO


/* ============================================================
   12. KIỂM TRA CÁC CẶP CURRENCY / SYMBOL TRONG STG
   ============================================================ */

SELECT DISTINCT
    UPPER(LTRIM(RTRIM(Currency)))
        AS Currency_Code,

    LTRIM(RTRIM(Currency_Symbol))
        AS Currency_Symbol

FROM Fashion_Staging.stg.transactions

ORDER BY Currency_Code;
GO


/* ============================================================
   13. KIỂM TRA MỘT CURRENCY CÓ NHIỀU SYMBOL KHÔNG

   Mong đợi:
       0 dòng

   Nếu có Currency có > 1 symbol thì cần kiểm tra nguồn.
   ============================================================ */

SELECT
    UPPER(LTRIM(RTRIM(Currency)))
        AS Currency_Code,

    COUNT(
        DISTINCT LTRIM(RTRIM(Currency_Symbol))
    ) AS So_Symbol

FROM Fashion_Staging.stg.transactions

WHERE
    NULLIF(
        LTRIM(RTRIM(Currency)),
        ''
    ) IS NOT NULL

GROUP BY
    UPPER(LTRIM(RTRIM(Currency)))

HAVING COUNT(
    DISTINCT LTRIM(RTRIM(Currency_Symbol))
) > 1;
GO


/* ============================================================
   14. KIỂM TRA CURRENCY TRONG STG
       KHÔNG CÓ TRONG DIM

   Mong đợi:
       0 dòng
   ============================================================ */

SELECT DISTINCT
    UPPER(
        LTRIM(RTRIM(t.Currency))
    ) AS Currency_Code

FROM Fashion_Staging.stg.transactions AS t

LEFT JOIN dbo.Dim_Currency AS d
    ON d.Currency_Code =
       UPPER(
           LTRIM(RTRIM(t.Currency))
       )

WHERE
    NULLIF(
        LTRIM(RTRIM(t.Currency)),
        ''
    ) IS NOT NULL

    AND d.Currency_Key IS NULL;
GO


/* ============================================================
   15. KIỂM TRA SỐ GIAO DỊCH THEO CURRENCY
   ============================================================ */

SELECT
    UPPER(
        LTRIM(RTRIM(Currency))
    ) AS Currency_Code,

    COUNT_BIG(*) AS So_Giao_Dich

FROM Fashion_Staging.stg.transactions

GROUP BY
    UPPER(
        LTRIM(RTRIM(Currency))
    )

ORDER BY Currency_Code;
GO


/* ============================================================
   16. ĐỐI SOÁT SỐ CURRENCY STG -> DW
   ============================================================ */

SELECT
    (
        SELECT COUNT(*)
        FROM
        (
            SELECT DISTINCT
                UPPER(
                    LTRIM(RTRIM(Currency))
                ) AS Currency_Code

            FROM Fashion_Staging.stg.transactions

            WHERE
                NULLIF(
                    LTRIM(RTRIM(Currency)),
                    ''
                ) IS NOT NULL
        ) AS Currency_STG
    ) AS STG_Currency_Count,

    (
        SELECT COUNT(*)
        FROM dbo.Dim_Currency
        WHERE Currency_Code <> 'UNK'
    ) AS DW_Currency_Count,

    (
        SELECT COUNT(*)
        FROM dbo.Dim_Currency
    ) AS DW_Including_Unknown;
GO


/* ============================================================
   17. KIỂM TRA CÁC CURRENCY ĐÚNG THEO THIẾT KẾ

   Nếu dữ liệu đúng tài liệu thì chỉ có:
       USD
       EUR
       GBP
       CNY

   Query dưới đây phải trả:
       0 dòng
   ============================================================ */

SELECT
    Currency_Key,
    Currency_Code,
    Currency_Symbol

FROM dbo.Dim_Currency

WHERE Currency_Code <> 'UNK'

AND Currency_Code NOT IN
(
    'USD',
    'EUR',
    'GBP',
    'CNY'
);
GO


/* ============================================================
   18. XEM DỮ LIỆU CUỐI
   ============================================================ */

SELECT
    Currency_Key,
    Currency_Code,
    Currency_Symbol

FROM dbo.Dim_Currency

ORDER BY Currency_Key;
GO