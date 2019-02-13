# Signal-Server docker

Docker environment for running Signal-Server.

## Clone repo

Clone this repo:

    git clone https://github.com/khaliullov/Signal-Server-docker.git

## Configure Nginx frontend

Configure nginx frontend:

    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /etc/nginx/certs/domain.ru/fullchain.pem;
        ssl_certificate_key /etc/nginx/certs/domain.ru/privkey.pem;

        server_name s3-signal.domain.ru;

        location / {
            proxy_pass http://127.0.0.1:9000;
            proxy_set_header Host s3-signal.domain.ru;
        }
    }

    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /etc/nginx/certs/domain.ru/fullchain.pem;
        ssl_certificate_key /etc/nginx/certs/domain.ru/privkey.pem;

        server_name textsecure-service.domain.ru;

        location / {
            proxy_pass http://127.0.0.1:8080;
        }

        location /v1/websocket {
            proxy_pass http://127.0.0.1:8080;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "Upgrade";
        }
    }

## Create .env file

Create `.env` file according to example `.env.dist`:

    POSTGRES_USER=signal  # create postgres user with such login
    POSTGRES_PASSWORD=thepassword  # and password
    MINIO_ACCESS_KEY=AKIAIG4ILCORMAJCS37A  # create local S3 with such access key
    MINIO_SECRET_KEY=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  # and secret
    HOST=127.0.0.1  # expose 8080 and 8081 to such host (in this case nginx is frontend)
    EXTERNAL_IP=0.0.0.0  # external IP of a host, because turn server is a behind docker proxy
    TURN_REALM=turn.domain.ru  # turn realm
    TURN_SECRET=test  # turn secret key
    TURN_LOW=49152  # turn minimum UDP port
    TURN_HIGH=49252  # turn maximun UDP port

## Configure Signal server

Create `signalserver/Signal-Server/config/Signal.yml` with following content:

    twilio: # Twilio gateway configuration
      accountId: AC302d9ea2695e21cd17ce15bc510d28fd #fake
      accountToken: febf5ccba3b4051dd7e7d0901a0fd404 #fake
      numbers: # Numbers allocated in Twilio
        - # First number
          +66876157370 #fake
      # messagingServicesId:
      localDomain: domain # Domain Twilio can connect back to for calls. Should be domain of your service.
    
    push:
      queueSize: 200 # Size of push pending queue
    
    # redphone:
    #   authKey: 1234567890 # Deprecated
    
    server:
      applicationConnectors:
        - type: http  # use https and add certificates if you use without nginx and .env:HOST=0.0.0.0
          port: 8080
      adminConnectors:
        - type: http
          port: 8081
    
    turn: # TURN server configuration
      secret: test
      uris:
        - turn:turn.domain.ru:3478
        - turn:turn.domain.ru:3479?transport=udp
    
    cache: # Redis server configuration for cache cluster
      url: "redis://signal-redis:6379/1"
    
    directory: # Redis server configuration for directory cluster
      url: "redis://signal-redis:6379/0"
    
    messageStore: # Postgresql database configuration for message store
      driverClass: org.postgresql.Driver
      user: "signal"
      password: "thepassword"
      url: "jdbc:postgresql://signal-postgresql/messagedb"
    
    attachments: # MINIO configuration
      accessKey: AKIAIG4ILCORMAJCS37A
      accessSecret: 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
      bucket: signal-attachments-buu
      endpoint: https://s3-signal.domain.ru
    
    profiles: # MINIO configuration
      accessKey: AKIAIG4ILCORMAJCS37A
      accessSecret: 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
      bucket: signal-profiles-buu
      region: us-east-1
    
    database: # Postgresql database configuration
      driverClass: org.postgresql.Driver
      user: "signal"
      password: "thepassword"
      url: "jdbc:postgresql://signal-postgresql/accountdb"
      properties:
        charSet: UTF-8
    
    # #apn: # Apple Push Notifications configuration
    #   bundleId:
    #   pushCertificate:
    #   pushKey:
    
    gcm: # GCM Configuration
      senderId: 412918270132
      apiKey: AIzaSyC8gPzceq2SPebZZWaD3I9OeqePyD9CUqk
    
    logging:
      level: INFO
      appenders:
        - type: file
          currentLogFilename: /tmp/textsecureshserver.log
          archivedLogFilenamePattern: /temp/textsecureserver-%d.log.gz
          archivedFileCount: 5
        - type: console

## Start server

Start docker-compose:

    make up

## Provision server

In order to proper work it is required to create S3 buckets:

    make provision
