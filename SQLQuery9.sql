-- Define DB to use
USE Education

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