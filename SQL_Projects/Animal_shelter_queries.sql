
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

-- Chapter 5 video 4
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
