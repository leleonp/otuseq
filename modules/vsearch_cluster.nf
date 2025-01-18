process VSEARCH_CLUSTER {
    publishDir "${params.outdir}/clustered", mode: 'copy'
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'
    label 'process_low'

    input:
        path derep_table
        path derep_rep_seqs

    output:
        path "${derep_table.simpleName}_clustered-table.qza", emit: clustered_table
        path "${derep_table.simpleName}_clustered-rep-seqs.qza", emit: clustered_rep_seqs

    script:
        """
        qiime vsearch cluster-features-de-novo \
            --i-table $derep_table \
            --i-sequences $derep_rep_seqs \
            --p-perc-identity ${params.perc_identity} \
            --o-clustered-table ${derep_table.simpleName}_clustered-table.qza \
            --o-clustered-sequences ${derep_table.simpleName}_clustered-rep-seqs.qza
        """
}
