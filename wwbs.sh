#!/bin/bash

# Create the HTML file
cp $1 "$1.html"

html_file="$1.html"

# Delete all lines that begin with #
sed -i '/^#/d' $html_file

# Delete comments inline
sed -ri 's/(.+)(#.+)/\1/' $html_file

# This sed script will delete double blank lines
sed -ri '
/^$/ b check # Check if pattern buffer is holding a blank line
b

:check
h # Copy the pattern buffer to the hold buffer
N # Append the new line into the pattern buffer

/\n$/ b delete # Check if the pattern buffer ends with a new line
b

:delete
g # Override the pattern buffer with the hold pattern
' $html_file

# This sed script will wrap the text with paragraph symbols
sed -rni '
/^$/ b wrap # Check if the pattern buffer is holding a blank line

H # Append the pattern buffer to the hold buffer

$ b wrap # Jump to wrap if end of file

b

:wrap
x # Swap the pattern and hold buffer
/\n(title|header|nav|link|picture|footer|ul|nl)/!{ # Check if the line is not a regular text
s/(\n*)(.*)/\1\<p\>\n\2\n\<\/p\>/p # Surround the text block with paragraph symbols
b
}
p # Print
' $html_file

