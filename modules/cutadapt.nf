process CUTADAPT {
    tag "Cutadapt on $sample_id"
    container 'community.wave.seqera.io/library/cutadapt:4.9--6438e6d7a026e467'
    label 'process_low'

    input:
        tuple val(sample_id), path(forward), path(reverse)
        val forward_primer
        val reverse_primer

    output:
        path("${sample_id}_ATCG_L001_R{1,2}_001.fastq.gz"), emit: trimmed_reads
        path "${sample_id}_cutadapt.log", emit: logs

    script:
        """
        cutadapt -g $forward_primer -G $reverse_primer \
            -o ${sample_id}_ATCG_L001_R1_001.fastq.gz -p ${sample_id}_ATCG_L001_R2_001.fastq.gz \
            $forward $reverse > ${sample_id}_cutadapt.log
        """
}
