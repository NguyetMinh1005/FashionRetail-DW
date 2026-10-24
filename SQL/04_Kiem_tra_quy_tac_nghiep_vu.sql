USE Fashion_Staging;
GO

/* ============================================================
   2.2.4. KIỂM TRA QUY TẮC NGHIỆP VỤ

   Mục đích:
   - Kiểm tra các điều kiện nghiệp vụ trên dữ liệu RAW
   - Chỉ đếm số dòng vi phạm
   - KHÔNG UPDATE / DELETE dữ liệu tại bước 2.2
   ============================================================ */


DECLARE
    @R1  BIGINT = 0,
    @R2  BIGINT = 0,
    @R3  BIGINT = 0,
    @R4  BIGINT = 0,
    @R5  BIGINT = 0,
    @R6  BIGINT = 0,
    @R7  BIGINT = 0,
    @R8  BIGINT = 0,
    @R9  BIGINT = 0,
    @R10 BIGINT = 0,
    @R11 BIGINT = 0,
    @R12 BIGINT = 0,
    @R13 BIGINT = 0;


/* ============================================================
   R1, R2, R3, R11, R12
   Kiểm tra trực tiếp trên transactions
   ============================================================ */

SELECT
    @R1 =
        SUM(
            CASE
                WHEN TRY_CONVERT(DECIMAL(18,4), Quantity) IS NULL
                     OR TRY_CONVERT(DECIMAL(18,4), Quantity) <= 0
                THEN 1 ELSE 0
            END
        ),

    @R2 =
        SUM(
            CASE
                WHEN TRY_CONVERT(DECIMAL(18,4), Unit_Price) IS NULL
                     OR TRY_CONVERT(DECIMAL(18,4), Unit_Price) <= 0
                THEN 1 ELSE 0
            END
        ),

    @R3 =
        SUM(
            CASE
                WHEN TRY_CONVERT(DECIMAL(18,4), Discount) IS NULL
                     OR TRY_CONVERT(DECIMAL(18,4), Discount) < 0
                     OR TRY_CONVERT(DECIMAL(18,4), Discount) > 1
                THEN 1 ELSE 0
            END
        ),

    @R11 =
        SUM(
            CASE
                WHEN Transaction_Type NOT IN ('Sale', 'Return')
                     OR Transaction_Type IS NULL
                THEN 1 ELSE 0
            END
        ),

    @R12 =
        SUM(
            CASE

                -- Sale phải có Line_Total > 0
                WHEN Transaction_Type = 'Sale'
                     AND (
                         TRY_CONVERT(DECIMAL(18,4), Line_Total) IS NULL
                         OR TRY_CONVERT(DECIMAL(18,4), Line_Total) <= 0
                     )
                THEN 1

                -- Return phải có Line_Total < 0
                WHEN Transaction_Type = 'Return'
                     AND (
                         TRY_CONVERT(DECIMAL(18,4), Line_Total) IS NULL
                         OR TRY_CONVERT(DECIMAL(18,4), Line_Total) >= 0
                     )
                THEN 1

                ELSE 0

            END
        )

FROM raw.transactions;


/* ============================================================
   R4, R5, R6, R7, R8
   Kiểm tra tính toàn vẹn tham chiếu giữa các bảng
   ============================================================ */

SELECT
    @R4 =
        SUM(
            CASE
                WHEN p.Product_ID IS NULL
                THEN 1 ELSE 0
            END
        ),

    @R5 =
        SUM(
            CASE
                WHEN s.Store_ID IS NULL
                THEN 1 ELSE 0
            END
        ),

    @R6 =
        SUM(
            CASE
                WHEN e.Employee_ID IS NULL
                THEN 1 ELSE 0
            END
        ),

    @R7 =
        SUM(
            CASE
                WHEN c.Customer_ID IS NULL
                THEN 1 ELSE 0
            END
        ),

    @R8 =
        SUM(
            CASE
                WHEN e.Employee_ID IS NOT NULL
                     AND t.Store_ID <> e.Store_ID
                THEN 1 ELSE 0
            END
        )

