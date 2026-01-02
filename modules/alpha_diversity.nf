process ALPHA_DIVERSITY {
    tag "Calculating alpha diversity indices"
    container 'public.ecr.aws/b1n7j4p9/qiime2:2023.2'
    label 'process_low'

    input:
        path table

    output:
        path 'shannon_vector.qza', emit: shannon
        path 'chao1_vector.qza', emit: chao1
        path 'ace_vector.qza', emit: ace
        path 'simpson_vector.qza', emit: simpson
        path 'observed_features_vector.qza', emit: observed_features
        path 'alpha_diversity/*'

    script:
        """
        # Shannon diversity index
        qiime diversity alpha \
            --i-table $table \
            --p-metric shannon \
            --o-alpha-diversity shannon_vector.qza

        # Chao1 richness estimator
        qiime diversity alpha \
            --i-table $table \
            --p-metric chao1 \
            --o-alpha-diversity chao1_vector.qza

        # ACE richness estimator
        qiime diversity alpha \
            --i-table $table \
            --p-metric ace \
            --o-alpha-diversity ace_vector.qza

        # Simpson diversity index
        qiime diversity alpha \
            --i-table $table \
            --p-metric simpson \
            --o-alpha-diversity simpson_vector.qza

        # Observed features (OTU richness)
        qiime diversity alpha \
            --i-table $table \
            --p-metric observed_features \
            --o-alpha-diversity observed_features_vector.qza

        # Export all to TSV
        mkdir -p alpha_diversity

        qiime tools export \
            --input-path shannon_vector.qza \
            --output-path alpha_diversity/shannon

        qiime tools export \
            --input-path chao1_vector.qza \
            --output-path alpha_diversity/chao1

        qiime tools export \
            --input-path ace_vector.qza \
            --output-path alpha_diversity/ace

        qiime tools export \
            --input-path simpson_vector.qza \
            --output-path alpha_diversity/simpson

        qiime tools export \
            --input-path observed_features_vector.qza \
            --output-path alpha_diversity/observed_features
        """
}
