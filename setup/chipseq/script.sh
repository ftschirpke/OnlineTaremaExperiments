cd $(dirname $0)

kubectl exec download-pod -- mkdir -p chipseq/input

# copy data csvs to download-pod
kubectl cp chip_seq_data.csv download-pod:/input/workflow-inputs/chipseq/input
kubectl cp chip_seq_data_small.csv download-pod:/input/workflow-inputs/chipseq/input
# download chipseq git repository
kubectl exec download-pod -- /bin/sh -c "`cat git-commands.sh`"
# overwrite chipseq config
kubectl cp modules.config download-pod:/input/workflow-inputs/chipseq/chipseq/conf/modules.config

# copy list of accession numbers to download-pod
kubectl cp accession_nb.txt download-pod:/input/workflow-inputs/chipseq/input
# download and extract data from NCBI's SRA
echo "Start downloading data from SRA..."
kubectl exec download-pod -- /bin/sh -c "`cat sra-commands.sh`"

# download reference data from AWS
kubectl exec download-pod -- /bin/sh -c "`cat aws-commands.sh`"
