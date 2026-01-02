#!/usr/bin/env python3

"""
Script to collect read statistics throughout the OTUseq pipeline
and generate a tracking report
"""

import sys
import json
import zipfile
import os
from pathlib import Path
import pandas as pd


def count_fastq_reads(fastq_file):
    """Count reads in a FASTQ file (gzipped or not)"""
    import gzip

    if fastq_file.endswith('.gz'):
        opener = gzip.open
        mode = 'rt'
    else:
        opener = open
        mode = 'r'

    count = 0
    with opener(fastq_file, mode) as f:
        for i, line in enumerate(f):
            if i % 4 == 0:  # Header lines
                count += 1
    return count


def extract_qza_stats(qza_file):
    """Extract statistics from a QIIME2 artifact"""
    stats = {}
    try:
        with zipfile.ZipFile(qza_file, 'r') as zip_ref:
            # List all files in the archive
            file_list = zip_ref.namelist()

            # Look for BIOM files
            biom_files = [f for f in file_list if f.endswith('.biom')]
            if biom_files:
                # Extract and read BIOM file
                biom_path = biom_files[0]
                with zip_ref.open(biom_path) as biom_file:
                    import biom
                    table = biom.load_table(biom_file)
                    stats['samples'] = table.shape[1]
                    stats['features'] = table.shape[0]
                    stats['total_frequency'] = int(table.sum())
                    stats['mean_frequency'] = stats['total_frequency'] / stats['samples']

    except Exception as e:
        print(f"Error extracting stats from {qza_file}: {e}", file=sys.stderr)

    return stats


def collect_pipeline_stats(output_dir):
    """Collect statistics from all pipeline steps"""

    output_path = Path(output_dir)
    tracking = []

    # Step 1: Raw sequences (from FastQC or samplesheet)
    # This would need to be populated from actual data

    # Step 2: After homopolymer removal
    # Look for filtered FASTQ files

    # Step 3: After cutadapt
    cutadapt_dir = output_path / "cutadapt"
    if cutadapt_dir.exists():
        cutadapt_files = list(cutadapt_dir.glob("*.fastq.gz"))
        if cutadapt_files:
            # Count reads in one of the files
            tracking.append({
                'step': 'After primer trimming',
                'description': 'Cutadapt primer removal',
                'files': len(cutadapt_files)
            })

    # Step 4: After QIIME2 import and deduplication
    derep_table = output_path / "vsearch_dereplicate" / "table.qza"
    if derep_table.exists():
        stats = extract_qza_stats(str(derep_table))
        tracking.append({
            'step': 'After deduplication',
            'description': 'VSEARCH dereplicate',
            'features': stats.get('features', 'N/A'),
            'total_reads': stats.get('total_frequency', 'N/A')
        })

    # Step 5: After clustering
    cluster_table = output_path / "vsearch_cluster" / "clustered-table.qza"
    if cluster_table.exists():
        stats = extract_qza_stats(str(cluster_table))
        tracking.append({
            'step': 'After clustering (97%)',
            'description': 'OTU clustering',
            'features': stats.get('features', 'N/A'),
            'total_reads': stats.get('total_frequency', 'N/A')
        })

    # Step 6: After chimera removal
    nonchimeric_table = output_path / "chimera_filtering" / "nonchimeric-table.qza"
    if nonchimeric_table.exists():
        stats = extract_qza_stats(str(nonchimeric_table))
        tracking.append({
            'step': 'After chimera removal',
            'description': 'VSEARCH UCHIME',
            'features': stats.get('features', 'N/A'),
            'total_reads': stats.get('total_frequency', 'N/A')
        })

    # Step 7: After taxa filtering
    filtered_table = output_path / "filter_taxa" / "filtered-table.qza"
    if filtered_table.exists():
        stats = extract_qza_stats(str(filtered_table))
        tracking.append({
            'step': 'After taxa filtering',
            'description': 'Remove mitochondria/chloroplast',
            'features': stats.get('features', 'N/A'),
            'total_reads': stats.get('total_frequency', 'N/A')
        })

    return tracking


def main():
    if len(sys.argv) < 2:
        print("Usage: collect_read_stats.py <output_dir>")
        sys.exit(1)

    output_dir = sys.argv[1]

    # Collect statistics
    tracking = collect_pipeline_stats(output_dir)

    # Convert to DataFrame
    if tracking:
        df = pd.DataFrame(tracking)

        # Save to CSV
        df.to_csv('read_tracking.csv', index=False)

        # Save to JSON
        with open('read_tracking.json', 'w') as f:
            json.dump(tracking, f, indent=2)

        print("Read tracking statistics saved to:")
        print("  - read_tracking.csv")
        print("  - read_tracking.json")
    else:
        print("No tracking data found.")


if __name__ == "__main__":
    main()
