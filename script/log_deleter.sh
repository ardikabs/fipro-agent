
DATA_DIR=/var/fipro/data

cowrie_deleter(){
    rm -rf $DATA_DIR/cowrie/log/cowrie.json.*
    #cat $DATA_DIR/cowrie/log/cowrie.json >> $DATA_DIR/cowrie/log/cowrie.bak
}

glastopf_deleter(){
    rm -rf $DATA_DIR/glastopf/log/glastopf.log.*
    truncate -s 0 $DATA_DIR/glastopf/log/glastopf.log
    #cat $DATA_DIR/glastopf/log/glastopf.log >> $DATA_DIR/glastopf/log/glastopf.log.bak

}

dionaea_deleter(){
    truncate -s 0 $DATA_DIR/dionaea/dionaea-errors.log
    truncate -s 0 $DATA_DIR/dionaea/dionaea.json
    #cat $DATA_DIR/dionaea/dionaea.json >> $DATA_DIR/dionaea/dionaea.json.bak
 
    rm -rf $DATA_DIR/dionaea/binaries/*
    rm -rf $DATA_DIR/dionaea/bistreams/*

}


main(){
    cowrie_deleter
    dionaea_deleter
    glastopf_deleter
    #sudo -u fipro docker restart $(docker ps -q)
}

main