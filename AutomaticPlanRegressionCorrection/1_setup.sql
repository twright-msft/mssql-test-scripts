USE WideWorldImporters
GO

DROP PROCEDURE IF EXISTS [dbo].[report]
GO
CREATE PROCEDURE [dbo].[report] ( @packagetypeid INT )
AS
    BEGIN
	DECLARE @X FLOAT
        SELECT  @X=AVG([UnitPrice] * [Quantity] - [TaxRate])
        FROM    [Sales].[OrderLines]
        WHERE   [PackageTypeID] = @packagetypeid;
    END;
GO

DROP PROCEDURE IF EXISTS [dbo].[regression]
GO
CREATE PROCEDURE [dbo].[regression]
AS
    BEGIN
        DBCC FREEPROCCACHE;
        BEGIN
            DECLARE @packagetypeid INT = 1;
            EXEC [report] @packagetypeid;
        END;
    END;
GO