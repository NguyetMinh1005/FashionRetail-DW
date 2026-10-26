USE Fashion_Staging;
GO

-- Kiem tra so dong du lieu trong cac bang STG

SELECT
    N'customers' AS TableName,
    COUNT_BIG(*) AS TotalRows
FROM stg.customers

UNION ALL

SELECT
    N'discounts',
    COUNT_BIG(*)
FROM stg.discounts

UNION ALL

SELECT
    N'employees',
    COUNT_BIG(*)
FROM stg.employees

UNION ALL

SELECT
    N'products',
    COUNT_BIG(*)
FROM stg.products

UNION ALL

SELECT
    N'stores',
    COUNT_BIG(*)
FROM stg.stores

UNION ALL

SELECT
    N'transactions',
    COUNT_BIG(*)
FROM stg.transactions;
GO
