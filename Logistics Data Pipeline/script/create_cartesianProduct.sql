Drop TABLE CartesianProduct;

WITH AllMaterials AS (
 SELECT SAP_Code
FROM (
    SELECT SAP_Code, ROW_NUMBER() OVER (ORDER BY SAP_Code) AS rn
    FROM SC.dim_material
    GROUP BY SAP_Code
) AS sub
WHERE rn > 5000
),
CartesianProduct AS (
    SELECT 
        dd.date_key,
        am.SAP_Code material_id,
		dp.Plant
    FROM 
        dbo.dim_date dd
    CROSS JOIN 
        AllMaterials am
	CROSS JOIN dim_plant dp
)
INSERT INTO dim_Cartesian (date_key, Plant, material_id)
SELECT 
    cp.date_key,
	cp.Plant,
    cp.material_id
FROM 
    CartesianProduct cp
ORDER BY date_key;

-- Create the table to store the Cartesian product
CREATE TABLE dim_Cartesian (
    date_key DATE,
	Plant VARCHAR(10),
    material_id INT,
);

select * from dim_Cartesian
order by date_key, material_id, Plant
