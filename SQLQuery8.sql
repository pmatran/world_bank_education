-- Define DB to use
USE Education

/*
-8- 
EDUCATIVE INDICATOR SELECTION

According to the World Bank Education documentation we know that the
social education indicators starts with the `SE` key world.
Moreover, the document notices that in social education, student are
grouping by grade categories. Nevertheless, we only want the high school
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