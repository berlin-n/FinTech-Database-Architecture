CREATE DATABASE Bank;
GO

--==============================================================================================================
--======================== CREATE DATABASE=====================================================================
--==============================================================================================================
-- Question 1
-- Create the address table first, because it is needed in the customer's table
CREATE TABLE Addresses (
	AddressID INT IDENTITY(1,1)	PRIMARY KEY,
	AddressLine1 NVARCHAR(100) NOT NULL,
	AddressLine2 NVARCHAR(100) NULL,
	City NVARCHAR(50) NOT NULL,
	County NVARCHAR(50) NOT NULL,
	PostalCode NVARCHAR(50) DEFAULT 'United Kingdom' NOT NULL
);
GO;

-- Creating the Customer's table next, make it reference the Address Table to collect Customer's address data
-- Hash the user's password as part of database security design consideration
CREATE TABLE Customers (
	CustomerID INT IDENTITY(1,1) Primary Key,
	FirstName NVARCHAR(50) NOT NULL,
	LastName NVARCHAR(50) NOT NULL,
	MiddleName NVARCHAR(50) NULL,
	AddressID INT NOT NULL,
	DateOfBirth DATE NOT NULL,
	Username NVARCHAR(50) NOT NULL,
	PasswordHash BINARY(64) NOT NULL, 
	Salt UNIQUEIDENTIFIER NOT NULL,
	EmailAddress NVARCHAR(30) NULL,
	PhoneNumber NVARCHAR(20) NULL,
	AccountClosureDate DATE NULL,

	-- Address Foreign Key
	CONSTRAINT FK_Customers_Addresses FOREIGN KEY (AddressID) REFERENCES Addresses(AddressID)
);
GO;

-- Creating the Accounts table next, the table references the Customer's Table, to identify the customer owning the account
-- Has 3 CHECK constraints for valid account types, valid Account Status, and to ensure that only loan and credit card accounts can't be null.
CREATE TABLE Accounts (
	AccountID INT IDENTITY(1,1) Primary Key,
	CustomerID INT NOT NULL,
	AccountName NVARCHAR(100) NOT NULL,
	AccountType NVARCHAR(20) NOT NULL,
	OpeningDate DATE NOT NULL,
	AccountStatus NVARCHAR(20) NOT NULL, 
	StatusChangeDate DATE NULL,
	ReferenceNumber NVARCHAR(50) NULL,

	-- Valid Account Types
	CONSTRAINT CHK_AccountType CHECK (AccountType IN ('Savings', 'Checking', 'Loan', 'Credit Card', 'Investment')),

	-- Valid Account Statuses
	CONSTRAINT CHK_Status CHECK (AccountStatus  in ('Active', 'Dormant', 'Closed', 'Frozen')),

	-- Customer Foreign Key
	CONSTRAINT FK_Customers_Accounts FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),

	 -- ReferenceNumber only allowed for Loan or Credit Card accounts
	 CONSTRAINT CHK_RefNumber_OnlyForTypes CHECK (
        ReferenceNumber IS NULL OR AccountType IN ('Loan', 'Credit Card'))
);
GO

-- The UNIQUE Constraint won't allow multiple NULLs, the Unique Index helps ignore multiple NULLs and focuses only on real values.
-- Create a Unique Index for Account's Reference Number
CREATE UNIQUE INDEX UQ_Accounts_ReferenceNumber
ON Accounts(ReferenceNumber)
WHERE ReferenceNumber IS NOT NULL;
GO;

-- Creating the transactions table with the Account as the foreign key, linking the transaction to the particular account
-- Adding due date for loans/credit payments
CREATE TABLE Transactions (
	TransactionID int IDENTITY(1,1) Primary Key,
	AccountID INT NOT NULL,
	TransactionDate DATETIME DEFAULT GETDATE() NOT NULL,
	DueDate DATE NULL,
	CompletionDate DATE NULL,
	TransactionAmount DECIMAL(18,2) NOT NULL,

	-- Account's Foreign Key
	CONSTRAINT FK_Accounts_Transactions FOREIGN KEY (AccountID) REFERENCES Accounts(AccountID)
);
GO

