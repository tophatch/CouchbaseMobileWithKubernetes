# Overview

The goal of this project is develop a [Kubernetes](http://kubernetes.io/) configuration for
[Couchbase Server](http://www.couchbase.com/nosql-databases/couchbase-server) and 
[Couchbase Sync Gateway](http://www.couchbase.com/nosql-databases/couchbase-mobile) to make 
deployment and management of a cluster using these technologies as simple as possible. These
instructions are based on using the community edition of Couchbase.

# Getting Started

This section will walk through the steps to deploy the configuration in this repo to 
[Google Cloud Platform (GCP)](https://cloud.google.com/). At the moment this has only 
been tested on GCP. 

## Setting up Google Cloud

In order to run things from the command line you need to get setup with the
[Google Cloud SDK](https://cloud.google.com/sdk/overview). Follow the instructions there to
get this installed and setup. 

Create a first project on GCP through the web interface. Make a note of it's name. Set this as 
an environment variable on the commandline:

`export GCP_PROJECT_NAME=your_project_name`
 
And set it as your default project for gcloud:

`gcloud config set project $GCP_PROJECT_NAME`

## Create a cluster

The next step is to create a cluster (a group of machines that will run the services). Decide
on a cluster name and set it as an environment variable:

`export GCP_CLUSTER_NAME=your_cluster_name`
 
Run the following commands to create and inspect the cluster (this creates a default
cluster of 3 machines of the default type):
```
gcloud container clusters create $GCP_CLUSTER_NAME
gcloud container clusters list
gcloud container clusters describe $GCP_CLUSTER_NAME
```

Now set the new cluster as the default cluster:
```
gcloud config set container/cluster $GCP_CLUSTER_NAME
gcloud container clusters get-credentials $GCP_CLUSTER_NAME
```

The cluster is now running and ready for use.

## Creating Docker images

Kubernetes uses [Docker](https://www.docker.com/) to define the containers it runs. To run
Couchbase Server and Couchbase Sync Gateway you need to create a docker container for each.
The docker configuration files are stored in `docker/couchbase` and `docker/sync_gateway`. First you will 
need to [setup docker](http://docs.docker.com/mac/started/) on your machine so that the docker command works.
Then assuming you are in the root directory for this repo. Run the following to create the Couchbase Server 
docker image:

`docker build -t gcr.io/$GCP_PROJECT_NAME/couchbase ./docker/couchbase/`

And then use the following command to push it to the Google Container Registry:

`gcloud docker push gcr.io/$GCP_PROJECT_NAME/couchbase`

Now Repeat this for sync-gateway:

`docker build -t gcr.io/$GCP_PROJECT_NAME/sync-gateway ./docker/sync-gateway/`
`gcloud docker push gcr.io/$GCP_PROJECT_NAME/sync-gateway`

At this point the two docker images have been created and stored in the Google Container Registry.

## Deploying Couchbase to the cluster

The minimum steps necessary to deploy to the cluster are:

Open the file `.\kubernetes\couchbase-node.yml` in a text editor. Change `YOUR_PROJECT_NAME` to 
the name of your GCP project. And change the password called `change_me` and replace it 
with a non-trivial password.

Open the file `.\kubernetes\couchbase-node.yml` in a text editor. Change `YOUR_PROJECT_NAME` to 
the name of your GCP project.

## Starting Couchbase Server and Couchbase Sync Gateway

Starting a 3 node Couchbase Server cluster with a single instance of sync-gateway is as 
simple as running the following script:

`./kubernetes/couchbase_up.sh`

Once this completes run the following command to attach to the running sync_gateway pod and monitor the 
output:

`kubectl attach $(kubectl get pods --no-headers=true -l role=gateway | grep "1/1.*Running" | awk '/sync-gateway-[a-z]*/ {print $1}')`

## Opening the admin interface

This is done separately as it opens the admin interface on the public internet. Start the admin 
service by running the following command:

`kubectl create -f .\kubernetes\couchbase-admin-service.yml`

Run the following command a few times until you see an IP address assigned for couchbase-admin-service:

`kubectl get services` 

You can then connect to the admin interface via http://IP_ADDRESS:8091 The username is Administrator and
the password is the one you set in "Deploying Couchbase to the cluster" above.

You can stop and start this service independently of the rest of the services. The following command will 
delete the service:

`kubectl delete pod couchbase-admin-service`

## Stopping Couchbase Server and Couchbase Sync Gateway

Run the following script to stop Couchbase. NOTE: this will delete ALL of the data in the database.

`./kubernetes/couchbase_down.sh`

It does not stop the Sync Gateway service so that its public IP address persist between restarts. 
You can stop this with the following command:

`kubectl delete service sync-gateway`

# How it works

This section will give a brief summary of how bootstrapping the Couchbase Server works, and
how Couchbase Sync Gateway gets configured.

## Couchbase Server

In order to bring up a cluster of Couchbase Server there first needs to be a single server.
The `couchbase_up.sh` script creates the couchbase service first, so when the startup script
for the Couchbase Server container `./docker/couchbase/configure-node.sh` the environment
variables `$COUCHBASE_SERVICE_HOST` and `$COUCHBASE_SERVICE_PORT` will have the IP and port
from the service. So first the script sets up the basic server. Then it tries to connect 
to another server through the service IP. If this fails, it must be the first server in the 
cluster. The `couchbase_up.sh` script uses a Replication Controller to bring up a single
pod first, once this has finished (determined by the readiness probe) then it scales the RC
to a total of 3 instances.

## Couchbase Sync Gateway

Once the 3 servers are running the `couchbase_up.sh` script moves on to starting up the 
gateway. The start up script for the container `./docker/sync-gateway/configure-node.sh` has
a script that uses `$COUCHBASE_SERVICE_HOST` to do a search and replace on the sync gateway 
config which is stored in `./sync-gateway/sync-gateway-config.json'.









