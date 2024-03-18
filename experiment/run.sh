#!/usr/bin/env bash

results_dir=/experiments/bachelor_results
namespace=ftschirpke

# workflows=( rnaseq chipseq sarek )
# workflows=( sarek )
#
# workflows=( Synthetic_Blast Synthetic_Bwa Synthetic_Cycles Synthetic_Genome Synthetic_Montage Synthetic_Seismology Synthetic_Soykb )
workflows=( rnaseq )
# workflows=( Synthetic_Montage )

# runs=( rankminrr benchmark_tarema online_tarema benchmark_tarema_exp online_tarema_exp )
# runs=( rankminrr benchmark_tarema online_tarema )
# runs=( rankminrr benchmark_tarema_exp online_tarema_exp )
# runs=( benchmark_tarema_exp online_tarema_exp )
# runs=( rankminrr )
runs=( rankminrr benchmark_tarema benchmark_tarema_exp )

# reruns=3
reruns=1

waitForNodes(){
    # Confirm that all nodes are ready before starting
    SECONDS_BETWEEN_CHECKS=10

    while true; do
        NOT_READY_COUNT=$(kubectl get nodes --no-headers | grep -v "Ready" | wc -l)
        TOTAL_NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
        READY_COUNT=$((TOTAL_NODE_COUNT - NOT_READY_COUNT))

        if [ "$NOT_READY_COUNT" -eq 0 ]; then
            echo "All nodes are ready!"
            break
        else
            echo "$READY_COUNT out of $TOTAL_NODE_COUNT nodes are ready. $NOT_READY_COUNT nodes are not ready yet. Waiting..."
        fi

        sleep "$SECONDS_BETWEEN_CHECKS"
    done
}

collectData() {
    experiment=$1
    workflow=$2
    cp /input/data/output/report.html $experiment/report.html
    cp /input/data/output/trace.csv $experiment/trace.csv
    cp /input/data/output/dag.html $experiment/dag.html
    cp /input/data/output/timeline.html $experiment/timeline.html
    cp -r /input/scheduler $experiment/scheduler
    cp -r launch $experiment/
    cp workflows/$workflow/nextflow.config $experiment/nextflow.config
}

cleanup(){
    kubectl delete ds -l app=nextflow --wait
    kubectl delete pods -l app=nextflow --wait
    kubectl delete pods -l nextflow.io/app=nextflow --wait
    rm /input/data -rf
    rm launch -rf
    kubectl delete pod workflow-scheduler --wait
}

for workflow in "${workflows[@]}"
do
    for run in "${runs[@]}"
    do
        trial=1
        while [ $trial -le $reruns ]
        do
            experiment=/experiments/bachelor_results/$workflow/$run/$trial
            if [ ! -d "$experiment/launch" ]; then
                break
            fi
            echo "Skipping $workflow $run $trial"
            trial=$(($trial+1))
        done
        if [ $trial -gt $reruns ]; then
            continue
        fi

        waitForNodes

        rm /input/data -rf
        rm /input/scheduler -rf

        echo "workflow: $workflow: loading to cache"
        kubectl create -f $workflow/loadToCache.yaml -n $namespace
        kubectl rollout status daemonset workflow-prepare -n $namespace
        kubectl delete -f $workflow/loadToCache.yaml --wait -n $namespace

        while [ $trial -le $reruns ]
        do
            start=$(date '+%Y-%m-%d--%H-%M-%S')
            experiment=/experiments/bachelor_results/$workflow/$run/$trial
            if [ -d "$experiment/launch" ]; then
                trial=$(($trial+1))
                continue
            else
                rm $experiment -rf
                mkdir -p $experiment
            fi

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
            waitForNodes

            nextflow run /input/workflows/$workflow $profile \
                -c /experiments/experiment/$workflow/nextflow.config \
                -c /experiments/experiment/configs/nextflow_$run.config \
                -c /experiments/experiment/configs/nextflow_main.config

            echo "workflow: $workflow $run ($trial): workflow finished, collecting results"

            cd ..

            error=false
            # check that all nodes are ready and the workflow did not fail/was influenced because of a failed node
            # Only increase and store results, if this condition is met
            NOT_READY_COUNT=$(kubectl get nodes --no-headers | grep -v "Ready" | wc -l)
            if [ "$NOT_READY_COUNT" -eq 0 ]; then
                # store data
                echo "workflow: $workflow $run ($trial): storing data"
                collectData $experiment $workflow
            else
                error=true
                echo "workflow: $workflow $run ($trial): not all nodes are ready, retrying"
            fi

            echo "workflow: $workflow $run ($trial): cleaning up"
            cleanup

            if ! grep -q "Workflow execution completed successfully" "$experiment/report.html"; then
                error=true
                echo "workflow: $workflow $run ($trial): workflow failed, retrying"
                mv $experiment $experiment-failed-$start
            fi

            if [ "$error" = false ] ; then
                trial=$(($trial+1))
            fi
        done
    done
done
