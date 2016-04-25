#!/bin/bash

pushd .

cd kubernetes

kubectl create -f couchbase-service.yml

kubectl create -f couchbase-node.yml

printf "Waiting for first couchbase node to start"
while true ; do 
	if kubectl get pods | grep "couchbase-node-.*1/1.*Running" >/dev/null ; then
		printf "\n"
		break;
	fi
	printf "."
	sleep 2
done

printf "Scaling to 3 couchbase nodes\n"
kubectl scale rc couchbase-node --replicas=3

#must be a better way to wait for a rebalance, but for now this will do
printf "Waiting for rebalance to complete\n"
sleep 60

kubectl create -f sync-gateway-service.yml

kubectl create -f sync-gateway.yml

printf "Waiting for sync-gateway to start"
while true ; do 
	if kubectl get pods | grep "sync-gateway-.*1/1.*Running" >/dev/null ; then
		printf "\n"
		break;
	fi
	printf "."
	sleep 2
done

popd

printf "Concepts cloud is up\n"
