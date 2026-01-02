#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import biom
import zipfile
import sys
import os

def extract_biom_from_qza(qza_file):
    """Extract BIOM file from QZA archive"""
    with zipfile.ZipFile(qza_file, 'r') as zip_ref:
        data_files = [f for f in zip_ref.namelist() if f.endswith('.biom')]
        if data_files:
            biom_file = data_files[0]
            zip_ref.extract(biom_file, '.')
            return biom_file
    return None

def plot_taxonomy_histogram(table_qza, taxonomy_qza, level, output_prefix):
    """Generate histogram plots for taxonomic composition"""

    # Extract BIOM table
    biom_file = extract_biom_from_qza(table_qza)
    if not biom_file:
        print("Error: Could not extract BIOM file")
        return

    # Load table
    table = biom.load_table(biom_file)
    df = table.to_dataframe().T

    # Calculate mean abundance across samples
    mean_abundance = df.mean(axis=0).sort_values(ascending=False)

    # Get top 20 taxa
    top_taxa = mean_abundance.head(20)

    # Set style
    sns.set_style("whitegrid")

    # Create figure
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(14, 12))

    # Plot 1: Absolute abundance
    colors = sns.color_palette("husl", len(top_taxa))
    ax1.bar(range(len(top_taxa)), top_taxa.values, color=colors)
    ax1.set_xticks(range(len(top_taxa)))
    ax1.set_xticklabels(top_taxa.index, rotation=45, ha='right', fontsize=9)
    ax1.set_ylabel('Mean Abundance (reads)', fontsize=12)
    ax1.set_title(f'Top 20 Taxa - Level {level} (Absolute Abundance)', fontsize=14, fontweight='bold')
    ax1.grid(axis='y', alpha=0.3)

    # Plot 2: Relative abundance
    rel_abundance = (top_taxa / top_taxa.sum()) * 100
    ax2.bar(range(len(rel_abundance)), rel_abundance.values, color=colors)
    ax2.set_xticks(range(len(rel_abundance)))
    ax2.set_xticklabels(rel_abundance.index, rotation=45, ha='right', fontsize=9)
    ax2.set_ylabel('Relative Abundance (%)', fontsize=12)
    ax2.set_title(f'Top 20 Taxa - Level {level} (Relative Abundance)', fontsize=14, fontweight='bold')
    ax2.grid(axis='y', alpha=0.3)

    plt.tight_layout()
    plt.savefig(f'{output_prefix}_level{level}_histogram.pdf', dpi=300, bbox_inches='tight')
    plt.savefig(f'{output_prefix}_level{level}_histogram.png', dpi=300, bbox_inches='tight')
    plt.close()

    # Clean up
    if os.path.exists(biom_file):
        os.remove(biom_file)

    print(f"Plots saved: {output_prefix}_level{level}_histogram.pdf/png")

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: plot_taxonomy.py <table.qza> <taxonomy.qza> <level> <output_prefix>")
        sys.exit(1)

    table_qza = sys.argv[1]
    taxonomy_qza = sys.argv[2]
    level = sys.argv[3]
    output_prefix = sys.argv[4]

    plot_taxonomy_histogram(table_qza, taxonomy_qza, level, output_prefix)
