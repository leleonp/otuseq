process CHIMERA_FILTERING {
    tag "Removing chimeric sequences with VSEARCH"
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'
    label 'process_medium'

    input:
        path table
        path rep_seqs

    output:
        path 'nonchimeric-table.qza', emit: table
        path 'nonchimeric-rep-seqs.qza', emit: rep_seqs
        path 'chimeras.qza', emit: chimeras

    script:
        """
        qiime vsearch uchime-denovo \
            --i-table $table \
            --i-sequences $rep_seqs \
            --o-chimeras chimeras.qza \
            --o-nonchimeras nonchimeric-rep-seqs.qza \
            --o-stats chimera-stats.qza

        qiime feature-table filter-features \
            --i-table $table \
            --m-metadata-file nonchimeric-rep-seqs.qza \
            --o-filtered-table nonchimeric-table.qza
        """
}
