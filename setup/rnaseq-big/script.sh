cd $(dirname $0)

kubectl exec download-pod -- mkdir -p rnaseq-big/input
# copy data csvs to download-pod
kubectl cp input.csv download-pod:/input/workflow-inputs/rnaseq-big/input
# download rnaseq-big git repository
kubectl exec download-pod -- /bin/sh -c "`cat git-commands.sh`"
# overwrite rnaseq-big config
kubectl cp modules.config download-pod:/input/workflow-inputs/rnaseq-big/rnaseq/conf/modules.config

# copy list of samples to download-pod
kubectl cp samples.txt download-pod:/input/workflow-inputs/rnaseq-big/input
# download and extract data from NCBI's SRA
echo "Start downloading data from SRA..."
kubectl exec download-pod -- /bin/sh -c "`cat sra-commands.sh`"

# download reference data from AWS
kubectl exec download-pod -- /bin/sh -c "`cat aws-commands.sh`"
