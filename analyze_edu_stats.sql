
/*			

			EDUCATION STATISTICS 
		  (World Data Bank dataset) 

*/

/* 
-1- 
Examine all columns informations of all tables:
	- COLUMN_NAMES
	- DATA_TYPE
	- NULLABLE
	- ...
This will be done with the `EXEC sp_columns` command recursivly
on all `information_schema.tables` using basic cursor.
*/

-- Define DB to use
USE Education

-- Declare variables
DECLARE @table_name varchar(255);

-- Set cursor that will take table names as values
DECLARE table_cursor CURSOR FOR
    SELECT table_name 
	FROM information_schema.tables;

OPEN table_cursor;

FETCH NEXT FROM table_cursor INTO @table_name;

--Loop through table name 
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC sp_columns @table_name;

    FETCH NEXT FROM table_cursor INTO @table_name;
END;

-- Close cursor
CLOSE table_cursor;
DEALLOCATE table_cursor;


/* 
-2- 
Analyze the % of NULL value for each table (rounded results).
Let's take an example of the 'series' table.
*/


-- Declare variables
DECLARE @table_name varchar(255);
DECLARE @column_name varchar(255);
DECLARE @sql varchar(max);

-- Set table name
SET @table_name = 'series'; -- **PUT THE REQUIRED TABLE NAME**

-- Set sql command
SET @sql = '';

-- Set cursor that will take table columns as values
DECLARE column_cursor CURSOR FOR
    SELECT column_name FROM information_schema.columns WHERE table_name = @table_name;
OPEN column_cursor;
FETCH NEXT FROM column_cursor INTO @column_name;

