--STEP 1: What OS are we running on?
select host_platform from sys.dm_os_host_info;

--STEP 2: Create a DB to hold our data and model for this demo
create database sqlpydemo
go
use sqlpydemo

-- STEP 3: Setup table for holding data:
create table iris_data (
		id int not null identity primary key
		, "Sepal.Length" float not null, "Sepal.Width" float not null
		, "Petal.Length" float not null, "Petal.Width" float not null
		, "Species" varchar(100) not null, "SpeciesId" int not null
);

-- STEP 4: Setup table for holding model(s):
create table iris_models (
	model_name varchar(30) not null default('default model') primary key,
	model varbinary(max) not null
);

-- STEP 5: Create a stored procedure to get the Iris data set
create procedure get_iris_dataset
as
begin
	-- Return iris dataset from Python to SQL:
	execute   sp_execute_external_script
					@language = N'Python'
				  , @script = N'
from sklearn import datasets

iris = datasets.load_iris()
iris_data = pandas.DataFrame(iris.data)
iris_data["Species"] = pandas.Categorical.from_codes(iris.target, iris.target_names)
iris_data["SpeciesId"] = iris.target
'
				  , @input_data_1 = N''
				  , @output_data_1_name = N'iris_data'
					with result sets (("Sepal.Length" float not null, "Sepal.Width" float not null
				  , "Petal.Length" float not null, "Petal.Width" float not null, "Species" varchar(100) not null, "SpeciesId" int not null));
end;

-- STEP 6: Populate data into the iris_data table using the stored procedure
insert into iris_data ("Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width", "Species", "SpeciesId")
exec dbo.get_iris_dataset;

-- STEP 7: Show the data in the iris_data table
select top(10) * from iris_data;

-- STEP 8: Create a stored procedure to create the model using the Naive Bayes algo
create or alter procedure generate_iris_model (@trained_model varbinary(max) OUTPUT)
as
begin
	execute sp_execute_external_script
	  @language = N'Python'
	, @script = N'
import pickle
from sklearn.naive_bayes import GaussianNB
GNB = GaussianNB()
trained_model = pickle.dumps(GNB.fit(iris_data[[0,1,2,3]], iris_data[[4]]))
'
	, @input_data_1 = N'select "Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width", "SpeciesId" from iris_data'
	, @input_data_1_name = N'iris_data'
	, @params = N'@trained_model varbinary(max) OUTPUT'
	, @trained_model = @trained_model OUTPUT;
end;

-- STEP 9: Generate model using the stored procedure and store the resulting model in the iris_models table as a binary blob
declare @model varbinary(max);
exec generate_iris_model @model OUTPUT;
insert into iris_models (model_name, model) values('Naive Bayes', @model);
select * from iris_models;

-- STEP 10: Create a stored procedure to predict the species using the specified algo
create procedure predict_species (@model varchar(100))
as
begin
	declare @nb_model varbinary(max) = (select model from iris_models where model_name = @model);
	-- Predict species based on the specified model:
	exec sp_execute_external_script 
					@language = N'Python'
				  , @script = N'
import pickle
irismodel = pickle.loads(nb_model)
species_pred = irismodel.predict(iris_data[[1,2,3,4]])
iris_data["PredictedSpecies"] = species_pred
#OutputDataSet = iris_data.query( ''PredictedSpecies != SpeciesId'' )[[0, 5, 6]]
OutputDataSet = iris_data[[0, 5, 6]]

print(OutputDataSet)
'
	, @input_data_1 = N'
	select id, "Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width", "SpeciesId"
	  from iris_data'
	, @input_data_1_name = N'iris_data'
	, @params = N'@nb_model varbinary(max)'
	, @nb_model = @nb_model
	with result sets ( ("id" int, "SpeciesId" int, "SpeciesId.Predicted" int));
end;

-- STEP 11: Test the model
exec predict_species 'Naive Bayes';












-- CLEAN UP FROM THE DEMO
use master
go
alter database sqlpydemo set RESTRICTED_USER with ROLLBACK IMMEDIATE;
drop database if exists sqlpydemo;