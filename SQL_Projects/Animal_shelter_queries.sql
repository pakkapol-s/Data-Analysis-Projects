Advanced SQL: Logical Query Processing, Part 1

Chapter 2 
Clip 2 

-- CROSS JOIN
-- Produces a Cartesian product, meaning every row from one table is paired with every row from the other table.
SELECT	* 
FROM	Staff 
		CROSS JOIN 
		Staff_Roles; 

-- INNER JOIN
-- starts with a Cartesian product but then applies a qualification predicate (using the ON keyword) to filter the rows
SELECT	* 
FROM	Staff 
		INNER JOIN 
		Staff_Roles
		ON 1 = 1;

-- Find animals that have not been adopted yet
SELECT	*
FROM	Animals AS A
		CROSS JOIN 
		Adoptions AS AD;

SELECT	AD.Adopter_Email, AD.Adoption_Date, A.*
FROM	Animals AS A
		LEFT OUTER JOIN 
		Adoptions AS AD
		ON	AD.Name = A.Name 
			AND 
			AD.Species = A.Species;

Clip 3





-- 1. Write a query to report animal and their vaccination. Include animals that have not been vaccinated. 
-- The report should show animal's name, species, breed, and primary color, vaccination time and the vaccine name, 
-- the staff's member first names, last names, and role. 
-- Use The minimal number of tables required. 
-- Use the correct logical join types and force join order as needed.


SELECT	A.Name,
		A.Species,
		A.Breed,
		A.Primary_Color,
		V.Vaccination_Time,
		V.Vaccine,
		P.First_Name,
		P.Last_Name,
		SA.Role
FROM	Animals AS A
		LEFT OUTER JOIN
		(	Vaccinations AS V
			INNER JOIN
			Staff_Assignments AS SA
				ON SA.Email = V.Email
			INNER JOIN
			Persons AS P
				ON P.Email = V.Email
		)
		ON	A.Name = V.Name
			AND
			A.Species = V.Species
ORDER BY A.Species, A.Name, A.Breed, V.Vaccination_Time DESC;

-- Chatper 4 Grouping

/*
Animal vaccination report
--------------------------

Write a query to report the number of vaccinations each animal has received.
Include animals that were never vaccinated.
Exclude all rabbits.
Exclude all Rabies vaccinations.
Exclude all animals that were last vaccinated on or after October first, 2019.

The report should return the following attributes:
Animals Name, Species, Primary Color, Breed,
and the number of vaccinations this animal has received,

-- Guidelines
Use the correct logical join types and force order if needed.
Use the  correct logical group by expressions.
*/

SELECT	AN.Name,
		AN.Species,
		MAX(AN.Primary_Color) AS Primary_Color, -- Dummy aggregate, functionally dependent.
		MAX(AN.Breed) AS Breed, -- Dummy aggregate, functionally dependent.
		COUNT(V.Vaccine) AS Number_Of_Vaccines
FROM	Animals AS AN
		LEFT OUTER JOIN 
		Vaccinations AS V
			ON	V.Name = AN.Name 
				AND 
				V.Species = AN.Species
WHERE	AN.Species <> 'Rabbit'
		AND
		(V.Vaccine <> 'Rabies' OR V.Vaccine IS NULL)
GROUP BY	AN.Species,
			AN.Name
HAVING	MAX(V.Vaccination_Time) < '20191001' 
		OR
		MAX(V.Vaccination_Time) IS NULL
ORDER BY	AN.Species,
			AN.Name;

-- Return an animal's species, name, checkup times, heart rate, and a Boolean column that is TRUE only 
-- for animals which all of their heart rate measurements were either equal to, 
-- or larger that the average heart rate for their species.

-- METHOD 1 -- Using a join

WITH avg_hr AS (
-- This calculates the AVG heart rate by species
		SELECT
			species,
			ROUND(AVG(heart_rate),2) AS Rounded_AVG_hr_species, -- to get rouned results
			CAST( AVG(heart_rate) AS DECIMAL (5,2) ) AS Cast_AVG_hr_species -- We can also use CAST
		FROM
			routine_checkups rc
		GROUP BY
			species 
			)
