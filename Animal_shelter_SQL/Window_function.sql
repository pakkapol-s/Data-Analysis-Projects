-- Window FUNCTION

Chapter 2 Window Function and the OVER Clause
Video 2: Overview and filter clause

-- Show the total number of animals in our shelter ever.

SELECT 	species, 
		name, 
		primary_color, 
		admission_date,
		(	SELECT 	COUNT (*) 
			FROM 	animals
			WHERE 	admission_date >= '2017-01-01'
		) AS number_of_animals
FROM 	animals
WHERE 	admission_date >= '2017-01-01'
ORDER BY admission_date ASC;

-- using over() saves more memory
SELECT 	species,
		name, 
		primary_color, 
		admission_date,
		COUNT (*) OVER () AS number_of_animals
FROM 	animals	
WHERE 	admission_date >= '2017-01-01'
ORDER BY admission_date ASC;

Chapter 2 Window Function and the OVER Clause
Video 3: PARTITION BY and ORDER BY

-- Show the number of animal species instead of total 

SELECT 	species,
		name,
		primary_color,
		admission_date,
		COUNT (*) OVER (PARTITION BY species) AS number_of_species_animals
FROM 	animals
ORDER BY 	species ASC, 
			admission_date ASC;

-- Optimized subquery solution
SELECT 	a.species, 
		a.name, 
		a.primary_color, 
		a.admission_date,
		species_counts.number_of_species_animals
FROM 	animals AS a
		JOIN 
		(	SELECT 	species,
					COUNT(*) AS number_of_species_animals
			FROM 	animals
			GROUP BY species
		) AS species_counts
		ON a.species = species_counts.species
ORDER BY 	a.species ASC,
			a.admission_date ASC;


Chapter 3 Framing, Exclusions, and Shortcuts
Video 2 Practical Framing Examples

-- Show the number of same specie animals on the previous date

-- ROWS = “Count 3 seats behind me in the cinema.” (position-based)
-- RANGE = “Count everyone who bought tickets within the last 3 days.” (value-based).

SELECT 	species,
		name, 
		primary_color, 
		admission_date,
		COUNT (*) 
		OVER (	PARTITION BY 	species
				ORDER BY 		admission_date ASC
				RANGE BETWEEN 	UNBOUNDED PRECEDING AND '1 day' PRECEDING
				-- Count all dogs admitted from the very beginning up to the day before this dog’s admission date.”
			 ) AS up_to_previous_day_species_animals
FROM 	animals
WHERE 	species = 'Dog' 
		AND 
		admission_date > '2017-08-01'
ORDER BY 	species ASC, 
			admission_date ASC;

Chapter 4 Aggregate window functions
Video 2: Aggregate Window FUNCTIONS


-- Return an animal's species, name, checkup time, heart rate, and a Boolean column that is TRUE only for animals which all or their heart rate measurements 
-- were either equal to, or larger than the average heart rate for their species.

Step by step solution
-- Average species heart rates

SELECT 	species, 
		name,
		checkup_time, 
		heart_rate,
		CAST (
				AVG (heart_rate) 
				OVER (PARTITION BY species)
			 AS DECIMAL (5, 2)
			 ) AS species_average_heart_rate
FROM	routine_checkups
ORDER BY 	species ASC,
			checkup_time ASC;

-- Split with CTE
WITH species_average_heart_rates
AS
(
SELECT 	species,
		name, 
		checkup_time, 
		heart_rate, 
		CAST (
					AVG (heart_rate) 
					OVER (PARTITION BY species) 
				AS DECIMAL (5, 2)
			 ) AS species_average_heart_rate
FROM	routine_checkups
)
SELECT	species,
		name, 
		checkup_time, 
		heart_rate,
		EVERY (heart_rate >= species_average_heart_rate) 
		OVER (PARTITION BY species, name) AS consistently_at_or_above_average
FROM 	species_average_heart_rates
ORDER BY 	species ASC,
			checkup_time ASC;

