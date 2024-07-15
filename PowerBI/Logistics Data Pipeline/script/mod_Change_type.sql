UPDATE Sales.po_by__vendor
SET Order_Quantity = REPLACE(REPLACE(Order_Quantity, ',', ''),'.','')

ALTER TABLE Sales.po_by__vendor
ALTER COLUMN Order_Quantity INT;

ALTER TABLE SC.stock_by_material
ALTER COLUMN Transit_and_Transfer INT;




UPDATE Sales.po_by__vendor
SET Still_to_be_delivered_qty = REPLACE(REPLACE(Still_to_be_delivered_qty, ',', ''),'.','')

ALTER TABLE Sales.po_by__vendor
ALTER COLUMN Still_to_be_delivered_qty INT;

SELECT 
    COLUMN_NAME,
    DATA_TYPE
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_NAME = 'po_by__vendor';

SELECT 
    COLUMN_NAME,
    DATA_TYPE
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_NAME = 'dim_date';