if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <workflow-name>"
    exit 1
fi

cd $(dirname $0)

workflow=$1
if [[ ! -d $workflow ]]; then
    echo "Workflow name can only be one of the following:"
    find . -maxdepth 1 -type d -not -name "." | sed 's/.\//- /'
    echo "Usage: $0 <workflow-name>"
    exit 1
fi

echo "=== Setting up inputs for $workflow ==="

kubectl wait pod download-pod --for=condition=Ready --timeout=10s && pod_ready=true || pod_ready=false
if [[ $pod_ready == false ]]; then
    echo "Download pod is not ready."
    echo "Please check the pod status and try again."
    exit 1
fi

bash $workflow/script.sh