-- Separate into CTEs
WITH species_average_heart_rates AS (
	SELECT 	species, 
			name, 
			checkup_time, 
			heart_rate, 
			CAST (	AVG (heart_rate) 
					OVER (PARTITION BY species) 
				AS DECIMAL (5, 2)
				) AS species_average_heart_rate
	FROM	routine_checkups
),
with_consistently_at_or_above_average_indicator AS (
	SELECT	species, 
			name, 
			checkup_time, 
			heart_rate,
			species_average_heart_rate,
			EVERY (heart_rate >= species_average_heart_rate) 
			OVER (PARTITION BY species, name) AS consistently_at_or_above_average
	FROM 	species_average_heart_rates
)
SELECT 	DISTINCT species,
		name,
		heart_rate,
		species_average_heart_rate
FROM 	with_consistently_at_or_above_average_indicator
WHERE 	consistently_at_or_above_average
ORDER BY 	species ASC,
			heart_rate DESC;

-- Explanation:
-- 1. EVERY (heart_rate >= species_average_heart_rate)
-- For each animal (species, name):
-- Look at all of its checkups.
-- If in every checkup, its heart_rate was ≥ the species’ average → TRUE.
-- If even one checkup was below average → FALSE.

Chapter 4 Aggregate window functions
Video 3 Combining grouped and window aggregate functions

-- Show monthly adtoprion fee revenue

-- Summary of adoption in each month in each year
SELECT	DATE_PART ('year', adoption_date) AS year,
		DATE_PART ('month', adoption_date) AS month,
		SUM (adoption_fee) AS month_total
FROM	adoptions
GROUP BY 	DATE_PART ('year', adoption_date), 
			DATE_PART ('month', adoption_date)
ORDER BY 	year ASC,
			month ASC;

-- Calculate annual percentage

SELECT 	DATE_PART ('year', adoption_date) AS year,
		DATE_PART ('month', adoption_date) AS month,
		SUM (adoption_fee) AS month_total,
		CAST	(100 *  SUM (adoption_fee) 
						/	SUM ( SUM (adoption_fee)) 
							OVER (PARTITION BY DATE_PART('year', adoption_date)) 
			AS DECIMAL (5, 2)
			) AS annual_percent
FROM 	adoptions
GROUP BY 	DATE_PART('year', adoption_date), 
			DATE_PART('month', adoption_date)
ORDER BY 	year ASC,
			month ASC;

-- Use CTE to improve readability

WITH monthly_grouped_adoptions
AS
(
SELECT 	DATE_PART ('year', adoption_date) AS year,
		DATE_PART ('month', adoption_date) AS month,
		SUM (adoption_fee) AS month_total
FROM 	adoptions
GROUP BY 	DATE_PART ('year', adoption_date), 
			DATE_PART ('month', adoption_date)
)
SELECT 	*,
		CAST 	(100 * month_total 
				 / 	SUM (month_total) 
					OVER (PARTITION BY year) 
				AS DECIMAL (5, 2)
				) AS annual_percent
FROM 	monthly_grouped_adoptions
ORDER BY 	year ASC,
			month ASC;

Challenge

-- Write a query that returns all years in which animals were vaccinated, and the total number of vaccinations given that year.
-- In addition, the following two columns should be included in the results:
-- 1. The average number of vaccinations given in the previous two years.
-- 2. The percent difference between the current year's number of vaccinations, and the average of the previous two years.
-- For the first year, return a NULL for both additional columns.

-- Hint: Cast averages and division expressions to DECIMAL (5, 2)

-- Step by step solution

SELECT * FROM vaccinations;

-- CTE for total number of annual vaccination
WITH annual_vaccinations
AS
(
SELECT	CAST (DATE_PART ('year', vaccination_time) AS INT) AS year,
		COUNT (*) AS number_of_vaccinations
FROM 	vaccinations
GROUP BY DATE_PART ('year', vaccination_time)
)
SELECT * FROM annual_vaccinations ORDER BY year; -- Uncomment to execute preceding CTE

