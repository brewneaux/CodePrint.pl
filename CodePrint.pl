#!/usr/bin/perl
# 
# Author: jonathan.c.bruno@gmail.com
# version 1.0
# First authored during the fall of 2014 on my free time
# Description: Levarges Vim to create HTML output of your code, so you can easily print it.
# Keeping it old school for code reviews (like I do at work all the time...)

use warnings;
use strict;
use File::Copy;
use File::Basename;
use Data::Dumper;
use Getopt::Long;

my $input_file;

# We store a file, whereever this is, that only has the path where we are going to store the output.

if (!-e ".dest") {
    # throw away first input
    shift;
    print "Before this can run, we need to know where to save your converted documents.";
    print "Please input the full path you want to use\n";
    my $path = <>;
    chomp $path;
    print "Is this the path you want to use?\n\t$path\n\n";
    my $confirm = <>;
    chomp $confirm;
    if (lc($confirm) eq 'y') {
        open my $DEST, '>', '.dest' or die "Couldn't open .dest";

        # Append a slash if you didn't provide one
        if ($path !~ /\w*\/$/) {
            print $DEST $path . '/';
        } else {
            print $DEST  $path;
        }

        close $DEST;
    }
    print "Thanks, now you are all set up";
    exit;
}

$input_file = shift;

die "\nYou need to give an input file.\n\n" if not $input_file;

chomp $input_file;

my @files_to_run;
my $print_files_to_run = "\nThe following files will be converted to HTML. Enter Y to continue.\n";
my @finished_files;

# If the input was a directory, we convert everything on the first level of it
if (-d $input_file) {
    opendir(DIR, $input_file);
    while (my $file = readdir(DIR)) {
        if (-f $input_file . $file) {
            push @files_to_run, $file;
            $print_files_to_run .= "\t$file \n";
        }
    }

    print $print_files_to_run;

    my $ok_to_go = <>;
    
    chomp $ok_to_go;

    if (lc($ok_to_go) ne "y") {
        exit;
    }

    foreach my $file_to_run (@files_to_run) {
        my $return = buildHtml($input_file . $file_to_run);    
        push @finished_files, $return;
    }
}
else {
    my $return = buildHtml($input_file);
    push @finished_files, $return;
}

my $file_msg_body = join("\n\t", @finished_files);

print "Finished converting files. \n\t$file_msg_body\n";

