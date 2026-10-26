USE Fashion_Staging;
GO

-- Kiem tra so dong du lieu trong cac bang RAW

SELECT
    N'customers' AS TableName,
    COUNT_BIG(*) AS TotalRows
FROM raw.customers

UNION ALL

SELECT
    N'discounts',
    COUNT_BIG(*)
FROM raw.discounts

UNION ALL

SELECT
    N'employees',
    COUNT_BIG(*)
FROM raw.employees

UNION ALL

SELECT
    N'products',
    COUNT_BIG(*)
FROM raw.products

UNION ALL

SELECT
    N'stores',
    COUNT_BIG(*)
FROM raw.stores

UNION ALL

SELECT
    N'transactions',
    COUNT_BIG(*)
FROM raw.transactions;
GO