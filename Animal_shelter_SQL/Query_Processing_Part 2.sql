Advanced SQL - Query Processing Part 2

Chapter 1 
Video: 1 Subqueries

-- show adoption rows including fees


-- Get MAX adoption fee
SELECT	MAX(Adoption_Fee)
FROM	Adoptions;

-- Non correlated expression subquery
SELECT	*,
		(	SELECT	MAX(Adoption_Fee)
			FROM	Adoptions
		) AS Max_Fee
FROM	Adoptions;

-- Must repeat entire subquery for each instance
SELECT	*,
		(SELECT MAX(Adoption_Fee) FROM Adoptions) AS Max_Fee,
		(((SELECT MAX(Adoption_Fee) FROM Adoptions) - Adoption_Fee) * 100)
			/ (SELECT MAX(Adoption_Fee) FROM Adoptions) AS Discount_Percent
FROM	Adoptions;
  

-- Get MAX adoption fee per species
SELECT	Species, 
		MAX(Adoption_Fee) AS Max_Species_Fee 
FROM	Adoptions 
GROUP BY Species;

-- Correlated expression subquery
-- Max fee per species
SELECT	*,
		(	SELECT	MAX(Adoption_Fee) 
			FROM	Adoptions AS A2 
			WHERE	A1.species = A2.Species
		) AS Max_Fee
FROM	Adoptions AS A1;

-- Better solution, get MAX fee only once per species...
SELECT	A.*,
		M.Max_Species_Fee
FROM	Adoptions AS A
		INNER JOIN
		(
			SELECT	Species, 
					MAX(Adoption_Fee) AS Max_Species_Fee
			FROM	Adoptions 
			GROUP BY Species
		) AS M
			ON A.Species = M.Species;


-- Don't try this at home!
SELECT	*,
		(	SELECT	MAX(Adoption_Fee) 
			FROM	Adoptions
			WHERE	Species = 'Dog'
		) AS Max_Dog_Fee,
		(	SELECT	MAX(Adoption_Fee) 
			FROM	Adoptions
			WHERE	Species = 'Cat'
		) AS Max_Cat_Fee,
		(	SELECT	MAX(Adoption_Fee) 
			FROM	Adoptions
			WHERE	Species = 'Rabbit'
		) AS Max_Rabbit_Fee
FROM	Adoptions;


-- Number of Persons and adoptions
SELECT	COUNT(*)
FROM	Persons;

SELECT	COUNT(*)
FROM	Adoptions;

-- Use JOIN
SELECT	DISTINCT P.*
FROM	Persons AS P
		INNER JOIN
		Adoptions AS A
			ON A.Adopter_Email = P.Email;


-- Non correlated EXISTS - Don't try this at home!
-- Show all adopters
SELECT	*
FROM	Persons
WHERE	EXISTS	(	
				SELECT	NULL
				FROM	Adoptions
				WHERE	species = 'Dog'
				);

-- Correlated EXISTS is the way to go!
-- correct answer
SELECT	*
FROM	Persons AS P
WHERE	EXISTS	(
				SELECT	*
				FROM	Adoptions AS A
				WHERE	A.Adopter_Email = P.Email
				);


Video 2: Set Operators

-- Animals that were not adopted
-- Using OUTER JOIN
SELECT	DISTINCT AN.Name, AN.Species
FROM	Animals AS AN
		LEFT OUTER JOIN
		Adoptions AS AD
			ON AD.Name = AN.Name AND AD.Species = AN.Species
WHERE	AD.Name IS NULL;

-- Using NOT EXISTS
SELECT	AN.Name, AN.Species
FROM	Animals AS AN
WHERE	NOT EXISTS	(
						SELECT	NULL
						FROM	Adoptions AS AD
						WHERE	AD.Name = AN.Name
								AND 
								AD.Species = AN.Species
					);

-- Using EXCEPT
-- The right way - Set Operators
SELECT	Name, Species
FROM	Animals
EXCEPT	
SELECT	Name, Species
FROM	Adoptions;


Challenge: Write a query to show which breeds were never adopted.

-- The elegant solution
SELECT	Species, Breed
FROM	Animals
EXCEPT	
SELECT	AN.Species, AN.Breed 
FROM	Animals AS AN
		INNER JOIN
		Adoptions AS AD
		ON	AN.Species = AD.Species
			AND
			AN.Name = AD.Name;

-- Do we have non breed animals that were adopted?
SELECT	*
FROM	Animals AS AN
		INNER JOIN 
		Adoptions AS AD
		ON	AD.Name = AN.Name 
			AND
			AD.Species = AN.Species
WHERE	AN.Breed IS NULL;