-- Full version solution
WITH annual_vaccinations AS (
	SELECT	CAST (DATE_PART ('year', vaccination_time) AS INT) AS year,
			COUNT (*) AS number_of_vaccinations
	FROM 	vaccinations
	GROUP BY DATE_PART ('year', vaccination_time)
)
-- SELECT * FROM annual_vaccinations ORDER BY year; -- Uncomment to execute preceding CTE
,annual_vaccinations_with_previous_2_year_average AS (
	SELECT 	*,
			CAST (AVG (number_of_vaccinations) 
				OVER (ORDER BY year ASC
						RANGE BETWEEN 2 PRECEDING AND 1 PRECEDING 
						-- Watch out for frame type...
						) 
				AS DECIMAL (5, 2)
				)
			AS previous_2_years_average
	FROM 	annual_vaccinations
-- WHERE year <> 2018 -- remove comment to check difference between ROWS and RANGE above
)
-- SELECT * FROM annual_vaccinations_with_previous_2_year_average ORDER BY year; -- Uncomment to execute preceding CTE
SELECT 	*,
		CAST ((100 * number_of_vaccinations / previous_2_years_average) 
			 AS DECIMAL (5, 2)
			 ) AS percent_change
FROM 	annual_vaccinations_with_previous_2_year_average
ORDER BY year ASC;


-- Explanations:
-- RANGE BETWEEN 2 PRECEDING AND 1 PRECEDING
-- This defines the frame of rows that the AVG() should look at for each current row.
-- 2 PRECEDING → start the frame 2 "steps" before the current row’s ordering value.
-- 1 PRECEDING → end the frame 1 "step" before the current row’s ordering value.
-- So the frame = the two years immediately before the current year.

Chapter 5 RANK and DISTRIBUTION Window Function
Video 2 ROW_NUMBER and NTILE

-- Show top 3 animals of each specie with the largest number of checkups, including species with less than 3 animals.

-- Include species with no checkups (or no animals for that matter...)
SELECT 	s.species, 
		rc.name, 
		COUNT (rc.checkup_time) AS number_of_checkups 
		-- Can't use * in order to return 0 for species with no checkups
FROM	reference.species AS s 
		LEFT JOIN -- Include species with no checkups...
		routine_checkups AS rc
		ON s.species = rc.species
GROUP BY 	s.species, 
			rc.name
ORDER BY 	s.species, 
			number_of_checkups DESC;


-- Solution
WITH animal_checkups
AS
(
SELECT 	s.species, 
		rc.name, -- For species with no checkups
		COUNT (checkup_time) AS number_of_checkups 
FROM	reference.species AS s 
		LEFT OUTER JOIN
		routine_checkups AS rc
		ON s.species = rc.species
GROUP BY 	s.species, 
			rc.name
)
-- SELECT * FROM animal_checkups ORDER BY species, number_of_checkups DESC;
, add_count_of_more_checked_animalss
AS
(
SELECT 	*,
		(	SELECT 	COUNT (*) 
			FROM	animal_checkups AS ac2
			WHERE	ac2.species = ac1.species
					AND
					ac2.number_of_checkups > ac1.number_of_checkups
		) AS number_of_more_checked_animals
FROM 	animal_checkups AS ac1
)
-- SELECT * FROM add_count_of_more_checked_animalss ORDER BY species, number_of_checkups DESC; 
SELECT 	species,
		name,
		number_of_checkups
FROM 	add_count_of_more_checked_animalss
WHERE 	number_of_more_checked_animals < 3 
ORDER BY 	species, 
			number_of_checkups DESC;

-- Solution with ROW_NUMBER
WITH animal_checkups
AS
(
SELECT 	s.species, 
		rc.name, -- For species with no checkups
		COUNT (checkup_time) AS number_of_checkups
FROM	reference.species AS s 
		LEFT OUTER JOIN 
		routine_checkups AS rc
		ON s.species = rc.species
GROUP BY 	s.species, 
			rc.name
)
, include_row_number_by_number_of_chekcups
AS 
(
SELECT 	*,
		ROW_NUMBER () 
		OVER (	PARTITION BY Species 
				ORDER BY 	number_of_checkups DESC, 
							name
			 ) AS row_number
FROM	animal_checkups
)
-- SELECT * FROM include_row_number_by_number_of_chekcups ORDER BY species, number_of_checkups DESC;
SELECT 	species,
		name,
		number_of_checkups
FROM 	include_row_number_by_number_of_chekcups
WHERE 	row_number <= 3
ORDER BY 	species, 
			number_of_checkups DESC;

-- NTILE
SELECT 	species, 
		name, 
		admission_date,
		NTILE (10) 
		OVER (ORDER BY admission_date) AS ten_segments,
		NTILE (30) 
		OVER (ORDER BY admission_date) AS thirty_segments,
		NTILE (30) 
		OVER (PARTITION BY Species 
			  ORDER BY admission_date) AS thirty_segments_per_species
