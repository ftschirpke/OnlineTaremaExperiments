cd $(dirname $0)

kubectl exec download-pod -- mkdir -p sarek/input
# copy data csvs to download-pod
kubectl cp input.csv download-pod:/input/workflow-inputs/sarek/input
kubectl cp inputSmall.csv download-pod:/input/workflow-inputs/sarek/input
# download sarek git repository
kubectl exec download-pod -- /bin/sh -c "`cat git-commands.sh`"

# copy list of samples to download-pod
kubectl cp samples.txt download-pod:/input/workflow-inputs/sarek/input
kubectl cp samplesSmall.txt download-pod:/input/workflow-inputs/sarek/input
# download and extract data from NCBI's SRA
echo "Start downloading data from SRA..."
kubectl exec download-pod -- /bin/sh -c "`cat sra-commands.sh`"

# download reference data from AWS
kubectl exec download-pod -- /bin/sh -c "`cat aws-commands.sh`"
