# Contenedorización de Aplicación Springboot en java

En este respositorio podran lograr ver una aplicación de prueba
de springboot para demonstrar como contenerizar nuestr aplicación

## Pre-requisitos 

----

1. Tener [Docker](https://www.docker.com/get-started/) Instalado

2. Se tiene que definir un _Dockerfile_ en nuestro caso se encuentra
en el folder principal de el repositorio

    ```dockerfile
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
    COPY target/<NOMBRE-PROYECTO>-0.0.1-SNAPSHOT.jar /app/<NOMBRE-PROYECTO>-0.0.1-SNAPSHOT.jar
    
    
    # Copy the initialization SQL script and entrypoint script
    COPY setup.sql /app/setup.sql
    COPY entrypoint.sh /app/entrypoint.sh
    
    # Make entrypoint script executable
    RUN chmod +x /app/entrypoint.sh
    
    # Expose port for Spring Boot application
    EXPOSE <APP PORT> 
    
    # Run the entrypoint script
    ENTRYPOINT ["/app/entrypoint.sh"]
    ```
   
3. Se tiene que definir un entrypoint.sh para poder definir los pasos de configuración
    ```shell
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
    exec java -jar /app/<NOMBRE-PROYECTO>-0.0.1-SNAPSHOT.jar
    ```
4. Hay que definir un setup.sql para crear la base de datos de los servicios
al igual que crear el login definido en `application.properties`

    ```properties
    spring.application.name=appName
    spring.datasource.url=jdbc:sqlserver://localhost:1433;databaseName=DatabaseName;encrypt=true;trustServerCertificate=true
   # Puede ser cual sea
    spring.datasource.username=appLogin
   # Puede ser cual sea
    spring.datasource.password=Password123#
    spring.datasource.driver-class-name=com.microsoft.sqlserver.jdbc.SQLServerDriver
   # Puede ser cual sea
    spring.jpa.show-sql=true
   # Puede ser cual sea
    spring.jpa.hibernate.ddl-auto=create-drop
    spring.jpa.properties.hibernate.format_sql=true
   # Puede ser cual sea
    spring.jpa.generate-ddl=true
    ```
    ```sql
    -- setup.sql
        
    -- Create the database as specified in your application.p roperties
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
    ```
      
## Pasos 

---

1. Asegurarse que se haya aplicación generado un .jar con `maven package`
2. Asegurarse que todos las declaraciones en los archivos esten de acuerdo con los nombres de los archivos
en sus equipos locales para sus proyectos
3. Correr en el directorio de el proyecto

    ```shell
    # Construirlo
    docker build -t <NOMBRE-PROYECTO> .
    # Correrlo
    docker run -p <PORT>:<PORT> --rm <NOMBRE-PROYECTO>
    ```
   
   Se deberia de poder acceder desde un cliente como postman
   ![postmanscreenshot](https://i.postimg.cc/CM2RYDMg/Screenshot-2024-06-07-001051.png)
   __la logica no es correcta__

4. Crear cuenta en [Google Cloud](https://console.cloud.google.com/)
5. Subir tu imagen a [Google Artifact Registry](https://cloud.google.com/artifact-registry/docs/docker/pushing-and-pulling)
6. Seguir los siguientes pasos

![](https://i.postimg.cc/8k7hhTjT/Screenshot-2024-06-07-001420.png) 
Haz click en Create Service
![](https://i.postimg.cc/8zSMQWwC/Screenshot-2024-06-07-001437.png) 
Elige la imagen que subiste
![](https://i.postimg.cc/dtdrxn2X/Screenshot-2024-06-07-001454.png) 
Haz click en aqui para permitir solicitudes sin autenticacion
![](https://i.postimg.cc/c1PfhPnw/Screenshot-2024-06-07-001557.png) 
_ASEGURATE DE DEJAR 1 MAXIMO PARA EVITAR COSTOS_

## Limitaciones

Cabe recalcar que, este metodo no es prático para la aplicación, dado que no
estamos desplegando un binario que se ejecuta en el servidor en conjunto con nuestra
instancia de base de datos, si no que le estamos proporcionando una imagen a un servicio de contenedroes
que sabe como instanciar un contenedor con la imagen que nosotros construimos.

Es decir que no existe una instancia central de la aplicación, existen cuantas
instancias sean necesarias para cumplir con el trafico que tiene el servicio

En nuestro caso como pusimos la maxima instancia como 0 es posible que nuestra
instancia sea apagada si no hay trafico y dependiendo de las configuraciones
puede hacer que se pierda los datos de tu aplicación y en general comportamiento
no esperado