### EGEOFFREY ###

### define base image
ARG ARCHITECTURE
FROM $ARCHITECTURE/eclipse-mosquitto

### expose the data folder into a static location
RUN mkdir -p /bridge && ln -s /mosquitto/config /bridge/config && ln -s /mosquitto/data /bridge/data && ln -s /mosquitto/log /bridge/logs && rm -f /bridge/config/mosquitto.conf
VOLUME ["/bridge/config", "/bridge/data", "/bridge/logs"]

### copy in the default config
COPY docker/config /bridge/default-config
COPY docker/docker-entrypoint.sh /docker-entrypoint.sh

### expose ports
EXPOSE 443 1883 8883
