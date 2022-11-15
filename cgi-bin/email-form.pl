#!/usr/bin/perl

use CGI;
use Net::SMTP;
my $query = new CGI;
my $smtp = Net::SMTP->new('localhost');
# Set to the name of the to address
my $address = "duozwang\@iu.edu";
my $address_teacher = "dzrobin91\@gmail.com";
my $error_message = "";
if (!$query->param()) {
  &print_page_start;
  &print_form;
  &print_page_end;
} else {
  &set_form_vars;
  if (!&validate_form) {
    &send_email;
    &print_page_start;
    &print_success;
    &print_page_end;
  } else {
    &print_page_start;
    &print_error_message;
    &print_form;
    &print_page_end;
  }
}

sub print_page_start {
  print $query->header;
  print "<html>\n";
  print "<head>\n";
  print "<title>Email Form</title>\n";
  print "</head>\n";
  print "<body>\n";
  print "<h1>Email Form</h1>\n";
}

sub print_page_end {
  print "</body>\n";
  print "</html>\n";
}

sub set_form_vars {
  $from = $query->param('from');
  $subject = $query->param('subject');
  $body = $query->param('body');
}

sub print_form {
  print "<form method=\"post\">\n";
  print "<p>\nYour email address:\n";
  print "<input type=\"text\" name=\"from\" value=\"$from\" />\n";
  print "</p>\n";
  print "<p>\nEmail subject:\n";
  print "<input type=\"text\" name=\"subject\" value=\"$subject\" />\n";
  print "</p>\n";
  print "<p>\nEmail body:<br />\n";
  print "<textarea name=\"body\" wrap=\"physical\" rows=\"5\" ";
  print "cols=\"70\">";
  print $body;
  print "</textarea>\n</p>\n";
  print "<p>\n<input type=\"submit\" value=\"Send Email\" />\n</p>\n";
  print "</form>\n";
}

sub validate_form {
  if (!$subject) {
    $error_message .= "<li>You need to enter a subject ";
    $error_message .= "for your message.</li>\n";
  }
  if (!$from) {
    $error_message .= "<li>You need to specify a recipient for ";
    $error_message .= "the message.</li>\n";
  }
  if ($from !~ /^[\w\.]+\@[\w\.]+$/) {
    $error_message .= "<li>The email address you entered is invalid,";
    $error_message .= "please enter a valid address. </li>\n";
  }
  if (!$body) {
    $error_message .= "<li>You need to enter some text in the ";
    $error_message .= "body of your message.</li>\n";
  }
  return $error_message;
}

sub print_error_message {
  print "<font color=\"red\">\n";
  print "<p>Please correct the following errors:</p>\n";
  print "<ul>\n";
  print $error_message;
  print "</ul>\n";
  print "</font>\n";
}

sub print_success {
  print "<p>An email with the subject \"$subject\" was sent to ";
  print "$address from $from.</p>\n";
}

sub send_email {
  $smtp->mail($from);
  $smtp->to($address);
  $smtp->to($address_teacher);
  $smtp->data();
  $smtp->datasend("From: $from\n");
  $smtp->datasend("To: $address\n");
  $smtp->datasend("To: $address_teacher\n");
  $smtp->datasend("Subject: $subject\n");
  $smtp->datasend("\n");
  $smtp->datasend($body);
  $smtp->dataend();
  $smtp->quit();
}