FROM 	Animals
ORDER BY 	species, 
			admission_date;

--------------------------
-- Alternative solution --
--------------------------
SELECT 	s.species,
		animal_checkups.name,
		COALESCE (animal_checkups.number_of_checkups, 0) AS number_of_checkups
FROM 	reference.species AS s
		LEFT JOIN LATERAL 
		(
			SELECT 	rc.species,
					rc.name,
					COUNT (*) AS number_of_checkups
			FROM 	routine_checkups AS rc
			WHERE 	s.species = rc.species
			GROUP BY 	rc.species, 
						rc.name
			ORDER BY 	rc.species,
						number_of_checkups DESC,
						name
			LIMIT 3 OFFSET 0
		) AS animal_checkups
		ON TRUE;

Chapter 5 RANK and DISTRIBUTION Window Function
Video 3 RANK and DENSE_RANK

-- All animals whoose number of checkups is in the top 3 distinct number of checkups per species

WITH all_ranks AS (
	SELECT 	species, 
			name, 
			COUNT (*) AS number_of_checkups,
			ROW_NUMBER () OVER W AS row_number,
			RANK () OVER W AS rank,
			DENSE_RANK () OVER W AS dense_rank
	FROM	routine_checkups
	GROUP BY species, name WINDOW W AS (PARTITION BY species ORDER BY COUNT(*) DESC)
)
SELECT 	species,
		name,
		number_of_checkups
FROM	all_ranks
WHERE 	dense_rank <= 3
ORDER BY 	species,
			number_of_checkups DESC;

Chapter 5 RANK and DISTRIBUTION Window Function
Video 4: Distribution window functions

-- Weight Analysis 

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

Challenge: 

-- Write a query that returns the top 25% of animals per species that had the fewest “temperature exceptions”.
-- Ignore animals that had no routine checkups.
-- A “temperature exception” is a checkup temperature measurement that is either equal to or exceeds +/- 0.5% from the specie's average.
-- If two or more animals of the same species have the same number of temperature exceptions, those with the more recent exceptions should be returned.
-- There is no need to return additional tied animals over the 25% mark.
-- If the number of animals for a species does not divide by 4 without remainder, you may return 1 more animal, but not less.

-- Solution
-- Check the average of species temperature 

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
SELECT * FROM checkups_with_temperature_differences ORDER BY species, difference_from_average;

-- Full solution
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


Chapter 6 Offset windows functions
Video 2: Row offset window functions

-- Show animal checkups, and how much weight they gained since the last checkups 

SELECT	species, 
		name,
		checkup_time,
		weight,
		weight - LAG (weight) 
				 OVER (PARTITION BY species, name 
				 	   ORDER BY checkup_time ASC
				 	  ) AS weight_gain
FROM 	routine_checkups
ORDER BY 	species ASC, 
			name ASC, 
			checkup_time ASC;

-- solution
SELECT	species, 
		name,
		checkup_time,
		weight,
		weight - LAG (weight) -- because we don't know what the gain is for the first checkup
				 OVER (PARTITION BY species, name 
				 	   ORDER BY checkup_time ASC
				 	  ) AS weight_gain
FROM 	routine_checkups
ORDER BY 	species ASC, 
			name ASC, 
			checkup_time ASC;

Chapter 6 Offset windows functions
Video 2: Frame offset functions

-- Show weight gain over the past 3 months 

WITH
weight_gains
AS
(
SELECT	species, 
		name,
		checkup_time,
		weight,
		(weight - 	FIRST_VALUE (weight) 
						OVER (PARTITION BY species, name 
							  ORDER BY CAST (checkup_time AS DATE) ASC
							  RANGE BETWEEN 	'3 months' PRECEDING 
												AND 
												'1 day' PRECEDING
							 )
		) AS weight_gain_in_3_months
FROM 	routine_checkups
)
SELECT 	*
FROM 	weight_gains
ORDER BY ABS (weight_gain_in_3_months) DESC NULLS LAST;

