USE Fashion_DW;
GO

/* ============================================================
   21 - LOAD DIM EMPLOYEE
   ============================================================ */

TRUNCATE TABLE dbo.Dim_Employee;
GO

INSERT INTO dbo.Dim_Employee
(
    Employee_ID,
    Store_ID,
    Employee_Name,
    Position
)
SELECT
    Employee_ID,
    Store_ID,
    Name,
    Position
FROM Fashion_Staging.stg.employees;
GO

/* Kiểm tra số dòng */
SELECT COUNT(*) AS SoDong
FROM dbo.Dim_Employee;
GO

/* Xem dữ liệu mẫu */
SELECT TOP 10 *
FROM dbo.Dim_Employee
ORDER BY Employee_Key;
GO