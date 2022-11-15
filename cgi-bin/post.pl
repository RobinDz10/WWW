#!/usr/bin/perl -Tw 2:

use CGI;
use strict;
use CGI::Carp qw(fatalsToBrowser);

my $query = new CGI;
my $topic_directory = "topics";
my $page_title;
my ($action, $author, $title, $post, $response_to) = ("","","","","");

print $query->header;

if ($query->param('action')) {
     &set_variables;
     # The form to create a new topic has been submitted
     if ($action eq "new") {
          my $error_message = &validate_form;
          if (!$error_message) {
               my $topic = &write_new_topic;
               $page_title = $title;
               &print_page_start;
               &print_success;
               &print_page_end;
          }
          else {
               $page_title = "New Topic";
               &print_page_start;
               &print_error($error_message);
               &print_form;
               &print_page_end;
          }
     }
     elsif ($action == "response") {
          &set_variables;
          my $error_message = &validate_form;
          if (!$error_message) {
               &write_response;
               $page_title = "New response entered";
               &print_page_start;
               &print_response_success;
               &print_page_end;
          }
          else {
               $page_title = "New response";
               &print_page_start;
               &print_error($error_message);
               &print_form;
               &print_page_end;
          }
     }
}
else {
     $action = "new";
     $page_title = "Enter new topic";
     &print_page_start;
     &print_form;
     &print_page_end;
}

sub set_variables {
     $action = ($query->param('action') || "");
     $title = ($query->param('title') || "");
     $author = ($query->param('author') || "");
     $post = ($query->param('post') || "");
     $response_to = ($query->param('response_to') || "");
}

sub print_page_start {
     print "<html>\n<head>\n<title>$page_title</title>\n</head>\n";
     print "<body>\n<h1>$page_title</h1>\n";
}

sub print_page_end {
     print "<p><a href=\"display.pl\">view response list</a> |\n";
     print "<a href=\"post.pl\">create new topic</a></p>\n";
     print "</body>\n</html>\n";
}

sub print_form {
     print "<p><table border=\"0\" bgcolor=\"lightgrey\">\n";
     print "<tr><td colspan=\"2\">";
     if ($action eq "response") {
          print "<b>Enter your response below:</b></td></tr>\n";
     }
     else {
          print "<b>Create your new topic below:</b></td></tr>\n";
     }
     print "<form method=\"post\">\n";
     print "<input type=\"hidden\" name=\"action\" value=\"$action\" />";
     if ($action eq "response") {
          print "<input type=\"hidden\" name=\"response_to\" ";
          print "value=\"$response_to\" />\n";
     }
     if ($action eq "new") {
          print "<tr><td><b>Topic Title:</b></td><td>";
          print "<input type=\"text\" name=\"title\" ";
          print "size=\"40\" maxlength=\"72\" value=\"$title\" />\n";
          print "</td></tr>\n";
     }
     print "<tr><td><b>Author:</b></td>";
     print "<td><input type=\"text\" name=\"author\" ";
     print "size=\"40\" maxlength=\"72\" value=\"$author\" />\n";
     print "</td></tr>\n";
     print "<tr><td colspan=\"2\"><b>Message body:</b></td></tr>\n";
     print "<tr><td colspan=\"2\">\n";
     print "<textarea rows=\"10\" cols=\"60\" name=\"post\" ";
     print "wrap=\"virtual\">$post</textarea><br />\n";
     if ($action eq "response") {
          print "<input type=\"submit\" value=\"post response\"><br />\n";
     }
     else {
          print "<input type=\"submit\" value=\"post topic\"><br />\n";
     }
     print "</td></tr>\n";
     print "</form>\n";
     print "</table></p>\n";
}

sub validate_form {
     my $error_message = '';
     if ($title eq '' && $action eq 'new') {
          $error_message .= "<li>You must enter a title.</li>\n";
     }
     if ($author eq ''){
          $error_message .= "<li>You must enter an author.</li>\n";
     }
     if ($post eq '') {
          $error_message .= "<li>You must enter a message.</li>\n";
     }
     if ($error_message eq ''){
          return undef;
     }
     else {
          return $error_message;
     }
}

sub write_new_topic {
     my $topic = time . $$;
     open (TOPIC, "> $topic_directory/$topic.xml")
          or die "Can't open $topic_directory/$topic.xml";
     print TOPIC "<topic>\n";
     print TOPIC "<title>$title</title>\n";
     print TOPIC "<author>$author</author>\n";
     print TOPIC "<lastmodified>" . time . "</lastmodified>\n";
     print TOPIC "<post>\n";
     $post =~ s/\n/<br \/>\n/g;
     print TOPIC $post;
     print TOPIC "</post>\n";
     print TOPIC "</topic>\n";
     close TOPIC;
     return $topic;
}

sub write_response { 
     if ($response_to =~ /^([-\@\w.]+)$/) { 
          $response_to = $1;
     } else {
          print "<p>Tainted data submitted. Response not written.</p>\n";
          return;
     }

     my $topic_file = $response_to . '.xml';
     open (TOPIC, "+>> $topic_directory/$topic_file")
          or die "Can't open $topic_directory/$topic_file";
     flock TOPIC, 2;
     seek TOPIC, 0, 0;
     my @topic_text = <TOPIC>;
     my $topic_text = join '', @topic_text;
     my $current_time = time;
     $topic_text =~ s/<lastmodified>(\d+)<\/lastmodified>/<lastmodified>$current_time<\/lastmodified>/x;
     $topic_text =~ s/<\/responses>//;
     $topic_text =~ s/<\/topic>//;
     seek TOPIC, 0, 0;
     truncate TOPIC, 0;
     print TOPIC $topic_text;
     if ($topic_text !~ /<responses>/) { 
          print "<responses>\n";
     }
     print TOPIC "<response>\n";
     print TOPIC "<responseauthor>$author</responseauthor>\n";
     $post =~ s/\n/<br \/>\n/g;
     print TOPIC "<responsepost>$post</responsepost>\n";
     print TOPIC "</response>\n";
     print TOPIC "</responses>\n";
     print TOPIC "</topic>\n";
     close TOPIC;
}

sub print_success {
     "<p><b>Created new topic: $title.</b></p>\n";
}

sub print_response_success {
     print "<p>New response entered.</p>\n";
}

sub print_error {
     my $error_message = shift(@_);
     print "<p>Please correct the following errors:</p>\n";
     print "<ul>$error_message</ul>\n";
}
