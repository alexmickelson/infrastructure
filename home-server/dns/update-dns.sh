#!/bin/bash

# curl -X GET https://api.cloudflare.com/client/v4/zones/bf7a05315be9bf7a39d50dd4001e7a97/dns_records -H "X-Auth-Email: alexmickelson96@gmail.com" -H "X-Auth-Key: jo7GntHEEBtANFsuteAM8EJ-stLUqyNbOk2x4Czr"  | python -m json.tool

source /home/alex/actions-runner/_work/infrastructure/infrastructure/home-pi/dns/cloudflare.env

NETWORK_INTERFACE=wlan0
IP=$(ip a s $NETWORK_INTERFACE | awk '/inet / {print$2}' | cut -d/ -f1)
EMAIL="alexmickelson96@gmail.com";
ZONE_ID="bf7a05315be9bf7a39d50dd4001e7a97";


update_record() {
    LOCAL_NAME=$1
    LOCAL_RECORD_ID=$2
    
    echo "UPDATING RECORD FOR $LOCAL_NAME TO $IP"

    curl -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$LOCAL_RECORD_ID" \
        -H "X-Auth-Email: alexmickelson96@gmail.com" \
        -H "X-Auth-Key: $CLOUDFLARE_TOKEN" \
        -H "Content-Type: application/json" \
        --data '{"type":"A","name":"'"$LOCAL_NAME"'","content":"'"$IP"'","ttl":1}' \
        | python3 -m json.tool;

    echo
    echo "------------------------------------"
    echo
}

NAME="ha.alexmickelson.guru";
RECORD_ID="09eac5a17fa4302091532dabdbe73a68"
update_record $NAME $RECORD_ID

NAME="jellyfin.alexmickelson.guru";
RECORD_ID="577293ab0488913308fda78010a7483b"
update_record $NAME $RECORD_ID

NAME="next.alexmickelson.guru";
RECORD_ID="cc686333d2421a4e558a04589b375ded"
update_record $NAME $RECORD_ID


