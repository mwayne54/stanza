outputprefix=$1
if [[ "$outputprefix" == "UD_"* ]]; then
    outputprefix=""
else
    shift
fi
treebank=$1
shift
gpu=$1
shift
short=`bash scripts/treebank_to_shorthand.sh ud $treebank`
if [[ "$short" == *"_xv" ]]; then
    short=`echo $short | rev | cut -d_ -f1- | rev`
fi
lang=`echo $short | sed -e 's#_.*##g'`
args=$@
if [ $lang == "vi" ]; then
    labels=data/tokenize/${short}-ud-train.json
    label_type=json_file
    eval_file="--json_file data/tokenize/${short}-ud-dev.json"
    train_eval_file="--dev_json_file data/tokenize/${short}-ud-dev.json"
else
    labels=data/tokenize/${short}-ud-train.toklabels
    label_type=label_file
    eval_file="--txt_file data/tokenize/${short}.dev.txt"
    train_eval_file="--dev_txt_file data/tokenize/${short}.dev.txt --dev_label_file data/tokenize/${short}-ud-dev.toklabels"
fi

if [ ! -e $labels ]; then
    bash scripts/prep_tokenize_data.sh $treebank train
    bash scripts/prep_tokenize_data.sh $treebank dev
fi

if [[ "$args" == *"--save_dir"* ]]; then
    savedir=""
else
    savedir="--save_dir ${outputprefix}saved_models/tokenize"
fi

DEV_GOLD=data/tokenize/${short}.dev.gold.conllu
seqlen=$(python -c "from math import ceil; print(ceil($(python stanfordnlp/utils/avg_sent_len.py $labels) * 3 / 100) * 100)")
echo "Running $args..."
CUDA_VISIBLE_DEVICES=$gpu python -m stanfordnlp.models.tokenizer --${label_type} $labels --txt_file data/tokenize/${short}.train.txt --lang $lang --max_seqlen $seqlen --mwt_json_file data/tokenize/${short}-ud-dev-mwt.json $train_eval_file --dev_conll_gold $DEV_GOLD --conll_file data/tokenize/${short}.dev.${outputprefix}pred.conllu --shorthand ${short} $savedir $args
CUDA_VISIBLE_DEVICES=$gpu python -m stanfordnlp.models.tokenizer --mode predict $eval_file --lang $lang --conll_file data/tokenize/${short}.dev.${outputprefix}pred.conllu --shorthand $short --mwt_json_file data/tokenize/${short}-ud-dev-mwt.json $savedir $args
results=`python stanfordnlp/utils/conll18_ud_eval.py -v $DEV_GOLD data/tokenize/${short}.dev.${outputprefix}pred.conllu | head -5 | tail -n+3 | awk '{print $7}' | pr --columns 3 -aJT`
echo $results $args >> data/tokenize/${short}.${outputprefix}results
echo $short $results $args
