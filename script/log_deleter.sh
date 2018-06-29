


cowrie_deleter(){
    rm -rf /var/fipro/data/cowrie/log/cowrie.json.*
}

glastopf_deleter(){
    truncate -s 0 /var/fipro/data/glastopf/log/glastopf.log
}

dionaea_deleter(){
    truncate -s 0 /var/fipro/data/dionaea/dionaea-errors.log
    truncate -s 0 /var/fipro/data/dionaea/dionaea.json
    rm -rf /var/fipro/data/dionaea/binaries/*
    rm -rf /var/fipro/data/dionaea/bistreams/*

}


main(){
    cowrie_deleter
    dionaea_deleter
    glastopf_deleter
    #sudo -u fipro docker restart $(docker ps -q)
}

main