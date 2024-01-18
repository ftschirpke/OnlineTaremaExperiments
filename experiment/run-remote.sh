cd $(dirname $0)

export KUBECONFIG="secrets/kubeconfig.yaml"
namespace=ftschirpke

bash cleanup.sh

# setup remote cluster
kubectl apply -f cluster/accounts.yaml -n $namespace
kubectl apply -f cluster/pvc.yaml -n $namespace
kubectl apply -f cluster/nextflow-pod.yaml -n $namespace
kubectl wait --timeout=100s --for=condition=ready pod nextflow -n $namespace
kubectl exec -n $namespace nextflow -- bash -c "apk add tar rsync openssh sshpass"
kubectl exec -n $namespace nextflow -- bash -c "cd /usr/local/bin/ && curl -LO 'https://dl.k8s.io/release/v1.28.3/bin/linux/amd64/kubectl' && chmod 700 kubectl"

# upload experiment data and scripts to remote cluster
for entry in run.sh nextflow.config configs/ cluster/
do
    echo "Copying $entry to remote cluster"
    kubectl cp -n $namespace ./$entry $namespace/nextflow:/experiments/experiment/$entry
done

results_dir=/experiments/bachelor_results
logname=$(date +%Y%m%d-%H%M%S).log
# run experiment on remote cluster
kubectl exec -n $namespace nextflow -- bash -c "mkdir -p $results_dir && nohup bash run.sh &> $results_dir/$logname & echo 'Successfully started remote experiment. DONE.'"