-- SELECT * FROM avg_hr ; -- Test
SELECT
	rc.species,
	rc."name",
	rc.checkup_time,
	rc.heart_rate,
	ahr.Cast_AVG_hr_species, -- just for comparison purposes
	ahr.Rounded_AVG_hr_species,
	CASE
		WHEN rc.heart_rate >= ahr.Rounded_AVG_hr_species THEN TRUE
		ELSE FALSE
	END AS higher_than_average 
FROM
	routine_checkups rc
INNER JOIN avg_hr ahr
	-- The join brings the table with the avg hr per species
 ON
	rc.species = ahr.species
WHERE 
	CASE
		WHEN rc.heart_rate >= ahr.Rounded_AVG_hr_species THEN TRUE
		ELSE FALSE
	END = TRUE
ORDER BY
	rc.species ASC,
	rc.checkup_time ASC
;

-- METHOD 2 -- Using Window funtion. 
-- Window function and filtering only animals whose heart rate is higher than the average for it's species

WITH all_values AS (
		SELECT
			rc.species,
			rc."name",
			rc.checkup_time,
			rc.heart_rate,
			CAST( AVG(rc.heart_rate) OVER (PARTITION BY species) AS DECIMAL (5,2) ) AS AVG_hr_species,
			CASE
				WHEN rc.heart_rate >= CAST( AVG(rc.heart_rate) OVER (PARTITION BY species) AS DECIMAL (5,2) ) THEN TRUE
				ELSE FALSE
			END AS higher_than_average
		FROM
			routine_checkups rc
		ORDER BY
			rc.species ASC,
			rc.checkup_time ASC
		)
--SELECT * FROM all_values ; -- Test
SELECT
	*
FROM all_values 
WHERE 
	higher_than_average = TRUE
ORDER BY
	species ASC,
	checkup_time ASC
;

-- Chapter 5 

video 4
-- Weight analysis of animals 

SELECT	species, 
		name, 
		CAST (AVG (weight) AS DECIMAL (5, 2)) AS average_weight
FROM 	routine_checkups
GROUP BY 	species, 
			name
ORDER BY 	species DESC, 
			average_weight DESC;

WITH average_weights
AS
(
SELECT	species, 
		name, 
		CAST (AVG (weight) AS DECIMAL (5, 2)) AS average_weight
FROM 	routine_checkups
GROUP BY 	species, 
			name
)
SELECT 	*,
		PERCENT_RANK () 
		OVER (PARTITION BY species 
			  ORDER BY average_weight
			 ) AS percent_rank,
		CUME_DIST () 
		OVER (PARTITION BY species 
			  ORDER BY average_weight
			 ) AS cumulative_distribtuion
FROM 	average_weights
ORDER BY 	species DESC, 
			average_weight DESC;


-- Challenge - Animals Temperature Exceptions
-- Write a query that returns the top 25% of animals per species that had the fewest "temperature exceptions". 
-- Ignore animals that had no routine checkups. 
-- A "temperature exception" is a checkup temperature measurement that is either equal to or exceeds +/- 0.5% from the species' average.
-- If two or more animals of the same species have the same number of temperature exceptions, those with the more recent exceptions should be returned.
-- There is no need to return additional tied animals over the 25% mark.
-- If the number of animals for a species does not divide by 4 without remainder, you may return 1 more animal, but not less.
-- See |Chapter5\Challenge.sql for full requirements and expected results.

WITH checkups_with_temperature_differences
AS
(
SELECT 	species,
		name,
		temperature,
		checkup_time,
		CAST ( 	AVG (temperature) 
				OVER (PARTITION BY species) 
			 	AS DECIMAL (5,2)
			 ) AS species_average_temperature,
		CAST (	temperature - 	AVG (temperature) 
								OVER (PARTITION BY species)
			 	AS DECIMAL (5, 2) 
			 ) AS difference_from_average
FROM 	routine_checkups
)
-- SELECT * FROM checkups_with_temperature_differences ORDER BY species, difference_from_average;
,temperature_differences_with_exception_indicator
AS
(
SELECT	*,
		CASE 
		WHEN ABS (difference_from_average / species_average_temperature) >= 0.005
			THEN 1
		ELSE 0
		END AS is_temperature_exception
FROM 	checkups_with_temperature_differences
)
-- SELECT * FROM temperature_differences_with_exception_indicator ORDER BY species, difference_from_average;
,grouped_animals_with_exceptions
AS 
(
SELECT	species,
		name,
		SUM (is_temperature_exception) AS number_of_exceptions,
		MAX (	CASE 
				WHEN is_temperature_exception = 1 
					THEN checkup_time
				ELSE NULL
				END
			) AS latest_exception
FROM 	temperature_differences_with_exception_indicator
GROUP BY 	species,
			name
)
-- SELECT * FROM grouped_animals_with_exceptions ORDER BY species, number_of_exceptions;
,animal_exceptions_with_ntile
AS
(
SELECT 	*,
		NTILE (4)
		OVER (	PARTITION BY species 
				ORDER BY number_of_exceptions ASC, -- try DESC,
						 latest_exception DESC -- try ASC
			 ) AS ntile
FROM 	grouped_animals_with_exceptions
)
-- SELECT * FROM animal_exceptions_with_ntile ORDER BY species, number_of_exceptions, latest_exception DESC;
SELECT 	species,
		name,
		number_of_exceptions,
		latest_exception
