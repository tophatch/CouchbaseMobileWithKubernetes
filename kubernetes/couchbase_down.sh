#!/bin/bash

kubectl delete service couchbase
#we leave the sync-gateway service running so it's IP does not change
kubectl delete rc,pod -l name=couchbase &>/dev/null

printf "Waiting for sync-gateway to stop"
while true ; do 
	if kubectl describe pod sync-gateway &>/dev/null ; then
		printf "."
		sleep 2
	else
		printf "\n"
		break
	fi
done

printf "Waiting for couchbase nodes to stop"
while true ; do 
	if kubectl describe pod couchbase-node &>/dev/null ; then
		printf "."
		sleep 2
	else
		printf "\n"
		break
	fi
done

 