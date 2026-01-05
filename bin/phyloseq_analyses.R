#!/usr/bin/env Rscript

# Script to generate all analyses from phyloseq object
# Author: Luis E. Leon
# Usage: phyloseq_analyses.R <phyloseq.rds> <outdir>

suppressPackageStartupMessages({
    library(phyloseq)
    library(ggplot2)
    library(openxlsx)
    library(vegan)
    library(iNEXT)
    library(dplyr)
    library(tidyr)
})

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2) {
    stop("Usage: phyloseq_analyses.R <phyloseq.rds> <outdir>")
}

phyloseq_rds <- args[1]
outdir <- args[2]

# Create output directories
dirs <- c(
    "abundance_tables",
    "taxonomy_plots",
    "rarefaction",
    "alpha_diversity",
    "beta_diversity"
)

for (dir in dirs) {
    dir.create(file.path(outdir, dir), showWarnings = FALSE, recursive = TRUE)
}

cat("Loading phyloseq object...\n")
ps <- readRDS(phyloseq_rds)

cat(sprintf("Loaded: %d samples, %d taxa\n\n", nsamples(ps), ntaxa(ps)))

# ============================================================================
# 1. EXCEL EXPORT - Abundance tables at each taxonomic level
# ============================================================================
cat("1. Generating Excel abundance tables...\n")

tax_levels <- c("Kingdom" = 1, "Phylum" = 2, "Class" = 3,
                "Order" = 4, "Family" = 5, "Genus" = 6)

for (level_name in names(tax_levels)) {
    level_num <- tax_levels[level_name]

    tryCatch({
        # Agglomerate at taxonomic level
        ps_glom <- tax_glom(ps, taxrank = level_name, NArm = TRUE)

        # Get OTU table
        otu_df <- as.data.frame(otu_table(ps_glom))

        # Add taxonomy names
        tax_df <- as.data.frame(tax_table(ps_glom))
        rownames(otu_df) <- tax_df[[level_name]]

        # Transpose for samples as rows
        otu_df_t <- as.data.frame(t(otu_df))

        # Calculate relative abundance
        rel_abundance <- sweep(otu_df_t, 1, rowSums(otu_df_t), FUN = "/") * 100

        # Calculate summary
        summary_df <- data.frame(
            Total_Reads = rowSums(otu_df_t),
            Observed_Taxa = rowSums(otu_df_t > 0)
        )

        # Write to Excel
        wb <- createWorkbook()
        addWorksheet(wb, "Absolute_Counts")
        addWorksheet(wb, "Relative_Abundance")
        addWorksheet(wb, "Summary")

        writeData(wb, "Absolute_Counts", otu_df_t, rowNames = TRUE)
        writeData(wb, "Relative_Abundance", rel_abundance, rowNames = TRUE)
        writeData(wb, "Summary", summary_df, rowNames = TRUE)

        output_file <- file.path(outdir, "abundance_tables",
                                sprintf("level-%d-abundance.xlsx", level_num))
        saveWorkbook(wb, output_file, overwrite = TRUE)

        cat(sprintf("  ✓ Level %d (%s): %s\n", level_num, level_name, output_file))
    }, error = function(e) {
        cat(sprintf("  ✗ Level %d (%s): %s\n", level_num, level_name, e$message))
    })
}

# ============================================================================
# 2. TAXONOMY PLOTS - Stacked bar plots at each level
# ============================================================================
cat("\n2. Generating taxonomy stacked bar plots...\n")

theme_set(theme_minimal(base_size = 12))