-- Creating the OverdueFees Table to track the fees that passed their Duedates, and became overdue
-- We linked the overdue fee to it's transaction
-- And defined a calculated column for Outstanding Balance
CREATE TABLE Overduefees (
	FeeID INT IDENTITY(1,1) Primary Key,
	TransactionID INT NOT NULL,
	DaysOverDue INT DEFAULT 0 NOT NULL,
	TotalOwed DECIMAL(18,2) DEFAULT 0.0 NOT NULL,
	TotalRepaid DECIMAL(18,2) DEFAULT 0.0 NOT NULL,
	OutstandingBalance as (TotalOwed - TotalRepaid),

	-- Transaction Foreign Key
	CONSTRAINT FK_Transactions_Overduefees FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID)
);
GO

-- Creating the repayments table to track customer repayments
-- Linked the repayment to the particular overdue fee
CREATE TABLE Repayments (
	RepaymentID INT IDENTITY(1,1) PRIMARY KEY,
	FeeID INT NOT NULL,
	RepaymentDateTime DATETIME DEFAULT GETDATE() NOT NULL,
	Amount DECIMAL(18,2) NOT NULL,
	PaymentMethod NVARCHAR(20) NOT NULL, 

		-- Valid Payment Method
	CONSTRAINT CHK_PaymentMethod CHECK(PaymentMethod IN ('Bank Transfer', 'Card', 'Cash')),

		-- Overduefees Foreign Key
	CONSTRAINT FK_Overduefees_Repayments FOREIGN KEY (FeeID) REFERENCES Overduefees(FeeID)
);
GO

--======================================================================================================
--======================== INSERT STATEMENTS============================================================
--======================================================================================================

-- Manually inserting vlaues into the address table
INSERT INTO Addresses (AddressLine1, City, County, PostalCode) VALUES
('10 Downing Street', 'London', 'Greater London','SW1A 2AA'),
('221B Baker Street', 'London','Greater London', 'NW1 6XE'),
('4 Privet Street', 'Surrey', 'Greater Surrey', 'GU4 7QX'),
('123 Fake Street', 'Manchester', 'Greater Manchester','M1 1AA');
GO;

----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- Insert Customer 1
DECLARE @Salt1 UNIQUEIDENTIFIER = NEWID();
INSERT INTO Customers (
FirstName, LastName, MiddleName, AddressID, DateOfBirth, Username, PasswordHash, Salt, EmailAddress, PhoneNumber) VALUES
('John', 'Doe', 'Isaac', 1, '1985-04-12', 'jdoe85', HASHBYTES('SHA2_512', 'SecurePass1!' + CAST(@salt1 AS NVARCHAR(36))), 
@Salt1, 'john.doe@email.com', '7351773826');

-- Insert Customer 2
DECLARE @Salt2 UNIQUEIDENTIFIER = NEWID();
INSERT INTO Customers (
FirstName, LastName, MiddleName, AddressID, DateOfBirth, Username, PasswordHash, Salt, EmailAddress, PhoneNumber) VALUES
('Jane', 'Smith', 'Elizabeth', 2, '1990-08-24', 'jsmith90', HASHBYTES('SHA2_512', 'G7d!Q2m#9Rz$' + CAST(@Salt2 AS NVARCHAR(36))), 
@Salt2, NULL, '7331673676');

-- Insert Customer 3
DECLARE @Salt3 UNIQUEIDENTIFIER = NEWID();
INSERT INTO Customers (
FirstName, LastName, MiddleName, AddressID, DateOfBirth, Username, PasswordHash, Salt, EmailAddress, PhoneNumber) VALUES
('Alice', 'Johnson', NULL, 3, '1978-11-05', 'ajohnson', HASHBYTES('SHA2_512', 'tB8&yP3v!Wq1' + CAST(@Salt3 AS NVARCHAR(36))), 
@Salt3, 'alice.j@email.com', NULL);

-- Insert Customer 4
DECLARE @Salt4 UNIQUEIDENTIFIER = NEWID();
INSERT INTO Customers (
FirstName, LastName, MiddleName, AddressID, DateOfBirth, Username, PasswordHash, Salt, EmailAddress, PhoneNumber) VALUES
('Bob', 'William', 'John', 4, '1995-02-15', 'bwilliam', HASHBYTES('SHA2_512', 'H6k*R9s@2Xj4' + CAST(@Salt4 AS NVARCHAR(36))), 
@Salt4, NULL, NULL);