FROM 	animal_exceptions_with_ntile
WHERE 	ntile = 1 -- try 4
ORDER BY 	species ASC,
			number_of_exceptions DESC,
			latest_exception DESC;


-----------------		
-- Alternative --
-----------------
-- Using a grouped derived table instead of an aggregate window function
WITH checkups_with_temperature_differences
AS
(
SELECT 	rc.species,
		name,
		temperature,
		checkup_time,
		species_average_temperature,
		(temperature - species_average_temperature) AS difference_from_average
FROM 	routine_checkups AS rc
		INNER JOIN
		(	SELECT	species,
					CAST ( AVG (temperature) AS DECIMAL (5, 2)) AS species_average_temperature
			FROM 	routine_checkups
			GROUP BY species
		) AS at -- Average Temperatures
			ON rc.species = at.species
)	
-- SELECT * FROM checkups_with_temperature_differences ORDER BY species, difference_from_average;
-- Using CROSS JOIN LATERAL instead of a SELECT expression.
-- Very useful in many cases, remember this one.
,temperature_differences_with_exception_indicator
AS
(
SELECT	*
FROM 	checkups_with_temperature_differences AS cw
		CROSS JOIN LATERAL
		(	VALUES (	CASE 
						WHEN ABS (cw.difference_from_average / cw.species_average_temperature) >= 0.005
							THEN TRUE
						ELSE NULL
						END
					)
		) AS exceptions (is_temperature_exception)
)
-- SELECT * FROM temperature_differences_with_exception_indicator ORDER BY species, difference_from_average;
,grouped_animals_with_exceptions
AS 
(
SELECT	species,
		name,
		COUNT (is_temperature_exception) AS number_of_exceptions,
		-- Count of Booleans - remember this trick too.
		MAX (	CASE 
				WHEN is_temperature_exception
					THEN checkup_time
				ELSE NULL
				END
			) AS latest_exception
FROM 	temperature_differences_with_exception_indicator
GROUP BY 	species,
			name
)
-- SELECT * FROM grouped_animals_with_exceptions ORDER BY species, number_of_exceptions;
,animal_exceptions_with_ranking
AS
(
SELECT 	*,
		PERCENT_RANK()
		OVER (	PARTITION BY species 
				ORDER BY number_of_exceptions ASC,
						 latest_exception DESC
			 ) AS rank
FROM 	grouped_animals_with_exceptions
)
-- SELECT * FROM animal_exceptions_with_ntile ORDER BY species, number_of_exceptions, latest_exception DESC;
SELECT 	species,
		name,
		number_of_exceptions,
		latest_exception
FROM 	animal_exceptions_with_ranking
WHERE 	rank <= 0.25
		-- Do you think this solution complies with the challenge requirements?
		-- If not, can you think of a situation where it will fail?
ORDER BY 	species ASC,
			number_of_exceptions DESC,
			latest_exception DESC;


Chapter 6

-- Challenge
-- Write a query that returns the top 5 most improved quarters in terms of the number of adoptions, both per species, and overall.
-- Improvement means the increase in number of adoptions compared to the previous calendar quarter.
-- The first quarter in which animals were adopted for each species and for all species, does not constitute an improvement from zero, and should be treated as no improvement.
-- In case there are quarters that are tied in terms of adoption improvement, return the most recent ones.

