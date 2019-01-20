#!/bin/bash
source scripts/config.sh

treebank=$1
shift
UDPIPEBASE=$UDBASE/UDPipe_out
DATADIR=data/mwt
short=`bash scripts/treebank_to_shorthand.sh ud $treebank`
lang=`echo $short | sed -e 's#_.*##g'`

if [ -d "$UDBASE/${treebank}_XV" ]; then
    src_treebank="${treebank}_XV"
    src_short="${short}_xv"
else
    src_treebank=$treebank
    src_short=$short
fi

train_conllu=$UDBASE/$src_treebank/${src_short}-ud-train.conllu
dev_conllu=$UDBASE/$src_treebank/${src_short}-ud-dev.conllu # gold dev
dev_gold_conllu=$UDBASE/$src_treebank/${src_short}-ud-dev.conllu

train_in_file=$DATADIR/${short}.train.in.conllu
dev_in_file=$DATADIR/${short}.dev.in.conllu
dev_gold_file=$DATADIR/${short}.dev.gold.conllu
# copy conllu file if exists; otherwise create empty files
if [ -e $train_conllu ]; then
    echo "Preparing training data..."
    cp $train_conllu $train_in_file
    bash scripts/prep_tokenize_data.sh $src_treebank train
else
    touch $train_in_file
fi

if [ -e $dev_conllu ]; then
    echo "Preparing dev data..."
    python stanfordnlp/utils/contract_mwt.py $dev_conllu $dev_in_file
    bash scripts/prep_tokenize_data.sh $src_treebank dev
else
    touch $dev_in_file
fi

if [ -e $dev_gold_conllu ]; then
    cp $dev_gold_conllu $dev_gold_file
else
    touch $dev_gold_file
fi
