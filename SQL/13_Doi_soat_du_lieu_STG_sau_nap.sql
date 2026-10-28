USE Fashion_Staging;
GO

/* ============================================================
   FILE 13 - ĐỐI SOÁT DỮ LIỆU STG SAU KHI NẠP
   ============================================================

   Mục đích:
   1. Kiểm tra số dòng của 6 bảng STG
   2. Đối chiếu với số dòng dữ liệu cleaned
   3. Kiểm tra dữ liệu tiền tệ trong transactions
   4. Kiểm tra khóa nghiệp vụ NULL/rỗng
   5. Kiểm tra khóa nghiệp vụ bị trùng ở Dimension
   6. Kiểm tra Invoice_ID + Line trong transactions
   7. Kiểm tra nhanh dữ liệu mẫu

   LƯU Ý:
   - File này CHỈ KIỂM TRA.
   - KHÔNG TRUNCATE.
   - KHÔNG DELETE.
   - KHÔNG UPDATE.
   ============================================================ */


/* ============================================================
   1. KIỂM TRA SỐ DÒNG 6 BẢNG STG
   ============================================================ */

PRINT N'1. SỐ DÒNG CÁC BẢNG STG';

SELECT 'customers' AS Bang, COUNT(*) AS SoDong
FROM stg.customers

UNION ALL

SELECT 'products', COUNT(*)
FROM stg.products

UNION ALL

SELECT 'stores', COUNT(*)
FROM stg.stores

UNION ALL

SELECT 'employees', COUNT(*)
FROM stg.employees

UNION ALL

SELECT 'discounts', COUNT(*)
FROM stg.discounts

UNION ALL

SELECT 'transactions', COUNT(*)
FROM stg.transactions;
GO


/* ============================================================
   2. ĐỐI CHIẾU SỐ DÒNG THỰC TẾ VÀ KỲ VỌNG
   ============================================================ */

PRINT N'2. ĐỐI CHIẾU SỐ DÒNG';

SELECT
    'customers' AS Bang,
    COUNT(*) AS SoDongThucTe,
    1643306 AS SoDongKyVong,
    CASE
        WHEN COUNT(*) = 1643306 THEN N'ĐẠT'
        ELSE N'KHÔNG ĐẠT'
    END AS KetQua
FROM stg.customers

UNION ALL

SELECT
    'products',
    COUNT(*),
    17940,
    CASE
        WHEN COUNT(*) = 17940 THEN N'ĐẠT'
        ELSE N'KHÔNG ĐẠT'
    END
FROM stg.products

UNION ALL

SELECT
    'stores',
    COUNT(*),
    35,
    CASE
        WHEN COUNT(*) = 35 THEN N'ĐẠT'
        ELSE N'KHÔNG ĐẠT'
    END
FROM stg.stores

UNION ALL

SELECT
    'employees',
    COUNT(*),
    404,
    CASE
        WHEN COUNT(*) = 404 THEN N'ĐẠT'
        ELSE N'KHÔNG ĐẠT'
    END
FROM stg.employees

UNION ALL

SELECT
    'discounts',
    COUNT(*),
    181,
    CASE
        WHEN COUNT(*) = 181 THEN N'ĐẠT'
        ELSE N'KHÔNG ĐẠT'
    END
FROM stg.discounts

UNION ALL

SELECT
    'transactions',
    COUNT(*),
    6416029,
    CASE
        WHEN COUNT(*) = 6416029 THEN N'ĐẠT'
        ELSE N'KHÔNG ĐẠT'
    END
FROM stg.transactions;
GO


/* ============================================================
   3. KIỂM TRA DỮ LIỆU TIỀN TỆ TRONG TRANSACTIONS
   ============================================================ */

PRINT N'3. KIỂM TRA TIỀN TỆ';

SELECT
    COUNT(*) AS TongDong,

    COALESCE(
        SUM(
            CASE
                WHEN Country_Code IS NULL
                     OR LTRIM(RTRIM(Country_Code)) = ''
                THEN 1
                ELSE 0
            END
        ),
        0
    ) AS ThieuCountryCode,

    COALESCE(
        SUM(
            CASE
                WHEN Expected_Currency IS NULL
                     OR LTRIM(RTRIM(Expected_Currency)) = ''
                THEN 1
                ELSE 0
            END
        ),
        0
    ) AS ThieuExpectedCurrency,

    COALESCE(
        SUM(
            CASE
                WHEN Exchange_Rate_To_USD IS NULL
                     OR LTRIM(RTRIM(Exchange_Rate_To_USD)) = ''
                THEN 1
                ELSE 0
            END
        ),
        0
    ) AS ThieuTyGia,

    COALESCE(
        SUM(
            CASE
                WHEN Net_Amount_USD IS NULL
                     OR LTRIM(RTRIM(Net_Amount_USD)) = ''
                THEN 1
                ELSE 0
            END
        ),
        0
    ) AS ThieuNetAmountUSD

FROM stg.transactions;
GO


/* ============================================================
   4. KIỂM TRA KHÓA NGHIỆP VỤ NULL / RỖNG
   ============================================================ */

PRINT N'4. KIỂM TRA KHÓA NGHIỆP VỤ NULL / RỖNG';

SELECT
    'customers' AS Bang,

    COALESCE(
        SUM(
            CASE
                WHEN Customer_ID IS NULL
                     OR LTRIM(RTRIM(Customer_ID)) = ''
                THEN 1
                ELSE 0
            END
        ),
        0
    ) AS SoDongKhoaNull

FROM stg.customers

UNION ALL

