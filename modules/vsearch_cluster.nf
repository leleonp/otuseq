process VSEARCH_CLUSTER {
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'
    label 'process_low'

    input:
        path derep_table
        path derep_rep_seqs

    output:
        path "clustered-table.qza", emit: clustered_table
        path "clustered-rep-seqs.qza", emit: clustered_rep_seqs

    script:
        """
        qiime vsearch cluster-features-de-novo \
            --i-table $derep_table \
            --i-sequences $derep_rep_seqs \
            --p-perc-identity 0.97 \
            --o-clustered-table clustered-table.qza \
            --o-clustered-sequences clustered-rep-seqs.qza
        """
}
