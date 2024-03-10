
results_dir=/experiments/bachelor_results
namespace=ftschirpke

# workflows=( rnaseq chipseq sarek )
# workflows=( sarek chipseq )
# workflows=( rnaseq )
# workflows=( chipseq rnaseq )
workflows=( Synthetic_Blast )
# synwfs=( Synthetic_Blast Synthetic_Bwa Synthetic_Cycles Synthetic_Genome Synthetic_Montage Synthetic_Seismology Synthetic_Soykb )

# workflows=( rnaseq sarek chipseq )

run=online_tarema

trial="single-try"

collectData() {
    experiment=$1
    workflow=$2
    cp /input/data/output/report.html $experiment/report.html
    cp /input/data/output/trace.csv $experiment/trace.csv
    cp /input/data/output/dag.html $experiment/dag.html
    cp /input/data/output/timeline.html $experiment/timeline.html
    cp -r launch $experiment/
    cp $workflow/nextflow.config $experiment/nextflow.config
}

for workflow in "${workflows[@]}"
do
    rm /input/data -rf
    rm /input/scheduler -rf

    echo "workflow: $workflow: loading to cache"
    kubectl create -f $workflow/loadToCache.yaml -n $namespace
    kubectl rollout status daemonset workflow-prepare -n $namespace
    kubectl delete -f $workflow/loadToCache.yaml --wait -n $namespace

    start=$(date '+%Y-%m-%d--%H-%M-%S')
    experiment=/experiments/bachelor_results/$workflow/$run/$trial

    rm $experiment -rf
    mkdir -p $experiment

    echo "workflow: $workflow $run ($trial): starting scheduler"
    kubectl apply -f cluster/workflow-scheduler.yaml --wait -n $namespace
    kubectl wait --for=condition=ready pod workflow-scheduler -n $namespace
    nohup kubectl logs workflow-scheduler -f -n $namespace > $experiment/scheduler.log &

    echo "workflow: $workflow $run ($trial): running on cluster"
    # make sure no data is left
    rm launch -rf
    mkdir launch
    cd launch
    profile=""
    #check if a profile is specified
    if [ -f /experiments/experiment/$workflow/profile.txt ]; then
        profile="-profile $(cat /experiments/experiment/$workflow/profile.txt)"
    fi

    nextflow run /input/workflows/$workflow $profile \
        -c /experiments/experiment/$workflow/nextflow.config \
        -c /experiments/experiment/configs/nextflow_$run.config \
        -c /experiments/experiment/configs/nextflow_main.config

    # profile="-profile test"
    # outdir="--outdir /input/data/outdata"
    # nextflow run /input/workflows/$workflow $outdir $profile \
    #     -c /experiments/experiment/configs/nextflow_$run.config \
    #     -c /experiments/experiment/configs/nextflow_main.config

    cd ..
    
    collectData $experiment $workflow
done
