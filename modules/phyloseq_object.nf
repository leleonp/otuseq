process PHYLOSEQ_OBJECT {
    tag "Creating phyloseq object"
    conda "bioconda::bioconductor-phyloseq=1.46.0 conda-forge::r-base=4.4 conda-forge::r-openxlsx conda-forge::r-vegan bioconda::bioconductor-biomformat conda-forge::r-ape conda-forge::r-tidyverse"
    label 'process_low'
    publishDir "${params.outdir}/phyloseq", mode: 'copy'

    input:
        path filtered_table
        path taxonomy
        path rooted_tree
        path metadata

    output:
        path 'phyloseq_object.rds', emit: rds
        path 'phyloseq_summary.txt', emit: summary

    script:
        """
        # Run the phyloseq creation script
        create_phyloseq.R \\
            ${filtered_table} \\
            ${taxonomy} \\
            ${rooted_tree} \\
            ${metadata} \\
            phyloseq_object.rds \\
            > phyloseq_summary.txt 2>&1

        # Create a summary
        echo "=== Phyloseq Object Created ===" >> phyloseq_summary.txt
        echo "Date: \$(date)" >> phyloseq_summary.txt
        echo "Input files:" >> phyloseq_summary.txt
        echo "  - Table: ${filtered_table}" >> phyloseq_summary.txt
        echo "  - Taxonomy: ${taxonomy}" >> phyloseq_summary.txt
        echo "  - Tree: ${rooted_tree}" >> phyloseq_summary.txt
        echo "  - Metadata: ${metadata}" >> phyloseq_summary.txt
        """
}