for (level_name in names(tax_levels)) {
    level_num <- tax_levels[level_name]

    tryCatch({
        # Agglomerate at taxonomic level
        ps_glom <- tax_glom(ps, taxrank = level_name, NArm = TRUE)

        # Get top 20 most abundant taxa
        top20 <- names(sort(taxa_sums(ps_glom), decreasing = TRUE)[1:min(20, ntaxa(ps_glom))])

        # Merge everything else into "Other"
        ps_top <- prune_taxa(top20, ps_glom)
        ps_other <- prune_taxa(setdiff(taxa_names(ps_glom), top20), ps_glom)

        # Transform to relative abundance
        ps_top_rel <- transform_sample_counts(ps_top, function(x) x / sum(x) * 100)

        # Prepare data for plotting
        melt_data <- psmelt(ps_top_rel)

        # Add "Other" category if there are taxa outside top 20
        if (ntaxa(ps_other) > 0) {
            other_abundance <- sample_sums(ps_other)
            total_abundance <- sample_sums(ps_glom)
            other_rel <- (other_abundance / total_abundance) * 100

            other_df <- data.frame(
                OTU = "Other",
                Sample = names(other_rel),
                Abundance = other_rel
            )
            other_df[[level_name]] <- "Other"

            # Add other columns to match
            for (col in setdiff(names(melt_data), names(other_df))) {
                other_df[[col]] <- NA
            }

            melt_data <- rbind(melt_data, other_df)
        }

        # Order taxa by mean abundance (most abundant first)
        taxa_order <- melt_data %>%
            group_by(!!sym(level_name)) %>%
            summarise(mean_abund = mean(Abundance, na.rm = TRUE)) %>%
            arrange(desc(mean_abund)) %>%
            pull(!!sym(level_name))

        # Move "Other" to the end if present
        if ("Other" %in% taxa_order) {
            taxa_order <- c(setdiff(taxa_order, "Other"), "Other")
        }

        melt_data[[level_name]] <- factor(melt_data[[level_name]], levels = rev(taxa_order))

        # Create stacked bar plot
        p <- ggplot(melt_data, aes(x = Sample, y = Abundance, fill = !!sym(level_name))) +
            geom_bar(stat = "identity", position = "stack") +
            theme_minimal(base_size = 12) +
            theme(
                axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5),
                legend.position = "right",
                legend.title = element_text(face = "bold"),
                plot.title = element_text(hjust = 0.5, face = "bold")
            ) +
            labs(
                title = sprintf("Taxonomic Composition - %s Level", level_name),
                x = "Sample",
                y = "Relative Abundance (%)",
                fill = level_name
            ) +
            scale_fill_manual(values = c(
                colorRampPalette(RColorBrewer::brewer.pal(12, "Paired"))(length(taxa_order) - 1),
                "#CCCCCC"  # Gray for "Other"
            ))

        # Save plots
        pdf_file <- file.path(outdir, "taxonomy_plots",
                             sprintf("taxonomy_level%d_histogram.pdf", level_num))
        png_file <- file.path(outdir, "taxonomy_plots",
                             sprintf("taxonomy_level%d_histogram.png", level_num))

        ggsave(pdf_file, p, width = 12, height = 8, dpi = 300)
        ggsave(png_file, p, width = 12, height = 8, dpi = 300)

        cat(sprintf("  ✓ Level %d (%s): stacked bar plot saved (%d taxa + Other)\n",
                    level_num, level_name, length(top20)))
    }, error = function(e) {
        cat(sprintf("  ✗ Level %d (%s): %s\n", level_num, level_name, e$message))
    })
}

# ============================================================================
# 3. RAREFACTION CURVES
# ============================================================================
cat("\n3. Generating rarefaction curves...\n")

tryCatch({
    # Prepare data for iNEXT
    otu_matrix <- as.matrix(otu_table(ps))
    if (!taxa_are_rows(ps)) {
        otu_matrix <- t(otu_matrix)
    }

    # Run iNEXT
    inext_out <- iNEXT(as.data.frame(otu_matrix), q = c(0, 1, 2),
                      datatype = "abundance", nboot = 50)

    # Plot
    p <- ggiNEXT(inext_out, type = 1, facet.var = "Order.q") +
        theme_bw(base_size = 12) +
        labs(title = "Rarefaction Curves",
             subtitle = "Hill numbers: q=0 (Species richness), q=1 (Shannon diversity), q=2 (Simpson diversity)")

    # Save
    pdf_file <- file.path(outdir, "rarefaction", "rarefaction_curves.pdf")
    png_file <- file.path(outdir, "rarefaction", "rarefaction_curves.png")

    ggsave(pdf_file, p, width = 14, height = 8, dpi = 300)
    ggsave(png_file, p, width = 14, height = 8, dpi = 300)

    # Export data
    rarefaction_data <- inext_out$iNextEst$size_based
    write.csv(rarefaction_data,
             file.path(outdir, "rarefaction", "rarefaction_data.csv"),
             row.names = FALSE)

    cat("  ✓ Rarefaction curves generated\n")
}, error = function(e) {
    cat(sprintf("  ✗ Rarefaction: %s\n", e$message))
})

# ============================================================================
# 4. ALPHA DIVERSITY
# ============================================================================
cat("\n4. Calculating alpha diversity...\n")

alpha_metrics <- c("Shannon", "Chao1", "ACE", "Simpson", "Observed")

