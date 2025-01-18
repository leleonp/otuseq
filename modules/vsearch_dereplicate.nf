process VSEARCH_DEREPLICATE {
    publishDir "${params.outdir}/dereplicated", mode: 'copy'
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'

    input:
        path demux_sample_qza

    output:
        path "${demux_sample_qza.simpleName}_table.qza", emit: derep_table
        path "${demux_sample_qza.simpleName}_rep-seqs.qza", emit: derep_rep_seqs

    script:
        """
        # Merge paired-end sequences
        qiime vsearch merge-pairs \
            --i-demultiplexed-seqs $demux_sample_qza \
            --o-merged-sequences merged-seqs.qza

        qiime vsearch dereplicate-sequences \
            --i-sequences merged-seqs.qza \
            --o-dereplicated-table ${demux_sample_qza.simpleName}_table.qza \
            --o-dereplicated-sequences ${demux_sample_qza.simpleName}_rep-seqs.qza
        """
}
