process RAREFACTION {
    tag "Generating rarefaction curves"
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'
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
        # Determine max depth (use median frequency)
        MAX_DEPTH=\$(qiime tools export \
            --input-path $table \
            --output-path temp_table && \
            python3 -c "
import biom
import numpy as np
table = biom.load_table('temp_table/feature-table.biom')
sums = table.sum(axis='sample')
print(int(np.median(sums)))
" && rm -rf temp_table)

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
