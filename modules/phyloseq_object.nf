process PHYLOSEQ_OBJECT {
    tag "Creating phyloseq object"
    container "895739677619.dkr.ecr.us-east-1.amazonaws.com/otuseq-phyloseq:latest"
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
        def metadata_arg = metadata?.name ? metadata : "no_metadata.csv"
        """
        # Create dummy metadata if not provided
        if [ ! -f "${metadata_arg}" ]; then
            echo "sample-id" > no_metadata.csv
        fi

        # Run the phyloseq creation script
        create_phyloseq.R \\
            ${filtered_table} \\
            ${taxonomy} \\
            ${rooted_tree} \\
            ${metadata_arg} \\
            phyloseq_object.rds \\
            > phyloseq_summary.txt 2>&1

        # Create a summary
        echo "=== Phyloseq Object Created ===" >> phyloseq_summary.txt
        echo "Date: \$(date)" >> phyloseq_summary.txt
        echo "Input files:" >> phyloseq_summary.txt
        echo "  - Table: ${filtered_table}" >> phyloseq_summary.txt
        echo "  - Taxonomy: ${taxonomy}" >> phyloseq_summary.txt
        echo "  - Tree: ${rooted_tree}" >> phyloseq_summary.txt
        echo "  - Metadata: ${metadata_arg}" >> phyloseq_summary.txt
        """
}
