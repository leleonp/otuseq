process REMOVE_HOMOPOLYMERS {
    tag "Removing homopolymers from ${sample_id}"
    container "community.wave.seqera.io/library/biopython_pandas:dbbdf93e473af259"

    input:
        tuple val(sample_id), path(R1), path(R2)

    output:
        path "*_R1_noh.fastq.gz", emit: forw_read
        path "*_R2_noh.fastq.gz", emit: rev_read


    script:
        """
        homopolymer_removal.py $R1 $R2
        """
}
