-- setup.sql

-- Create the database as specified in your application.properties
CREATE DATABASE DatabaseName;
GO

-- Use the newly created database
USE DatabaseName;
GO

-- Create login
CREATE LOGIN appLogin WITH PASSWORD = 'Password123#';
GO

-- Create user for the database
CREATE USER appUser FOR LOGIN appLogin;
GO

-- Grant necessary permissions
ALTER ROLE db_owner ADD MEMBER appUser;
GO
