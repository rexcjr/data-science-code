CREATE TABLE property_sales (
	Id INT,
	MSSubClass VARCHAR(64),
	LotShape VARCHAR(64),
	LandContour	VARCHAR(128),
	LandSlope VARCHAR(64),
	BldgType VARCHAR(64),
	HouseStyle VARCHAR(64),
	OverallQual VARCHAR(64),
	OverallCond	VARCHAR(64),
	LotFrontage VARCHAR(64),
	LotArea	INT NOT NULL,
	GarageArea	INT NOT NULL,
	GrLivArea	INT NOT NULL,
	TotalBsmtSF	INT NOT NULL,
	SalePrice INT NOT NULL
);

-- IMPORT

SELECT * FROM property_sales ;

-- TASK # 1 : Perform One-Hot Encoding 
-- view categories
SELECT 
	landslope, 
	COUNT(*) AS count
FROM 
	property_sales
GROUP BY
	landslope
ORDER BY
	count DESC
;

-- add new feature columns
ALTER TABLE property_sales
ADD COLUMN gentle_slope INT,
ADD COLUMN moderate_slope INT,
ADD COLUMN severe_slope INT
;

-- update with One-Hot Encoding on new columns based on landslope column
UPDATE 
	property_sales
SET
	gentle_slope = 
		CASE 
	   		WHEN landslope = 'Gentle slope' THEN 1
	   		ELSE 0
	   	END,
	moderate_slope = 
		CASE 
	 		WHEN landslope = 'Moderate Slope' THEN 1
			ELSE 0
 		END,			 
	severe_slope = 
		CASE 
	   		WHEN landslope = 'Severe Slope' THEN 1
	   		ELSE 0
	   	END
; 	

-- Check if correct
SELECT 
	landslope, 
	COUNT(*) AS count,
	SUM(gentle_slope) AS gentle_sum,
	SUM(moderate_slope) AS moderate_sum,
	SUM(severe_slope) AS severe_sum
FROM 
	property_sales
GROUP BY
	landslope
ORDER BY
	count DESC
; -- all good

-- TASK # 2 : Perform Ordinal encoding 
-- view categories
SELECT 
	lotshape, 
	COUNT(*) AS count
FROM 
	property_sales
GROUP BY
	lotshape
ORDER BY
	count DESC
;

-- add new feature column
ALTER TABLE 
	property_sales
ADD COLUMN ordinal_lot_shape INT
;

-- update with Ordinal Encoding on new columns based on landslope column
UPDATE 
	property_sales
SET
	ordinal_lot_shape = 
		CASE 
			WHEN lotshape = 'Regular' THEN 0
			WHEN lotshape = 'Slightly irregular' THEN 1
			WHEN lotshape = 'Moderately Irregular' THEN 2
			WHEN lotshape = 'Irregular' THEN 3
			ELSE 4
		END
; 	

-- Check if correct
SELECT 
	lotshape, 
	COUNT(*) AS count,
	COUNT(CASE WHEN ordinal_lot_shape = 0 THEN 1 END) AS reg_cnt,
	COUNT(CASE WHEN ordinal_lot_shape = 1 THEN 1 END) AS slight_cnt,
	COUNT(CASE WHEN ordinal_lot_shape = 2 THEN 1 END) AS mod_cnt,
	COUNT(CASE WHEN ordinal_lot_shape = 3 THEN 1 END) AS irreg_cnt,
	COUNT(CASE WHEN ordinal_lot_shape = 4 THEN 1 END) AS none_cnt
FROM 
	property_sales
GROUP BY
	lotshape
ORDER BY
	count DESC
; -- all good

-- TASK # 3 : Perform Mean encoding
-- view categories
SELECT 
	landcontour, 
	COUNT(*) AS count
FROM 
	property_sales
GROUP BY
	landcontour
ORDER BY
	count DESC
;

-- view mean per category of target col gentle_slope 
SELECT DISTINCT
	landcontour,
	ROUND(AVG(gentle_slope) OVER (
		PARTITION BY landcontour), 2) as avg_target_mean
FROM
	property_sales
ORDER BY
	avg_target_mean
;

-- add new feature column
ALTER TABLE 
	property_sales
ADD COLUMN
	mean_land_contour FLOAT
;

--  With a temporary table, perform Mean encoding set in mean_land_contour col 
-- based on target mean(gentle_slope col) as category
WITH tmp_property_sales AS (
	SELECT
	landcontour,
	ROUND(AVG(gentle_slope) OVER (
			PARTITION BY landcontour), 2) AS target
  	FROM property_sales
)
UPDATE 
	property_sales
SET 
	mean_land_contour = tmp_property_sales.target
FROM 
	tmp_property_sales
WHERE
	property_sales.landcontour = tmp_property_sales.landcontour
;

-- Check if correct
SELECT DISTINCT
	landcontour,
	mean_land_contour,
	ROUND(AVG(gentle_slope) OVER (
			PARTITION BY landcontour), 2) AS target
FROM property_sales
; -- all good!

-- TASK # 4 : Perform Mean Normalization 
-- view columns with NULL values

SELECT 
	*
FROM 
	property_sales
WHERE 
	lotfrontage IS NULL OR
	lotarea IS NULL OR
	garagearea IS NULL OR
	grlivarea IS NULL OR
	totalbsmtsf IS NULL OR
	saleprice IS NULL
;

SELECT 
	lotfrontage,
	COUNT(*) AS count
FROM 
	property_sales
WHERE 
	lotfrontage = 'NA'
GROUP BY lotfrontage
; -- 259 NA count

