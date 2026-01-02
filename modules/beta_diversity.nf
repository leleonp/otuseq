process BETA_DIVERSITY {
    tag "Calculating beta diversity and PCoA"
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'
    label 'process_medium'

    input:
        path table
        path tree

    output:
        path 'bray_curtis_distance.qza', emit: bray_curtis
        path 'jaccard_distance.qza', emit: jaccard
        path 'weighted_unifrac_distance.qza', emit: weighted_unifrac, optional: true
        path 'unweighted_unifrac_distance.qza', emit: unweighted_unifrac, optional: true
        path 'bray_curtis_pcoa.qza', emit: bray_curtis_pcoa
        path 'jaccard_pcoa.qza', emit: jaccard_pcoa
        path 'weighted_unifrac_pcoa.qza', emit: weighted_unifrac_pcoa, optional: true
        path 'unweighted_unifrac_pcoa.qza', emit: unweighted_unifrac_pcoa, optional: true
        path 'beta_diversity/*'

    script:
        """
        # Bray-Curtis dissimilarity
        qiime diversity beta \
            --i-table $table \
            --p-metric braycurtis \
            --o-distance-matrix bray_curtis_distance.qza

        qiime diversity pcoa \
            --i-distance-matrix bray_curtis_distance.qza \
            --o-pcoa bray_curtis_pcoa.qza

        # Jaccard distance
        qiime diversity beta \
            --i-table $table \
            --p-metric jaccard \
            --o-distance-matrix jaccard_distance.qza

        qiime diversity pcoa \
            --i-distance-matrix jaccard_distance.qza \
            --o-pcoa jaccard_pcoa.qza

        # Weighted UniFrac distance (phylogenetic)
        # Use error handling as UniFrac can crash on some datasets
        qiime diversity beta-phylogenetic \
            --i-table $table \
            --i-phylogeny $tree \
            --p-metric weighted_unifrac \
            --p-threads ${task.cpus} \
            --o-distance-matrix weighted_unifrac_distance.qza || echo "Weighted UniFrac failed, creating placeholder"

        if [ -f weighted_unifrac_distance.qza ]; then
            qiime diversity pcoa \
                --i-distance-matrix weighted_unifrac_distance.qza \
                --o-pcoa weighted_unifrac_pcoa.qza
        fi

        # Unweighted UniFrac distance (phylogenetic)
        qiime diversity beta-phylogenetic \
            --i-table $table \
            --i-phylogeny $tree \
            --p-metric unweighted_unifrac \
            --p-threads ${task.cpus} \
            --o-distance-matrix unweighted_unifrac_distance.qza || echo "Unweighted UniFrac failed, creating placeholder"

        if [ -f unweighted_unifrac_distance.qza ]; then
            qiime diversity pcoa \
                --i-distance-matrix unweighted_unifrac_distance.qza \
                --o-pcoa unweighted_unifrac_pcoa.qza
        fi

        # Export all to TSV
        mkdir -p beta_diversity

        qiime tools export \
            --input-path bray_curtis_distance.qza \
            --output-path beta_diversity/bray_curtis

        qiime tools export \
            --input-path jaccard_distance.qza \
            --output-path beta_diversity/jaccard

        # Export UniFrac results only if they exist
        if [ -f weighted_unifrac_distance.qza ]; then
            qiime tools export \
                --input-path weighted_unifrac_distance.qza \
                --output-path beta_diversity/weighted_unifrac
        fi

        if [ -f unweighted_unifrac_distance.qza ]; then
            qiime tools export \
                --input-path unweighted_unifrac_distance.qza \
                --output-path beta_diversity/unweighted_unifrac
        fi

        qiime tools export \
            --input-path bray_curtis_pcoa.qza \
            --output-path beta_diversity/bray_curtis_pcoa

        qiime tools export \
            --input-path jaccard_pcoa.qza \
            --output-path beta_diversity/jaccard_pcoa

        if [ -f weighted_unifrac_pcoa.qza ]; then
            qiime tools export \
                --input-path weighted_unifrac_pcoa.qza \
                --output-path beta_diversity/weighted_unifrac_pcoa
        fi

        if [ -f unweighted_unifrac_pcoa.qza ]; then
            qiime tools export \
                --input-path unweighted_unifrac_pcoa.qza \
                --output-path beta_diversity/unweighted_unifrac_pcoa
        fi
        """
}
