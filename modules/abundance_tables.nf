process ABUNDANCE_TABLES {
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'
    label 'process_low'

    input:
        tuple val(level), path(filtered_table), path(taxonomy)

    output:
        path "level-${level}-table.qza"
        path "level-${level}/*"

    script:
        """
        qiime taxa collapse \
            --i-table $filtered_table \
            --i-taxonomy $taxonomy \
            --p-level $level \
            --o-collapsed-table level-${level}-table.qza
        qiime tools export \
            --input-path level-${level}-table.qza \
            --output-path level-${level}
        """
}