-- Will only insert 4 customer first to show insert, and simulate transactions. The rest will be inserted through procedure.
GO;
----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------
-- Manually inserting vlaues into the accounts table
INSERT INTO Accounts (CustomerID, AccountName, AccountType, AccountStatus, ReferenceNumber, OpeningDate) VALUES 
(1, 'Everyday Checking', 'Checking', 'Active', NULL, '2022-04-12'),
(1, 'Personal Loan', 'Loan', 'Active', 'LN-100293', '2022-11-05'),
(2, 'High Yield Savings', 'Savings', 'Active', NULL, '2021-08-24'),
(2, 'Rewards Credit Card', 'Credit Card', 'Active', 'CC-998877', '2020-02-05'),
(3, 'Basic Checking', 'Checking', 'Closed', NULL, '2023-12-31'),
(3, 'Auto Loan', 'Loan', 'Active', 'LN-554433', '2021-07-30'),
(4, 'Investment Portfolio', 'Investment', 'Active', NULL, '2024-05-15'),
(4, 'Startup Loan', 'Loan', 'Active', 'LN-122231', '2025-01-16');
GO;

-- Manually inserting vlaues into the transactions table
INSERT INTO Transactions (AccountID, TransactionDate, DueDate, CompletionDate, TransactionAmount) VALUES
(1, DATEADD(day, -20, GETDATE()), NULL, DATEADD(day, -20, GETDATE()), 150.00),
(3, DATEADD(day, -15, GETDATE()), NULL, DATEADD(day, -15, GETDATE()), 500.00),
-- Pending Payments due in LESS than 5 days
(2, GETDATE(), DATEADD(day, 3, GETDATE()), NULL, 250.00),
(4, GETDATE(), DATEADD(day, 2, GETDATE()), NULL, 75.00),
-- Overdue transactions (Triggers the fees below)
(2, DATEADD(day, -45, GETDATE()), DATEADD(day, -15, GETDATE()), NULL, 250.00),
(6, DATEADD(day, -75, GETDATE()), DATEADD(day, -45, GETDATE()), NULL, 250.00),
(8, DATEADD(day, -40, GETDATE()), DATEADD(day, -10, GETDATE()), NULL, 75.00),
(4, DATEADD(day, -70, GETDATE()), DATEADD(day, -40, GETDATE()), NULL, 75.00),
(6, DATEADD(day, -35, GETDATE()), DATEADD(day, -5, GETDATE()), NULL, 400.00),
(4, DATEADD(day, -65, GETDATE()), DATEADD(day, -35, GETDATE()), NULL, 400.00),
(8, DATEADD(day, -100, GETDATE()),DATEADD(day, -70, GETDATE()), NULL, 700.00);
GO;

-- Manually inserting vlaues into the overdue fees table
-- Asumption: A flat fee of 2.50 per day
INSERT INTO OverdueFees (TransactionID, DaysOverdue, TotalOwed, TotalRepaid) VALUES 
(5, 15, 37.5, 16.00),
(6, 45, 112.50, 30.00), 
(7, 10, 25.00,  18.00),
(8, 40, 100.00,  100.00),
(9, 5,  12.50,  0.00), 
(10, 35, 87.50, 43.75),
(11, 70, 175.00, 0); 
GO;

-- Manually inserting values into the repayments table
INSERT INTO Repayments (FeeID, RepaymentDateTime, Amount, PaymentMethod) VALUES 
(1, DATEADD(day, -2, GETDATE()), 16.00, 'Card'),
(2, DATEADD(day, -5, GETDATE()), 30.00, 'Bank Transfer'),
(3, DATEADD(day, -1, GETDATE()), 18.00, 'Card'),
(4, DATEADD(day, -10, GETDATE()), 50.00, 'Cash'),
(4, DATEADD(day, -8, GETDATE()), 50.00, 'Bank Transfer'),
(6, DATEADD(day, -3, GETDATE()), 23.75, 'Card'),
(6, DATEADD(day, -4, GETDATE()), 20.00, 'Cash'); 
GO

--=====================================================================================================
--============================ PROCEDURES=============================================================
--=====================================================================================================

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------- 2A: Procdure to Search accounts by name------------------------
CREATE PROCEDURE sp_SearchAccountsByName
    @SearchTerm NVARCHAR(100)
AS
BEGIN

    SELECT 
        AccountID,
        CustomerID,
        AccountName,
        AccountType,
        AccountStatus,
        OpeningDate,
        ReferenceNumber
    FROM Accounts
    WHERE AccountName LIKE '%' + @SearchTerm + '%'
    ORDER BY OpeningDate DESC;