WITH weight_gains
AS
(
SELECT	species, 
		name,
		checkup_time,
		weight,
		(weight - 	FIRST_VALUE (weight) 
						OVER (PARTITION BY species, name 
							  ORDER BY CAST (checkup_time AS DATE) ASC
							  RANGE BETWEEN 	'3 months' PRECEDING 
												AND 
												'1 day' PRECEDING
							 )
		) AS weight_gain_in_3_months
FROM 	routine_checkups
),
include_percentage
AS
(
SELECT 	*,
		CAST (100 * weight_gain_in_3_months / weight 
			 AS DECIMAL (5, 2)
			 ) AS percent_change
FROM 	weight_gains
)
SELECT 	*
FROM 	include_percentage
WHERE 	percent_change IS NOT NULL
ORDER BY ABS (percent_change) DESC;

Challenge

-- Write a query that returns the top 5 most improved quarters in terms of the number of adoptions, both per species, and overall.
-- Improvement means the increase in number of adoptions compared to the previous calendar quarter.
-- The first quarter in which animals were adopted for each species and for all species, does not constitute an improvement from zero, 
-- and should be treated as no improvement.
-- In case there are quarters that are tied in terms of adoption improvement, return the most recent ones.

-- Hint: Quarters can be identified by their first day.

WITH adoption_quarters
AS
(
SELECT 	Species,
		MAKE_DATE (	CAST (DATE_PART ('year', adoption_date) AS INT),
					CASE 
						WHEN DATE_PART ('month', adoption_date) < 4
							THEN 1
						WHEN DATE_PART ('month', adoption_date) BETWEEN 4 AND 6
							THEN 4
						WHEN DATE_PART ('month', adoption_date) BETWEEN 7 AND 9
							THEN 7
						WHEN DATE_PART ('month', adoption_date) > 9
							THEN 10
					END,
					1
				 ) AS quarter_start
FROM 	adoptions
)
-- SELECT * FROM adoption_quarters ORDER BY species, quarter_start;
,quarterly_adoptions
AS
(
SELECT 	COALESCE (species, 'All species') AS species,
		quarter_start,
		COUNT (*) AS quarterly_adoptions,
		COUNT (*) - COALESCE (
					-- For quarters with no previous adoptions use 0, not NULL 
							 	FIRST_VALUE (COUNT (*))
							 	OVER (PARTITION BY species
							 		  ORDER BY quarter_start ASC
								   	  RANGE BETWEEN 	INTERVAL '3 months' PRECEDING 
														AND 
														INTERVAL '3 months' PRECEDING
						 			 )
							, 0)
		AS adoption_difference_from_previous_quarter,
-- 		COUNT (*) OVER (PARTITION BY quarter_start) AS quarter_total_all_species, -- use with GROUP BY quarter_start, species
		CASE 	
			WHEN	quarter_start =	FIRST_VALUE (quarter_start) 
									OVER (PARTITION BY species
										  ORDER BY quarter_start ASC
										  RANGE BETWEEN 	UNBOUNDED PRECEDING
															AND
															UNBOUNDED FOLLOWING
										 )
			THEN 	0
			ELSE 	NULL
		END 	AS zero_for_first_quarter
FROM 	adoption_quarters
GROUP BY	GROUPING SETS 	((quarter_start, species), 
							 (quarter_start)
							)
)
-- SELECT * FROM quarterly_adoptions ORDER BY species, quarter_start;
,quarterly_adoptions_with_rank
AS
(
SELECT 	*,
		RANK ()
		OVER (	PARTITION BY species
				ORDER BY 	COALESCE (zero_for_first_quarter, adoption_difference_from_previous_quarter) DESC,
							-- First quarters are 0, all others NULL
							quarter_start DESC)
		AS quarter_rank
FROM 	quarterly_adoptions
)
-- SELECT * FROM quarterly_adoptions_with_rank ORDER BY species, quarter_rank, quarter_start;
SELECT 	species,
		CAST (DATE_PART ('year', quarter_start) AS INT) AS year,
		CAST (DATE_PART ('quarter', quarter_start) AS INT) AS quarter,
		adoption_difference_from_previous_quarter,
		quarterly_adoptions
FROM 	quarterly_adoptions_with_rank
WHERE 	quarter_rank <= 5
ORDER BY 	species ASC,
			adoption_difference_from_previous_quarter DESC,
			quarter_start ASC;