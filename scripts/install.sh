#!/bin/sh
# Copy the addon into the local WoW Forever AddOns folder (WSL path).
set -eu
cd "$(dirname "$0")/.."
dest="${WOW_ADDONS:-/mnt/e/World of Warcraft/_forever_/Interface/AddOns}/RecipeScout"
mkdir -p "$dest"
cp RecipeScout.toc Recipe.lua Panel.lua RecipeScout.lua "$dest/"
echo "installed to $dest"
