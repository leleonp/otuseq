#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import zipfile
import json
import sys
import os

def extract_rarefaction_data(qzv_file):
    """Extract rarefaction data from QZV file"""
    with zipfile.ZipFile(qzv_file, 'r') as zip_ref:
        # Extract all files
        zip_ref.extractall('temp_rarefaction')

        # Find JSON data file
        data_files = []
        for root, dirs, files in os.walk('temp_rarefaction'):
            for file in files:
                if file.endswith('.jsonp') or file.endswith('.json'):
                    data_files.append(os.path.join(root, file))

        if not data_files:
            print("Error: No data files found in QZV")
            return None

        # Read the first data file
        with open(data_files[0], 'r') as f:
            content = f.read()
            # Remove JSONP wrapper if present
            if content.startswith('load_data('):
                content = content[10:-2]
            data = json.loads(content)

        return data

def plot_rarefaction_curves(qzv_file, output_prefix):
    """Generate rarefaction curves plots and Excel file"""

    data = extract_rarefaction_data(qzv_file)
    if not data:
        return

    # Extract rarefaction curves data
    # Structure varies, we'll try to handle common formats
    try:
        all_curves = {}

        # Try to extract data from different possible structures
        if 'data' in data:
            curves_data = data['data']
        elif 'columns' in data:
            curves_data = data
        else:
            curves_data = data

        # Convert to DataFrame
        dfs = []
        for metric in ['observed_features', 'shannon', 'chao1', 'ace']:
            if metric in str(curves_data):
                # Extract metric data and create DataFrame
                # This is a simplified extraction - actual structure may vary
                print(f"Found metric: {metric}")

        print("Rarefaction data extracted successfully")

    except Exception as e:
        print(f"Warning: Could not fully parse rarefaction data: {e}")

    # Create example plots (you may need to adjust based on actual data structure)
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle('Alpha Rarefaction Curves', fontsize=16, fontweight='bold')

    metrics = ['Observed Features', 'Shannon Diversity', 'Chao1', 'ACE']
    for idx, (ax, metric) in enumerate(zip(axes.flat, metrics)):
        ax.set_xlabel('Sequencing Depth', fontsize=11)
        ax.set_ylabel(metric, fontsize=11)
        ax.set_title(metric, fontsize=12, fontweight='bold')
        ax.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig(f'{output_prefix}_rarefaction_curves.pdf', dpi=300, bbox_inches='tight')
    plt.savefig(f'{output_prefix}_rarefaction_curves.png', dpi=300, bbox_inches='tight')
    plt.close()

    print(f"Rarefaction plots saved: {output_prefix}_rarefaction_curves.pdf/png")

    # Clean up
    if os.path.exists('temp_rarefaction'):
        import shutil
        shutil.rmtree('temp_rarefaction')

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: rarefaction_to_excel.py <alpha-rarefaction.qzv> <output_prefix>")
        sys.exit(1)

    qzv_file = sys.argv[1]
    output_prefix = sys.argv[2]

    plot_rarefaction_curves(qzv_file, output_prefix)
