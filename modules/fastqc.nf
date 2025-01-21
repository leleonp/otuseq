process FASTQC {
    tag "FASTQC on $sample_id"
    container 'public.ecr.aws/biocontainers/fastqc:0.12.1--hdfd78af_0'
    label 'process_low'

    
    input:
        tuple val(sample_id), path(R1), path(R2)  

    output:
        path "*_fastqc.{zip,html}", emit: fastqc_results

    script:
        """
        fastqc -q $R1 
        fastqc -q $R2
        """
}