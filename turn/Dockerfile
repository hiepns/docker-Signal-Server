FROM ubuntu:18.04

RUN apt-get update
RUN apt-get install -y coturn
ENV EXTERNAL_IP 0.0.0.0
ENV TURN_REALM turn
ENV TURN_SECRET yoursecret
ENV TURN_LOW 49152
ENV TURN_HIGH 49252
CMD ["/bin/bash", "-c", "turnserver -a --prod -v -n -f --no-dtls --no-tls -r \"${TURN_REALM}\" --mobility --static-auth-secret ${TURN_SECRET} -X ${EXTERNAL_IP} --min-port ${TURN_LOW} --max-port ${TURN_HIGH}"]
