process FILTER_TAXA {
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'
    label 'process_low'

    input:
        path table
        path taxonomy
        val excluded_taxa

    output:
        path 'filtered-table.qza'

    script:
        """
        qiime taxa filter-table \
            --i-table $table \
            --i-taxonomy $taxonomy \
            --p-exclude $excluded_taxa \
            --o-filtered-table filtered-table.qza
        """
}