WITH curr_stk AS (
    SELECT
        Material,
        Material_Description,
        Plant,
        SUM(Unrestricted) AS Unres_Qty,
        SUM(Quality_Inspection) AS Insp_Qty,
        SUM([Transit_and_Transfer]) AS Trans_Qty,
        SUM([Restricted-Use_Stock]) AS Restricted_Qty
    FROM
        SC.stock_by_material
    GROUP BY
        Material,
        Material_Description,
        Plant
),
incoming_stk AS (
    SELECT
        Material,
        Short_Text AS Material_Description,
        Plant,
        [Vendor/supplying_plant] AS Supplying,
        Document_Date,
        Purchasing_Document,
        DATEADD(DAY,	
                CASE 
                    WHEN Plant = 'VN49' THEN 7 * 4
                    WHEN Plant = 'VNT0' THEN 7 * 5
                    ELSE 0
                END, 
                Document_Date) AS Available_Date,
        SUM(Still_to_be_delivered_qty) AS Qty
    FROM
        Sales.po_by__vendor
    WHERE
        Deletion_indicator IS NULL
    GROUP BY
        Material,
        Short_Text,
        Plant,
        [Vendor/supplying_plant],
        Document_Date,
        Purchasing_Document
    HAVING
        SUM(Still_to_be_delivered_qty) > 0
)
SELECT c.Material, 
       c.Material_Description, 
       c.Plant, 
       c.Unres_Qty, 
       i.Qty, 
       i.Supplying, 
       i.Available_Date,
       (c.Unres_Qty + i.Qty) as Available_Qty,
       CASE
           WHEN Available_Date IS NULL THEN Date
           ELSE Available_Date
       END AS Stock_Date
FROM curr_stk c
FULL JOIN dbo.temp_Cartesian_Product as cp 
	ON cp.Material = c.Material
	AND	cp.Date = c.Date
FULL JOIN incoming_stk i 
	ON c.Material = i.Material
	AND c.Plant = i.Plant
WHERE c.Material IS NOT NULL
AND c.Material IN (
    SELECT Material
    FROM curr_stk
    GROUP BY Material
    HAVING COUNT(*) > 2 -- Filters materials appearing more than 2 times
)
AND c.Plant = 'VN49'
ORDER BY Material, Stock_Date;
