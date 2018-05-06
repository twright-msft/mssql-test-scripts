create database sqlpydemo;
go
use sqlpydemo;
go
drop table if exists iris_data;
drop table if exists iris_models;
go
-- Setup table for holding data:
create table iris_data (
		id int not null identity primary key
		, "Sepal.Length" float not null, "Sepal.Width" float not null
		, "Petal.Length" float not null, "Petal.Width" float not null
		, "Species" varchar(100) not null, "SpeciesId" int not null
);
-- Setup table for holding model(s):
create table iris_models (
	model_name varchar(30) not null default('default model') primary key,
	model varbinary(max) not null
);
go
create or alter procedure get_iris_dataset
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
go
--truncate table iris_data;
-- Populate data from iris dataset in R:
insert into iris_data ("Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width", "Species", "SpeciesId")
exec dbo.get_iris_dataset;
select top(10) * from iris_data;
select count(*) from iris_data;
go

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
go

--truncate table iris_models;
-- Generate model based on Naive Bayes algorithm:
declare @model varbinary(max);
exec generate_iris_model @model OUTPUT;
insert into iris_models (model_name, model) values('Naive Bayes', @model);
select * from iris_models;
go

create or alter procedure predict_species (@model varchar(100))
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
go

exec predict_species 'Naive Bayes';
go



--select host_platform, host_distribution, host_release from sys.dm_os_host_info;