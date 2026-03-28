/*
Create Database and Schemas
二二二三二二二三二二二二＝
Script Purpose:
This script creates a new database named 'DataWarehouse' after checking if it already exists.
If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas within the database: 'bronze' , 'silver', and 'gold'.
WARNING:
Running this script will drop the entire 'DataWarehouse' database if it exists.
All data in the database will be permanently deleted. Proceed with caution and ensure you have proper backups before running this script.
*/



USE master;
GO
-- Drop and recreate the 'DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'dataWarehouse')
BEGIN
  ALTER DATABASE dataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  DROP DATABASE dataWarehouse;
END;
GO
-- Create the 'DataWarehouse' database
CREATE DATABASE dataWarehouse;
GO
USE dataWarehouse;
GO
-- Create Schemas
CREATE SCHEMA Bronze;
GO
CREATE SCHEMA Silver;
GO
CREATE SCHEMA Gold;
GO
