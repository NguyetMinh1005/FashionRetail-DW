USE Fashion_Staging;
GO

/* ============================================================
   2.2.5. PHÂN TÍCH DỮ LIỆU BẤT THƯỜNG

   Mục đích:
   - Tìm các hiện tượng đáng chú ý trong dữ liệu
   - KHÔNG tự động xem tất cả là dữ liệu lỗi
   - KHÔNG UPDATE / DELETE dữ liệu
   ============================================================ */


DECLARE
    @A1 BIGINT = 0,
    @A2 BIGINT = 0,
    @A3 BIGINT = 0,
    @A4 BIGINT = 0,
    @A5 BIGINT = 0,
    @A6 BIGINT = 0;


/* ============================================================
   A1. RETURN CÓ LINE_TOTAL KHÔNG KHỚP CÔNG THỨC GIẢ ĐỊNH

   Công thức dùng để đối chiếu:
   Return Line_Total ≈
   - Unit_Price * Quantity * (1 - Discount)

   LƯU Ý:
   Đây chỉ là phép đối chiếu.
   Không kết luận ngay các dòng này là lỗi dữ liệu.
   ============================================================ */

SELECT
    @A1 = COUNT_BIG(*)

FROM raw.transactions

WHERE Transaction_Type = 'Return'

AND ABS(
        TRY_CONVERT(DECIMAL(18,4), Line_Total)
        -
        (
            -1
            * TRY_CONVERT(DECIMAL(18,4), Unit_Price)
            * TRY_CONVERT(DECIMAL(18,4), Quantity)
            * (
                1
                - TRY_CONVERT(DECIMAL(18,4), Discount)
              )
        )
    ) > 0.01;


/* ============================================================
   A2. MỘT INVOICE_ID CÓ NHIỀU GIÁ TRỊ INVOICE_TOTAL
   ============================================================ */

SELECT
    @A2 = COUNT_BIG(*)

FROM
(
    SELECT
        Invoice_ID

    FROM raw.transactions

    GROUP BY
        Invoice_ID

    HAVING
        COUNT(
            DISTINCT TRY_CONVERT(
                DECIMAL(18,4),
                Invoice_Total
            )
        ) > 1
) AS X;


/* ============================================================
   A3. TIỀN TỐ RET KHÔNG KHỚP TRANSACTION_TYPE

   Return thường có Invoice_ID bắt đầu bằng RET.
   Kiểm tra:
   - Invoice RET nhưng không phải Return
   - Return nhưng Invoice không bắt đầu bằng RET
   ============================================================ */

SELECT
    @A3 = COUNT_BIG(*)

FROM raw.transactions

WHERE
       (
           Invoice_ID LIKE 'RET%'
           AND Transaction_Type <> 'Return'
       )

    OR (
           Invoice_ID NOT LIKE 'RET%'
           AND Transaction_Type = 'Return'
       );


/* ============================================================
   A4. NUMBER_OF_EMPLOYEES CỦA STORE KHÔNG KHỚP
       SỐ NHÂN VIÊN THỰC TẾ TRONG EMPLOYEES
   ============================================================ */

WITH SoNhanVienThucTe AS
(
    SELECT
        Store_ID,
        COUNT(DISTINCT Employee_ID) AS Actual_Employees

    FROM raw.employees

    GROUP BY
        Store_ID
)

SELECT
    @A4 = COUNT_BIG(*)

FROM raw.stores s

LEFT JOIN SoNhanVienThucTe e
    ON s.Store_ID = e.Store_ID

WHERE
       TRY_CONVERT(INT, s.Number_of_Employees)
           <> ISNULL(e.Actual_Employees, 0)

    OR TRY_CONVERT(
           INT,
           s.Number_of_Employees
       ) IS NULL;


/* ============================================================
   A5. DATE_OF_BIRTH KHÔNG CHUYỂN ĐƯỢC SANG DATE

   Chỉ xét các giá trị không rỗng.
   Missing đã được khảo sát ở 2.2.2.
   ============================================================ */

SELECT
    @A5 = COUNT_BIG(*)

FROM raw.customers

WHERE
    NULLIF(
        LTRIM(RTRIM(Date_Of_Birth)),
        ''
    ) IS NOT NULL

AND TRY_CONVERT(
        DATE,
        Date_Of_Birth
    ) IS NULL;


/* ============================================================
   A6. PRODUCTION_COST KHÔNG HỢP LỆ

   Điều kiện bất thường:
   - Không chuyển được thành số
   - Hoặc <= 0

   Chỉ xét các giá trị không rỗng.
   ============================================================ */

SELECT
    @A6 = COUNT_BIG(*)

FROM raw.products

WHERE
    NULLIF(
        LTRIM(RTRIM(Production_Cost)),
        ''
    ) IS NOT NULL

