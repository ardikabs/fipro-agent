
if [[ "$(whoami)" != "root" ]]; then
	echo "You must be root to run this script"
	exit 1
fi

if [[ $# -ne 3 ]]; then
	echo "Wrong number of arguments supplied"
	echo "Usage: $0 <server_url> <api_key> <deploy_key>"
	exit 1
fi

CURRENT_DIR=`dirname "$(readlink -f "$0")"`
SERVER_URL=$1
API_KEY=$2
DEPLOY_KEY=$3

export SCRIPT_DIR=$PWD/script
export DOCKER_DIR=$PWD/docker
export DATA_DIR=$PWD/data

curl -s -X POST -H "Content-Type: application/json" -d "{
	\"deploy_key\": \"$DEPLOY_KEY\",
    \"api_key\": \"$API_KEY\"
}" $SERVER_URL/api/v1/agent/ > /tmp/agent.json

IP_SERVER=$(cat /tmp/agent.json | python3 -c 'import sys,json;obj=json.load(sys.stdin);print (obj["ip_server"])')
IP_AGENT=$(cat /tmp/agent.json | python3 -c 'import sys,json;obj=json.load(sys.stdin);print (obj["ip_agent"])')
IDENTIFIER=$(cat /tmp/agent.json | python3 -c 'import sys,json;obj=json.load(sys.stdin);print (obj["identifier"])')

install_docker(){
    echo ">>>> Docker Engine Installation >>>>"
    
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
    echo ">>>> Initialize Directory for Sensor Purpose >>>>"

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

    chown -R 3500:3500 $PWD

    sleep 3
}

setup_ssh(){
    echo ">>>> Change SSH Port 22 to 2222 >>>>"
    sudo apt-get install openssh-server
    sed -i 's/Port 22/Port 2222/g' /etc/ssh/sshd_config
    sudo /etc/init.d/ssh restart

    sleep 3
}

setup_cronjob(){
    # Inserting Cronjob for Deleting Schedule
    sudo crontab -u fipro -l | { cat; echo "0 0 * * * bash /var/fipro/agent/script/log_deleter.sh"; } | crontab -
}

setup_fluentbit(){
    # Set Fluentbit Configuration
    sed -i 's/@SET ip_fluentd=<ip_fluentd>/@SET ip_fluentd='$IP_SERVER'/g' $DOCKER_DIR/fluentbit/conf/fluent-bit.conf
    sed -i 's/@SET ip_host=<ip_host>/@SET ip_host='$IP_AGENT'/g' $DOCKER_DIR/fluentbit/conf/fluent-bit.conf
    sed -i 's/@SET identifier=<uid>/@SET identifier='$IDENTIFIER'/g' $DOCKER_DIR/fluentbit/conf/fluent-bit.conf
}

create_user(){
    sudo addgroup --gid 3500 fipro
    sudo adduser --system --no-create-home --shell /bin/bash --uid 3500 --disabled-password \
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
    sudo -u fipro bash -c docker-compose -f $DOCKER_DIR/docker-compose.yml up -d

    sleep 3

    # clear
    echo ">>> Agent Installation Done <<<"
}


main(){
    create_user
    install_docker
    setup_dir
    setup_ssh    
    setup_fluentbit
    setup_cronjob
    composer
}

main