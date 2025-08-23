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

-- Write query about the aminals and their adopters
SELECT	*
FROM	Animals AS AN
		INNER JOIN 
		Adoptions AS AD
			ON AD.Name = AN.Name 
			AND 
			AD.Species = AN.Species
		INNER JOIN 
		Persons AS P 
			ON	AD.Adopter_Email = P.Email;

-- Animals that were never adopted

SELECT	*
FROM	Animals AS AN
		LEFT OUTER JOIN 
			Adoptions AS AD
			INNER JOIN 
			Persons AS P 
				ON	AD.Adopter_Email = P.Email
			ON 	AD.Name = AN.Name 
				AND 
				AD.Species = AN.Species;

Challenge:
-- 1. Write a query to report animal and their vaccination. Include animals that have not been vaccinated. 
-- The report should show animal's name, species, breed, and primary color, vaccination time and the vaccine name, 
-- the staff's member first names, last names, and role. 
-- Use The minimal number of tables required. 
-- Use the correct logical join types and force join order as needed.

-- Solution: 
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

Chapter 3 Row filters

Clip 1

-- Write a query that includes all dogs except bullmastiff
SELECT	*
FROM	Animals 
WHERE	Species = 'Dog'	
		AND 
		Breed <> 'Bullmastiff';

SELECT	*
FROM	Animals
WHERE	Breed IS DISTINCT FROM 'Bullmastiff';

SELECT	*
FROM	Animals
WHERE	(Breed = 'Bullmastiff') IS NOT TRUE;

Chatper 4 Grouping

Video 3

-- Identify hoarders

SELECT	Adopter_Email,
		COUNT(*) AS Number_Of_Adoptions
FROM	Adoptions
GROUP BY Adopter_Email
HAVING	COUNT(*) > 1
ORDER BY Number_Of_Adoptions DESC;

SELECT	Adopter_Email,
		COUNT(*) AS Number_Of_Adoptions
FROM	Adoptions
WHERE	Adopter_Email NOT LIKE '%gmail.com'
GROUP BY Adopter_Email
HAVING	COUNT(*) > 1
ORDER BY Number_Of_Adoptions DESC;


Challenge

-- Animal vaccination report
-- --------------------------
-- Write a query to report the number of vaccinations each animal has received.
-- Include animals that were never vaccinated.
-- Exclude all rabbits.
-- Exclude all Rabies vaccinations.
-- Exclude all animals that were last vaccinated on or after October first, 2019.

-- The report should return the following attributes:
-- Animals Name, Species, Primary Color, Breed,
-- and the number of vaccinations this animal has received,

-- -- Guidelines
-- Use the correct logical join types and force order if needed.
-- Use the  correct logical group by expressions.


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
