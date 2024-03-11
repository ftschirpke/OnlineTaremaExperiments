cd rnaseq-big

nohup sh -c 'cat samples.txt | parallel -j 20 "echo download {}; fastq-dump --gzip --split-files {};"' &
