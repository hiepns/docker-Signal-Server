FROM ubuntu:18.04

RUN apt-get update
RUN apt-get install -y coturn
CMD ["/bin/bash", "-c", "turnserver -a --prod -v -n --no-dtls --no-tls -u signalchik:signalchik -r 'someRealm'"]