for (metric in alpha_metrics) {
    tryCatch({
        metric_dir <- file.path(outdir, "alpha_diversity", tolower(metric))
        dir.create(metric_dir, showWarnings = FALSE, recursive = TRUE)

        # Calculate metric
        if (metric == "Observed") {
            values <- estimate_richness(ps, measures = "Observed")
        } else {
            values <- estimate_richness(ps, measures = metric)
        }

        # Create output table
        output_df <- data.frame(
            SampleID = rownames(values),
            Value = values[[1]]
        )
        names(output_df)[2] <- tolower(metric)

        # Save
        write.table(output_df,
                   file.path(metric_dir, "alpha-diversity.tsv"),
                   sep = "\t", row.names = FALSE, quote = FALSE)

        cat(sprintf("  ✓ %s diversity calculated\n", metric))
    }, error = function(e) {
        cat(sprintf("  ✗ %s: %s\n", metric, e$message))
    })
}

# Also create "observed_features" for compatibility
tryCatch({
    metric_dir <- file.path(outdir, "alpha_diversity", "observed_features")
    dir.create(metric_dir, showWarnings = FALSE, recursive = TRUE)

    values <- estimate_richness(ps, measures = "Observed")
    output_df <- data.frame(
        SampleID = rownames(values),
        observed_features = values[[1]]
    )

    write.table(output_df,
               file.path(metric_dir, "alpha-diversity.tsv"),
               sep = "\t", row.names = FALSE, quote = FALSE)

    cat("  ✓ Observed features (alias) calculated\n")
}, error = function(e) {
    cat(sprintf("  ✗ Observed features: %s\n", e$message))
})

# ============================================================================
# 5. BETA DIVERSITY
# ============================================================================
cat("\n5. Calculating beta diversity...\n")

beta_metrics <- list(
    "bray_curtis" = "bray",
    "jaccard" = "jaccard"
)

for (metric_name in names(beta_metrics)) {
    tryCatch({
        metric_dir <- file.path(outdir, "beta_diversity", metric_name)
        dir.create(metric_dir, showWarnings = FALSE, recursive = TRUE)

        # Calculate distance
        dist_matrix <- distance(ps, method = beta_metrics[[metric_name]])

        # Convert to matrix
        dist_df <- as.matrix(dist_matrix)

        # Save distance matrix
        write.table(dist_df,
                   file.path(metric_dir, "distance-matrix.tsv"),
                   sep = "\t", quote = FALSE)

        # Calculate PCoA
        pcoa_result <- ordinate(ps, method = "PCoA", distance = dist_matrix)

        # Save PCoA coordinates
        pcoa_df <- as.data.frame(pcoa_result$vectors)
        write.table(pcoa_df,
                   file.path(metric_dir, "pcoa-coordinates.tsv"),
                   sep = "\t", quote = FALSE)

        cat(sprintf("  ✓ %s distance calculated\n", metric_name))
    }, error = function(e) {
        cat(sprintf("  ✗ %s: %s\n", metric_name, e$message))
    })
}

# UniFrac distances (requires tree)
unifrac_metrics <- list(
    "weighted_unifrac" = "weighted",
    "unweighted_unifrac" = "unweighted"
)

for (metric_name in names(unifrac_metrics)) {
    tryCatch({
        metric_dir <- file.path(outdir, "beta_diversity", metric_name)
        dir.create(metric_dir, showWarnings = FALSE, recursive = TRUE)

        # Calculate UniFrac distance
        dist_matrix <- UniFrac(ps, weighted = (unifrac_metrics[[metric_name]] == "weighted"))

        # Convert to matrix
        dist_df <- as.matrix(dist_matrix)

        # Save distance matrix
        write.table(dist_df,
                   file.path(metric_dir, "distance-matrix.tsv"),
                   sep = "\t", quote = FALSE)

        # Calculate PCoA
        pcoa_result <- ordinate(ps, method = "PCoA", distance = dist_matrix)

        # Save PCoA coordinates
        pcoa_df <- as.data.frame(pcoa_result$vectors)
        write.table(pcoa_df,
                   file.path(metric_dir, "pcoa-coordinates.tsv"),
                   sep = "\t", quote = FALSE)

        cat(sprintf("  ✓ %s distance calculated\n", metric_name))
    }, error = function(e) {
        cat(sprintf("  ✗ %s: %s\n", metric_name, e$message))
    })
}

cat("\n✓ All analyses completed!\n")
cat(sprintf("\nOutputs saved to: %s\n", outdir))
