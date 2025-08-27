-- Window FUNCTION

Chapter 2 
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
		COUNT (*)
		OVER () AS number_of_animals
FROM 	animals	
WHERE 	admission_date >= '2017-01-01'
ORDER BY admission_date ASC;

