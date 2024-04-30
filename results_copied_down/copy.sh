#!/usr/bin/env bash

cd $(dirname $0)

export KUBECONFIG="../experiment/secrets/kubeconfig.yaml"
namespace=ftschirpke

num=0

while [[ -d "bachelor_results_$num" ]]; do
    num=$((num+1))
done

echo "Copying results to bachelor_results_$num"
kubectl cp $namespace/nextflow:/experiments/bachelor_results bachelor_results_$num
