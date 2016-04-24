#!/bin/bash
set -m

curl -H 'Cache-Control: no-cache' $SYNC_GATEWAY_CONFIG | sed 's/$COUCHBASE_CLUSTER_IP/'"$COUCHBASE_SERVICE_HOST"'/g' > /tmp/sync_gateway_config.json

cat /tmp/sync_gateway_config.json

sync_gateway /tmp/sync_gateway_config.json
