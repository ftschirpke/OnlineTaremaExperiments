mkdir -p chipseq/input/ref
cd chipseq/input/ref

aws s3 --no-sign-request sync s3://ngi-igenomes/igenomes/Homo_sapiens/Ensembl/GRCh37/Sequence/BWAIndex/version0.6.0/ version0.6.0
aws s3 --no-sign-request sync s3://ngi-igenomes/igenomes/Homo_sapiens/Ensembl/GRCh37/Sequence/Bowtie2Index/ Bowtie2Index/
aws s3 --no-sign-request sync s3://ngi-igenomes/igenomes/Homo_sapiens/Ensembl/GRCh37/Sequence/STARIndex/ STARIndex/
aws s3 --no-sign-request cp s3://ngi-igenomes/igenomes/Homo_sapiens/Ensembl/GRCh37/Sequence/WholeGenomeFasta/genome.fa genome.fa
aws s3 --no-sign-request cp s3://ngi-igenomes/igenomes/Homo_sapiens/Ensembl/GRCh37/Annotation/Genes/genes.gtf genes.gtf
aws s3 --no-sign-request cp s3://ngi-igenomes/igenomes/Homo_sapiens/Ensembl/GRCh37/Annotation/README.txt README.txt
