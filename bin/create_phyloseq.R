#!/usr/bin/env Rscript

# Script to create phyloseq object from QIIME2 artifacts
# Author: Luis E. Leon
# Usage: create_phyloseq.R <filtered_table.qza> <taxonomy.qza> <tree.qza> <metadata.csv> <output.rds>

suppressPackageStartupMessages({
    library(phyloseq)
    library(Biostrings)
    library(ape)
})

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 5) {
    stop("Usage: create_phyloseq.R <table.qza> <taxonomy.qza> <tree.qza> <metadata.csv> <output.rds>")
}

table_qza <- args[1]
taxonomy_qza <- args[2]
tree_qza <- args[3]
metadata_file <- args[4]
output_rds <- args[5]

cat("Creating phyloseq object from QIIME2 artifacts...\n")

# Function to extract files from QZA
extract_qza <- function(qza_file, pattern) {
    temp_dir <- tempdir()
    unzip(qza_file, exdir = temp_dir, overwrite = TRUE)

    # Find the data file
    data_files <- list.files(
        file.path(temp_dir, dirname(unzip(qza_file, list = TRUE)$Name[1]), "data"),
        pattern = pattern,
        full.names = TRUE,
        recursive = TRUE
    )

    if (length(data_files) == 0) {
        stop(paste("No files matching pattern", pattern, "found in", qza_file))
    }

    return(data_files[1])
}

# 1. Extract and load OTU table
cat("  - Extracting OTU table...\n")
biom_file <- extract_qza(table_qza, "\\.biom$")

# Read BIOM file
otu_data <- biomformat::read_biom(biom_file)
otu_matrix <- as.matrix(biomformat::biom_data(otu_data))
otu_table <- otu_table(otu_matrix, taxa_are_rows = TRUE)

cat(sprintf("    OTU table: %d features x %d samples\n",
            ntaxa(otu_table), nsamples(otu_table)))

# 2. Extract and load taxonomy
cat("  - Extracting taxonomy...\n")
tax_file <- extract_qza(taxonomy_qza, "taxonomy\\.tsv$")

tax_data <- read.table(tax_file, sep = "\t", header = TRUE, row.names = 1, quote = "")

# Parse taxonomy string into levels
parse_taxonomy <- function(tax_string) {
    # Remove confidence scores if present
    tax_string <- gsub("\\s*\\([0-9.]+\\)", "", tax_string)

    # Split by semicolon
    levels <- strsplit(as.character(tax_string), ";")[[1]]
    levels <- trimws(levels)

    # Create named vector with standard ranks
    ranks <- c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species")
    result <- rep(NA, length(ranks))
    names(result) <- ranks

    # Fill in available levels
    for (i in seq_along(levels)) {
        if (i <= length(ranks) && levels[i] != "") {
            # Remove rank prefixes if present (e.g., "d__", "p__", "c__")
            clean_level <- gsub("^[a-z]__", "", levels[i])
            result[i] <- clean_level
        }
    }

    return(result)
}

tax_matrix <- t(sapply(tax_data$Taxon, parse_taxonomy))
rownames(tax_matrix) <- rownames(tax_data)
tax_table <- tax_table(tax_matrix)

cat(sprintf("    Taxonomy: %d taxa classified\n", nrow(tax_matrix)))

# 3. Extract and load phylogenetic tree
cat("  - Extracting phylogenetic tree...\n")
tree_file <- extract_qza(tree_qza, "\\.nwk$")
phy_tree <- read.tree(tree_file)

cat(sprintf("    Tree: %d tips\n", length(phy_tree$tip.label)))

# 4. Load metadata if provided
sam_data <- NULL
if (file.exists(metadata_file)) {
    cat("  - Loading sample metadata...\n")
    metadata <- read.csv(metadata_file, row.names = 1)
    sam_data <- sample_data(metadata)
    cat(sprintf("    Metadata: %d samples, %d variables\n",
                nrow(metadata), ncol(metadata)))
} else {
    cat("  - No metadata file found, creating minimal sample data\n")
    sample_names <- sample_names(otu_table)
    metadata <- data.frame(
        SampleID = sample_names,
        row.names = sample_names
    )
    sam_data <- sample_data(metadata)
}

# 5. Create phyloseq object
cat("  - Assembling phyloseq object...\n")

if (!is.null(sam_data)) {
    ps <- phyloseq(otu_table, tax_table, phy_tree, sam_data)
} else {
    ps <- phyloseq(otu_table, tax_table, phy_tree)
}

# 6. Basic statistics
cat("\n=== Phyloseq Object Summary ===\n")
print(ps)

cat("\nSample sums (total reads per sample):\n")
print(summary(sample_sums(ps)))

cat("\nTaxa sums (total reads per OTU):\n")
print(summary(taxa_sums(ps)))

# 7. Save phyloseq object
cat(sprintf("\n  - Saving phyloseq object to %s...\n", output_rds))
saveRDS(ps, output_rds)

cat("\n✓ Phyloseq object created successfully!\n")
