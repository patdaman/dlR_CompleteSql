set nocount on
declare @databasename varchar(100)
declare @query varchar(max)
declare @login varchar(128)
set @query = ''

set @databasename = 'master'
set @login = 'SGNL\pdelosreyes'

select @query=coalesce(@query,',' )+'kill '+convert(varchar, spid)+ '; '
from master..sysprocesses 
where dbid=db_id(@databasename)
	and loginame = @login

if len(@query) > 0
begin
print @query
	exec(@query)
end