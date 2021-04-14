#!/bin/bash

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
    s/(picture )(.*)/<img src=\"..\/pictures\/\2\"\/>/
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
    title_src=$(head -n 1 ./page/$file)
    anchor="<a href=\"#top\"><\/a>"
    title=$(sed -rn "s/(title \")(.*)(\")/<h1>\2<\/h1>/p" ./html/$html_file)
    style_sheet="<link rel="stylesheet" href="../style/style.css">"
    sub_title=$(sed -rn "s/header/<small>$author \| $date<\/small>/p" ./html/$html_file)
    sed -in "1,4d" ./html/$html_file
    sed -i "
    1i $style_sheet
    2i $title
    3i $sub_title
    4i $anchor
    " ./html/$html_file
}

create_footer (){
    sed -rin "$ d" ./html/$html_file
    echo "<small><a name="top" href="">Top</a></small>" >> ./html/$html_file
}

create_code (){
    sed -rin "
        # If a line starts with code jump to wrap label
        s/^code/<div class=hl_box>\n<pre>\n<code>/
        t move
        b
    
        :move
        n # Read in next line into the pattern buffer (line counter increases)

        /^!/{
        s/.*/\n/
        t move # Jump to move label only if substitution occurs
        }

        /^$/!{
        b move # primitive looping!!
        }
        s/.*/<\/code>\n<\/pre>\n<\/div>/ # Substitute all of the pattern buffer
    " $1
}

create_html (){
    cp $file_path "$file.html"
    html_file="$file.html"
    mv "$html_file" ./html/
    
    author="GrapeJuiceSoda"
    date=$(date)
    
    del_comments ./html/$html_file
    del_blank ./html/$html_file
    create_para ./html/$html_file
    create_header ./html/$html_file
    create_symbols ./html/$html_file
    create_list ./html/$html_file
    create_code ./html/$html_file
    create_title 
    create_footer
}

# Main
# Create the HTML file
declare -a param_arry
while [ ! $# -eq 0 ] # While parameter is not equal to 0/null
do
    param_arry+=($1)
    shift
done

for i in ${param_arry[@]}
do
    
    if [[ $i =~ ^--help ]]; then
        # do somethin
        echo "USEAGE: wwbs [OPTION]"
        echo "  --help                  Print help message"
        echo "  --file='page/text'      Input text"
        echo "  --raw='text'            Print raw html file"
        echo "  --delete='text'         Delete raw html file"
        echo "EXAMPLE: "
        echo "  wwbs --file=page/sample"
        echo "  wwbs --raw=sample"
        exit
    elif [[ $i =~ ^--file ]]; then
        file_path=$(echo $i | sed -nr 's/(^--file=)(.*)/\2/p')
        file=$(echo $i | sed -nr 's/(^--file=)(.*\/)(.*)/\3/p')
        create_html
    elif [[ $i =~ ^--raw ]]; then
        file=$(echo $i | sed -nr 's/(^--raw=)(.*)/\2/p')
        cat html/"$file.html"
        exit
    elif [[ $i =~ ^--delete ]]; then
        file=$(echo $i | sed -nr 's/(^--delete=)(.*)/\2/p')
        html_file="$file.html"
        if [[ -f html/$html_file ]]; then
            rm html/$html_file
            echo "Deleted $html_file"
        fi
        exit
    else
        exit
    fi
done

# Clean up
file=./html/$(ls ./html/ | grep ".htmln")
if [[ -f $file ]]; then
    echo "Removing something"
    rm $file
fi
