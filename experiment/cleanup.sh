#!/usr/bin/env bash

export KUBECONFIG="secrets/kubeconfig.yaml"
namespace=ftschirpke

kubectl exec -n ftschirpke nextflow -- bash -c "rm -rd /experiments/experiment/*"
kubectl exec -n ftschirpke nextflow -- bash -c "rm -rd /experiments/bachelor_results/test"

kubectl delete ds -l app=nextflow --wait
kubectl delete pods -l app=nextflow --wait
kubectl delete pods -l nextflow.io/app=nextflow --wait

