#!/bin/bash

PREFERRED_PICTURE_SIZE=1024

is_picture() {
  RESULT=1
  if identify "$1" &> /dev/null ; then
    IMAGE_FORMAT=$(identify -format '%m' "$1")
    if [ "$IMAGE_FORMAT" == "JPEG" ] || [ "$IMAGE_FORMAT" == "PNG" ] ; then       
      RESULT=0   
    fi  
  fi
  
  return $RESULT  
}

is_too_big() { 
  RESULT=1
  if [ $(identify -format '%w' "$1") -gt "$PREFERRED_PICTURE_SIZE" ] || [ $(identify -format '%h' "$1") -gt "$PREFERRED_PICTURE_SIZE" ] ; then
    RESULT=0
  fi
  
  return $RESULT
}

is_portrait() { 
  RESULT=1
  if [ $(identify -format '%w' "$1") -lt $(identify -format '%h' "$1") ] ; then
    RESULT=0
  fi
  
  return $RESULT
}

resize_picture() {  
  if is_portrait "$1" ; then
    convert "$1" -resize "x${PREFERRED_PICTURE_SIZE}" "$2/$3"
  else
    convert "$1" -resize "${PREFERRED_PICTURE_SIZE}" "$2/$3"
  fi  
}

OUTPUT_DIR="/tmp/resized-pictures-${USER}"
rm -fr "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR" 

THUNDERBIRD_CMD="thunderbird -compose \"attachment='"
CURRENT_PARAM_NUMBER=0
PARAM_SIZE=$#
while [ -n "$1" ] ; do
  INPUT_PATH="$1"
  FILE_NAME=$(basename "$INPUT_PATH")
  CURRENT_PARAM_NUMBER=$((CURRENT_PARAM_NUMBER+1))  

  if is_picture "$INPUT_PATH" && is_too_big "$INPUT_PATH" ; then   
    resize_picture "$INPUT_PATH" "$OUTPUT_DIR" "$FILE_NAME"   
    THUNDERBIRD_CMD="${THUNDERBIRD_CMD}${OUTPUT_DIR}/${FILE_NAME}"      
  else
    THUNDERBIRD_CMD="${THUNDERBIRD_CMD}${INPUT_PATH}"      
  fi

  if [ "$CURRENT_PARAM_NUMBER" -lt "$PARAM_SIZE" ] ; then
    THUNDERBIRD_CMD="${THUNDERBIRD_CMD},"
  fi
  
  shift
done
THUNDERBIRD_CMD="${THUNDERBIRD_CMD}'\""

eval "$THUNDERBIRD_CMD"
