cd $(dirname $0)

# real workflows
bash setup-inputs.sh chipseq
bash setup-inputs.sh rnaseq-big
bash setup-inputs.sh rnaseq-small
bash setup-inputs.sh sarek
