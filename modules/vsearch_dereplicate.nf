process VSEARCH_DEREPLICATE {
    publishDir "${params.outdir}/dereplicated", mode: 'copy'
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'
    label 'process_low'

    input:
        path demux_sample_qza

    output:
        path "table.qza", emit: derep_table
        path "rep-seqs.qza", emit: derep_rep_seqs

    script:
        """
        # Merge paired-end sequences
        qiime vsearch merge-pairs \
            --i-demultiplexed-seqs $demux_sample_qza \
            --o-merged-sequences merged-seqs.qza

        qiime vsearch dereplicate-sequences \
            --i-sequences merged-seqs.qza \
            --o-dereplicated-table table.qza \
            --o-dereplicated-sequences rep-seqs.qza
        """
}
