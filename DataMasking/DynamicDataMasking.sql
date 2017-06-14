/*Dynamic Data Masking Demo/Test Script*/

--Create a demo/test data table with columns of different data types
CREATE TABLE Employee_Financial (
Emp_ID INT IDENTITY(1, 1) PRIMARY KEY
,Emp_First_Name NVARCHAR(10) NOT NULL
,Emp_Last_Name NVARCHAR(10) NOT NULL
,Emp_Date_Of_Birth DATETIME NULL
,Emp_Salary INT NULL
,Emp_Email NVARCHAR(50) NULL
,Emp_Employment_Date DATETIME NULL
)

--Create a simple record in the table
INSERT INTO Employee_Financial VALUES ('Janet','Smith','1986-5-11',123456,'sample@sample.com','2002-08-21')

--Show how the results look normally without any masking applied
SELECT * FROM Employee_Financial

--Create a user that will be granted permission to query the table, but the results will be masked for that user.
CREATE USER DDMUser WITHOUT LOGIN;  
GRANT SELECT ON Employee_Financial TO DDMUser;  

--Run the select * query as that new user to show that it currently starts out unmasked
EXECUTE AS USER = 'DDMUser'; SELECT * FROM Employee_Financial; REVERT;

--Create a mask on the last name column which will use the default() function to mask the entire string
ALTER TABLE Employee_Financial  
ALTER COLUMN EMP_Last_Name varchar(10) MASKED WITH (FUNCTION = 'default()');  

--Show the masked results when querying as the masked user
EXECUTE AS USER = 'DDMUser'; SELECT * FROM Employee_Financial; REVERT;

--Show that the normal user is still not masked
SELECT * FROM Employee_Financial;

--Use one of the built in masking functions for an email address field
ALTER TABLE Employee_Financial  
ALTER COLUMN EMP_Email nvarchar(50) MASKED WITH (FUNCTION = 'Email()');

--Show the email masking effect
EXECUTE AS USER = 'DDMUser'; SELECT * FROM Employee_Financial; REVERT;

--Use the built in random masking function
ALTER TABLE Employee_Financial  
ALTER COLUMN EMP_Salary int MASKED WITH (FUNCTION='random(1,9)');

--Show the effect of the random function
EXECUTE AS USER = 'DDMUser'; SELECT * FROM Employee_Financial; REVERT;

--Use the partial built in function
ALTER TABLE Employee_Financial  
ALTER COLUMN EMP_First_name nvarchar(10) MASKED WITH (FUNCTION= 'partial(3,"XXXX",3)');

--Show the effect
EXECUTE AS USER = 'DDMUser'; SELECT * FROM Employee_Financial; REVERT;

--Use default() to mask datetime fields
ALTER TABLE Employee_Financial  
ALTER COLUMN EMP_Date_Of_Birth datetime MASKED WITH (FUNCTION = 'default()');

--Show the effect: 1900-01-01 00:00:00.000 instead of XXXX
EXECUTE AS USER = 'DDMUser'; SELECT * FROM Employee_Financial; REVERT;
