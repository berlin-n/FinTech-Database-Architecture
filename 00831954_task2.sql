-- Create Database
CREATE DATABASE PrescriptionsDB
USE PrescriptionsDB;
GO

-- Verify after import
SELECT *
FROM Drugs

 -- Apply Foreign Keys
ALTER TABLE Prescriptions
ADD CONSTRAINT FK_Prescriptions_Practice 
FOREIGN KEY (PRACTICE_CODE) REFERENCES Medical_Practice(PRACTICE_CODE);
GO

ALTER TABLE Prescriptions
ADD CONSTRAINT FK_Prescriptions_Drugs 
FOREIGN KEY (BNF_CODE) REFERENCES Drugs(BNF_CODE);
GO

ALTER TABLE [Prescriptions Summary]
ADD CONSTRAINT FK_PresSummary_Practice 
FOREIGN KEY (PRACTICE_CODE) REFERENCES Medical_Practice(PRACTICE_CODE);
GO

-- Question 1
SELECT 
    BNF_CODE, CHEMICAL_SUBSTANCE_BNF_DESCR,
    BNF_DESCRIPTION, BNF_CHAPTER_PLUS_CODE
FROM Drugs
WHERE 
    BNF_DESCRIPTION LIKE '%tablet%' 
    OR BNF_DESCRIPTION LIKE '%capsule%';

-- Question 2
SELECT 
    PRESCRIPTION_CODE, PRACTICE_CODE,BNF_CODE,
    ITEMS AS NumberOfPacks, QUANTITY AS ItemsPerPack,
    CAST(ROUND((ITEMS * QUANTITY), 0) AS INT) AS TotalQuantityPrescribed
FROM Prescriptions;

-- Question 3
WITH MonthlySubstanceCounts AS (
    SELECT ps.REPORT_MONTH,  d.CHEMICAL_SUBSTANCE_BNF_DESCR, SUM(p.ITEMS) AS TotalItemsPrescribed,
     ROW_NUMBER() OVER(PARTITION BY ps.REPORT_MONTH ORDER BY SUM(p.ITEMS) DESC) as RankID
    FROM Prescriptions p
    JOIN [Prescriptions Summary] ps ON p.PRACTICE_CODE = ps.PRACTICE_CODE
    JOIN Drugs d ON p.BNF_CODE = d.BNF_CODE
    GROUP BY 
        ps.REPORT_MONTH, d.CHEMICAL_SUBSTANCE_BNF_DESCR
)
SELECT 
    REPORT_MONTH,  CHEMICAL_SUBSTANCE_BNF_DESCR, 
    TotalItemsPrescribed
FROM  MonthlySubstanceCounts
WHERE RankID = 1;

-- Question 4
SELECT 
    d.BNF_CHAPTER_PLUS_CODE,
    COUNT(p.PRESCRIPTION_CODE) AS TotalPrescriptions,
    CAST(AVG(p.ACTUAL_COST) AS DECIMAL(10,2)) AS AverageCost,
    CAST(MIN(p.ACTUAL_COST) AS DECIMAL(10,2)) AS MinimumCost,
    CAST(MAX(p.ACTUAL_COST) AS DECIMAL(10,2)) AS MaximumCost
FROM Prescriptions p
JOIN Drugs d ON p.BNF_CODE = d.BNF_CODE
GROUP BY d.BNF_CHAPTER_PLUS_CODE;

-- Question 5
SELECT 
    m.PRACTICE_NAME, MAX(p.ACTUAL_COST) AS MaxPrescriptionCost
FROM Prescriptions p
JOIN Medical_Practice m ON p.PRACTICE_CODE = m.PRACTICE_CODE
GROUP BY m.PRACTICE_NAME
HAVING MAX(p.ACTUAL_COST) > 4000
ORDER BY MaxPrescriptionCost DESC;

-- QUESTION 6.1: Evaluating Practice Specialization
SELECT 
    m.PRACTICE_NAME, COUNT(p.PRESCRIPTION_CODE) AS CardioPrescriptions
FROM Medical_Practice m
JOIN Prescriptions p ON m.PRACTICE_CODE = p.PRACTICE_CODE
JOIN Drugs d ON p.BNF_CODE = d.BNF_CODE
WHERE d.BNF_CHAPTER_PLUS_CODE LIKE '%Cardiovascular%'
GROUP BY m.PRACTICE_NAME
HAVING COUNT(p.PRESCRIPTION_CODE) > 5  
ORDER BY CardioPrescriptions DESC;

-- QUESTION 6.2: Supporting Bulk Purchasing Decisions (REVISED)
SELECT TOP 10
    d.CHEMICAL_SUBSTANCE_BNF_DESCR, SUM(p.ITEMS) AS TotalPacksDemanded
FROM Prescriptions p
JOIN Drugs d ON p.BNF_CODE = d.BNF_CODE
GROUP BY d.CHEMICAL_SUBSTANCE_BNF_DESCR
ORDER BY TotalPacksDemanded DESC;

-- QUESTION 6.3: Reporting Errors or Unusual Cases
SELECT 
    PRACTICE_CODE, PRACTICE_NAME
FROM Medical_Practice m
WHERE EXISTS (
    SELECT 1
    FROM Prescriptions p
    WHERE p.PRACTICE_CODE = m.PRACTICE_CODE
      AND p.ACTUAL_COST > 5000  
);

-- QUESTION 6.4: Comparisons of Current vs. Previous Months
WITH MonthlyTotals AS (
    SELECT 
        ps.REPORT_MONTH, SUM(ps.TOTAL_COST) AS TotalCost
    FROM [Prescriptions Summary] ps
    GROUP BY ps.REPORT_MONTH
)
SELECT 
    REPORT_MONTH, CAST(TotalCost AS DECIMAL(15,2)) AS CurrentMonthCost,
    CAST(LAG(TotalCost) OVER (ORDER BY REPORT_MONTH) AS DECIMAL(15,2)) AS PreviousMonthCost,
    CAST(TotalCost - LAG(TotalCost) OVER (ORDER BY REPORT_MONTH) AS DECIMAL(15,2)) AS MonthOverMonthVariance
FROM MonthlyTotals;
