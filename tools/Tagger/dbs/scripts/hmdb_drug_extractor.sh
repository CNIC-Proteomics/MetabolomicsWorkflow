#!/bin/bash

# Name: Rafael Barrero Rodríguez
# Date: 2020-07-27
# Description: Bash script used to extract drugs from hmdb database
# Usage example: bash hmdb_drug_extractor.sh hmdb_metabolites.zip


# Get file name from command line
HMDB_FILE=$1

zcat $HMDB_FILE | awk '
    BEGIN {hmdb=0; metabolite=0; name_index=0; name[name_index]=""; synonyms=0; ontology=0; root=0; role=0; descendants_1=0; descendant_1=0; 
    industrialApp=0; descendants_2=0; descendant_2=0; drug=0; start=0; end=0; accession=""; disposition=0; source=0; endogenous=0}

    /^<hmdb[^>]*>$/ {hmdb=1}

    /^<metabolite[^>]*>$/ {if(hmdb==1){ metabolite=1; accession=""; drug=0; endogenous=0; name_index=0; name[name_index] = ""} }
  
    /^  <accession>[^<>]*<\/accession>$/ {if(metabolite==1){ start=index($0, ">")+1; end=index($0, "</"); accession=substr($0, start, end-start)}}

    /^  <name>[^<>]*<\/name>$/ {if(metabolite==1){start=index($0, ">")+1; end=index($0, "</"); 
                                name[name_index] = substr($0, start, end-start); name_index++}}
    
    /^  <synonyms>$/ {if(metabolite==1) synonyms=1}

    /^    <synonym>[^<>]*<\/synonym>$/ {if(synonyms==1){start=index($0, ">")+1; end=index($0, "</"); 
                                name[name_index] = substr($0, start, end-start); name_index++}} 

    /^  <\/synonyms>$/ {if(metabolite==1) synonyms=0}


    /^  <ontology>$/ {if(metabolite==1) ontology=1}

    /^    <root>$/ {if(ontology==1) root=1}

    /^      <term>Role<\/term>$/ {if(root==1) role=1}

    /^      <term>Disposition<\/term>$/ {if(root==1) disposition=1}

    /^      <descendants>$/ {if(role==1 || disposition==1) descendants_1=1}

    /^        <descendant>$/ {if(descendants_1==1) descendant_1=1}

    /^          <term>Industrial application<\/term>$/ {if(descendant_1==1 && role==1) industrialApp=1}

    /^          <term>Source<\/term>$/ {if(descendant_1==1 && disposition==1) source=1}

    /^          <descendants>$/ {if(industrialApp==1 || source==1) descendants_2=1}

    /^            <descendant>$/ {if(descendants_2==1) descendant_2=1}

    /^              <term>Drug<\/term>$/ {if(descendant_2==1) drug=1}

    /^              <term>Pharmaceutical industry<\/term>$/ {if(descendant_2==1) drug=1}

    /^              <term>Endogenous<\/term>$/ {if(descendant_2==1) endogenous=1}

    /^            <\/descendant>$/ {if(descendants_2==1) descendant_2=0}

    /^          <\/descendants>$/ {if(industrialApp==1 || source==1) descendants_2=0}    

    /^        <\/descendant>$/ {if(descendants_1==1){descendant_1=0; industrialApp=0; source=0}}  

    /^      <\/descendants>$/ {if(role==1 || disposition==1) descendants_1=0}

    /^    <\/root>$/ {if(ontology==1) root=0; role=0; disposition=0}

    /^  <\/ontology>$/ {if(metabolite==1) ontology=0}

    /^<\/metabolite[^>]*>$/ {if(hmdb==1){ metabolite=0}; if(drug==1 && endogenous==0){ for(i=0; i<name_index; i++) print("\x22" name[i] "\x22" "\t" accession)} }

    /^<\/hmdb[^>]*>$/ {hmdb=0}

    ' > hmdb_drug_tmp.tsv

cat <(echo -e "Name\tHMDB_ID") <(echo "$(cat hmdb_drug_tmp.tsv | sort | uniq)") > hmdb_drug_prueba.tsv

rm hmdb_drug_tmp.tsv