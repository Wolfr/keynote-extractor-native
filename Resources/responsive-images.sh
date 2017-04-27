#!/bin/sh

#  responsive-images.sh
#  KeynoteExtractor
#
#  Created by Johan Ronsse on 27/04/2017.

# Bail on errors.
set -o errexit;

# Configure the widths and their labels. The label is what will be put between
# the original basename and the extension. E.g. "foo.jpg" for label " + large"
# will become "foo + large.jpg".
sizes=(
    1024='-lg'
    640='-md'
    320='-sm'
);

# Configure the extensions to look for. Note: no wildcards.
extensions=(
    jpg
    jpeg
    png
    gif
);

# Ignore generated files based on their filename.
for size in "${sizes[@]}"; do
    label="${size#*=}";
    for extension in "${extensions[@]}"; do
        GLOBIGNORE="$GLOBIGNORE:*$label.$extension";
    done;
done;
export GLOBIGNORE="${GLOBIGNORE#:}";

# If a directory has been specified, go there first. If not, execute it in the
# current working directory.
# TODO: support multiple directories as parameters to this script?
if [ -d "$1" ]; then
    cd "$1";
fi;

# If nothing matches the wildcard ("glob") pattern, don't include it
# literally. I.e., do not return "*.jpg" when there are no JPEG files.
shopt -s nullglob;

# Create an array of the images in the current directory.
files=();
for extension in "${extensions[@]}"; do
    files+=(*."$extension");
done;

# Now apply image transformation using sips on each of those files. Render the
# file to same folder and keep the original.
# `for foo in "${all_foos[@]}"; do xxx; done` is the way to loop through the
# "all_foos" array, putting the values in the "foo" variable in the for loop's
# body.
# TODO: Store the output in a separate directory?
for original in "${files[@]}"; do
    extension="${original##*.}";
    basename="${original/%.$extension}";
    
    for size in "${sizes[@]}"; do
        max_width="${size%=*}";
        label="${size#*=}";
        sips -Z "$max_width" "$original" --out "$basename$label.$extension";
    done;
done;
