--Kiểm tra khoảng thời gian
SELECT
    MIN(TRY_CONVERT(DATETIME2, Date)) AS MinDate,
    MAX(TRY_CONVERT(DATETIME2, Date)) AS MaxDate
FROM raw.transactions;

--Kiểm tra các loại giao dịch
SELECT
    Transaction_Type,
    COUNT(*) AS TotalRows
FROM raw.transactions
GROUP BY Transaction_Type
ORDER BY TotalRows DESC;

--Kiểm tra số quốc gia cửa hàng
SELECT
    COUNT(DISTINCT Country) AS TotalCountries
FROM raw.stores;

--Kiểm tra số cửa hàng
SELECT
    COUNT(DISTINCT Store_ID) AS TotalStores
FROM raw.stores;

--Xem danh sách quốc gia
SELECT DISTINCT Country
FROM raw.stores
ORDER BY Country;

-- =========================================================
-- 2.2.2. KIỂM TRA DỮ LIỆU THIẾU
-- Kiểm tra NULL, chuỗi rỗng và chuỗi chỉ chứa khoảng trắng
-- trên toàn bộ 6 bảng RAW
-- =========================================================


-- =========================================================
-- 1. KIỂM TRA DỮ LIỆU THIẾU - CUSTOMERS
-- =========================================================

SELECT
    COUNT(*) AS TotalRows,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Customer_ID)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Customer_ID,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Name)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Name,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Email)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Email,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Telephone)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Telephone,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(City)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_City,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Country)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Country,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Gender)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Gender,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Date_Of_Birth)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Date_Of_Birth,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Job_Title)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Job_Title

FROM raw.customers;


-- =========================================================
-- 2. KIỂM TRA DỮ LIỆU THIẾU - PRODUCTS
-- =========================================================

SELECT
    COUNT(*) AS TotalRows,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Product_ID)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Product_ID,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Category)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Category,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Sub_Category)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Sub_Category,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Color)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Color,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Sizes)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Sizes,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Production_Cost)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Production_Cost

FROM raw.products;


-- =========================================================
-- 3. KIỂM TRA DỮ LIỆU THIẾU - STORES
-- =========================================================

SELECT
    COUNT(*) AS TotalRows,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Store_ID)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Store_ID,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Country)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Country,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(City)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_City,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Store_Name)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Store_Name,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Number_of_Employees)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Number_of_Employees,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(ZIP_Code)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_ZIP_Code,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Latitude)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Latitude,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Longitude)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Longitude

FROM raw.stores;


-- =========================================================
-- 4. KIỂM TRA DỮ LIỆU THIẾU - EMPLOYEES
-- =========================================================

SELECT
    COUNT(*) AS TotalRows,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Employee_ID)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Employee_ID,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Store_ID)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Store_ID,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Name)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Name,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Position)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Position

FROM raw.employees;


-- =========================================================
-- 5. KIỂM TRA DỮ LIỆU THIẾU - DISCOUNTS
-- =========================================================

SELECT
    COUNT(*) AS TotalRows,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM([Start])), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Start,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM([End])), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_End,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Discont)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Discont,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Description)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Description,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Category)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Category,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Sub_Category)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Sub_Category

FROM raw.discounts;
-- =========================================================
-- 6. KIỂM TRA DỮ LIỆU THIẾU - TRANSACTIONS
-- =========================================================

SELECT
    COUNT(*) AS TotalRows,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Invoice_ID)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Invoice_ID,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Line)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Line,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Customer_ID)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Customer_ID,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Product_ID)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Product_ID,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Size)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Size,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Color)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Color,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Unit_Price)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Unit_Price,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Quantity)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Quantity,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Date)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Date,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Discount)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Discount,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Line_Total)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Line_Total,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Store_ID)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Store_ID,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Employee_ID)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Employee_ID,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Currency)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Currency,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Currency_Symbol)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Currency_Symbol,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(SKU)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_SKU,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Transaction_Type)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Transaction_Type,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Payment_Method)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Payment_Method,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Invoice_Total)), '') IS NULL
        THEN 1 ELSE 0 END) AS Missing_Invoice_Total

FROM raw.transactions;


-- =========================================================
-- KẾT THÚC KIỂM TRA DỮ LIỆU THIẾU
-- Sau khi chạy:
-- 1. Ghi lại các cột có Missing > 0
-- 2. Tính tỷ lệ Missing
-- 3. Đưa các cột đáng chú ý vào Bảng 2.9 của báo cáo
-- =========================================================

-- =========================================================
-- 2.2.3. KIỂM TRA DỮ LIỆU TRÙNG LẶP
-- Kiểm tra trùng theo khóa nghiệp vụ và trùng toàn dòng
-- trên các bảng RAW
-- =========================================================


-- =========================================================
-- 1. TRANSACTIONS
-- Khóa nghiệp vụ: Invoice_ID + Line
-- =========================================================

SELECT
    Invoice_ID,
    Line,
    COUNT(*) AS Duplicate_Count
FROM raw.transactions
GROUP BY Invoice_ID, Line
HAVING COUNT(*) > 1
ORDER BY Duplicate_Count DESC;


-- =========================================================
-- 2. CUSTOMERS
-- Khóa nghiệp vụ: Customer_ID
-- =========================================================

SELECT
    Customer_ID,
    COUNT(*) AS Duplicate_Count
FROM raw.customers
GROUP BY Customer_ID
HAVING COUNT(*) > 1
ORDER BY Duplicate_Count DESC;


-- =========================================================
-- 3. PRODUCTS
-- Khóa nghiệp vụ: Product_ID
-- =========================================================

SELECT
    Product_ID,
    COUNT(*) AS Duplicate_Count
