cd /nfs/sarek/input

nohup sh -c 'cat samplesSmall.txt | parallel -j 2000 "echo download {}; fastq-dump --gzip --split-files {};"' &