SELECT
    'products',

    COALESCE(
        SUM(
            CASE
                WHEN Product_ID IS NULL
                     OR LTRIM(RTRIM(Product_ID)) = ''
                THEN 1
                ELSE 0
            END
        ),
        0
    )

FROM stg.products

UNION ALL

SELECT
    'stores',

    COALESCE(
        SUM(
            CASE
                WHEN Store_ID IS NULL
                     OR LTRIM(RTRIM(Store_ID)) = ''
                THEN 1
                ELSE 0
            END
        ),
        0
    )

FROM stg.stores

UNION ALL

SELECT
    'employees',

    COALESCE(
        SUM(
            CASE
                WHEN Employee_ID IS NULL
                     OR LTRIM(RTRIM(Employee_ID)) = ''
                THEN 1
                ELSE 0
            END
        ),
        0
    )

FROM stg.employees;
GO


/* ============================================================
   5. KIỂM TRA KHÓA NGHIỆP VỤ BỊ TRÙNG
   ============================================================ */

PRINT N'5. KIỂM TRA KHÓA NGHIỆP VỤ BỊ TRÙNG';

SELECT
    'customers' AS Bang,
    COUNT(*) AS SoKhoaBiTrung
FROM
(
    SELECT Customer_ID
    FROM stg.customers
    WHERE Customer_ID IS NOT NULL
      AND LTRIM(RTRIM(Customer_ID)) <> ''
    GROUP BY Customer_ID
    HAVING COUNT(*) > 1
) AS T

UNION ALL

SELECT
    'products',
    COUNT(*)
FROM
(
    SELECT Product_ID
    FROM stg.products
    WHERE Product_ID IS NOT NULL
      AND LTRIM(RTRIM(Product_ID)) <> ''
    GROUP BY Product_ID
    HAVING COUNT(*) > 1
) AS T

UNION ALL

SELECT
    'stores',
    COUNT(*)
FROM
(
    SELECT Store_ID
    FROM stg.stores
    WHERE Store_ID IS NOT NULL
      AND LTRIM(RTRIM(Store_ID)) <> ''
    GROUP BY Store_ID
    HAVING COUNT(*) > 1
) AS T

UNION ALL

SELECT
    'employees',
    COUNT(*)
FROM
(
    SELECT Employee_ID
    FROM stg.employees
    WHERE Employee_ID IS NOT NULL
      AND LTRIM(RTRIM(Employee_ID)) <> ''
    GROUP BY Employee_ID
    HAVING COUNT(*) > 1
) AS T;
GO


/* ============================================================
   6. KIỂM TRA TRANSACTIONS TRÙNG THEO INVOICE_ID + LINE

   LƯU Ý:
   Kết quả khác 0 KHÔNG đồng nghĩa duplicate hoàn toàn.
   Đây chỉ là kiểm tra theo khóa rút gọn.

   Phân tích chi tiết nằm trong file 14.
   ============================================================ */

PRINT N'6. KIỂM TRA TRANSACTIONS THEO INVOICE_ID + LINE';

SELECT
    COUNT(*) AS SoNhomTrungTheoInvoiceLine
FROM
(
    SELECT
        Invoice_ID,
        Line
    FROM stg.transactions
    WHERE Invoice_ID IS NOT NULL
      AND LTRIM(RTRIM(Invoice_ID)) <> ''
      AND Line IS NOT NULL
      AND LTRIM(RTRIM(Line)) <> ''
    GROUP BY
        Invoice_ID,
        Line
    HAVING COUNT(*) > 1
) AS T;
GO


/* ============================================================
   7. KIỂM TRA TRANSACTIONS TRÙNG HOÀN TOÀN
   THEO CÁC THUỘC TÍNH NGHIỆP VỤ

   Không dùng:
   - Stg_Row_ID
   - Source_File
   - Load_Date
   ============================================================ */

PRINT N'7. KIỂM TRA TRANSACTIONS TRÙNG HOÀN TOÀN';

WITH TrungHoanToan AS
(
    SELECT
        Invoice_ID,
        Line,
        Customer_ID,
        Product_ID,
        Size,
        Color,
        Unit_Price,
        Quantity,
        Date,
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
        Is_Review,
        Country_Code,
        Expected_Currency,
        Currency_Match,
        Net_Amount_Local,
        Exchange_Rate_To_USD,
        Exchange_Rate_Date,
        Exchange_Rate_Source,
        Net_Amount_USD,
        COUNT(*) AS SoLan

    FROM stg.transactions

    GROUP BY
        Invoice_ID,
        Line,
        Customer_ID,
        Product_ID,
        Size,
        Color,
        Unit_Price,
        Quantity,
        Date,
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
        Is_Review,
        Country_Code,
        Expected_Currency,
        Currency_Match,
        Net_Amount_Local,
        Exchange_Rate_To_USD,
        Exchange_Rate_Date,
        Exchange_Rate_Source,
        Net_Amount_USD

    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS SoNhomTrungHoanToan,
    COALESCE(SUM(SoLan), 0) AS TongDongTrongNhomTrung,
    COALESCE(SUM(SoLan - 1), 0) AS SoDongDuThua
FROM TrungHoanToan;
GO


/* ============================================================
   8. KIỂM TRA NHANH DỮ LIỆU MẪU
   ============================================================ */

PRINT N'8. XEM DỮ LIỆU MẪU';


SELECT TOP 10 *
FROM stg.customers;
GO


SELECT TOP 10 *
FROM stg.products;
GO


SELECT TOP 10 *
FROM stg.stores;
GO


SELECT TOP 10 *
FROM stg.employees;
GO


SELECT TOP 10 *
FROM stg.discounts;
GO


SELECT TOP 10 *
FROM stg.transactions;
GO