#!/bin/bash

INPUT="/chemin/fichier.video" # A adapter
OUTPUT_DIR="chapitres_mp3" # Dossier pour enregistrer les mp3
mkdir -p "$OUTPUT_DIR" # Création du dossier s'il n'existe pas

CHAP_JSON=$(ffprobe -i "$INPUT" -loglevel error -print_format json -show_chapters)
CHAP_COUNT=$(echo "$CHAP_JSON" | jq '.chapters | length')

TRACK_NUM=1

# Le premier chapitre a l'index 0 ; on peut commencer ou on veut
for (( i=0; i<CHAP_COUNT; i++ ))
do
    START=$(echo "$CHAP_JSON" | jq -r ".chapters[$i].start_time")
    END=$(echo "$CHAP_JSON" | jq -r ".chapters[$i].end_time")
    TITLE=$(echo "$CHAP_JSON" | jq -r ".chapters[$i].tags.title // \"track_$i\"")

    # Vérifie si le titre est vide ou non pertinent
    if [[ "$TITLE" == "<Untitled Chapter"* || -z "$TITLE" ]]; then
        TITLE="track_$TRACK_NUM"
    fi

    # Nettoyer le titre
    SAFE_TITLE=$(echo "$TITLE" | tr -cd '[:alnum:] _-' | tr ' ' '_')

    # Formatage du numéro de piste (ex: 01, 02...)
    TRACK_PADDED=$(printf "%02d" $TRACK_NUM)

    echo "Extraction : $TRACK_PADDED - $SAFE_TITLE"

    ffmpeg -i "$INPUT" -ss "$START" -to "$END" -vn -acodec libmp3lame -ab 192k "$OUTPUT_DIR/${TRACK_PADDED}_${SAFE_TITLE}.mp3"

    ((TRACK_NUM++))
done