END;
GO

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
---------2B: Procedure to get upcoming payments in the next 5 days ---------------
CREATE PROCEDURE sp_GetUpcomingPayments
AS
BEGIN

    SELECT 
        c.FirstName + ' ' + c.LastName AS CustomerName,
        a.AccountName,
        a.AccountType,
        t.TransactionID,
        t.TransactionAmount AS PaymentAmount,
        CAST(t.DueDate AS DATE) AS DueDate,
        DATEDIFF(day, GETDATE(), t.DueDate) AS DaysUntilDue
    FROM Transactions t
    JOIN Accounts a ON t.AccountID = a.AccountID
    JOIN Customers c ON a.CustomerID = c.CustomerID
    WHERE a.AccountType IN ('Loan', 'Credit Card')
      AND t.CompletionDate IS NULL 
      AND CAST(t.DueDate AS DATE) BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(day, 5, CAST(GETDATE() AS DATE))
    ORDER BY t.DueDate ASC; 
END;
GO

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
------------------- 2C: Procedure to add customers to the database --------------------
CREATE PROCEDURE AddCustomer
	@username NVARCHAR(50), @password NVARCHAR(50), @firstname NVARCHAR(40), @lastname NVARCHAR(40),
	@dob DATE, @email NVARCHAR(30),
	-- Address Parameters
    @addressline1 NVARCHAR(100), @addressline2 NVARCHAR(100) = NULL,
    @city NVARCHAR(50), @county NVARCHAR(50), @postalcode NVARCHAR(50),
    -- Initial Account Parameters
    @accountname NVARCHAR(100), @accounttype NVARCHAR(20), @referenceNumber NVARCHAR(15) = NULL
	AS
    BEGIN
    -- Start the error handling block
    BEGIN TRY 

        -- Start the transaction to enforce atomicity
        BEGIN TRANSACTION

		INSERT INTO Addresses (AddressLine1, AddressLine2, City, County, PostalCode)
        VALUES (@addressline1, @addressline2, @city, @county, @postalcode);

		 -- Capture the newly generated AddressID
        DECLARE @AddressID INT = SCOPE_IDENTITY();

        DECLARE @salt UNIQUEIDENTIFIER=NEWID()

        -- Insert Customer into Customer Table
	    INSERT INTO Customers (FirstName, LastName, AddressID, DateOfBirth, Username, PasswordHash, Salt ,EmailAddress) 
        VALUES (
        @firstname, @lastname, @AddressID, @dob, @username, HASHBYTES('SHA2_512', @password+CAST(@salt AS NVARCHAR(36))), @salt, @email);

        -- Get the newly generated customer id
        DECLARE @NewCustomerID INT = SCOPE_IDENTITY();

        INSERT INTO Accounts (CustomerID, AccountName, AccountType, AccountStatus, ReferenceNumber, OpeningDate) 
        VALUES (
        @NewCustomerID, @accountname, @accounttype, 'Active', @referenceNumber, GETDATE());

        -- If the insertions succeeds without errors, COMMIT to make it permanent
        COMMIT TRANSACTION
        PRINT 'Transaction Completed: Customer Added Successfully'

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
            DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
            SELECT @ErrMsg = ERROR_MESSAGE(),
            @ErrSeverity = ERROR_SEVERITY()
            RAISERROR(@ErrMsg, @ErrSeverity, 1)
    END CATCH
    END;
GO;
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
--------------------- 2D: Procedure to Update customer details -------------------------
CREATE PROCEDURE sp_UpdateCustomerDetails
    @Username NVARCHAR(50),
    @NewEmail NVARCHAR(100) = NULL,
    @NewPhone NVARCHAR(20) = NULL,
    @NewAddressID INT = NULL
AS
BEGIN TRY
	BEGIN TRANSACTION
	UPDATE Customers
    SET 
        EmailAddress = ISNULL(@NewEmail, EmailAddress),
        PhoneNumber = ISNULL(@NewPhone, PhoneNumber),
        AddressID = ISNULL(@NewAddressID, AddressID)
    WHERE Username = @Username;

	COMMIT TRANSACTION;
	PRINT 'Customer details updated successfully.';
END TRY
BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
            DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
            SELECT @ErrMsg = ERROR_MESSAGE(),
            @ErrSeverity = ERROR_SEVERITY()
            RAISERROR(@ErrMsg, @ErrSeverity, 1)
    END CATCH;
GO

--=====================================================================================================
--===============================================VIEWS================================================
--=====================================================================================================

