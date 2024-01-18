#!/usr/bin/env bash

# remove old data
rm -rd /input/data

# load to cache  TODO: uncomment this and provide a loadToCache.yaml for each workflow
# echo "workflow: $workflow: loading to cache"
# kubectl apply -f $workflow/loadToCache.yaml -n $namespace
# kubectl rollout status daemonset workflow-prepare -n $namespace
# kubectl delete -f $workflow/loadToCache.yaml --wait -n $namespace

results_dir=/experiments/bachelor_results
experiment_name=test
namespace=ftschirpke

echo "workflow: $experiment_name - starting scheduler"
kubectl apply -f cluster/workflow-scheduler.yaml --wait -n $namespace
kubectl wait --timeout=100s --for=condition=ready pod workflow-scheduler -n $namespace
mkdir -p $results_dir/$experiment_name
nohup kubectl logs workflow-scheduler -f -n $namespace > $results_dir/$experiment_name/scheduler.log &

nextflow run hello
