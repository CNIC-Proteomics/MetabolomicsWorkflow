#!/bin/bash

# Author: Rafael Barrero Rodriguez
# Date: 2020-11-23
# Description: Script to generate drug_list.tsv and food_list.tsv
# with all synonyms (for now) hmdb database

# Usage example: bash list_generator.sh 


SRC_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
HMDB_FILE=$1

# get pre_hmdb_drug.tsv
echo "** Extracting drug"
bash "$SRC_HOME/scripts/hmdb_drug_extractor.sh" $HMDB_FILE

# get pre_hmdb_food.tsv
echo "** Extracting food"
bash "$SRC_HOME/scripts/hmdb_food_extractor.sh" $HMDB_FILE

# get pre_diterpenoids.tsv
echo "** Extracting diterpenoids"
bash "$SRC_HOME/scripts/hmdb_diterpenoids_extractor.sh" $HMDB_FILE

# concatenate pre_hmdb_food.tsv, pre_diterpenoids.tsv
cat "$SRC_HOME/scripts/pre_hmdb_food.tsv" "$SRC_HOME/scripts/pre_hmdb_diterpenoids.tsv" > "$SRC_HOME/scripts/pre_hmdb_food_diterpenoids.tsv"
rm -f "$SRC_HOME/scripts/pre_hmdb_food.tsv" "$SRC_HOME/scripts/pre_hmdb_diterpenoids.tsv"

# get pre_hmdb_drug.tsv synonyms
echo "** Getting drug synonyms"
python "$SRC_HOME/scripts/getAllSynonyms.py" "$SRC_HOME/scripts/pre_hmdb_drug.tsv"
rm -f "$SRC_HOME/drug_database.tsv"
mv "$SRC_HOME/scripts/allSynonyms.tsv" "$SRC_HOME/drug_list_original.tsv"
cat "$SRC_HOME/drug_list_original.tsv" | awk 'BEGIN {FS="\t"; OFS="\t"} NR==1 {print} NR!=1 {print tolower($1)"\t"$2}' > "$SRC_HOME/drug_list.tsv"

# get pre_hmdb_food_diterpenoids.tsv synonyms
echo "** Getting food synonyms"
python "$SRC_HOME/scripts/getAllSynonyms.py" "$SRC_HOME/scripts/pre_hmdb_food_diterpenoids.tsv"
rm -f "$SRC_HOME/food_list.tsv"
mv "$SRC_HOME/scripts/allSynonyms.tsv" "$SRC_HOME/food_list_original.tsv"
cat "$SRC_HOME/food_list_original.tsv" | awk 'BEGIN {FS="\t"; OFS="\t"} NR==1 {print} NR!=1 {print tolower($1)"\t"$2}' > "$SRC_HOME/food_list.tsv"

# remove pre files
rm -f  "$SRC_HOME/scripts/pre_hmdb_drug.tsv"  "$SRC_HOME/scripts/pre_hmdb_food_diterpenoids.tsv" "$SRC_HOME/drug_list_original.tsv" "$SRC_HOME/food_list_original.tsv"

# microbial compounds
cat "$SRC_HOME/scripts/microbial_pre_list.tsv" | awk 'NR==1 {print "Name\tinHouse_ID"} NR!=1 {print $0"\tcnic_"NR-1}' > "$SRC_HOME/scripts/microbial_pre_list_id.tsv"
python "$SRC_HOME/scripts/getAllSynonyms.py" "$SRC_HOME/scripts/microbial_pre_list_id.tsv"
cat <(echo -e "Name\tinHouse_ID") <(cat "$SRC_HOME/scripts/allSynonyms.tsv" | tail -n +2) |  awk 'NR==1{print} NR!=1{print tolower($0)}' > "$SRC_HOME/microbial_list.tsv"
rm "$SRC_HOME/scripts/allSynonyms.tsv" "$SRC_HOME/scripts/microbial_pre_list_id.tsv"

echo "($date) - INFO: Food, Drug and Microbial lists updated" >> "$SRC_HOME/log.info"