-- 3. View to display all transactions including ones with overdue fees and their fee detials
CREATE VIEW TransactionsReportView
AS
SELECT
	t.TransactionID,
	c.FirstName + '  ' + c.Lastname AS CustomerName,
	a.AccountName,
	t.TransactionAmount AS TransactionAmount,
	t.TransactionDate, 
	t.DueDate,
	t.CompletionDate,
	f.FeeID,
	ISNULL(f.TotalOwed, 0.00) AS ChargedPenalty,
	ISNULL(f.TotalRepaid, 0.00) AS PenaltyRepaid,
	ISNULL(f.OutstandingBalance, 0.00) AS OutstandingPenalty
	FROM Transactions t
		INNER JOIN Accounts a ON t.AccountID = a.AccountID
		INNER JOIN Customers c ON a.CustomerID = c.CustomerID
		LEFT JOIN Overduefees f ON t.TransactionID = f.TransactionID
	GO

	-- 5. List of customers who paid less than 50% of their overdue fees
	CREATE VIEW HighRiskCustomers
	AS
	SELECT
		c.CustomerID,
		c.Username,
		c.FirstName + ' ' +  c.LastName AS FullName,
		COUNT(f.FeeID) AS OverdueFeesCount,
		SUM(f.TotalOwed) AS TotalAccumulatedFees,
		SUM(f.TotalRepaid) AS TotalAmountRepaid,
		SUM(f.OutstandingBalance) AS TotalOutstandingDebt
		FROM Customers c
			INNER JOIN Accounts a ON c.CustomerID = a.CustomerID
			INNER JOIN Transactions t ON a.AccountID = t.AccountID
			INNER JOIN Overduefees f ON t.TransactionID = f.TransactionID
		GROUP BY
			c.CustomerID,
			c.Username,
			c.FirstName,
			c.LastName
		HAVING 
			SUM(f.TotalRepaid) < (0.5 * SUM(f.TotalOwed))
			AND SUM(f.TotalOwed) > 0;
		GO
--=====================================================================================================
--=============================================TRIGGERS================================================
--=====================================================================================================
-- 4. View to display all transactions including ones with overdue fees and their fee detials
CREATE TRIGGER AutoCloseLoanAccount
ON Transactions
AFTER UPDATE
AS
BEGIN

    -- Only run the heavy logic if the CompletionDate was actually changed
    IF UPDATE(CompletionDate)
    BEGIN
        -- Update the AccountStatus to 'Closed'
        UPDATE a
        SET a.AccountStatus = 'Closed'
        FROM Accounts a
        -- Join with the special 'inserted' table to only check accounts that were just updated
        INNER JOIN inserted i ON a.AccountID = i.AccountID
        WHERE a.AccountType IN ('Loan', 'Credit Card')
          AND a.AccountStatus = 'Active' -- Only bother updating if it's currently Active
          -- ]Ensure no unpaid transactions exist for this specific account
          AND NOT EXISTS (
              SELECT 1 
              FROM Transactions t 
              WHERE t.AccountID = a.AccountID 
                AND t.CompletionDate IS NULL
          );
    END
END;
GO
--=====================================================================================================
--===============================================6. TESTS================================================
--=====================================================================================================
------------------------------------------------------------------------------------------------------
----------------------------- Search accounts by Name Test-----------------------------------
-- Test 1 (Valid Input)
EXEC sp_SearchAccountsByName @SearchTerm = 'Loan';

-- Test 2 (Invalid Input - Should return empty)
EXEC sp_SearchAccountsByName @SearchTerm = 'Zebra';

----------------------------------------------------------------------------------------------
------------------------------Add customers Procedure--------------------------------
-- Adding extra customers
EXECUTE AddCustomer 
    -- Customer Info
    @firstname='Bruce', @lastname='Wayne', @dob='1980-02-19', 
    @username='bwayne', @password='GothamKnight1!', @email='bruce@wayne-ent.com',
    -- Address Info
    @addressline1='1007 Mountain Drive', @city='Gotham', @county='Bristol', @postalcode='GH1 1AA',
    -- Account Info
    @accountname='Wayne Enterprise Checking', @accounttype='Checking';

EXECUTE AddCustomer 
    -- Customer Info
    @firstname='Charile', @lastname='Brown', @dob='2000-07-30', 
    @username='cbrown', @password='Zp4#L7f%8Nd2', @email='charlie.b@email.com',
    -- Address Info
    @addressline1='742 Evergreen Terrace', @city='Springfield', @county='Greater London', @postalcode='SP1 2AB',
    -- Account Info
    @accountname='Basic Checking', @accounttype='Checking';

    EXECUTE AddCustomer 
    -- Customer Info
    @firstname='Diana', @lastname='Prince', @dob='1988-12-01', 
    @username='dprince', @password='Zp4#L7f%8Nd2', @email='diana.p@email.com',
    -- Address Info
    @addressline1='7 Seaford Road', @city='Manchester', @county='Greater Manchester', @postalcode='M6 6FN',
    -- Account Info
    @accountname='Investment Portfolio', @accounttype='Investment';

