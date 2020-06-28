# Signal-Server Docker Compose and Kubernetes

Docker compose or Kubernetes environment for running Signal-Server.

## Clone repo

Clone this repo:

    git clone https://github.com/khaliullov/docker-Signal-Server.git

## Configure Nginx frontend

Configure nginx frontend:

    client_max_body_size 100M;  # for uploading large attachments
    
    server {  # for attachments
        listen 443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /etc/nginx/certs/domain.ru/fullchain.pem;
        ssl_certificate_key /etc/nginx/certs/domain.ru/privkey.pem;

        server_name s3.domain.ru;

        location / {
            proxy_pass http://127.0.0.1:9000;
            proxy_set_header Host s3-signal.domain.ru;
        }
    }

    server {  # profiles
        listen 443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /etc/letsencrypt/live/domain.ru/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/domain.ru/privkey.pem;

        server_name cdn.domain.ru;

	    location /profiles {
            proxy_pass http://127.0.0.1:9000/signal-profiles-buu/profiles;
            proxy_set_header Host cdn.domain.ru;
        }

        location / {
            proxy_pass http://127.0.0.1:9000/signal-profiles-buu;
            proxy_set_header Host cdn.domain.ru;
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
    REGISTRY=registry.domain.ru/namespace/  # registry for storing Docker images for k8s
    IMAGE_PULL_SECRETS=regcred  # password for accessing registry

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
        - turn:turn.domain.ru:3478?transport=udp
    
    cache: # Redis server configuration for cache cluster
      url: "redis://signal-redis:6379/1"
      replicaUrls:
        - "redis://signal-redis:6379/4"
    
    directory: # Redis server configuration for directory cluster
      url: "redis://signal-redis:6379/0"
      replicaUrls:
        - "redis://signal-redis:6379/5"
    
    pushScheduler:
      url: "redis://signal-redis:6379/6"
      replicaUrls:
        - "redis://signal-redis:6379/7"
    
    messageCache: # Redis server configuration for message store cache
      redis:
        url: "redis://signal-redis:6379/2"
        replicaUrls:
          - "redis://signal-redis:6379/3"
    
    messageStore: # Postgresql database configuration for message store
      driverClass: org.postgresql.Driver
      user: "signal"
      password: "thepassword"
      url: "jdbc:postgresql://signal-postgresql/messagedb"
    
    attachments: # MINIO configuration
      accessKey: AKIAIG4ILCORMAJCS37A
      accessSecret: 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
      bucket: signal-attachments-buu
      endpoint: https://s3.domain.ru
    
    profiles: # MINIO configuration
      accessKey: AKIAIG4ILCORMAJCS37A
      accessSecret: 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
      bucket: signal-profiles-buu
      region: us-east-1
      endpoint: https://s3.domain.ru
    
    database: # Postgresql database configuration
      driverClass: org.postgresql.Driver
      user: "signal"
      password: "thepassword"
      url: "jdbc:postgresql://signal-postgresql/accountdb"
      properties:
        charSet: UTF-8
    
    apn: # Apple Push Notifications configuration
      bundleId: org.whispersystems.securesms
      pushCertificate: |
        -----BEGIN CERTIFICATE-----
        ...
        -----END CERTIFICATE-----
      pushKey: |
        -----BEGIN RSA PRIVATE KEY-----
        ...
        -----END RSA PRIVATE KEY-----
    
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

## Deploy to Kubernetes via Helm

To deploy via Helm you ought to build and publish `signal-server` and
`signal-turn` images to the Kubernetes Docker registry.

After that you may deploy:

    make helm

all values for Helm templates will be used from `.env` file.

## Configuring Ingress

It is required to manually configure Ingress to make everything work.
Sample Ingress configuration:

    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: main-ingress
      annotations:
        kubernetes.io/ingress.class: nginx
        nginx.ingress.kubernetes.io/worker-shutdown-timeout: "60"
        nginx.ingress.kubernetes.io/proxy-body-size: "0"
        certmanager.k8s.io/acme-challenge-type: http0
        certmanager.k8s.io/cluster-issuer: letsencrypt-production
        nginx.org/mergeable-ingress-type: master
    spec:
      tls:
      - hosts:
        - s3.domain.ru
        - cdn.domain.ru
        - textsecure-service.domain.ru
        secretName: certificates-secret
      rules:
      - host: s3.domain.ru
      - host: cdn.domain.ru
      - host: textsecure-service.domain.ru

And apply them:

    kubectl apply -f ingress.yaml
