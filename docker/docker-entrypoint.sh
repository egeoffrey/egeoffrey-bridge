#!/bin/sh

# if the config directory is empty copy there the default configuration
if [ ! "$(ls -A /bridge/config)" ]; then
    echo -e "Deploying default configuration..."
    cp -Rf /bridge/default-config/* /bridge/config
fi
# replace placeholders in configuration
echo -e "Generating configuration file..."
CONFIG_FILE=/bridge/config/mosquitto.conf
# set gateway hostname
if [ -z "$EGEOFFREY_GATEWAY_HOSTNAME" ]; then
    EGEOFFREY_GATEWAY_HOSTNAME="egeoffrey-gateway"
fi
sed -i "s/EGEOFFREY_GATEWAY_HOSTNAME/$EGEOFFREY_GATEWAY_HOSTNAME/g" $CONFIG_FILE
# set gateway port
if [ -n "$EGEOFFREY_GATEWAY_CA_CERT" ]; then
    EGEOFFREY_GATEWAY_PORT=8883
else
    EGEOFFREY_GATEWAY_PORT=1883
fi
sed -i "s/EGEOFFREY_GATEWAY_PORT/$EGEOFFREY_GATEWAY_PORT/g" $CONFIG_FILE
# set house id
if [ -z "$EGEOFFREY_ID" ]; then
    EGEOFFREY_ID="default_house"
fi
sed -i "s/EGEOFFREY_ID/$EGEOFFREY_ID/g" $CONFIG_FILE
# set house passcode
if [ -n "$EGEOFFREY_PASSCODE" ]; then
    sed -i "s/#local_password EGEOFFREY_PASSCODE/local_password $EGEOFFREY_PASSCODE/g" $CONFIG_FILE
    sed -i "s/#remote_password EGEOFFREY_PASSCODE/remote_password $EGEOFFREY_PASSCODE/g" $CONFIG_FILE
fi
# set ca file
if [ -n "$EGEOFFREY_GATEWAY_CA_CERT" ]; then
    sed -i "s/#bridge_cafile \/mosquitto\/config\/ca.crt/bridge_cafile \/mosquitto\/config\/ca.crt/g" $CONFIG_FILE
fi
# set cert file
if [ -n "$EGEOFFREY_GATEWAY_CERTFILE" ]; then
    sed -i "s/#bridge_cafile \/mosquitto\/config\/ca.crt/bridge_cafile \/mosquitto\/config\/ca.crt/g" $CONFIG_FILE
fi
# set key file
if [ -n "$EGEOFFREY_GATEWAY_KEYFILE" ]; then
    sed -i "s/#bridge_keyfile \/mosquitto\/config\/client.key/bridge_keyfile \/mosquitto\/config\/client.key/g" $CONFIG_FILE
fi

# execute configured command
exec "$@"