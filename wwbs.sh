#!/bin/bash

# Create the HTML file
cp $1 "$1.html"

file=$1
html_file="$1.html"
author="GrapeJuiceSoda"
date=$(date)

#Input $html_file
del_comments (){
    # Delete all lines that begin with #
    sed -i '/^#/d' $1
    # Delete comments inline
    sed -ri 's/(.+)(#.+)/\1/' $1
}

#Input $html_file
del_blank (){
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
    ' $1
}
    
#Input $html_file
create_para(){
    # This sed script will wrap the text with paragraph symbols
    sed -rni '
    /^$/ b wrap # Check if the pattern buffer is holding a blank line
    
    H # Append the pattern buffer to the hold buffer
    
    $ b wrap # Jump to wrap if end of file
    
    b
    
    :wrap
    x # Swap the pattern and hold buffer
    /\n(title|header|nav|link|picture|footer)/!{ # Check if the line is not a regular text
    s/(\n*)(.*)/\1\<p\>\n\2\n\<\/p\>/p # Surround the text block with paragraph symbols
    b
    }
    p # Print
    ' $1
}    


# Input is $html_file
create_header (){
    sed -rin "
    s/(^h)([0-9])(.*)/<h\2>\3<\/h\2>/
    " $1
}

# Input is $html_file
create_symbols (){
    sed -rin '
    /^(link|picture|ul|nl|\*)/ b wrap
    b
    
    :wrap
    /^link/ b link_wrap
    /^picture/ b picture_wrap
    /^ul/ b unorder_wrap
    /^\*/ b list_wrap
    b
    
    :link_wrap
    s/(link )(.* )(.*)/<a href=\"\2\">\3<\/a>/
    b
    
    :picture_wrap
    s/(picture )(.*)/<img src=\"\2\"\/>/
    b

    :unorder_wrap
    s/ul/<ul>/
    b

    :list_wrap
    s/(^\* )(.*)/<li>\2<\/li>/
    b

    ' $1
}

create_list (){
    sed -rin "
        # If a line starts with <ul> jump to wrap label
        /^<ul>/ b move
        b
    
        :move
        n # Read in next line into the pattern buffer (line counter increases)
        /^<li>/{
        b move # primitive looping!!
        }
        s/.*/<\/ul>/ # Substitute all of the pattern buffer for <\ul>
    " $1
}

create_title (){
    title_src=$(head -n 1 $file)
    title=$(sed -rn "s/(title \")(.*)(\")/<h1>\2<\/h1>/p" $html_file)
    sub_title=$(sed -rn "s/header/<h5>$author \| $date<\/h5>/p" $html_file)
    sed -in "1,4d" $html_file
    sed -i "
    1i $title
    2i $sub_title
    " $html_file
}


del_comments $html_file
del_blank $html_file
create_para $html_file
create_header $html_file
create_symbols $html_file
create_list $html_file
create_title

# Clean up
file=$(ls ./ | grep ".htmln")
if [[ -f $file ]]; then
    echo "Removing something"
    rm $file
fi
