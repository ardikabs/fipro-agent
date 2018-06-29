#!/bin/bash

if [[ "$(whoami)" != "root" ]]; then
	echo "You must be root to run this script"
	exit 1
fi

if [[ $# -ne 3 ]]; then
	echo "Wrong number of arguments supplied"
	echo "Usage: $0 <server_ip> <agent_ip> <identifier>"
	exit 1
fi

export SCRIPT_DIR=`dirname "$(readlink -f "$0")"`
export AGENT_DIR=`dirname "$(readlink -f $SCRIPT_DIR)"`
export BASE_DIR=`dirname "$(readlink -f $AGENT_DIR)"`
export DOCKER_DIR=$AGENT_DIR/docker
export DATA_DIR=$BASE_DIR/data

SERVER_IP=$1
AGENT_IP=$2
IDENTIFIER=$3

install_docker(){
    echo -e "\n\n>>>> Docker Engine Installation >>>>"
    
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce
    
    # (optional)
    sudo usermod -aG docker fipro
    sleep 2

    echo ">>>> Docker Compose Installation >>>>"
    curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    sleep 3
}

setup_dir(){
    echo -e "\n\n>>>> Initialize Directory for Sensor Purpose >>>>"

    mkdir -p $DATA_DIR/dionaea/log
    mkdir -p $DATA_DIR/dionaea/rtp
    mkdir -p $DATA_DIR/dionaea/binaries
    mkdir -p $DATA_DIR/dionaea/bistreams
    mkdir -p $DATA_DIR/dionaea/roots/www
    mkdir -p $DATA_DIR/dionaea/roots/ftp
    mkdir -p $DATA_DIR/dionaea/roots/tftp
    mkdir -p $DATA_DIR/dionaea/roots/upnp


    mkdir -p $DATA_DIR/glastopf/db
    mkdir -p $DATA_DIR/glastopf/log

    mkdir -p $DATA_DIR/cowrie/log
    mkdir -p $DATA_DIR/cowrie/log/tty
    mkdir -p $DATA_DIR/cowrie/downloads
    mkdir -p $DATA_DIR/cowrie/keys

    chown -R 3500:3500 $BASE_DIR

    sleep 3
}

setup_ssh(){
    echo -e "\n\n>>>> Change SSH Port 22 to 2222 >>>>"
    sudo apt-get install openssh-server
    sed -i 's/Port 22/Port 2222/g' /etc/ssh/sshd_config
    sudo /etc/init.d/ssh restart

    sleep 3
}

setup_cronjob(){
    # Inserting Cronjob for Deleting Schedule
    # Every 00:00
    # sudo crontab -u fipro -l | { cat; echo "0 0 * * * bash /var/fipro/agent/script/log_deleter.sh"; } | crontab -u fipro -

    # Every 12:00
    sudo crontab -u fipro -l | { cat; echo "0 12 * * * bash /var/fipro/agent/script/log_deleter.sh"; } | crontab -u fipro -
}

setup_fluentbit(){
    # Set Fluentbit Configuration
    sed -i 's/@SET fluentd_ip=<fluentd_ip>/@SET fluentd_ip='$SERVER_IP'/g' $DOCKER_DIR/fluentbit/conf/fluent-bit.conf
    sed -i 's/@SET agent_ip=<agent_ip>/@SET agent_ip='$AGENT_IP'/g' $DOCKER_DIR/fluentbit/conf/fluent-bit.conf
    sed -i 's/@SET identifier=<identifier>/@SET identifier='$IDENTIFIER'/g' $DOCKER_DIR/fluentbit/conf/fluent-bit.conf
}

setup_agent(){
    touch $DOCKER_DIR/agent/project/.env
    SECRET=$(python3 -c 'import os;import binascii;print(binascii.hexlify(os.urandom(24)))')
    echo "SERVER_IP=$SERVER_IP" >> $DOCKER_DIR/agent/project/.env
    echo "SECRET_KEY=$SECRET" >> $DOCKER/agent/project/.env
}

create_user(){
    sudo addgroup --gid 3500 fipro
    sudo adduser --system --shell /bin/bash --uid 3500 --disabled-password \
        --disabled-login --gid 3500 fipro
    
    add_sudoers fipro
}

add_sudoers(){
    while [[ -n $1 ]]; do
        echo "$1 ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers;
        shift
    done
}

composer(){
    sudo -u fipro docker-compose -f $DOCKER_DIR/docker-compose.yml up -d

    sleep 3
    clear
    echo -e "\n\n>>> Agent Installation Done <<<"
}


main(){
    create_user
    install_docker
    setup_dir
    setup_ssh    
    setup_fluentbit
    setup_cronjob
    setup_agent
    composer
}

main