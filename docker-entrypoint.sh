#!/bin/sh

CONFIG_FILE="/mosquitto/config/mosquitto.conf"
PASSWORD_FILE="/mosquitto/config/passwords.txt"

# execute mosquitto
if [ "$1" = 'mosquitto' ]; then
    # if the config directory is empty copy there the default configuration
    if [ ! "$(ls -A /mosquitto/config)" ]; then
        echo -e "Deploying default configuration..."
        cp -Rf default_config/* /mosquitto/config
    fi
    
    # add broker users provided by the env variable (in the format user1:password1\nuser2:password2)
    if [ -n "$EGEOFFREY_GATEWAY_USERS" ]; then 
        echo -e "Configuring users..."
        echo -e $EGEOFFREY_GATEWAY_USERS > $PASSWORD_FILE
        mosquitto_passwd -U $PASSWORD_FILE
        sed -i -E "s/^#password_file (.+)$/password_file \1/" $CONFIG_FILE
        sed -i -E "s/^#allow_anonymous (.+)$/allow_anonymous false/" $CONFIG_FILE
    else
        echo "" > $PASSWORD_FILE
        sed -i -E "s/^password_file (.+)$/#password_file \1/" $CONFIG_FILE
        sed -i -E "s/^allow_anonymous (.+)$/#allow_anonymous false/" $CONFIG_FILE
    fi
    
    # enable ACLs
    if [ -n "$EGEOFFREY_GATEWAY_ACL" ]; then 
        echo -e "Enabling ACLs..."
        sed -i -E "s/^#acl_file (.+)/acl_file \1/" $CONFIG_FILE
    else
        sed -i -E "s/^acl_file (.+)/#acl_file \1/" $CONFIG_FILE
    fi


    # replace placeholders in configuration
    echo -e "Generating configuration file..."

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
    if [ "$REMOTE_EGEOFFREY_GATEWAY_SSL" = "1" ]; then
        sed -i -E "s/^#bridge_capath (.+)$/bridge_capath \1/" $CONFIG_FILE
    else
        sed -i -E "s/^bridge_capath (.+)$/#bridge_capath \1/" $CONFIG_FILE
    fi

    # set house id
    if [ -z "$EGEOFFREY_ID" ] || [ -z "$REMOTE_EGEOFFREY_ID" ]; then
        echo "ERROR: no local/remote house id provided"
        exit 1
    fi
    sed -i "s/REMOTE_EGEOFFREY_ID/$REMOTE_EGEOFFREY_ID/g" $CONFIG_FILE
    sed -i "s/EGEOFFREY_ID/$EGEOFFREY_ID/g" $CONFIG_FILE

    # set house passcode
    if [ -n "$EGEOFFREY_PASSCODE" ]; then
        sed -i -E "s/^#local_password EGEOFFREY_PASSCODE/local_password $EGEOFFREY_PASSCODE/" $CONFIG_FILE
    else
        sed -i -E "s/^local_password EGEOFFREY_PASSCODE/#local_password $EGEOFFREY_PASSCODE/" $CONFIG_FILE
    fi
    if [ -n "$REMOTE_EGEOFFREY_PASSCODE" ]; then
        sed -i -E "s/^#remote_password REMOTE_EGEOFFREY_PASSCODE/remote_password $REMOTE_EGEOFFREY_PASSCODE/" $CONFIG_FILE
    else
        sed -i -E "s/^remote_password REMOTE_EGEOFFREY_PASSCODE/#remote_password $REMOTE_EGEOFFREY_PASSCODE/" $CONFIG_FILE
    fi

    # run user setup script if found
    if [ -f "./docker-init.sh" ]; then 
        echo -e "Running init script..."
        ./docker-init.sh
    fi
    # start mosquitto
    echo -e "Starting moquitto..."
    chown -R mosquitto.mosquitto /mosquitto
    exec /usr/sbin/mosquitto -c /mosquitto/config/mosquitto.conf 
fi


# execute configured command
exec "$@"
