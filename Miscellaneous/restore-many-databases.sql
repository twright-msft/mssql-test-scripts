declare @i int
set @i=2
declare @restorestmt NCHAR(4000)
while (@i< 200)
Begin
set @restorestmt= 'RESTORE DATABASE AdventureWorks2008R2_'+convert(nvarchar,@i) + ' FROM  DISK = ''F:\backup\adventure-works-2008r2-oltp.bak''' +  ' WITH  FILE = 1,  MOVE ''AdventureWorks2008R2_Data'' TO ''F:\data\AdventureWorks2008r2_'+convert(nvarchar,@i)+'_Data.mdf'','  +  ' MOVE ''AdventureWorks2008R2_Log'' TO ''G:\log\AdventureWorks2008R2_'+convert(nvarchar,@i)+'LOG.ldf'''
select @restorestmt
execute sp_executesql @restorestmt
set @i = @i+1;
end