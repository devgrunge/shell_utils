#!/bin/bash

OUTPUT_FILE="repository_structure.txt"

IGNORE_PATTERN="node_modules|.git|venv|.dist|langchain-env|lib"

echo "*********  Generating directory and file structure of the repository... *********"

tree -a -I "$IGNORE_PATTERN" > "$OUTPUT_FILE"

if [[ $? -eq 0 ]]; then
    echo "***************************************************************"
    echo "Structure generated successfully! File saved as '$OUTPUT_FILE'."
    echo "***************************************************************"
else
    echo "***************************************************************"
    echo "Error generating the structure. Make sure the 'tree' command is installed."
    echo "***************************************************************"
fi