#!/bin/bash

# Ensure directories exist and set correct permissions
mkdir -p /var/opt/mssql/.system
chmod -R 777 /var/opt/mssql/.system
chown -R mssql:mssql /var/opt/mssql/.system

# Start SQL Server
/opt/mssql/bin/sqlservr &

# Wait for SQL Server to start up
echo "Waiting for SQL Server to start..."
sleep 30s

# Check if SQL Server started successfully
if [ $(pgrep -c sqlservr) -eq 0 ]; then
  echo "SQL Server failed to start."
  cat /var/opt/mssql/log/errorlog
  exit 1
fi


# Check for PAL initialization errors
if grep -q "PAL initialization failed" /var/opt/mssql/log/errorlog; then
  echo "PAL initialization failed. Printing log files for more information..."
  cat /var/opt/mssql/log/errorlog
  exit 1
fi


# Set SA password and configure SQL Server
MSSQL_SA_PASSWORD="YourStrong!Passw0rd123" /opt/mssql/bin/mssql-conf set-sa-password

# Run setup.sql to initialize database
echo "Running setup.sql..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -d master -i /app/setup.sql -C
if [ $? -ne 0 ]; then
  echo "Failed to execute setup.sql"
  cat /var/opt/mssql/log/errorlog
  exit 1
fi

# Start the Java Spring Boot application
echo "Starting Java Spring Boot application..."
exec java -jar /app/dockerDemo-0.0.1-SNAPSHOT.jar
