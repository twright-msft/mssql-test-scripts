--
-- Microsoft Data Amp, India | 3 May 2017
--
-- Python demo in SQL Server 2017
--
-- The cardinal rule of information science:
-- Don't bring the data to your computation if you can help it. Bring your computation to your data instead.
--
-- More info:
-- https://blogs.technet.microsoft.com/dataplatforminsider/2017/04/19/python-in-sql-server-2017-enhanced-in-database-machine-learning/

-- SQL Server 2017 provides in-database analytics and machine learning services with R and Python.
-- Python can now be used within SQL Server to perform analytics, run machine learning models,
-- or handle nearly any kind of data-powered work.
-- 
--
-- Why Python in SQL Server?
-- Python is one of the most popular languages for data science and has a rich ecosystem of powerful libraries.
-- Users can now build machine learning models using the language of their choice: R or Python
--
-- Eliminate data movement: eliminates barriers of security, compliance, governance, integrity, and a host of similar issues related to moving vast amounts of data around.
-- Easy deployment: Deploying Python models is easy: embed it in a T-SQL script that any SQL client application can call to take advantage of Python-based models and intelligence.
-- Enterprise-grade performance & scale: use SQL Server�s advanced capabilities like in-memory table and column store indexes with the high-performance scalable APIs in RevoScalePy package. RevoScalePy is modeled after RevoScaleR package in SQL Server R Services.
-- Rich extensibility: install and run any open source Python packages in SQL Server to build deep learning and AI applications on huge amounts of data in SQL Server.
-- Wide availability at no additional costs: available in all editions of SQL Server 2017
--


USE TutorialDB;

-- Table containing ski rental data
SELECT * FROM [dbo].[rental_data];

-------------------------- STEP 1 - Setup model table ----------------------------------------
DROP TABLE IF EXISTS rental_py_models;
GO
CREATE TABLE rental_py_models (
                model_name VARCHAR(30) NOT NULL DEFAULT('default model') PRIMARY KEY,
                model VARBINARY(MAX) NOT NULL
);
GO

-------------------------- STEP 2 - Train model ----------------------------------------
-- DATA SCIENTIST OR DATABASE ADMINISTRATOR --
-- Create a stored procedure that trains and generates an R model using the rental_data and a decision tree algorithm
-- Data to train the model comes from the table: dbo.rental_data
--
DROP PROCEDURE IF EXISTS generate_rental_py_model;
go
CREATE PROCEDURE generate_rental_py_model (@trained_model varbinary(max) OUTPUT)
AS
BEGIN
    EXECUTE sp_execute_external_script
      @language = N'Python'
    , @script = N'

df = rental_train_data

# Get all the columns from the dataframe.
columns = df.columns.tolist()


# Store the variable well be predicting on.
target = "RentalCount"

from sklearn.linear_model import LinearRegression

# Initialize the model class.
lin_model = LinearRegression()
# Fit the model to the training data.
lin_model.fit(df[columns], df[target])

import pickle
#Before saving the model to the DB table, we need to convert it to a binary object
trained_model = pickle.dumps(lin_model)
'

    , @input_data_1 = N'select "RentalCount", "Year", "Month", "Day", "WeekDay", "Snow", "Holiday" from dbo.rental_data where Year < 2015'
    , @input_data_1_name = N'rental_train_data'
    , @params = N'@trained_model varbinary(max) OUTPUT'
    , @trained_model = @trained_model OUTPUT;
END;
GO

------------------- STEP 3 - Save model to table -------------------------------------
-- DATA SCIENTIST OR DATABASE ADMINISTRATOR --
-- Run stored procedure 'generate_rental_py_model' to generate the model and save it in the database
--
TRUNCATE TABLE rental_py_models;

DECLARE @model VARBINARY(MAX);
EXEC generate_rental_py_model @model OUTPUT;

INSERT INTO rental_py_models (model_name, model) VALUES('linear_model', @model);

SELECT * FROM rental_py_models;

------------------ STEP 4  - Use the model to predict number of rentals --------------------------
-- DATA SCIENTIST OR DATABASE ADMINISTRATOR --
-- Create a stored procedure that uses the generated model to predict "RentalCount_Predicted"
--
DROP PROCEDURE IF EXISTS py_predict_rentalcount;
GO
CREATE PROCEDURE py_predict_rentalcount (@model varchar(100))
AS
BEGIN
	DECLARE @py_model varbinary(max) = (select model from rental_py_models where model_name = @model);

	EXEC sp_execute_external_script 
					@language = N'Python'
				  , @script = N'


import pickle
rental_model = pickle.loads(py_model)

  
df = rental_score_data
#print(df)

# Get all the columns from the dataframe.
columns = df.columns.tolist()
# Filter the columns to remove ones we dont want.
# columns = [c for c in columns if c not in ["Year"]]

# Store the variable well be predicting on.
target = "RentalCount"

# Generate our predictions for the test set.
lin_predictions = rental_model.predict(df[columns])
print(lin_predictions)

# Import the scikit-learn function to compute error.
from sklearn.metrics import mean_squared_error
# Compute error between our test predictions and the actual values.
lin_mse = mean_squared_error(lin_predictions, df[target])
#print(lin_mse)

import pandas as pd
predictions_df = pd.DataFrame(lin_predictions)  
OutputDataSet = pd.concat([predictions_df, df["RentalCount"], df["Month"], df["Day"], df["WeekDay"], df["Snow"], df["Holiday"], df["Year"]], axis=1)
'
	, @input_data_1 = N'Select "RentalCount", "Year" ,"Month", "Day", "WeekDay", "Snow", "Holiday"  from rental_data where Year = 2015'
	, @input_data_1_name = N'rental_score_data'
	, @params = N'@py_model varbinary(max)'
	, @py_model = @py_model
	with result sets (("RentalCount_Predicted" float, "RentalCount" float, "Month" float,"Day" float,"WeekDay" float,"Snow" float,"Holiday" float, "Year" float));
			  
END;
GO

---------------- STEP 5 - Create DB table to store predictions -----------------------
-- DATABASE ADMINISTRATOR --
-- Create a table to store the predictions
--
DROP TABLE IF EXISTS [dbo].[py_rental_predictions];
GO
--Create a table to store the predictions in
CREATE TABLE [dbo].[py_rental_predictions](
	[RentalCount_Predicted] [int] NULL,
	[RentalCount_Actual] [int] NULL,
	[Month] [int] NULL,
	[Day] [int] NULL,
	[WeekDay] [int] NULL,
	[Snow] [int] NULL,
	[Holiday] [int] NULL,
	[Year] [int] NULL
) ON [PRIMARY]
GO

---------------- STEP 6 - Save the predictions in a DB table -----------------------
-- DATABASE USER OR CLIENT APPLICATION --
-- Execute stored procedure 'py_predict_rentalcount' insert the predictions into 'py_predict_rentalcount'
TRUNCATE TABLE py_rental_predictions;
--Insert the results of the predictions for test set into a table
INSERT INTO py_rental_predictions
EXEC py_predict_rentalcount 'linear_model';

-- Select contents of the table
SELECT * FROM py_rental_predictions;


