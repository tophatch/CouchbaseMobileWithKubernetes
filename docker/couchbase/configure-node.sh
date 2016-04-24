set -m

/entrypoint.sh couchbase-server &

sleep 15

curl -v -X POST http://127.0.0.1:8091/pools/default -d memoryQuota=300 -d indexMemoryQuota=300
curl -v http://127.0.0.1:8091/node/controller/setupServices -d services=kv%2Cn1ql%2Cindex
curl -v http://127.0.0.1:8091/settings/web -d port=8091 -d username=$CB_REST_USERNAME -d password=$CB_REST_PASSWORD
curl -X POST -u $CB_REST_USERNAME:$CB_REST_PASSWORD -d name=sync_gateway -d ramQuotaMB=300 -d authType=sasl -d replicaNumber=1 http://127.0.0.1:8091/pools/default/buckets

#see if there is a server live on the service already, if there is connect to it
if timeout 30 couchbase-cli server-info --cluster=$COUCHBASE_SERVICE_HOST:$COUCHBASE_SERVICE_PORT &>/dev/null ; then

  export IP=`hostname -I`

  sleep 15

  echo "Joining cluster"
  couchbase-cli server-add --cluster=$COUCHBASE_SERVICE_HOST:$COUCHBASE_SERVICE_PORT --server-add=$IP --service=data,index,query --server-add-username=$CB_REST_USERNAME --server-add-password=$CB_REST_PASSWORD

  sleep 10
  echo "Rebalancing cluster"
  couchbase-cli rebalance -c $COUCHBASE_SERVICE_HOST:$COUCHBASE_SERVICE_PORT
    
  echo ok > /tmp/joined_cluster
else
  echo "First node in cluster"
  echo ok > /tmp/joined_cluster
fi

fg 1

