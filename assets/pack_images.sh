#!/bin/bash
mkdir -p output
mkdir -p temp

process_directory() {
    local dir=$1
    local dirname=$(basename "$dir")
    
    rm -rf temp/*
    
    # Trim images
    for img in "$dir"/*; do
        filename=$(basename "$img")
        convert "$img" -trim +repage "temp/$filename"
    done
    
    # Create montage with white background
    montage temp/* -geometry '+2+2' -tile 0 -background white "output/${dirname}-montage.png"
    
    # Update README
    echo "## ${dirname}" >> README.md
    echo "![$dirname](output/${dirname}-montage.png)" >> README.md
    echo "" >> README.md
    
    echo "<details><summary>Details</summary>" >> README.md
    for img in "$dir"/*; do
        filename=$(basename "$img")
        dimensions=$(identify -format "%wx%h" "$img")
        echo "- \`$filename\` ($dimensions)" >> README.md
    done
    echo "</details>" >> README.md
    echo "" >> README.md
}

echo "# Image Assets" > README.md
echo "" >> README.md
for dir in */; do
    process_directory "$dir"
done
rm -rf temp
