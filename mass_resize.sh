#!/bin/bash

for file in *.{jpg,JPG,jpeg,JPEG,png,PNG}; do
  if [ -e "$file" ]; then
    base_name=$(basename "$file")
    new_name="${base_name%.*}_32x32.${base_name##*.}"
    convert "$file" -resize 32x32\! "$new_name"
  fi
done