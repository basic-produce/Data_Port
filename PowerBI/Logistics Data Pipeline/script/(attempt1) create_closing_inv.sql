WITH AllDates AS (
    SELECT DISTINCT date_key, material_id FROM dbo.temp_Cartesian_Product
),curr_stk AS (
    SELECT
        Material,
        Material_Description,
        Plant,
		'2022-01-01' AS update_date,
        SUM(Unrestricted) AS Unres_Qty,
        SUM(Quality_Inspection) AS Insp_Qty,
        SUM([Transit_and_Transfer]) AS Trans_Qty,
        SUM([Restricted-Use_Stock]) AS Restricted_Qty
    FROM
        SC.stock_by_material
	WHERE Material is not null
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
		AND Material IS NOT NULL
    GROUP BY
        Material,
        Short_Text,
        Plant,
        [Vendor/supplying_plant],
        Document_Date,
        Purchasing_Document
    HAVING
        SUM(Still_to_be_delivered_qty) > 0
),
StockLevels AS (
    SELECT 
        CONVERT(datetime, ad.date_key) AS date_key,
        cs.Material, 
        cs.Material_Description, 
        cs.Plant, 
        cs.Unres_Qty, 
        COALESCE(i.Qty, 0) AS Qty,
        COALESCE(i.Available_Date, ad.date_key) AS Available_Date,
        (cs.Unres_Qty + COALESCE(i.Qty, 0)) AS Available_Qty,
        CASE
            WHEN i.Available_Date IS NULL THEN ad.date_key
            ELSE i.Available_Date
        END AS Stock_Date
    FROM 
        AllDates ad
	LEFT JOIN curr_stk cs
	on cs.Material = ad.material_id
    Full JOIN
        incoming_stk i  
		ON
		ad.date_key=i.Available_Date
		and cs.Material = i.Material
		AND cs.Plant = i.Plant
)
SELECT * FROM StockLevels
--where date_key is not null
ORDER BY Material, Stock_Date