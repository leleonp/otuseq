process FILTER_TAXA {
    publishDir "${params.outdir}/filtered", mode: 'copy'
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'
    label 'process_low'

    input:
        path table
        path taxonomy

    output:
        path 'filtered-table.qza'

    script:
        """
        qiime taxa filter-table \
            --i-table $table \
            --i-taxonomy $taxonomy \
            --p-exclude ${params.exclude_taxa} \
            --o-filtered-table filtered-table.qza
        """
}