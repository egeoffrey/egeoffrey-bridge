#!/bin/sh

# execute mosquitto
if [ "$1" = 'mosquitto' ]; then
    # if the config directory is empty copy there the default configuration
    if [ ! "$(ls -A config)" ]; then
        echo -e "Deploying default configuration..."
        cp -Rf default_config/* config
    fi

    # replace placeholders in configuration
    echo -e "Generating configuration file..."
    CONFIG_FILE="config/mosquitto.conf"

    # set gateway hostname
    if [ -z "$REMOTE_EGEOFFREY_GATEWAY_HOSTNAME" ]; then
        echo "ERROR: no remote gateway hostname provided"
        exit 1
    fi
    sed -i "s/REMOTE_EGEOFFREY_GATEWAY_HOSTNAME/$REMOTE_EGEOFFREY_GATEWAY_HOSTNAME/g" $CONFIG_FILE

    # set gateway port
    if [ -z "$REMOTE_EGEOFFREY_GATEWAY_PORT" ]; then
        echo "ERROR: no remote gateway port provided"
        exit 1
    fi
    sed -i "s/REMOTE_EGEOFFREY_GATEWAY_PORT/$REMOTE_EGEOFFREY_GATEWAY_PORT/g" $CONFIG_FILE

    # set gateway ssl
    if [ "$REMOTE_EGEOFFREY_GATEWAY_SSL" = "1"]; then
        sed -i "s/#bridge_capath \/etc\/ssl\/certs/bridge_capath \/etc\/ssl\/certs/g" $CONFIG_FILE
    fi

    # set house id
    if [ -z "$EGEOFFREY_ID" ] || [ -z "$REMOTE_EGEOFFREY_ID" ]; then
        echo "ERROR: no local/remote house id provided"
        exit 1
    fi
    sed -i "s/EGEOFFREY_ID/$EGEOFFREY_ID/g" $CONFIG_FILE
    sed -i "s/REMOTE_EGEOFFREY_ID/$REMOTE_EGEOFFREY_ID/g" $CONFIG_FILE

    # set house passcode
    if [ -n "$EGEOFFREY_PASSCODE" ]; then
        sed -i "s/#local_password EGEOFFREY_PASSCODE/local_password $EGEOFFREY_PASSCODE/g" $CONFIG_FILE
    fi
    if [ -n "$REMOTE_EGEOFFREY_PASSCODE" ]; then
        sed -i "s/#remote_password REMOTE_EGEOFFREY_PASSCODE/remote_password $REMOTE_EGEOFFREY_PASSCODE/g" $CONFIG_FILE
    fi

    # copy test CA certificate in /etc/ssl/certs
    cp -f default_config/certs/ca.crt /etc/ssl/certs/eGeoffrey_test_CA.pem

    # rehash certificates in case a custom certificate has been mapped into /etc/ssl/certs
    for file in /etc/ssl/certs/*.pem; do FILE=/etc/ssl/certs/"$(openssl x509 -hash -noout -in "$file")".0 &&  rm -f $FILE && ln -s "$file" $FILE; done
    # run user setup script if found
    if [ -f "./docker-init.sh" ]; then 
        echo -e "Running init script..."
        ./docker-init.sh
    fi
    # start mosquitto
    echo -e "Starting moquitto..."
    exec /usr/sbin/mosquitto -c /mosquitto/config/mosquitto.conf 
fi


# execute configured command
exec "$@"
