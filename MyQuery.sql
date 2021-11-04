--
SELECT * FROM Core.Users u ORDER BY u.Id DESC
SELECT * FROM Core.Users u WHERE u.Id in (476,927)

--ALTER DATABASE RPSI SET TRUSTWORTHY OFF
--SELECT * FROM sys.configurations WHERE name = 'clr enabled'
--SELECT * from sys.dm_clr_properties
--SELECT * from sys.dm_clr_appdomains
--SELECT * from sys.dm_clr_tasks
--SELECT * from sys.dm_clr_loaded_assemblies