FROM raw.products
GROUP BY Product_ID
HAVING COUNT(*) > 1
ORDER BY Duplicate_Count DESC;


-- =========================================================
-- 4. STORES
-- Khóa nghiệp vụ: Store_ID
-- =========================================================

SELECT
    Store_ID,
    COUNT(*) AS Duplicate_Count
FROM raw.stores
GROUP BY Store_ID
HAVING COUNT(*) > 1
ORDER BY Duplicate_Count DESC;


-- =========================================================
-- 5. EMPLOYEES
-- Khóa nghiệp vụ: Employee_ID
-- =========================================================

SELECT
    Employee_ID,
    COUNT(*) AS Duplicate_Count
FROM raw.employees
GROUP BY Employee_ID
HAVING COUNT(*) > 1
ORDER BY Duplicate_Count DESC;


-- =========================================================
-- 6. DISCOUNTS
-- Bảng discounts không có ID riêng
-- Kiểm tra trùng theo:
-- Start + End + Discont + Category + Sub_Category
-- =========================================================

SELECT
    [Start],
    [End],
    Discont,
    Category,
    Sub_Category,
    COUNT(*) AS Duplicate_Count
FROM raw.discounts
GROUP BY
    [Start],
    [End],
    Discont,
    Category,
    Sub_Category
HAVING COUNT(*) > 1
ORDER BY Duplicate_Count DESC;


-- =========================================================
-- 7. KIỂM TRA TRÙNG TOÀN DÒNG - CUSTOMERS
-- =========================================================

SELECT
    Customer_ID,
    Name,
    Email,
    Telephone,
    City,
    Country,
    Gender,
    Date_Of_Birth,
    Job_Title,
    COUNT(*) AS Duplicate_Count
FROM raw.customers
GROUP BY
    Customer_ID,
    Name,
    Email,
    Telephone,
    City,
    Country,
    Gender,
    Date_Of_Birth,
    Job_Title
HAVING COUNT(*) > 1
ORDER BY Duplicate_Count DESC;


-- =========================================================
-- 8. KIỂM TRA TRÙNG TOÀN DÒNG - PRODUCTS
-- =========================================================

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
    Production_Cost,
    COUNT(*) AS Duplicate_Count
FROM raw.products
GROUP BY
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
HAVING COUNT(*) > 1
ORDER BY Duplicate_Count DESC;


-- =========================================================
-- 9. KIỂM TRA TRÙNG TOÀN DÒNG - STORES
-- =========================================================

SELECT
    Store_ID,
    Country,
    City,
    Store_Name,
    Number_of_Employees,
    ZIP_Code,
    Latitude,
    Longitude,
    COUNT(*) AS Duplicate_Count
FROM raw.stores
GROUP BY
    Store_ID,
    Country,
    City,
    Store_Name,
    Number_of_Employees,
    ZIP_Code,
    Latitude,
    Longitude
HAVING COUNT(*) > 1
ORDER BY Duplicate_Count DESC;


-- =========================================================
-- 10. KIỂM TRA TRÙNG TOÀN DÒNG - EMPLOYEES
-- =========================================================

SELECT
    Employee_ID,
    Store_ID,
    Name,
    Position,
    COUNT(*) AS Duplicate_Count
FROM raw.employees
GROUP BY
    Employee_ID,
    Store_ID,
    Name,
    Position
HAVING COUNT(*) > 1
ORDER BY Duplicate_Count DESC;


-- =========================================================
-- 11. KIỂM TRA TRÙNG TOÀN DÒNG - DISCOUNTS
-- =========================================================

SELECT
    [Start],
    [End],
    Discont,
    Description,
    Category,
    Sub_Category,
    COUNT(*) AS Duplicate_Count
FROM raw.discounts
GROUP BY
    [Start],
    [End],
    Discont,
    Description,
    Category,
    Sub_Category
HAVING COUNT(*) > 1
ORDER BY Duplicate_Count DESC;


-- =========================================================
-- 12. KIỂM TRA TRÙNG TOÀN DÒNG - TRANSACTIONS
-- Lưu ý: bảng rất lớn, query này có thể chạy lâu
-- =========================================================

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
    COUNT(*) AS Duplicate_Count
FROM raw.transactions
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
    Invoice_Total
HAVING COUNT(*) > 1
ORDER BY Duplicate_Count DESC;


-- =========================================================
-- KẾT THÚC 2.2.3
-- Cách đọc kết quả:
--
-- 1. Nếu một query không trả về dòng nào:
--    => không phát hiện trùng theo điều kiện đó.
--
-- 2. Nếu có kết quả:
--    Duplicate_Count > 1
--    => khóa/bản ghi đó xuất hiện nhiều hơn một lần.
--
-- 3. Ghi lại:
--    - bảng nào có duplicate
--    - khóa nào bị trùng
--    - số nhóm trùng
--    - số dòng bị ảnh hưởng
--
-- 4. Chưa DELETE dữ liệu ở bước này.
--    Việc xử lý duplicate sẽ thực hiện ở mục 2.3.1.
-- =========================================================
-- =========================================================
-- 13. TỔNG HỢP SỐ NHÓM VÀ SỐ DÒNG TRÙNG
-- TRANSACTIONS THEO KHÓA (Invoice_ID, Line)
-- =========================================================

WITH Dup AS
(
    SELECT
        Invoice_ID,
        Line,
        COUNT(*) AS Duplicate_Count
    FROM raw.transactions
    GROUP BY Invoice_ID, Line
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*) AS Duplicate_Groups,
    SUM(Duplicate_Count) AS Total_Rows_In_Duplicate_Groups,
    SUM(Duplicate_Count - 1) AS Extra_Duplicate_Rows
FROM Dup;