AND
(
       TRY_CONVERT(
           DECIMAL(18,4),
           Production_Cost
       ) IS NULL

    OR TRY_CONVERT(
           DECIMAL(18,4),
           Production_Cost
       ) <= 0
);


/* ============================================================
   KẾT QUẢ TỔNG HỢP
   ============================================================ */

SELECT
    Ma_bat_thuong,
    Loai_bat_thuong,
    Dieu_kien_kiem_tra,
    So_luong,
    Nhan_dinh

FROM
(
    VALUES

    (
        'A1',
        N'Thành tiền Return không khớp công thức giả định',
        N'Line_Total khác -Unit_Price × Quantity × (1 - Discount)',
        @A1,
        N'Chưa kết luận là lỗi; cần lưu ý khi xử lý Return'
    ),

    (
        'A2',
        N'Invoice_Total không nhất quán',
        N'Một Invoice_ID có nhiều giá trị Invoice_Total',
        @A2,
        N'Không nên cộng trực tiếp Invoice_Total ở mức dòng'
    ),

    (
        'A3',
        N'Mã hóa đơn Return không khớp loại giao dịch',
        N'Tiền tố RET không phù hợp với Transaction_Type',
        @A3,
        N'Kiểm tra tính nhất quán giữa mã hóa đơn và loại giao dịch'
    ),

    (
        'A4',
        N'Số nhân viên cửa hàng không khớp',
        N'Number_of_Employees khác số Employee_ID thực tế theo Store',
        @A4,
        N'Cần đối chiếu stores với employees khi phân tích nhân sự'
    ),

    (
        'A5',
        N'Ngày sinh không hợp lệ',
        N'Date_Of_Birth không chuyển được sang DATE',
        @A5,
        N'Có thể ảnh hưởng đến tính tuổi và nhóm tuổi khách hàng'
    ),

    (
        'A6',
        N'Giá vốn sản phẩm không hợp lệ',
        N'Production_Cost không phải số hoặc <= 0',
        @A6,
        N'Có thể ảnh hưởng đến các phân tích liên quan đến giá vốn'
    )

) AS KQ
(
    Ma_bat_thuong,
    Loai_bat_thuong,
    Dieu_kien_kiem_tra,
    So_luong,
    Nhan_dinh
)

ORDER BY
    Ma_bat_thuong;


/* ============================================================
   CHI TIẾT A4 - CỬA HÀNG CÓ SỐ NHÂN VIÊN KHÔNG KHỚP
   ============================================================ */

WITH SoNhanVienThucTe AS
(
    SELECT
        Store_ID,
        COUNT(DISTINCT Employee_ID) AS Actual_Employees

    FROM raw.employees

    GROUP BY
        Store_ID
)

SELECT
    s.Store_ID,
    s.Store_Name,

    TRY_CONVERT(
        INT,
        s.Number_of_Employees
    ) AS Declared_Employees,

    ISNULL(
        e.Actual_Employees,
        0
    ) AS Actual_Employees

FROM raw.stores s

LEFT JOIN SoNhanVienThucTe e
    ON s.Store_ID = e.Store_ID

WHERE
       TRY_CONVERT(
           INT,
           s.Number_of_Employees
       ) <> ISNULL(
           e.Actual_Employees,
           0
       )

    OR TRY_CONVERT(
           INT,
           s.Number_of_Employees
       ) IS NULL

ORDER BY
    s.Store_ID;

--xác nhận chắc chắn cả 35 cửa hàng đều chênh đúng 3

    WITH SoNhanVienThucTe AS
(
    SELECT
        Store_ID,
        COUNT(DISTINCT Employee_ID) AS Actual_Employees
    FROM raw.employees
    GROUP BY Store_ID
)

SELECT
    s.Store_ID,
    s.Store_Name,
    TRY_CONVERT(INT, s.Number_of_Employees) AS Declared_Employees,
    e.Actual_Employees,
    e.Actual_Employees
        - TRY_CONVERT(INT, s.Number_of_Employees) AS Difference
FROM raw.stores s
LEFT JOIN SoNhanVienThucTe e
    ON s.Store_ID = e.Store_ID
ORDER BY s.Store_ID;

--xem tóm tắt:
WITH SoNhanVienThucTe AS
(
    SELECT
        Store_ID,
        COUNT(DISTINCT Employee_ID) AS Actual_Employees
    FROM raw.employees
    GROUP BY Store_ID
)

SELECT
    MIN(
        e.Actual_Employees
        - TRY_CONVERT(INT, s.Number_of_Employees)
    ) AS Min_Difference,

    MAX(
        e.Actual_Employees
        - TRY_CONVERT(INT, s.Number_of_Employees)
    ) AS Max_Difference,

    AVG(
        1.0 * (
            e.Actual_Employees
            - TRY_CONVERT(INT, s.Number_of_Employees)
        )
    ) AS Avg_Difference

FROM raw.stores s
JOIN SoNhanVienThucTe e
    ON s.Store_ID = e.Store_ID;