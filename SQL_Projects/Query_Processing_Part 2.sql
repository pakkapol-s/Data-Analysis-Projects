Advanced SQL - Query Processing Part 2

Advanced SQL: Logical Query Processing, Part 2
Subqueries


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

-- Shorten with WITH clause
WITH Adoptions_and_Max_Fee
AS
(
SELECT	*,
		(SELECT MAX(Adoption_Fee) FROM Adoptions) AS Max_Fee
FROM	Adoptions
)
SELECT	*, 
		Max_Fee,
		(((Max_Fee - Adoption_Fee) * 100) / Max_Fee) AS Discount_Percent
FROM	Adoptions_and_Max_Fee;

-- Use variables
DECLARE @Max_Fee INT = (SELECT MAX(Adoption_Fee) FROM Adoptions);

SELECT	*,
		@Max_Fee,
		(((@Max_Fee - Adoption_Fee) * 100) / @Max_Fee) AS Discount_Percent
FROM Adoptions;
  

-- Get MAX adoption fee per species
SELECT	Species, 
		MAX(Adoption_Fee) AS Max_Species_Fee 
FROM	Adoptions 
GROUP BY Species;

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

-- Correlated expression subquery
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

-- Use IN = where is the bug?
SELECT	*
FROM	Persons
WHERE	Email IN (SELECT Email FROM Adoptions);

-- Be careful with subquery aliases!
SELECT	*
FROM	Persons
WHERE	Email IN (SELECT Adopter_Email FROM Adoptions);

-- True row expression
/* PostgreSQL
SELECT	*
FROM	Animals
WHERE	(Name, Species) = ROW('Abby', 'Dog');
*/

-- Non correlated EXISTS - Don't try this at home!
SELECT	*
FROM	Persons
WHERE	EXISTS	(	
				SELECT	NULL
				FROM	Adoptions
				WHERE	species = 'Dog' -- 'Elephant'
				);

-- Correlated EXISTS is the way to go!
SELECT	*
FROM	Persons AS P
WHERE	EXISTS	(
				SELECT	NULL
				FROM	Adoptions AS A
				WHERE	A.Adopter_Email = P.Email
				);


Video 2

Video 1

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

Clip 1

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

Clip 2

-- Get animals' most recent vaccination
-- Using correlated subquery
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


-- Must repeat entire subquery...
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
		) AS Last_Vaccine,
		(
			SELECT	V.Vaccination_Time
			FROM	Vaccinations AS V
			WHERE	V.Name = A.Name
					AND
					V.Species = A.species
			ORDER BY V.Vaccination_Time DESC
			OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY
		) AS Last_Vaccine_Time
FROM	Animals AS A
ORDER BY 	A.Name, 
			Last_Vaccine;


-- This is what we logically need, but it doesn't work
-- SELECT	A.Name,
-- 		A.Species,
-- 		A.Primary_Color,
-- 		A.Breed,
-- 		Last_Vaccinations.*
-- FROM	Animals AS A
-- 		CROSS JOIN 
-- 		(
-- 			SELECT	V.Vaccine, 
-- 					V.Vaccination_Time
-- 			FROM	Vaccinations AS V
-- 			WHERE	V.Name = A.Name
-- 					AND
-- 					V.Species = A.species
-- 			ORDER BY V.Vaccination_Time DESC
-- 			OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY
-- 		) AS Last_Vaccinations
-- ORDER BY 	A.Name, 
-- 			Vaccination_Time;