FROM raw.transactions t

LEFT JOIN raw.products p
    ON t.Product_ID = p.Product_ID

LEFT JOIN raw.stores s
    ON t.Store_ID = s.Store_ID

LEFT JOIN raw.employees e
    ON t.Employee_ID = e.Employee_ID

LEFT JOIN raw.customers c
    ON t.Customer_ID = c.Customer_ID;


/* ============================================================
   R9, R10
   Kiểm tra bảng discounts
   ============================================================ */

SELECT
    @R9 =
        SUM(
            CASE
                WHEN TRY_CONVERT(DATE, [Start]) IS NULL
                     OR TRY_CONVERT(DATE, [End]) IS NULL
                     OR TRY_CONVERT(DATE, [Start])
                        > TRY_CONVERT(DATE, [End])
                THEN 1 ELSE 0
            END
        ),

    @R10 =
        SUM(
            CASE
                WHEN TRY_CONVERT(DECIMAL(18,4), Discont) IS NULL
                     OR TRY_CONVERT(DECIMAL(18,4), Discont) < 0
                     OR TRY_CONVERT(DECIMAL(18,4), Discont) > 1
                THEN 1 ELSE 0
            END
        )

FROM raw.discounts;


/* ============================================================
   R13
   Invoice_ID + Line phải duy nhất

   LƯU Ý:
   22.312 ở đây là số dòng dư theo KHÓA NGHIỆP VỤ,
   KHÔNG phải số dòng sẽ tự động xóa.

   2.2.3 đã xác định:
   - 798 dòng trùng hoàn toàn dư
   - các dòng còn lại cùng khóa nhưng khác nội dung
     phải được xem xét riêng.
   ============================================================ */

WITH DuplicateKey AS
(
    SELECT
        Invoice_ID,
        Line,
        COUNT_BIG(*) AS So_lan_xuat_hien

    FROM raw.transactions

    GROUP BY
        Invoice_ID,
        Line

    HAVING COUNT_BIG(*) > 1
)

SELECT
    @R13 =
        ISNULL(
            SUM(So_lan_xuat_hien - 1),
            0
        )

FROM DuplicateKey;


/* ============================================================
   KẾT QUẢ CUỐI CÙNG
   ============================================================ */

SELECT
    Quy_tac,
    Dieu_kien,
    So_dong_vi_pham,

    CASE
        WHEN So_dong_vi_pham = 0
        THEN N'Đạt'
        ELSE N'Có vi phạm'
    END AS Ket_luan

FROM
(
    VALUES

    ('R1',
     N'Quantity > 0',
     @R1),

    ('R2',
     N'Unit_Price > 0',
     @R2),

    ('R3',
     N'0 <= Discount <= 1',
     @R3),

    ('R4',
     N'Product_ID tồn tại trong products',
     @R4),

    ('R5',
     N'Store_ID tồn tại trong stores',
     @R5),

    ('R6',
     N'Employee_ID tồn tại trong employees',
     @R6),

    ('R7',
     N'Customer_ID tồn tại trong customers',
     @R7),

    ('R8',
     N'Employee thuộc đúng Store',
     @R8),

    ('R9',
     N'Start <= End',
     @R9),

    ('R10',
     N'0 <= Discont <= 1',
     @R10),

    ('R11',
     N'Transaction_Type chỉ gồm Sale hoặc Return',
     @R11),

    ('R12',
     N'Sale: Line_Total > 0; Return: Line_Total < 0',
     @R12),

    ('R13',
     N'(Invoice_ID, Line) là duy nhất',
     @R13)

) AS KQ(
    Quy_tac,
    Dieu_kien,
    So_dong_vi_pham
)

ORDER BY
    TRY_CONVERT(
        INT,
        REPLACE(Quy_tac, 'R', '')
    );