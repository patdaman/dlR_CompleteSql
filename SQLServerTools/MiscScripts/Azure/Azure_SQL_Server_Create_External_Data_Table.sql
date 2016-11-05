USE master
GO

CREATE LOGIN testAccount 
	WITH PASSWORD = 'test123!' 
GO

USE TestDB
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'FWmydoh*VKFSscy0eAhNsBn4d,PjvnO$&trs5$7Ub5iVQbN,w3z8pWeVdJIDfLviUoA$3U,*R7ikKDbkMmTKo$00H$,2UGZ9LQmI'; 
GO

CREATE DATABASE SCOPED CREDENTIAL AnalyticsTest 
WITH IDENTITY = 'testAccount', 
SECRET = 'test123!';  
GO

CREATE EXTERNAL DATA SOURCE ANALYTICS WITH 
    (TYPE = RDBMS, 
    LOCATION = 'analytics-dev.database.windows.net', 
    DATABASE_NAME = 'SGNL_ANALYTICS', 
    CREDENTIAL = AnalyticsTest, 
) ;

CREATE EXTERNAL TABLE [dbo].[enum_GainDel_source] 
( 	[id] [nvarchar](50) NOT NULL,
	[Item] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](100) NULL,
	[Active] [bit] NOT NULL) 
WITH 
( DATA_SOURCE = ANALYTICS) ;
GO

USE MASTER
GO

ALTER DATABASE SGNL_ANALYTICS
    SET REMOTE_DATA_ARCHIVE = ON
        (
            SERVER = '<server_name>' ,
            CREDENTIAL = <db_scoped_credential_name>
        ) ;
GO;