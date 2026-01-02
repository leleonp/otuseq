process TAXONOMY_BARPLOTS {
    tag "Generating taxonomy barplots for all levels"
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'
    label 'process_low'
    publishDir "${params.outdir}/taxonomy_plots", mode: 'copy'

    input:
        path table
        path taxonomy

    output:
        path 'taxa-bar-plots.qzv'
        path 'taxa_barplots/*'

    script:
        """
        # Generate interactive barplots
        qiime taxa barplot \
            --i-table $table \
            --i-taxonomy $taxonomy \
            --o-visualization taxa-bar-plots.qzv

        # Export the visualization
        qiime tools export \
            --input-path taxa-bar-plots.qzv \
            --output-path taxa_barplots
        """
}
