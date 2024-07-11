#!/bin/bash

sed -i -E 's/"intendedFor": \[/"IntendedFor": \[/' "$1"
#sed -i -E 's/bids::sub-[0-9a-zA-Z]+\///g' "$1"

# Check if the OS is macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' -E 's/bids::sub-[0-9a-zA-Z]+\///g' "$1"
else
    sed -i -E 's/bids::sub-[0-9a-zA-Z]+\///g' "$1"
fi