----------------------------------------------------------------------------------------------
------------------------------Get customers due in 5 days-----------------------------
-- Check before inserting new payments
EXEC sp_GetUpcomingPayments;

-- Insert pending payments due in less than 5 days
INSERT INTO Transactions (AccountID, TransactionDate, DueDate, CompletionDate, TransactionAmount) VALUES 
(3, GETDATE(), DATEADD(day, 3, GETDATE()), NULL, 50.00),
(4, GETDATE(), DATEADD(day, 3, GETDATE()), NULL, 60.00),
(5, GETDATE(), DATEADD(day, 4, GETDATE()), NULL, 40.00),
(8, GETDATE(), DATEADD(day, 2, GETDATE()), NULL, 70.00);

-- Check again to see the newly inserted upcoming payments
EXEC sp_GetUpcomingPayments;

----------------------------------------------------------------------------------------------
------------------------Trigger Test to close account----------------------------------
-- Check a Loan account before the final payment
SELECT AccountID, AccountName, AccountStatus FROM Accounts WHERE AccountID = 8;

-- Simulate paying off the final scheduled transaction for that loan
UPDATE Transactions 
SET CompletionDate = GETDATE() 
WHERE AccountID = 8 AND CompletionDate IS NULL;

-- Check the Loan account after the payment 
SELECT AccountID, AccountName, AccountStatus FROM Accounts WHERE AccountID = 8;
----------------------------------------------------------------------------------------------
---------------------------Update customers details-------------------------------------
SELECT Username, EmailAddress, PhoneNumber
FROM Customers
WHERE Username = 'jdoe85'

EXEC sp_UpdateCustomerDetails
@Username =  'jdoe85',
@NewEmail = 'john.doe.new@email.com'

SELECT Username, EmailAddress, PhoneNumber
FROM Customers
WHERE Username = 'jdoe85'

--=====================================================================================================
--====================================7. ADDITIONAL QUERIES==============================================
--=====================================================================================================

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
---------------- Function to calculate the exact overdue penalty -------------------
CREATE FUNCTION fn_CalculateOverdueAmount (
    @DueDate DATE, 
    @CompletionDate DATE
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @DaysOverdue INT = 0;
    DECLARE @DailyRate DECIMAL(18,2) = 2.50; -- Our assumed daily penalty rate
    DECLARE @TotalPenalty DECIMAL(18,2) = 0.00;

    IF @CompletionDate IS NULL 
        SET @DaysOverdue = DATEDIFF(day, @DueDate, GETDATE());
    ELSE 
        SET @DaysOverdue = DATEDIFF(day, @DueDate, @CompletionDate);

    IF @DaysOverdue > 0
        SET @TotalPenalty = @DaysOverdue * @DailyRate;

    RETURN @TotalPenalty;
END;
GO
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-------- Create the Stored Procedure to update the OverdueFees table ----------
CREATE PROCEDURE sp_UpdateAllOverdueFees
AS
BEGIN
    UPDATE f
    SET 
        f.TotalOwed = dbo.fn_CalculateOverdueAmount(t.DueDate, t.CompletionDate),
        
        f.DaysOverdue = CASE 
            WHEN t.CompletionDate IS NULL THEN DATEDIFF(day, t.DueDate, GETDATE())
            ELSE DATEDIFF(day, t.DueDate, t.CompletionDate)
        END
    FROM OverdueFees f
    JOIN Transactions t ON f.TransactionID = t.TransactionID
    WHERE t.DueDate < GETDATE(); 
    
    PRINT 'Overdue Fees have been successfully updated.';
END;
GO

----------------------------------------------------------------------------------------------
---------------------------------Calculate overdue fees---------------------------------
-- Calculate a fee for 10 days overdue
SELECT dbo.fn_CalculateOverdueAmount(DATEADD(day, -10, GETDATE()), NULL) AS CalculatedFee;

----------------------------------------------------------------------------------------------
------------------------------Update over due fees test-------------------------------
-- Look at the data before the update
SELECT FeeID, DaysOverdue, TotalOwed, OutstandingBalance FROM OverdueFees;

-- Execute the procedure
EXEC sp_UpdateAllOverdueFees;

-- Look at the data after the update
SELECT FeeID, DaysOverdue, TotalOwed, OutstandingBalance FROM OverdueFees;