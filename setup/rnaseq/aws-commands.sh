mkdir -p rnaseq/ref
cd rnaseq/ref

aws s3 --no-sign-request cp s3://ngi-igenomes/igenomes/Drosophila_melanogaster/Ensembl/BDGP6/Sequence/WholeGenomeFasta/genome.fa genome.fa
aws s3 --no-sign-request cp s3://ngi-igenomes/igenomes/Drosophila_melanogaster/Ensembl/BDGP6/Annotation/Genes/genes.gtf genes.gtf
aws s3 --no-sign-request cp s3://ngi-igenomes/igenomes/Drosophila_melanogaster/Ensembl/BDGP6/Annotation/Genes/genes.bed genes.bed
aws s3 --no-sign-request sync s3://ngi-igenomes/igenomes/Drosophila_melanogaster/Ensembl/BDGP6/Sequence/STARIndex/ STARIndex/
