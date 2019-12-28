#!/bin/bash
set -Eeuo pipefail
set -o xtrace

PASSWORD=""
if [ ! -z ${MONGODB_CLUSTER_ADMIN_PASSWORD+x} ]; then
    echo $MONGODB_CLUSTER_ADMIN_PASSWORD
    PASSWORD="--password $MONGODB_CLUSTER_ADMIN_PASSWORD"
fi
USER=""
if [ ! -z ${MONGODB_CLUSTER_ADMIN_USER+x} ]; then
    echo $MONGODB_CLUSTER_ADMIN_USER
    USER="--username $MONGODB_CLUSTER_ADMIN_USER"
fi

run_mongo() {
    local command="$1"
    local res=$(
        mongo $USER $PASSWORD --eval $command \
            | egrep -v "MongoDB shell version|Percona Server for MongoDB|connecting to:|Implicit session:|MongoDB server version|WARNING:"
    )
    echo $res
}

check_if_in_rs() {
    local status=$(run_mongo "JSON.stringify(rs.status())")
    local ok=$(echo $status \
            | jq '.ok'
    )

    if [ $ok = "1" ]; then
        true
    else
        false
    fi
}

check_status() {
    local status=$(run_mongo "JSON.stringify(db.serverStatus())")
    local ok=$(echo $status \
            | jq '.ok'
    )

    if [ $ok = "1" ]; then
        true
    else
        false
    fi
}

if check_if_in_rs; then
    echo "in rs";
else 
    echo "not in RS";
    exit 1
fi

if check_status; then
    echo "status is ok";
else 
    echo "status is not ok";
    exit 1
fi

exit 0
