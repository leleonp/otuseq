process CUTADAPT {
    tag "Cutadapt on $sample_id"
    publishDir "${params.outdir}/cutadapt", mode: 'copy'
    container 'public.ecr.aws/biocontainers/cutadapt:4.9--py310h1fe012e_3'
    label 'process_low'

    input:
        tuple val(sample_id), path(forward), path(reverse)

    output:
        path("${sample_id}_ATCG_L001_R{1,2}_001.fastq.gz"), emit: trimmed_reads
        path "${sample_id}_cutadapt.log", emit: logs

    script:
        """
        cutadapt -g ${params.forward_primer} -G ${params.reverse_primer} \
            -o ${sample_id}_ATCG_L001_R1_001.fastq.gz -p ${sample_id}_ATCG_L001_R2_001.fastq.gz \
            $forward $reverse > ${sample_id}_cutadapt.log
        """
}