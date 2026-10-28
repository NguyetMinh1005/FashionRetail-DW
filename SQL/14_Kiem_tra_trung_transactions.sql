USE Fashion_Staging;
GO

/* ============================================================
   FILE 14 - KIỂM TRA TRÙNG TRANSACTIONS
   ============================================================

   Mục đích:
   1. Kiểm tra Invoice_ID + Line xuất hiện nhiều lần
   2. Kiểm tra thêm Product_ID, Size, Color, Transaction_Type
   3. Quan sát chi tiết một số trường hợp
   4. Kiểm tra duplicate hoàn toàn theo thuộc tính nghiệp vụ
   5. Đếm số nhóm duplicate hoàn toàn
   6. Kết luận có cần loại bỏ dữ liệu hay không

   LƯU Ý:
   - KHÔNG DELETE dữ liệu trong file này.
   - KHÔNG TRUNCATE dữ liệu.
   ============================================================ */


/* ============================================================
   1. KIỂM TRA TRÙNG THEO INVOICE_ID + LINE
   ============================================================ */

PRINT N'1. TRÙNG THEO INVOICE_ID + LINE';

SELECT TOP 100
    Invoice_ID,
    Line,
    COUNT(*) AS SoLan
FROM stg.transactions

WHERE Invoice_ID IS NOT NULL
  AND LTRIM(RTRIM(Invoice_ID)) <> ''
  AND Line IS NOT NULL
  AND LTRIM(RTRIM(Line)) <> ''

GROUP BY
    Invoice_ID,
    Line

HAVING COUNT(*) > 1

ORDER BY
    SoLan DESC,
    Invoice_ID,
    Line;
GO


/* ============================================================
   2. ĐẾM SỐ NHÓM TRÙNG THEO INVOICE_ID + LINE
   ============================================================ */

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
   3. KIỂM TRA THÊM:
      INVOICE_ID
      + LINE
      + PRODUCT_ID
      + SIZE
      + COLOR
      + TRANSACTION_TYPE

   Kết quả vẫn có thể > 1.
   Chưa được kết luận duplicate hoàn toàn.
   ============================================================ */

PRINT N'3. KIỂM TRA KHÓA RÚT GỌN CHI TIẾT HƠN';

SELECT TOP 100
    Invoice_ID,
    Line,
    Product_ID,
    Size,
    Color,
    Transaction_Type,
    COUNT(*) AS SoLan

FROM stg.transactions

GROUP BY
    Invoice_ID,
    Line,
    Product_ID,
    Size,
    Color,
    Transaction_Type

HAVING COUNT(*) > 1

ORDER BY
    SoLan DESC,
    Invoice_ID,
    Line;
GO


/* ============================================================
   4. XEM CHI TIẾT MỘT TRƯỜNG HỢP ĐÃ PHÁT HIỆN

   Ví dụ trong dữ liệu:
   RET-US-002-01839756
   Line = 3
   Product_ID = 3857

   Các dòng có thể giống một số trường nhưng khác Date,
   Invoice_Total,... nên không phải duplicate hoàn toàn.
   ============================================================ */

PRINT N'4. XEM CHI TIẾT MỘT TRƯỜNG HỢP';

SELECT *
FROM stg.transactions

WHERE Invoice_ID = 'RET-US-002-01839756'
  AND Line = '3'
  AND Product_ID = '3857'

ORDER BY
    Transaction_Date,
    Stg_Row_ID;
GO


/* ============================================================
   5. KIỂM TRA DUPLICATE HOÀN TOÀN
   THEO CÁC THUỘC TÍNH NGHIỆP VỤ

   Không đưa các cột kỹ thuật vào:
   - Stg_Row_ID
   - Source_File
   - Load_Date
   ============================================================ */

PRINT N'5. KIỂM TRA DUPLICATE HOÀN TOÀN';

SELECT TOP 100
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

ORDER BY SoLan DESC;
GO


/* ============================================================
   6. TỔNG HỢP SỐ NHÓM DUPLICATE HOÀN TOÀN
   ============================================================ */

PRINT N'6. TỔNG HỢP DUPLICATE HOÀN TOÀN';

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

    COALESCE(
        SUM(SoLan),
        0
    ) AS TongDongTrongNhomTrung,

    COALESCE(
        SUM(SoLan - 1),
        0
    ) AS SoDongDuThua

FROM TrungHoanToan;
GO


/* ============================================================
   7. KIỂM TRA SỐ DÒNG TRANSACTIONS CUỐI CÙNG
   ============================================================ */

PRINT N'7. TỔNG SỐ DÒNG TRANSACTIONS';

SELECT
    COUNT(*) AS TongSoDongTransactions
FROM stg.transactions;
GO