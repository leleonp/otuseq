process VSEARCH_MERGE {
    publishDir "${params.outdir}/final", mode: 'copy'
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'
    label 'process_low'


    input:
        path clustered_table_files
        path clustered_rep_seq_files

    output:
        path 'final_table.qza', emit: final_table
        path 'final_rep_seqs.qza', emit: final_rep_seqs

    script:
        """
        # Merge feature tables
        qiime feature-table merge \
            --i-tables $clustered_table_files \
            --o-merged-table final_table.qza

        # Merge representative sequences
        qiime feature-table merge-seqs \
            --i-data $clustered_rep_seq_files \
            --o-merged-data final_rep_seqs.qza
        """
}
