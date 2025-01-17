process ABUNDANCE_TABLES {
    publishDir "${params.outdir}/abundance", mode: 'copy'
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'

    input:
        path filtered_table

    output:
        path 'abundance_tables/*'

    script:
        """
        mkdir abundance_tables
        for level in 2 3 4 5 6 7; do
            qiime taxa collapse \
                --i-table $filtered_table \
                --p-level \$level \
                --o-collapsed-table abundance_tables/level-\${level}-table.qza
            qiime tools export \
                --input-path abundance_tables/level-\${level}-table.qza \
                --output-path abundance_tables/level-\${level}
        done
        """
}