-- Loop over column names
WHILE @@FETCH_STATUS = 0
BEGIN
	-- Perform % computation
    SET @sql = @sql + 'SELECT ''' + @column_name + ''' AS Col, '
        + 'ROUND(100 * SUM(CASE WHEN ' + @column_name + ' IS NULL THEN 1 ELSE 0 END) / COUNT(*), 0) AS ''%NULL'' '
        + 'FROM ' + @table_name + ' UNION ';
    FETCH NEXT FROM column_cursor INTO @column_name;
END;

-- remove the last "UNION"
SET @sql = LEFT(@sql, LEN(@sql) - 6); 

EXEC (@sql);

-- Close cursor
CLOSE column_cursor;
DEALLOCATE column_cursor;


/* We identify that for some reason the very import column named `region`
(table named `country`) contains some NULL values. However, an other column
in the same table seems to have the correct value of this field.
Let's try to fill these NULL values by the other column.
*/

UPDATE country
SET region = COALESCE(short_name, region)
WHERE region IS NULL;

/* 
-3- 
To better understand the shape of our tables, let's create a
new table that summary the number of rows (nrow) and columns
(ncol) of each sql raw table in data base.
Once more, we will using the cursor method to iterate over 
database tables.
*/

-- DROP TABLE table_shape
CREATE TABLE table_shape (
    table_name varchar(255),
    nrow INT,
    ncol INT
);

DECLARE @table_name varchar(255);
DECLARE @sql varchar(max);

DECLARE table_cursor CURSOR FOR
    SELECT table_name 
	FROM information_schema.tables 
	WHERE table_type = 'BASE TABLE' AND table_name NOT IN ('table_shape');
OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @table_name;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = 'INSERT INTO table_shape (table_name, nrow, ncol) SELECT ''' + @table_name
	+ ''', (SELECT COUNT(*) FROM ' + @table_name + '), (SELECT COUNT(COL_LENGTH(''' + @table_name + ''', COLUMN_NAME)) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''' + @table_name + ''')';
    EXEC (@sql);
    FETCH NEXT FROM table_cursor INTO @table_name;
END;
CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Print new created table
SELECT * from table_shape


/* 
-4- 
What columns are important for our start-up?
Let's assume that the usefull columns correspond to:

	- country_code				(to use as country primary key)
	- country_name       		(to identify countries)
	- indicator_code			(to compute and evaluate statistics and indicator primary key)
	- indicator_name			(to have better knowledge about statistics)
	- topic						(to group indicators by sectors)
	- region			        (to identify geographic block)
	- country currency          (to fix online course price)
	- income_group				(to adapt course prices to country's standard of living)
	- 2000, .., 2017			(indicator historical values -> from 2000 to 2017)
	- 2017, ..., 2035           (indicator predictive values -> from 2017 to 2035) [we assume that 2035 is far enough]
	
Now, let's try to build a new table with all usefull elements
*/
DROP TABLE main
-- Build main data table
SELECT  DISTINCT
		data.country_code,
		data.country_name,
		data.indicator_code,
		data.indicator_name,
		series.topic,
		series.long_definition  as indicator_definition,
		country.region,
        country.currency_unit as country_currency,
		country.income_group as country_income_group,
		data.year_2000,
		data.year_2001,
		data.year_2002,
		data.year_2003,
		data.year_2004,
		data.year_2005,
		data.year_2006,
		data.year_2007,
		data.year_2008,
		data.year_2009,
		data.year_2010,
		data.year_2011,
		data.year_2012,
		data.year_2013,
		data.year_2014,
		data.year_2015,
		data.year_2016,
		data.year_2017,
		data.year_2020,
		data.year_2025,
		data.year_2030,
		data.year_2035
-- New table
INTO main
FROM data
-- Join series informations
LEFT JOIN series
ON data.indicator_code = series.series_code
-- join country informations
LEFT JOIN country
ON data.country_code = country.country_code

/*
-5- 
Let's count the total number of indicators availables in the `main` dataset.
*/
SELECT COUNT(DISTINCT indicator_code) AS total_indicators
FROM main

/*  
As calculated above, the dataset gives 3665 distinct indicators so now,
the goal is to filter the `main` dataset only by meaningful indicators.
Let's assume that we will focus on 4 categories of indicators:

- DEMOGRAPHIC : we are targeting only high school and higher students between 15 and 24 years old
- ECONOMIC : we are looking for some basic economic metrics like per capita income, standard of living, ...
- EDUCATIVE : we are looking the state of education such as school enrolment rate, academic achievement, ...
- NUMERIC : we are obviously targeting people with internet access, personal computer since it's the core of our offer

So let's try to identify 1 or 2 meaningful indicators for each categories.
*/


/*
-6- 
DEMOGRAPHIC INDICATOR SELECTION

According to the World Bank Education documentation we know that the 
indicators of population contains the `POP` key world. 
Next the age group 15-24 years old contains the key word `1524`.

Let's filter our `main` table to see all the interested indicators
*/

SELECT * 
FROM main
WHERE indicator_code LIKE '%POP%' AND indicator_code LIKE '%1524%'

/* 
We notice that 3 important key words in the indicator for population :
	- 'FE' : female
	- 'MA' : male
	- 'TO' : total

We obviously don't want to differentiate people by gender in this study.
Let's filter again adding the 'TO' key world.
*/

SELECT DISTINCT indicator_code, indicator_name, indicator_definition 
FROM main
WHERE indicator_code LIKE '%POP%' 
  AND indicator_code LIKE '%1524%'
  AND indicator_code LIKE '%TO%'

/* 
So, the chosen DEMOGRAPHIC indicator is 'SP.POP.1524.TO.UN'
*/ 


/*
-7- 
ECONOMIC INDICATOR SELECTION

According to the World Bank Education documentation we know that the
national accounts indicators starts with the `NY` key world.
Note that we are preferentially focus on GNI/GNP (Gros National Income)
rather than GNP (Gross Domestic Product). Finally, we want the currency
to be based on current international dollar  (key world `CD`) 
rather than a fix dollar value

Let's filter our `main` table to see all the interested indicators
*/

SELECT DISTINCT indicator_code, indicator_name, indicator_definition 
FROM main
WHERE indicator_code LIKE 'NY%'
  AND indicator_code LIKE '%GNP%'
  AND indicator_code LIKE '%CD%'

/* 
So, the chosen ECONOMIC indicator is 'NY.GNP.PCAP.CD'
*/ 

/*
-8- 
EDUCATIVE INDICATOR SELECTION

According to the World Bank Education documentation we know that the
social education indicators starts with the `SE` key world.
Moreover, the document notices that in social education, student are
grouping by grade categories. Nvertheless, we only want the high school
student (secondary, key word `SEC`) and higher (tertiary, key word `TER`).

Let's filter our `main` table to see all the interested indicators
*/
SELECT DISTINCT indicator_code, indicator_name, indicator_definition 
FROM main
WHERE indicator_code LIKE 'SE%' 
  AND (indicator_code LIKE '%SEC%' OR indicator_code LIKE '%TER%')
  AND indicator_code NOT LIKE '%.FE%' -- remove female only
  AND indicator_code NOT LIKE '%.MA%' -- remove male only

/* 
So, the chosen EDUCATIVE indicator are 'SE.TER.ENRR' and 'SE.SEC.ENRR'
(Gross enrollment rate in higher education, for both sexes (%))
*/ 


/*
-9- 
NUMERIC INDICATOR SELECTION

According to the World Bank Education documentation we know that the
social education indicators starts with the `IT`.

Let's filter our `main` table to see all the interested indicators
*/

SELECT DISTINCT indicator_code, indicator_name, indicator_definition 
FROM main
WHERE indicator_code LIKE 'IT%'

/*
We can notice that they are 2 interesting indicators:
	- 'IT.CMP.PCMP.P2':  % people that own a personal computer
	- 'IT.NET.USER.P2': % people that correspond to regular internet users

We assume that our startup can be used with all internet connected 
devices, so the best NUMERIC indicator here is 'IT.NET.USER.P2'
*/



/*
-10-
 
Unfortunatly, the CREATE VIEW statement does not work 
properly in MS SQL Server, but we can alternativly
create a function to subset the `main` table to by 
required indicators (2).
*/

CREATE FUNCTION get_filtered (@indicators nvarchar(max) = NULL)
RETURNS TABLE
AS
RETURN (
  SELECT *
  FROM main
  WHERE indicator_code IN (SELECT value FROM STRING_SPLIT(ISNULL(@indicators, 'SP.POP.1524.TO.UN,SE.SEC.ENRR,SE.TER.ENRR,IT.NET.USER.P2,NY.GNP.PCAP.PP.CD'), ','))
);

-- Test function on all select indicators
SELECT * FROM get_filtered(NULL) -- all selected indicators
SELECT * FROM get_filtered('SE.SEC.ENRR') -- one specific indicator



/*
-11-

Now let's try to identify the countries with a high potential 
of customers for our services. We will focus on 2015 results
since it is the nearest year (today: 2023) with usable data

To do so, we will work on the RANK method on the maximum
value of each indicator in each country. Next, we will assume
that the the the best country for us to implement our activity
correspond to the lowest average ranks of selected indicators
(lowest score).
	  
*/

-- 1) Perform ranking process (store in temporary table)
SELECT 
	country_name,
	indicator_code,
	MAX(year_2015) AS max_value,
	RANK() OVER (PARTITION BY indicator_code ORDER BY MAX(year_2015) DESC) AS rank_number
INTO ##ranked_by_country
FROM get_filtered(NULL)
GROUP BY country_name, indicator_code;

-- 2) Compute score as average(rank_indicator_1, rank_indicator_2, ...)
SELECT country_name, AVG(rank_number) AS score
FROM ##ranked_by_country
GROUP BY country_name
ORDER BY score;


/*
-12-

Let's perform the same process but working on larger geographical
area (`region`).
	  
*/

-- 1) Perform ranking process (store in temporary table)
SELECT 
	region,
	indicator_code,
	MAX(year_2015) AS max_value,
	RANK() OVER (PARTITION BY indicator_code ORDER BY MAX(year_2015) DESC) AS rank_number
INTO ##ranked_by_region
FROM get_filtered(NULL)
GROUP BY region, indicator_code;

-- 2) Compute score as average(rank_indicator_1, rank_indicator_2, ...)
SELECT region, AVG(rank_number) AS score
FROM ##ranked_by_region
GROUP BY region
ORDER BY score;

/* 
	--- CONCLUSION ---

Most targeted countries: 
	- Germany
	- Korea Republic
	- Spain

Most targeted geographic blocs:
	- East Asia & Pacific
	- Europe & Central Asia

*/