-- Remove NA values and replace with NULL, then cast col to INT type
-- DID NOT CHOOSE TO IMPUTE DATA IN lotfrontage COL WITH MEAN DUE TO MULTIPLE FEATURES THAT MAY SKEW THE DATA
UPDATE property_sales
SET lotfrontage = NULL
WHERE lotfrontage = 'NA'
;

ALTER TABLE property_sales
ALTER COLUMN lotfrontage TYPE INT
USING lotfrontage::integer
;

-- add columns to contain mean normalized values
ALTER TABLE property_sales
ADD COLUMN lotfrontage_mean_norm FLOAT,
ADD COLUMN lotarea_mean_norm FLOAT,
ADD COLUMN garagearea_mean_norm FLOAT,
ADD COLUMN grlivarea_mean_norm FLOAT,
ADD COLUMN totalbsmtsf_mean_norm FLOAT,
ADD COLUMN saleprice_mean_norm FLOAT
;

-- MEAN NORMALIZATION: 
-- X' = (X - mean(X)) / (max(X) - min(X))
-- used temp table, then updated mean normalized data to property_sales table
WITH tmp_tbl AS (
	SELECT
		id,
		(lotfrontage - AVG(lotfrontage) OVER() ) / 
			(MAX(lotfrontage) OVER() - MIN(lotfrontage)OVER() )
				AS lotfrontage_mean_norm,
	
		(lotarea - AVG(lotarea) OVER() ) / 
			(MAX(lotarea) OVER() - MIN(lotarea)OVER() )
				AS lotarea_mean_norm,
	
		(garagearea - AVG(garagearea) OVER() ) / 
			(MAX(garagearea) OVER() - MIN(garagearea)OVER() )
				AS garagearea_mean_norm,
	
		(grlivarea - AVG(grlivarea) OVER() ) /
			(MAX(grlivarea) OVER() - MIN(grlivarea)OVER() )
				AS grlivarea_mean_norm,
	
		(totalbsmtsf - AVG(totalbsmtsf) OVER() ) / 
			(MAX(totalbsmtsf) OVER() - MIN(totalbsmtsf)OVER() )
				AS totalbsmtsf_mean_norm,
	
		(saleprice - AVG(saleprice) OVER() ) /
			(MAX(saleprice) OVER() - MIN(saleprice)OVER() )
				AS saleprice_mean_norm
	FROM 
		property_sales
)
UPDATE
	property_sales
SET
	lotfrontage_mean_norm = tmp_tbl.lotfrontage_mean_norm,
	lotarea_mean_norm = tmp_tbl.lotarea_mean_norm,
	garagearea_mean_norm = tmp_tbl.garagearea_mean_norm,
	grlivarea_mean_norm = tmp_tbl.grlivarea_mean_norm,
	totalbsmtsf_mean_norm = tmp_tbl.totalbsmtsf_mean_norm,
	saleprice_mean_norm = tmp_tbl.saleprice_mean_norm
FROM
	tmp_tbl
WHERE
	property_sales.id = tmp_tbl.id
;

-- check dataset
SELECT * FROM property_sales 

-- TASK # 5 : Perform Standardization on all the numerical variables to rescale these variables
-- DID NOT CHOOSE TO IMPUTE DATA IN lotfrontage COL WITH MEAN DUE TO MULTIPLE FEATURES THAT MAY SKEW THE DATA
-- add columns to contain standardized values
ALTER TABLE property_sales
ADD COLUMN lotfrontage_standard FLOAT,
ADD COLUMN lotarea_standard FLOAT,
ADD COLUMN garagearea_standard FLOAT,
ADD COLUMN grlivarea_standard FLOAT,
ADD COLUMN totalbsmtsf_standard FLOAT,
ADD COLUMN saleprice_standard FLOAT
;

-- STANDARDIZATION: 
-- X' = (X - mean(X)) / standard deviation STDDEV_POP()
-- used temp table, then updated mean normalized data to property_sales table
WITH tmp_tbl AS (
	SELECT
		id,
		(lotfrontage - AVG(lotfrontage) OVER() ) / 
			(STDDEV_POP(lotfrontage) OVER() )
				AS lotfrontage_standard,
		
		(lotarea - AVG(lotarea) OVER() ) / 
			(STDDEV_POP(lotarea) OVER() )
				AS lotarea_standard,
	
		(garagearea - AVG(garagearea) OVER() ) / 
			(STDDEV_POP(garagearea) OVER() )
				AS garagearea_standard,
	
		(grlivarea - AVG(grlivarea) OVER() ) / 
			(STDDEV_POP(grlivarea) OVER() )
				AS grlivarea_standard,
	
		(totalbsmtsf - AVG(totalbsmtsf) OVER() ) / 
			(STDDEV_POP(totalbsmtsf) OVER() )
				AS totalbsmtsf_standard,	
		
		(saleprice - AVG(saleprice) OVER() ) / 
			(STDDEV_POP(saleprice) OVER() )
				AS saleprice_standard	
	FROM 
		property_sales
)
UPDATE
	property_sales
SET
	lotfrontage_standard = tmp_tbl.lotfrontage_standard,
	lotarea_standard = tmp_tbl.lotarea_standard,
	garagearea_standard = tmp_tbl.garagearea_standard,
	grlivarea_standard = tmp_tbl.grlivarea_standard,
	totalbsmtsf_standard = tmp_tbl.totalbsmtsf_standard,
	saleprice_standard = tmp_tbl.saleprice_standard
FROM
	tmp_tbl
WHERE
	property_sales.id = tmp_tbl.id
;

-- check dataset
SELECT * FROM property_sales 

