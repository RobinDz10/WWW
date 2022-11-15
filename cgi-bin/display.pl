#!/usr/bin/perl -Tw 2:

use CGI;
use strict;
my $query = new CGI;
my $topic_directory = "topics";
my $page_title = "Message Board";
my @response_list = ();
my ($topic_title, $topic_author, $last_modified, $post);
my $need_header = 1;

if ($query->param('topic')) {
    &parse_topic(&open_topic($query->param('topic')));
    $page_title = $topic_title;
    &print_page_start;
    &print_topic;
    &print_response_form($query->param('topic'));
    &print_page_end;
}
else {
    $page_title = "Topic Index"; 
    &print_page_start; 
    $need_header = 0;
    &print_topic_index;
    &print_page_end;
} 

sub print_page_start {
    print $query->header;
    print "<html>\n<head>\n<title>$page_title</title>\n</head>\n";
    print "<body>\n<h1>$page_title</h1>\n";
}

sub print_page_end {
    print "<p><a href=\"display.pl\">view response list</a> |\n";
    print "<a href=\"post.pl\">create new topic</a></p>\n";
    print "</body>\n</html>\n";
}

sub print_topic_index { 
    eval {
        opendir (TOPICS, "$topic_directory")
            or die "Can't open $topic_directory";
        my @topics = grep (/^.+\.xml$/, readdir (TOPICS)); 
        print "<p>\n";
        foreach my $topic (@topics) {
            $topic =~ s/(.+)\.xml/$1/;
            &parse_topic(&open_topic($topic));
            print "<b><a href=\"display.pl?topic=$topic\">"; 
            print "$page_title</a></b>, $topic_author<br />\n";
        } 
        print "</p>\n";
    };
}

sub open_topic {
    my $topic = shift(@_);
    if ($topic =~ /^([-\@\w.]+)$/) {
        $topic = $1;
    }
    else{
        print "<p>Tainted data submitted. Response not opened.</p>\n";
        return; 
    }
    my $topic_file = "$topic_directory/" . $topic . ".xml";
    my @topic_text = ();
    eval {
        open (TOPIC, "< $topic_file")
            or die "Can't open $topic_file";
        @topic_text = <TOPIC>;
    };
    if ($@) { 
        &file_error($@);
    }
    return join("", @topic_text);
}

sub parse_topic {
    my $topic_text = shift(@_);
    if (!$topic_text) {
        &format_error("Empty topic file.");
        return; 
    }
    # Extract the topic title from the topic
    if ($topic_text =~ /<title>(.*)<\/title>/s) {
        $page_title = $1;
        $topic_title = $1;
    }
    else {
        &format_error("Title not found.");
        return;
    }
    # Extract the author from the topic
    if ($topic_text =~ /<author>(.*)<\/author>/s) {
        $topic_author = $1;
    }
    else {
        &format_error("Topic author not found.");
        return;
    }
# Extract the date when the file was last modified
    if ($topic_text =~ /<lastmodified>(.*)<\/lastmodified>/s) {
        $last_modified = $1;
    }
    else {
        &format_error("Last modified date not found.");
        return;
    }
    # Extract the first post from the topic
    if ($topic_text =~ /<post>(.*)<\/post>/s) {
        $post = $1;
    }
    else {
        &format_error("Post not found.");
        return;
    }
    while ($topic_text =~ /<response>(.*?)<\/response>/sg) {
        my $response = $1;
        if ($response =~ /<responseauthor>(.*)<\/responseauthor>/s) {
            push @response_list, $1;
        }
        else {
            &format_error("Invalid response format (author).");
            return;
        }
        if ($response =~ /<responsepost>(.*)<\/responsepost>/s) {
            push @response_list, $1;
        }
        else {
            &format_error("Invalid response format (post).");
            return;
        } 
    }
}

sub print_topic {
    print "<p><table border=\"1\" cellspacing=\"0\" ";
    print "cellpadding=\"5\">\n";
    print "<tr><td colspan=\"2\" bgcolor=\"cyan\">";
    print "<b>$topic_title</b></td></tr>\n";
    print "<tr><td>Author:</td><td>$topic_author</td></tr>\n";
    print "<tr><td>Most recent response:</td>";
    print "<td>", scalar localtime($last_modified), "</td></tr>\n";
    print "<tr><td colspan=\"2\">";
    print "$post\n";
    print "</td></tr>\n";
    my $part_type = "author";
    foreach my $response_part (@response_list) {
        if ($part_type eq "author") {
            print "<tr bgcolor=\"lightgrey\">";
            print "<td colspan=\"2\">Response from ";
            print "$response_part</td></tr>\n";
            $part_type = "body";
        }
        else {
            print "<tr><td colspan=\"2\">";
            print "$response_part\n";
            print "</td></tr>\n";
            $part_type = "author";
        } 
    }
    print "</table></p>\n"; 
}



sub print_response_form {
    my $topic = shift(@_);
    my $author = ($query->param('author') || "");
    print "<p><table border=\"0\" bgcolor=\"lightgrey\">\n";
    print "<tr><td><b>Enter your response below:</td></tr>\n";
    print "<form method=\"post\" action=\"post.pl\">\n";
    print "<input type=\"hidden\" name=\"action\" ";
    print "value=\"response\" />\n";
    print "<input type=\"hidden\" name=\"response_to\" ";
    print "value=\"$topic\" />\n";
    print "<tr><td>Author: ";
    print "<input type=\"text\" name=\"author\" ";
    print "size=\"40\" maxlength=\"72\" value=\"$author\" /></p>\n";
    print "</td></tr>\n";
    print "<tr><td><p>Message body:</td></tr>\n";
    print "<tr><td>\n";
    print "<textarea rows=\"10\" cols=\"60\" name=\"post\" ";
    print "wrap=\"virtual\">";
    print "</textarea></td></tr>\n";
    print "<tr><td>\n";
    print "<input type=\"submit\" value=\"post response\" />\n";
    print "</td></tr>\n";
    print "</form>\n";
    print "</table></p>\n";
}

sub format_error {
    if ($need_header) {
        print $query->header;
        print "<html><head><title>Format Error</title></head><body>\n";
    }
    my $error_message = shift(@_);
    print "<p><table border=\"1\" cellspacing=\"0\"><tr><td>\n";
    print "<h3>Format Error</h3>\n<p>$error_message</p>\n";
    print "</td></tr></table></p>\n";
}

sub file_error {
    my $error_message = shift(@_); 
    if ($need_header) {
        print $query->header;
    print "<html><head><title>File Error</title></head><body>\n";
    }
    print "<p><table border=\"1\" cellspacing=\"0\"><tr><td>\n";
    print "‹body><h3>File Error</h3>\n<p>$error_message</p>\n"; 
    print "</body>\n</html>\n"; 
    print "</td</tr></table></p>\n"; 
    exit;
}
