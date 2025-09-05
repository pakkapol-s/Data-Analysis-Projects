Query sheet


Level: Medium
1. Show patient_id, diagnosis from admissions. Find patients admitted multiple times for the same diagnosis.
SELECT 
    patient_id,
    diagnosis
FROM admissions
GROUP BY patient_id, diagnosis
HAVING COUNT(*) > 1
ORDER BY patient_id;

-- patient_id, diagnosis
-- 137	Pregnancy
-- 320	Pneumonia
-- 1577	Congestive Heart Failure
-- 2004	Left Shoulder Rotator Cuff Repair
-- 2859	Severed Spine At C3
-- 3012	Appendicitis
-- 3367	Pyelonephritis
-- 3468	Congestive Heart Failure
-- 4083	Congestive Heart Failure
-- 4121	Congestive Heart Failure
-- 4363	Congestive Heart Failure

-- 2. Show all columns for patient_id 542's most recent admission_date.

-- Option 1
SELECT 
  *
from 
  admissions
where
  patient_id = 542
group by
  patient_id
having
  max(admission_date)

-- Option 2
SELECT *
FROM admissions
WHERE
  patient_id = '542'
  AND admission_date = (
    SELECT MAX(admission_date)
    FROM admissions
    WHERE patient_id = '542'
  )

-- Option 3
SELECT *
FROM admissions
WHERE patient_id = 542
ORDER BY admission_date DESC
LIMIT 1

-- Option 4
SELECT *
FROM admissions
GROUP BY patient_id
HAVING
  patient_id = 542
  AND max(admission_date)

-- patient_id, admission_date, dischrage_date, diagnosis, attending_doctor_id
-- 542	2019-04-06	2019-04-09	Abdominal Pain	14

3. Show unique first names from the patients table which only occurs once in the list. For example, 
-- if two or more people are named 'John' in the first_name column then don't include their name in the output list. 
-- If only 1 person is named 'Leo' then include them in the output.

-- Option 1
select 
  first_name
from
  patients
group by
  first_name
having
  count(*) = 1

-- Option 2 

SELECT first_name
FROM (
    SELECT
      first_name,
      count(first_name) AS occurrencies
    FROM patients
    GROUP BY first_name
  )
WHERE occurrencies = 1

-- first_name
-- Abby
-- Adelaide
-- Adelia
-- Akira
-- Albert
-- Aldo
-- Alec
-- Alicia
-- Allan
-- Alpa
-- Amane
-- .
-- .
-- .


Level: Hard

1. Show the provinces that has more patients identified as 'M' than 'F'. Must only show full province_name

-- Option 1
SELECT pn.province_name
FROM patients p
JOIN province_names pn 
    ON p.province_id = pn.province_id
GROUP BY pn.province_name
HAVING 
    SUM(CASE WHEN p.gender = 'M' THEN 1 ELSE 0 END) >
    SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END);

-- Option 2
SELECT province_name
FROM (
    SELECT
      province_name,
      SUM(gender = 'M') AS n_male,
      SUM(gender = 'F') AS n_female
    FROM patients pa
      JOIN province_names pr ON pa.province_id = pr.province_id
    GROUP BY province_name
  )
WHERE n_male > n_female

-- Option 3
SELECT pr.province_name
FROM patients AS pa
  JOIN province_names AS pr ON pa.province_id = pr.province_id
GROUP BY pr.province_name
HAVING
  SUM(gender = 'M') > SUM(gender = 'F');

-- Option 4
SELECT province_name
FROM patients p
  JOIN province_names r ON p.province_id = r.province_id
GROUP BY province_name
HAVING
  SUM(CASE WHEN gender = 'M' THEN 1 ELSE -1 END) > 0


-- Option 5 
SELECT pr.province_name
FROM patients AS pa
  JOIN province_names AS pr ON pa.province_id = pr.province_id
GROUP BY pr.province_name
HAVING
  COUNT( CASE WHEN gender = 'M' THEN 1 END) > COUNT(*) * 0.5;

-- Option 6
SELECT province_name from province_names
WHERE province_id IN 
(SELECT province_id
FROM patients
group by province_id 
having SUM(gender = 'M') > SUM(gender = 'F'))

province_name
-- Alberta
-- British Columbia
-- Manitoba
-- Newfoundland and Labrador
-- Nova Scotia
-- Ontario
-- Saskatchewan
