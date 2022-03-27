DROP TABLE IF EXISTS titanic ;

CREATE TABLE IF NOT EXISTS titanic(
	PassengerId INT,
	Survived INT,
	Pclass INT,
	Name VARCHAR(100),
	Sex VARCHAR(6),
	Age DECIMAL,
	SibSp INT,
	Parch INT,
	Ticket VARCHAR(50),
	Fare DECIMAL,
	Cabin VARCHAR(50),
	Embarked VARCHAR(5)
);

COPY titanic(
	PassengerId,
	Survived,
	Pclass,
	Name,
	Sex,
	Age,
	SibSp,
	Parch,
	Ticket,
	Fare,
	Cabin,
	Embarked
	)
FROM 'C:\Users\carolirs\titanic.csv'
DELIMITER ','
CSV HEADER 
;

SELECT * FROM titanic ;

/* 
Task #1: Handle the missing data under columns “Age” and “Cabin” by replacing the appropriate
values
*/

-- count null values
SELECT age, COUNT(*) AS null_age_count
FROM titanic
WHERE age IS NULL
GROUP BY age
; -- result 177 null values

-- get average age
SELECT ROUND(AVG(age),0) AS avg_age FROM titanic ; -- result: 30

-- update null values in age column with average age
UPDATE titanic
SET age = COALESCE(age, 30)
WHERE age IS NULL
; -- result:  UPDATE 177

SELECT * FROM titanic ;

-- count cabin null values
SELECT cabin, COUNT(*) AS null_cabin_count
FROM titanic
WHERE cabin IS NULL
GROUP BY cabin
; -- result 687 null values

-- update null values in cabin column with 'unknown'
UPDATE titanic
SET cabin = COALESCE(cabin, 'unknown')
WHERE cabin IS NULL
; -- result:  UPDATE 687

SELECT * FROM titanic ;

/* 
Task #2: Standardize the values found under column “Sex”
*/

-- count and group sex record values
SELECT sex, COUNT(*) as sex_count
FROM titanic 
GROUP BY sex
ORDER BY sex_count DESC
; -- result: male 557, female 298, M 20, F 16

-- test standardization before updating table
SELECT 
	*, 
	CASE
		WHEN sex = 'M' THEN 'male'
		WHEN sex = 'F' THEN 'female'
		ELSE sex
	END as sex2
FROM titanic
;
-- standardize sex column
UPDATE titanic
SET 
	sex = CASE
		      WHEN sex = 'M' THEN 'male'
			  WHEN sex = 'F' THEN 'female'
			  ELSE sex
	      END
WHERE sex = 'M' OR sex = 'F'
; --result: UPDATE 36

-- check updated values
SELECT sex, COUNT(*) as sex_count
FROM titanic 
GROUP BY sex
ORDER BY sex_count DESC
;

/* 
Task #3: Create a column “Last_Name” and populate with values derived from “Name” column
*/

SELECT name, COUNT(*) AS name_count
FROM titanic 
GROUP BY name 
ORDER BY name_count DESC
;

-- view last_name
SELECT
	name,
	split_part(name, ',', 1) AS "Last_Name"
FROM titanic
;

-- add Last_Name col 
ALTER TABLE titanic
ADD "Last_Name" VARCHAR(100)
DEFAULT 'None'
; -- result ALTER TABLE

-- set values
UPDATE titanic
SET "Last_Name" = split_part(name, ',', 1)
; -- result: UPDATE 891

-- check 
SELECT
	COUNT(name) as name_count,
	COUNT("Last_Name") as last_name_count
FROM titanic
;

/* 
Task #4: Create a column “Title” and populate with values derived from “Name” column
*/

SELECT name, COUNT(*) AS name_count
FROM titanic 
GROUP BY name 
ORDER BY name_count DESC
;

-- view extracted title using regex
SELECT 
	name,
	(regexp_match(name, '\, ([a-zA-Z]+)\.'))[1] AS Title,
	COUNT(*) AS title_count
FROM titanic
GROUP BY name
;

-- view title groups
SELECT 
	(regexp_match(name, '\, ([a-zA-Z]+)\.'))[1] AS Title,
	COUNT(*) AS title_count
FROM titanic
GROUP BY Title
ORDER BY title_count DESC
;

-- add Title col 
ALTER TABLE titanic
ADD "Title" VARCHAR(20)
DEFAULT 'None'
; -- result ALTER TABLE

-- set Title values
UPDATE titanic
SET "Title" = (regexp_match(name, '\, ([a-zA-Z]+)\.'))[1]
; -- result: UPDATE 891

SELECT * FROM titanic ;

/* 
Task #5: Create a column “First_Name” and populate with values derived from “Name” column
(do not remove values in parenthesis)
*/

-- view first name
SELECT 
	name, 
	split_part(name, '. ' , 2) AS "First_Name",
	COUNT(*) AS name_count
FROM titanic 
GROUP BY name 
ORDER BY name_count DESC
;

-- add First_Name col 
ALTER TABLE titanic
ADD "First_Name" VARCHAR(100)
DEFAULT 'None'
; -- result ALTER TABLE

-- set title values
UPDATE titanic
SET "First_Name" = split_part(name, '. ' , 2)
; -- result: UPDATE 891

SELECT * FROM titanic ;

-- export to csv file Titanic_cleaned.csv
COPY (SELECT * FROM titanic ) 
TO 'C:\Users\carolirs\Titanic_cleaned.csv'
DELIMITER ','
CSV HEADER
;
