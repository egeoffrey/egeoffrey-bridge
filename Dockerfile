### EGEOFFREY ###

### define base image
ARG ARCHITECTURE
FROM $ARCHITECTURE/eclipse-mosquitto

### define workdir
ENV WORKDIR=/bridge
WORKDIR $WORKDIR

### install dependencies
RUN apk update && apk add ca-certificates openssl && rm -rf /var/cache/apk/*

### expose ports
EXPOSE 443 1883 8883

### copy in the files
COPY . $WORKDIR

### expose the data folder into a static location
RUN ln -s /mosquitto/config config \
  && ln -s /mosquitto/data data \
  && ln -s /mosquitto/log logs \
  && rm -f /bridge/config/mosquitto.conf \
  && chown -R mosquitto.mosquitto /bridge
VOLUME ["/bridge/config", "/bridge/data", "/bridge/logs"]

ENTRYPOINT ["sh", "docker-entrypoint.sh"]
CMD ["mosquitto"]
