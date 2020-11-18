#!/bin/bash

# Name: Rafael Barrero Rodríguez
# Date: 2020-09-15
# Description: Script used to extract diterpenoids compounds from HMDB database (sub_class: Diterpenoids)
# Usage example: bash diterpenoids_extractor.sh hmdb_metabolites.zip


# Get file name from command line
HMDB_FILE=$1

zcat $HMDB_FILE | awk '
    BEGIN {hmdb=0; metabolite=0; name_index=0; name[name_index]=""; synonyms=0; taxonomy=0; diterpenoid=0; ontology=0; root=0;
            disposition=0; descendants_1=0; descendant_1=0; source=0; descendants_2=0; descendant_2=0; food=0; start=0; end=0; 
            accession="";}

    /^<hmdb[^>]*>$/ {hmdb=1}

    /^<metabolite[^>]*>$/ {if(hmdb==1){ metabolite=1; accession=""; diterpenoid=0; food=0; name_index=0; name[name_index] = ""} }
  
    /^  <accession>[^<>]*<\/accession>$/ {if(metabolite==1){ start=index($0, ">")+1; end=index($0, "</"); accession=substr($0, start, end-start)}}

    /^  <name>[^<>]*<\/name>$/ {if(metabolite==1){start=index($0, ">")+1; end=index($0, "</"); 
                                name[name_index] = substr($0, start, end-start); name_index++}}
    
    /^  <synonyms>$/ {if(metabolite==1) synonyms=1}

    /^    <synonym>[^<>]*<\/synonym>$/ {if(synonyms==1){start=index($0, ">")+1; end=index($0, "</"); 
                                name[name_index] = substr($0, start, end-start); name_index++}}   

    /^  <\/synonyms>$/ {if(metabolite==1) synonyms=0}


    /^  <taxonomy>$/ {if(metabolite==1) taxonomy=1}

    /^    <sub_class>Diterpenoids<\/sub_class>$/ {if(taxonomy==1) diterpenoid=1;}

    /^  <\/taxonomy>$/ {if(metabolite==1) taxonomy=0}

    /^  <ontology>$/ {if(metabolite==1) ontology=1}

    /^    <root>$/ {if(ontology==1) root=1}

    /^      <term>Disposition<\/term>$/ {if(root==1) disposition=1}

    /^      <descendants>$/ {if(disposition==1) descendants_1=1}

    /^        <descendant>$/ {if(descendants_1==1) descendant_1=1}

    /^          <term>Source<\/term>$/ {if(descendant_1==1) source=1}

    /^          <descendants>$/ {if(source==1) descendants_2=1}

    /^            <descendant>$/ {if(descendants_2==1) descendant_2=1}

    /^              <term>Food<\/term>$/ {if(descendant_2==1) food=1}

    /^            <\/descendant>$/ {if(descendants_2==1) descendant_2=0}

    /^          <\/descendants>$/ {if(source==1) descendants_2=0}    

    /^        <\/descendant>$/ {if(descendants_1==1){descendant_1=0; source=0}}  

    /^      <\/descendants>$/ {if(disposition==1) descendants_1=0}

    /^    <\/root>$/ {if(ontology==1) root=0; disposition=0}

    /^  <\/ontology>$/ {if(metabolite==1) ontology=0}

    /^<\/metabolite[^>]*>$/ {if(hmdb==1){ metabolite=0; 
                                        if(diterpenoid==1 && food==0){ for(i=0; i<name_index; i++) print("\x22" name[i] "\x22" "\t" accession)}
                                        else if(diterpenoid==1 && food==1){ for(i=0; i<name_index; i++) print("\x22" name[i] "\x22" "\t" accession "\t" "food") } } }

    /^<\/hmdb[^>]*>$/ {hmdb=0}
    
    ' > hmdb_diterpenoids_tmp.tsv

cat <(echo -e "Name\tHMDB_ID\tFood") <(echo "$(cat hmdb_diterpenoids_tmp.tsv | sort | uniq)") > hmdb_diterpenoids.tsv

rm hmdb_diterpenoids_tmp.tsv