-- Try the NOT EXISTS approach (doesn't work...)
SELECT	DISTINCT Species, Breed
FROM	Animals AS AN
WHERE	NOT EXISTS	(
						SELECT	NULL
						FROM	Adoptions AS AD
						WHERE	AD.Name = AN.Name
								AND 
								AD.Species = AN.Species
					);


Chapter 2 
Video 1: Self and iequlity joins

-- Show adopters who adopted 2 animals in the same day

-- Adoptions matched with themselves
SELECT	A1.Adopter_Email,
		A1.Adoption_Date,
		A1.Name AS First_Animal_Name,
		A1.Species AS First_Animal_Species,
		A2.Name AS Second_Animal_Name,
		A2.Species AS Second_Animal_Species
FROM	Adoptions AS A1
		INNER JOIN
		Adoptions AS A2
			ON	A1.Adopter_Email = A2.Adopter_Email
				AND 
				A1.Adoption_Date = A2.Adoption_Date
ORDER BY	A1.Adopter_Email, 
			A1.Adoption_Date;

-- Adoptions no longer matched with themselves,
-- but we still get 2 rows for each adoption of 2 animals on the same day.
SELECT	A1.Adopter_Email,
		A1.Adoption_Date,
		A1.Name AS First_Animal_Name,
		A1.Species AS First_Animal_Species,
		A2.Name AS Second_Animal_Name,
		A2.Species AS Second_Animal_Species
FROM	Adoptions AS A1
		INNER JOIN
		Adoptions AS A2
			ON	A1.Adopter_Email = A2.Adopter_Email
				AND 
				A1.Adoption_Date = A2.Adoption_Date
				AND
				A1.Name <> A2.Name
ORDER BY	A1.Adopter_Email,
			A1.Adoption_Date;

-- Now we get only 1 row for each 'double' adoption, but we're not done yet.
SELECT	A1.Adopter_Email,
		A1.Adoption_Date,
		A1.Name AS First_Animal_Name,
		A1.Species AS First_Animal_Species,
		A2.Name AS Second_Animal_Name,
		A2.Species AS Second_Animal_Species
FROM	Adoptions AS A1
		INNER JOIN
		Adoptions AS A2
			ON	A1.Adopter_Email = A2.Adopter_Email
				AND 
				A1.Adoption_Date = A2.Adoption_Date
				AND
				A1.Name > A2.Name
ORDER BY	A1.Adopter_Email,
			A1.Adoption_Date;

-- Add an animal with the same name but of a difference species
INSERT INTO Animals (Name, Species, Primary_Color, Implant_Chip_ID, Breed, Gender, Birth_Date, Pattern, Admission_Date)
VALUES	('Duplicate', 'Dog', 'Black', NEWID(), NULL, 'M', '20171001', 'Solid', '20171101'),
		('Duplicate', 'Rabbit', 'Black', NEWID(), NULL, 'M', '20171001', 'Solid', '20171101');

-- and both adopted on the same day, by the same person.
INSERT INTO Adoptions (Name, Species, Adopter_Email, Adoption_Date, Adoption_Fee)
VALUES	('Duplicate', 'Dog', 'alan.cook@hotmail.com', '20181201', 40),
		('Duplicate', 'Rabbit', 'alan.cook@hotmail.com', '20181201', 40)

-- Try to execute again, will they show up?
SELECT	A1.Adopter_Email,
		A1.Adoption_Date,
		A1.Name AS First_Animal_Name,
		A1.Species AS First_Animal_Species,
		A2.Name AS Second_Animal_Name,
		A2.Species AS Second_Animal_Species
FROM	Adoptions AS A1
		INNER JOIN
		Adoptions AS A2
			ON	A1.Adopter_Email = A2.Adopter_Email
				AND 
				A1.Adoption_Date = A2.Adoption_Date
				AND
				A1.Name > A2.Name
ORDER BY	A1.Adopter_Email,
			A1.Adoption_Date;

-- You might have been tempted to do the following...
SELECT	A1.Adopter_Email,
		A1.Adoption_Date,
		A1.Name AS First_Animal_Name,
		A1.Species AS First_Animal_Species,
		A2.Name AS Second_Animal_Name,
		A2.Species AS Second_Animal_Species
FROM	Adoptions AS A1
		INNER JOIN
		Adoptions AS A2
			ON	A1.Adopter_Email = A2.Adopter_Email
				AND 
				A1.Adoption_Date = A2.Adoption_Date
				AND
				(A1.Name > A2.Name OR A1.Species <> A2.Species)
ORDER BY	A1.Adopter_Email,
			A1.Adoption_Date;

-- And then you might have been tempted to do...
SELECT	A1.Adopter_Email,
		A1.Adoption_Date,
		A1.Name AS First_Animal_Name,
		A1.Species AS First_Animal_Species,
		A2.Name AS Second_Animal_Name,
		A2.Species AS Second_Animal_Species
FROM	Adoptions AS A1
		INNER JOIN
		Adoptions AS A2
		ON	A1.Adopter_Email = A2.Adopter_Email
			AND 
			A1.Adoption_Date = A2.Adoption_Date
			AND
			(A1.Name > A2.Name OR A1.Species > A2.Species)
ORDER BY	A1.Adopter_Email,
			A1.Adoption_Date;

-- Spell out all 3 possible conditions
SELECT	A1.Adopter_Email,
		A1.Adoption_Date,
		A1.Name AS First_Animal_Name,
		A1.Species AS Firs_Animal_Species,
		A2.Name AS Second_Animal_Name,
		A2.Species AS Second_Animal_Species
FROM	Adoptions AS A1
		INNER JOIN
		Adoptions AS A2
			ON	A1.Adopter_Email = A2.Adopter_Email
				AND 
				A1.Adoption_Date = A2.Adoption_Date
				AND	(	(A1.Name = A2.Name AND A1.Species > A2.Species)
						OR
						(A1.Name > A2.Name AND A1. Species = A2.Species)
						OR
						(A1.Name > A2.Name AND A1.Species > A2.Species)
					)

-- (Alvin Pillay 28/9/2020) The above code can be reduced to the following:
--				AND	(	(A1.Name = A2.Name AND A1.Species > A2.Species)
--						OR
--						(A1.Name > A2.Name)
--					)
--
-- This makes logical sense because we use (A1.Name > A2.Name) to get rid of the "repeating groups" and then for the cases where two animals 
-- have the same name but different species, we get rid of those with (A1.Name = A2.Name AND A1.Species > A2.Species).
		
ORDER BY	A1.Adopter_Email,
			A1.Adoption_Date;

-- For the last predicate, we can't use 2 > as there is no guarantee both name and species will be in that order.
-- We must use one of them as <>, doesn't matter which one...
-- A1.Name > A2.Name AND A1.Species <> A2.Species
SELECT	A1.Adopter_Email,
		A1.Adoption_Date,
		A1.Name AS First_Animal_Name,
		A1.Species AS Firs_Animal_Species,
		A2.Name AS Second_Animal_Name,
		A2.Species AS Second_Animal_Species
FROM	Adoptions AS A1
		INNER JOIN
		Adoptions AS A2
		ON	A1.Adopter_Email = A2.Adopter_Email
			AND 
			A1.Adoption_Date = A2.Adoption_Date
			AND	(	(A1.Name = A2.Name AND A1.Species > A2.Species)
					OR
					(A1.Name > A2.Name AND A1. Species = A2.Species)
					OR
					(A1.Name > A2.Name AND A1.Species <> A2.Species)
				)
ORDER BY	A1.Adopter_Email,
			A1.Adoption_Date;

-- Alternatively, A1.Name <> A2.Name AND A1.Species > A2.Species
SELECT	A1.Adopter_Email,
		A1.Adoption_Date,
		A1.Name AS First_Animal_Name,
		A1.Species AS Firs_Animal_Species,
		A2.Name AS Second_Animal_Name,
		A2.Species AS Second_Animal_Species
FROM	Adoptions AS A1
		INNER JOIN
		Adoptions AS A2
			ON	A1.Adopter_Email = A2.Adopter_Email
				AND A1.Adoption_Date = A2.Adoption_Date
				AND	(	(A1.Name = A2.Name AND A1.Species > A2.Species)
						OR
						(A1.Name > A2.Name AND A1. Species = A2.Species)
						OR
						(A1.Name <> A2.Name AND A1.Species > A2.Species)
					)
ORDER BY	A1.Adopter_Email,
			A1.Adoption_Date;

-- Cleanup
DELETE FROM Adoptions WHERE Name = 'Duplicate';
DELETE FROM Animals WHERE Name = 'Duplicate';

------

Chapter 2
Video 2: Lateral joins

-- Get animals' most recent vaccination
-- Using correlated subquery

-- This query works but it's limited and inefficient. i.e. you can't use the order by clause
SELECT	A.Name,
		A.Species,
		A.Primary_Color,
		A.Breed,
		(
			SELECT	Vaccine
			FROM	Vaccinations AS V
			WHERE	V.Name = A.Name
					AND
					V.Species = A.species
			ORDER BY V.Vaccination_Time DESC
			OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY
		) AS Last_Vaccine
FROM	Animals AS A
ORDER BY A.Name, Last_Vaccine;


-- Solution
SELECT	A.Name,
		A.Species,
		A.Primary_Color,
		A.Breed,
		Last_Vaccinations.*
FROM	Animals AS A
		CROSS JOIN LATERAL
		(
			SELECT	V.Vaccine, 
					V.Vaccination_Time
			FROM	Vaccinations AS V
			WHERE	V.Name = A.Name
					AND
					V.Species = A.species
			ORDER BY V.Vaccination_Time DESC
			LIMIT 3 OFFSET 0
		) AS Last_Vaccinations
ORDER BY 	A.Name, 
			Vaccination_Time;

-- Show animal that are not vaccinated

SELECT	A.Name,
		A.Species,
		A.Primary_Color,
		A.Breed,
		Last_Vaccinations.*
FROM	Animals AS A
		LEFT OUTER JOIN LATERAL
		(
			SELECT	V.Vaccine, 
					V.Vaccination_Time
			FROM	Vaccinations AS V
			WHERE	V.Name = A.Name
					AND
					V.Species = A.species
			ORDER BY V.Vaccination_Time DESC
			LIMIT 3 OFFSET 0
		) AS Last_Vaccinations
			ON TRUE
ORDER BY 	A.Name, 
			Vaccination_Time;

Challenge

-- Our shelter has been experiencing financial difficulties.
-- !!! PLEASE consider donating to your local animal shelter !!!
-- The board of directors decided to explore additional revenue sources and came up with an idea.
-- Instead of spaying and neutering all animals, the shelter should consider responsible breeding of purebred animals.
-- !!!	This is a hypothetical question – ALWAYS spay and neuter your pets !!! 

-- Your challenge is to figure out which animals are breeding candidates.

-- Solution
SELECT	A1.Species,
		A1.Breed AS Breed,
		A1.Name AS Male,
		A2.Name AS Female
FROM	Animals AS A1
		INNER JOIN
		Animals AS A2
		ON	A1.Species = A2.Species
			AND
			A1.Breed = A2.Breed -- Removes NULL breeds
			AND
			A1.Name <> A2.Name
			AND
			A1.Gender = 'M'
			AND 
			A2.Gender = 'F'
ORDER BY 	A1.Species, 
			A1.Breed;

-- Solution with > shortcut 
-- 	  !!! Only works if collation is dictionary based, and if case insensitive or casing is consistent !!!
SELECT	A1.Species,
		A1.Breed AS Breed,
		A1.Name AS Male,
		A2.Name AS Female
FROM	Animals AS A1
		INNER JOIN
		Animals AS A2
		ON	A1.Species = A2.Species
			AND
			A1.Breed = A2.Breed -- Removes NULL breeds
			AND
			A1.Name <> A2.Name
			AND
			A1.Gender > A2.Gender
ORDER BY 	A1.Species, 
			A1.Breed;

Chapter 3
Video 1

-- String concat
SELECT	Adoption_Date,
		SUM(Adoption_Fee) AS Total_Fee,
		STRING_AGG(CONCAT(Name, ' the ',  Species), ', ') AS Adopted_Animals
FROM	Adoptions
GROUP BY Adoption_Date
HAVING	COUNT(*) > 1;

-- min max avg of vaccination for each specie

WITH Vaccination_Ranking AS (
	SELECT Name, Species, COUNT(*) AS Num_of_V
	FROM Vaccinations
	GROUP BY Name, Species
)
SELECT Species, MAX(Num_of_V) AS MAX_V, MIN(Num_of_V) AS MIN_V,
  CAST(AVG(Num_of_V) AS DECIMAL(9,2)) AS AVG_V
FROM Vaccination_Ranking
GROUP BY Species ;


-- What would be the rank of an hypothetical animal that received X vaccinations?
-- Too advance. May not need to dig too deep for this one
WITH Vaccination_Ranking
AS
(
SELECT	Name, 
		Species,
		COUNT(*) AS Number_Of_Vaccinations
FROM	Vaccinations
GROUP BY Name, Species
)
SELECT  Species,
        MAX(Number_Of_Vaccinations) AS MAX_Vaccinations,
        MIN(Number_Of_Vaccinations) AS MIN_Vaccinations,
        CAST(AVG(Number_Of_Vaccinations) AS DECIMAL(9,2)) AS AVG_Vaccinations,
        DENSE_RANK(5)	
		WITHIN GROUP (ORDER BY Number_Of_Vaccinations DESC) AS How_Would_X_Rank,
        PERCENT_RANK(5) 
		WITHIN GROUP (ORDER BY Number_Of_Vaccinations DESC) AS How_Would_X_Rank_Percent_Wise,
        PERCENTILE_CONT(0.333) 
		WITHIN GROUP (ORDER BY Number_Of_Vaccinations DESC) AS Inverse_Continous,
        PERCENTILE_DISC(0.333) 
		WITHIN GROUP (ORDER BY Number_Of_Vaccinations DESC) AS Inverse_Discrete
FROM    Vaccination_Ranking
GROUP BY Species;

