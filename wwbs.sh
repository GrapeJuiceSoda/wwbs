#!/bin/bash

# Create the HTML file
cp $1 "$1.html"

html_file="$1.html"

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
    # read in a line from the $html_file
    while read line; do
        # Grab the line that contains the header symbol
        flag=$(echo "$line" | grep "^:")
        # Get the length of the grepped line
        len=$(echo ${#flag})
        if [[ $len != 0 ]]; then
            # Get the length of the header symbol
            header_num=$(echo $line | awk '{print length($1)}')
            # Swap the header symbols for <h#>
            sed -rin "
            /$line/ b wrap
            b
            :wrap
            s|(:+ )(.*)|<h$header_num>\2<\/h$header_num>|
            " $1
        fi
    done < $1
}

# Input is $html_file
create_symbols (){
    sed -rin '
    /^(link|picture|ul|nl)/ b wrap
    b
    
    :wrap
    /^link/ b link_wrap
    /^picture/ b picture_wrap
    b
    
    :link_wrap
    s/(link )(.* )(.*)/<a href=\"\2\">\3<\/a>/
    b
    
    :picture_wrap
    s/(picture )(.*)/<img src=\"\2\"\/>/
    b

    ' $1
}


del_comments $html_file
del_blank $html_file
create_para $html_file
create_header $html_file
create_symbols $html_file

# Clean up
file=$(ls ./ | grep ".htmln")
if [[ -f $file ]]; then
    echo "Removing something"
    rm $file
fi