sub buildHtml {

    my $input_file = shift;
    # Build out a bunch of filenames.
    my $input_file_html = $input_file . '.html';
    my $basename = File::Basename::basename($input_file);
    my $base_html = $basename . '.html';
    my $temp_filename = "/tmp/$ENV{USER}/$base_html";

    # Read the file path we are going to use for ouput
    open my $DEST, "<", ".dest" or die "Couldn't open .dest";
    my $print_dir = <$DEST>;
    close $DEST;

    my $output_file = "$print_dir" . $basename . '.html';

    # Make a user directory in tmp if it doesn't exist. This is only really necessary on DWH3, to stop permission overlaps
    if (!-d "/tmp/$ENV{USER}") {
        system("mkdir /tmp/$ENV{USER}");
    }

    # *********
    # This section keeps your print folder clean
    # *********

    my @filearray;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $datefilename_today = ($year + 1900) . $mon + 1 . $mday;
    my ($ysec,$ymin,$yhour,$ymday,$ymon,$yyear,$ywday,$yyday,$yisdst) = localtime(time() - 24*60*60);
    my $datefilename_yesterday = ($yyear + 1900) . $ymon + 1 . $ymday;

    # Create print_dir if it doesn't exist
    if (!-d $print_dir) {
        system("mkdir -p $print_dir");
    }

    # If there are files in there already, and they have same name or are more than a day old, 
    # Move them to an archive folder
    opendir (DIR, $print_dir) or die $!;
    while (my $file = readdir(DIR)) {
        push @filearray, $file if ($file eq $base_html);
    }

    if (@filearray) {
        foreach my $filetwo (@filearray) {
            if (-M $print_dir . $filetwo > 1) {
                system("mkdir -p $print_dir/old/$datefilename_yesterday");
                system("mv $print_dir$filetwo $print_dir/old/$datefilename_yesterday/.")
            }
            elsif ($filetwo eq $base_html) {
                system("mkdir -p $print_dir/old/$datefilename_today");
                system("mv $print_dir$filetwo $print_dir/old/$datefilename_today/.")
            }
        }
    }



    # This does all the HTML magic - we are only using it to assign words their types.
    my $vim_command = q(vim -E -s -c "let g:html_no_progress=1" -c "let g:html_number_lines = 1" -c "syntax on" -c "runtime syntax/2html.vim" -cwqa ) . $input_file;

    `$vim_command`;

    File::Copy::move($input_file_html, $temp_filename);

    # This is a brand new, custom header that I wrote.  It does a lot of cool stuff, including:
    #   Black and white syntax highlighting, using bold, italics, and greys.
    #   Font size changing with a button

    my $new_header = qq(
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=UTF-8">
<title>$input_file</title>) . q(
<meta name="Generator" content="Vim/7.3">
<meta name="plugin-version" content="vim7.3_v12">
<meta name="syntax" content="perl">
<meta name="settings" content="use_css,pre_wrap,no_foldcolumn,prevent_copy=">
<meta name="colorscheme" content="none">
<style type="text/css">
pre {
    white-space: pre-wrap;
    font-family: Menlo, monospace;
    color: #000000;
    background-color: #ffffff;
}

body {
    font-family: Menlo, monospace;
    color: #000000;
    background-color: #ffffff;
    white-space: pre;

}

.Comment {
    color: #555;
    font-style: italic;
}

.Special {
    color: #444;
}

.Identifier {
    color: #000;
    font-weight: bold;
}

.Statement {
    color: #444;
    font-weight: bold;
}

.PreProc {
    color: #777777;
}

.LineNr {
    color: #333;
}

.Error {
    color: black;
    font-weight: bold;
}

.Type {
    color: black;
    font-weight: bold;
}

.line {
    font-size: 12px;
    text-indent: -4em;
    margin-left: 4em;
    line-height: 1.2;
}

.fontchanger {
    height: 40px;
    width: 300px;
    position: fixed;
    top: 10px;
    right: 10px;
    border-radius: 6px;
}

.increase, .decrease {
    cursor: pointer;
    user-select: none;
    -webkit-user-select: none;
  /* Chrome all / Safari all */
    -moz-user-select: none;
     /* Firefox all */
    -ms-user-select: none;
      /* IE 10+ */
    font-size: 3em;
    color: white;
    vertical-align: center;
    text-align: center;
    background-color: #666;
    border-radius: 5px;
    width: 45px;
    height: 45px;
    margin-left: 15px;
    float: left;
}

.currentSize {
    float:left;
    margin-top: 10px;   
}
@media print
{    
    .fontchanger
    {
        display: none !important;
    }
}
</style>
<script src="http://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
<script>$(document).ready(function() {
    $(document.body).append( "<div class='fontchanger'><span class='increase' onclick='increaseFont()'>+</span><span class='decrease' onclick='decreaseFont()'>-</span></div>");
});</script>
<script>
function increaseFont() {
    var currentSize = parseInt($('.line').css("font-size"));
    currentSize++;
    $('.line').css("font-size",currentSize);
    $('.currentSize').remove();
    $('.fontchanger').append('<span class="currentSize"> The current font size is ' + currentSize + 'px</span>');
}

function decreaseFont() {
    var currentSize = parseInt($('.line').css("font-size"));
    currentSize--;
    $('.line').css("font-size",currentSize);
    $('.currentSize').remove();
    $('.fontchanger').append('<span class="currentSize"> The current font size is ' + currentSize + 'px</span>');

}
</script>
</head>
    );

    # This first step figures out where we can start after our header is appended - I think it will always be the same but I'm not taking the chances.
    open my $INPUT_FROM_VIM, '<', $temp_filename;
    my $begin_line_number;
    my $i;

    while (my $line_in = <$INPUT_FROM_VIM>) {
        last if ($begin_line_number);
        if ($line_in =~ '</head>') {
            $begin_line_number = $i;
        }
        $i++;
    }

    # Open up the output
    open my $OUTFILE, '+>', $output_file or die "couldnt open output $output_file";

    my $timestring = ($mon +1) . '/' . $mday . '/' . ($year + 1900) . " $hour:$min:$sec $input_file";
    # put in the header
    print $OUTFILE $new_header;
    # We wrap each line in a div to allow for the class indented-wrap stuff.
    while (my $line_to_print = <$INPUT_FROM_VIM>) {
        if ($line_to_print =~ /vimCodeElement/g) {
            print $OUTFILE q(<div class="line"><pre id='vimCodeElement'><br />) . $timestring . q(<br /></div>);
        } else {
        print $OUTFILE '<div class="line">' . $line_to_print . '</div>' if ($. > $begin_line_number);
        }
    }

    close $OUTFILE;
    close $INPUT_FROM_VIM;

    # Clean up after ourselves.
    if (-e $input_file_html) {
        unlink $input_file_html;
    }
    if (-e $temp_filename){
        unlink $temp_filename;
    }

    return $output_file;
}

