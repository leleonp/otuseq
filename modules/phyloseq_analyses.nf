process PHYLOSEQ_ANALYSES {
    tag "Running phyloseq-based analyses"
    conda "bioconda::bioconductor-phyloseq=1.46.0 conda-forge::r-base=4.4 conda-forge::r-openxlsx conda-forge::r-vegan bioconda::bioconductor-biomformat conda-forge::r-ape conda-forge::r-inext conda-forge::r-tidyverse conda-forge::r-ggplot2 conda-forge::r-dplyr conda-forge::r-tidyr"
    label 'process_medium'
    publishDir "${params.outdir}", mode: 'copy', pattern: "{abundance_tables,taxonomy_plots,rarefaction,alpha_diversity,beta_diversity}/**"

    input:
        path phyloseq_rds

    output:
        path 'abundance_tables/*.xlsx', emit: excel
        path 'taxonomy_plots/*.{pdf,png}', emit: plots
        path 'rarefaction/*', emit: rarefaction
        path 'alpha_diversity/**/*', emit: alpha
        path 'beta_diversity/**/*', emit: beta
        path 'analysis_log.txt', emit: log

    script:
        """
        # Create output directory structure
        mkdir -p abundance_tables taxonomy_plots rarefaction alpha_diversity beta_diversity

        # Run all analyses
        phyloseq_analyses.R \\
            ${phyloseq_rds} \\
            . \\
            > analysis_log.txt 2>&1

        echo "=== Analysis Complete ===" >> analysis_log.txt
        echo "Date: \$(date)" >> analysis_log.txt
        echo "" >> analysis_log.txt
        echo "Generated files:" >> analysis_log.txt
        echo "  Excel tables: \$(ls -1 abundance_tables/*.xlsx 2>/dev/null | wc -l)" >> analysis_log.txt
        echo "  Taxonomy plots: \$(ls -1 taxonomy_plots/*.{pdf,png} 2>/dev/null | wc -l)" >> analysis_log.txt
        echo "  Rarefaction files: \$(ls -1 rarefaction/* 2>/dev/null | wc -l)" >> analysis_log.txt
        echo "  Alpha diversity: \$(find alpha_diversity -type f 2>/dev/null | wc -l)" >> analysis_log.txt
        echo "  Beta diversity: \$(find beta_diversity -type f 2>/dev/null | wc -l)" >> analysis_log.txt
        """
}
