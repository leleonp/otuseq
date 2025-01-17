#!/usr/bin/env python3


import pandas as pd
from Bio import SeqIO
import gzip
import sys

def forward_to_df(fq_gz):
    """ This fx convert fastq file to pandas df """
    with gzip.open(fq_gz, "rt") as fq_file:
        fq_list = [[rec.description, "".join([x for x in rec.seq]),
                    ''.join([chr(x + 33) for x in rec.letter_annotations['phred_quality']])] for rec in SeqIO.parse(fq_file, "fastq")]
    forw_df = pd.DataFrame.from_records(fq_list, columns=["ID_f", "Sequence_f", "Quality_f"])
    forw_df[['ID', "Barcode_f"]] = forw_df["ID_f"].str.split(" ", expand=True)
    return forw_df


def reverse_to_df(fq_gz):
    """ This fx convert fastq file to pandas df """
    with gzip.open(fq_gz, "rt") as fq_file:
        fq_list = [[rec.description, "".join([x for x in rec.seq]),
                    ''.join([chr(x + 33) for x in rec.letter_annotations['phred_quality']])] for rec in SeqIO.parse(fq_file, "fastq")]
    forw_df = pd.DataFrame.from_records(fq_list, columns=["ID_r", "Sequence_r", "Quality_r"])
    forw_df[['ID', "Barcode_r"]] = forw_df["ID_r"].str.split(" ", expand=True)
    return forw_df


def merge_pandas(forw_df, rev_df):
    merged = pd.merge(forw_df, rev_df, how='inner', on='ID')
    return merged

def find_homopolymers(sequence):
    if "AAAAAAAA" in sequence:
        return "true"
    elif "TTTTTTTT" in sequence:
        return "true"
    elif "CCCCCCCC" in sequence:
        return "true"
    elif "GGGGGGGG" in sequence:
        return "true"
    else:
        return "false"
    

def find_ambiguous(sequence):
    if "N" in sequence:
        return "true"
    else:
        return "false"
    
def convert_df_to_fastq(df, name):
    with gzip.open(name + "_R1_noh.fastq.gz", "wt") as ofile1:
        for index, row in df.iterrows():
            ofile1.write("@{}\n{}\n+\n{}\n".format(row['ID_f'], row['Sequence_f'], row['Quality_f']))
    
    with gzip.open(name + "_R2_noh.fastq.gz", "wt") as ofile2:
        for index, row in df.iterrows():
            ofile2.write("@{}\n{}\n+\n{}\n".format(row['ID_r'], row['Sequence_r'], row['Quality_r']))


## Main pipeline

for_in = sys.argv[1]
rev_in = sys.argv[2]
name = for_in.split("_")[0]

for_in_df = forward_to_df(for_in)
rev_in_df = reverse_to_df(rev_in)
merged = merge_pandas(for_in_df, rev_in_df)

merged['homopolymer_f'] = merged.apply(lambda row: find_homopolymers(row['Sequence_f']), axis=1)
merged['homopolymer_r'] = merged.apply(lambda row: find_homopolymers(row['Sequence_r']), axis=1)

merged['N_seq_f'] = merged.apply(lambda row: find_ambiguous(row['Sequence_f']), axis=1)
merged['N_seq_r'] = merged.apply(lambda row: find_ambiguous(row['Sequence_r']), axis=1)

## Filter

merged = merged[merged['homopolymer_f'] == "false"]
merged = merged[merged['homopolymer_r'] == "false"]
merged = merged[merged['N_seq_f'] == "false"]
merged = merged[merged['N_seq_r'] == "false"]

convert_df_to_fastq(merged, name)


