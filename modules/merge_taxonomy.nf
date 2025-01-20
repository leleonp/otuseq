process MERGE_TAXONOMY {
    publishDir "${params.outdir}/merged_taxonomy", mode: 'copy'
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'
    label 'process_medium'
    label 'error_retry'

    input:
        path "*_taxonomy.qza"

    output:
        path "merged_taxonomy.qza"

    script:
    """
    # Create a manifest file listing all input taxonomy files
    ls *_taxonomy.qza > taxonomy_manifest.txt

    # Merge taxonomy artifacts
    qiime feature-table merge-taxa \
        --i-data @taxonomy_manifest.txt \
        --o-merged-data merged_taxonomy.qza
    """
}