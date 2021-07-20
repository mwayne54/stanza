"""Processes the tokenization section of the LST20 Thai dataset

The dataset is available here:

https://aiforthai.in.th/corpus.php


python3 -m stanza.utils.datasets.tokenization.convert_th_lst20 extern_data/thai/LST20_Corpus data/tokenize

Unlike Orchid and BEST, LST20 has train/eval/test splits, which we relabel train/dev/test.

./scripts/run_tokenize.sh UD_Thai-lst20 --dropout 0.05 --unit_dropout 0.05
"""


import argparse
import glob
import os
import sys

from stanza.utils.datasets.tokenization.process_thai_tokenization import write_section, convert_processed_lines, reprocess_lines

def read_document(lines):
    document = []
    sentence = []
    for line in lines:
        line = line.strip()
        if not line:
            if sentence:
                #sentence[-1] = (sentence[-1][0], True)
                document.append(sentence)
                sentence = []
        else:
            pieces = line.split("\t")
            # there are some nbsp in tokens in lst20, but the downstream tools expect spaces
            pieces = [p.replace("\xa0", " ") for p in pieces]
            if pieces[0] == '_':
                sentence[-1] = (sentence[-1][0], True)
            else:
                sentence.append((pieces[0], False))

    if sentence:
        #sentence[-1] = (sentence[-1][0], True)
        document.append(sentence)
        sentence = []
    # TODO: is there any way to divide up a single document into paragraphs?
    return [[document]]

def retokenize_document(lines):
    processed_lines = []
    sentence = []
    for line in lines:
        line = line.strip()
        if not line:
            if sentence:
                processed_lines.append(sentence)
                sentence = []
        else:
            pieces = line.split("\t")
            if pieces[0] == '_':
                sentence.append(' ')
            else:
                sentence.append(pieces[0])
    if sentence:
        processed_lines.append(sentence)

    processed_lines = reprocess_lines(processed_lines)
    paragraphs = convert_processed_lines(processed_lines)
    return paragraphs


def read_data(input_dir, section, resegment):
    input_dir = os.path.join(input_dir, section)
    filenames = glob.glob(os.path.join(input_dir, "*.txt"))
    documents = []
    for filename in filenames:
        with open(filename) as fin:
            lines = fin.readlines()
        if resegment:
            document = retokenize_document(lines)
        else:
            document = read_document(lines)
        documents.extend(document)
    return documents

def add_lst20_args(parser):
    parser.add_argument('--no_lst20_resegment', action='store_false', dest="lst20_resegment", default=True, help='When processing th_lst20 tokenization, use pythainlp to resegment the text.  The other option is to keep the original sentence segmentation.  Currently our model is not good at that')

def parse_lst20_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('input_dir', help="Directory to use when processing lst20")
    parser.add_argument('output_dir', help="Directory to use when saving lst20")
    add_lst20_args(parser)
    return parser.parse_args()



def convert(input_dir, output_dir, args):
    full_input_dir = os.path.join(input_dir, "thai", "LST20_Corpus")
    if os.path.exists(full_input_dir):
        # otherwise hopefully the user gave us the full path?
        input_dir = full_input_dir
    for (in_section, out_section) in (("train", "train"),
                                      ("eval", "dev"),
                                      ("test", "test")):
        print("Processing %s" % out_section)
        documents = read_data(input_dir, in_section, args.lst20_resegment)
        print("  Read in %d documents" % len(documents))
        write_section(output_dir, "lst20", out_section, documents)

def main():
    args = parse_lst20_args()
    convert(args.input_dir, args.output_dir, args)

if __name__ == '__main__':
    main()
