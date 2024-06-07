# Use the official OpenJDK image from the Docker Hub
FROM openjdk:17-jdk-slim

# Install necessary packages and add Microsoft repository for SQL Server
RUN apt-get update && \
    apt-get install -y curl gnupg2 apt-transport-https software-properties-common wget && \
    curl https://packages.microsoft.com/keys/microsoft.asc | tee /etc/apt/trusted.gpg.d/microsoft.asc && \
    add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/20.04/mssql-server-2022.list)" && \
    curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | tee /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y mssql-server mssql-tools18 unixodbc-dev&& \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables for the SQL Server setup
ENV ACCEPT_EULA=Y
ENV SA_PASSWORD=YourStrong!Passw0rd123
ENV MSSQL_PID=Developer
# Add /opt/mssql-tools18/bin/ to PATH for login sessions
RUN echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile

# Add /opt/mssql-tools18/bin/ to PATH for interactive/non-login sessions
RUN echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc

# Source the .bashrc file to update the PATH
RUN /bin/bash -c "source ~/.bashrc"

# Set the working directory
WORKDIR /app

# Copy the Spring Boot application jar to the container
COPY target/dockerDemo-0.0.1-SNAPSHOT.jar /app/dockerDemo-0.0.1-SNAPSHOT.jar

# Copy the initialization SQL script and entrypoint script
COPY setup.sql /app/setup.sql
COPY entrypoint.sh /app/entrypoint.sh

# Make entrypoint script executable
RUN chmod +x /app/entrypoint.sh

# Expose port for Spring Boot application
EXPOSE 8080

# Run the entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"]