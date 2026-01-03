process RAREFACTION {
    tag "Generating rarefaction curves"
    container "895739677619.dkr.ecr.us-east-1.amazonaws.com/otuseq-rarefaction:1.0.0"
    conda 'bioconda::qiime2 bioconda::biom-format conda-forge::numpy'
    label 'process_medium'
    publishDir "${params.outdir}/rarefaction", mode: 'copy'

    input:
        path table
        path tree

    output:
        path 'alpha-rarefaction.qzv'
        path 'rarefaction_curves/*'

    script:
        """
        # Export table to calculate max depth (suppress qiime output)
        qiime tools export \
            --input-path $table \
            --output-path temp_table > /dev/null 2>&1

        # Calculate median depth
        MAX_DEPTH=\$(python3 -c "
import biom
import numpy as np
table = biom.load_table('temp_table/feature-table.biom')
sums = table.sum(axis='sample')
print(int(np.median(sums)))
")

        # Clean up temp files
        rm -rf temp_table

        echo "Using max rarefaction depth: \$MAX_DEPTH"

        # Generate rarefaction curves
        qiime diversity alpha-rarefaction \
            --i-table $table \
            --i-phylogeny $tree \
            --p-max-depth \$MAX_DEPTH \
            --p-steps 20 \
            --p-metrics shannon \
            --p-metrics chao1 \
            --p-metrics observed_features \
            --p-metrics ace \
            --o-visualization alpha-rarefaction.qzv

        # Export visualization
        qiime tools export \
            --input-path alpha-rarefaction.qzv \
            --output-path rarefaction_curves
        """
}
