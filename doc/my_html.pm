use warnings;
use strict;

# fix various annoyances in the texinfo to HTML conversion
#  (1) enclose @quotation in <div>
#  (2) @footnote text should have label inlined

package Texinfo::Config;

use Texinfo::Convert::HTML;
use Carp;

unless (Texinfo::Config->can('texinfo_register_init_loading_warning')) {
    # this was not added until 7.0
    *texinfo_register_init_loading_warning = sub {
        carp "$_[0]";
    };
}


################################################################
#   (1) enclose @quotation in <div>
#       with its own class so that it can be sensibly css-formatted

my $qconv;
for my $dcc (qw(default_commands_conversion
                default_command_conversion)) {
    # method renamed between 6.8 and 7.0
    if (Texinfo::Convert::HTML->can($dcc)) {
        $qconv = Texinfo::Convert::HTML->$dcc('quotation');
        last;
    }
}

sub convert_quotation {
    my $self = shift;
    my $cquote = $self->$qconv(@_);
    if (!$self->in_string()) {
        $cquote = "<div class=\"quotation\">" . $cquote . "</div>";
    }
    return $cquote;
}

if ($qconv) {
    Texinfo::Config::texinfo_register_command_formatting(
        quotation => \&convert_quotation
       );
}
else {
    warn 'quotations not reformatted -- need to update '
      . __FILE__ . ' for texinfo version '
      . $Texinfo::Convert::HTML::VERSION;
}


################################################################
# (2) @footnote text should have label inlined
#

sub footnote_mark($$$) {
    my ($id, $href, $mark) = @_;
    return qq{<sup><a id="$id" href="$href">$mark</a></sup>};
}
sub footnote_outer($) {
    chomp $_[0];
    return qq{<div class="footnote-text">$_[0]\n</div>\n};
}

sub format_footnote($$$$$$)
{
  my $self = shift;
  my ($command, $id, $number_in_doc, $href, $mark) = @_;

  my $category = 'footnote mark';
  my $mark_text = footnote_mark($id, $href, $mark);

  $self->register_pending_formatted_inline_content(
      $category, "$mark_text&emsp;");

  my $footnote_text
      = $self->convert_tree_new_formatting_context(
          $command->{'args'}->[0],
          "$command->{'cmdname'} $number_in_doc $id");

  my $cancelled = $self->cancel_pending_formatted_inline_content(
      $category);

  return footnote_outer(
      ($cancelled ? "<p>$mark_text</p>" : '')
      . $footnote_text);
}

# eventually:
#
#    texinfo_register_formatting_function(
#        format_single_footnote => \&format_footnote);
#
# but for now we need to be backwards compatible:

use version;

sub valid_format_key;
# is KEY valid for texinfo_register_formatting_function?

eval {
    no warnings 'all';
    Texinfo::Convert::HTML->default_formatting_function(
        'never never'  # known invalid handler name
       );
    # 7.0+    does ${default_formatting_references}{$_[0]},
    #   and can thus test for valid keys
    # pre-7.0 does $_[0]->{default_formatting_functions},
    #   raises "Can't use string as a HASH ref..."
    #   and is useless
};
if (!$@) {
    *valid_format_key = sub {
        return !!Texinfo::Convert::HTML
          ->default_formatting_function($_[0]);
    };
}
elsif (version->parse($Texinfo::Convert::HTML::VERSION)
       >= version->parse("7.0")) {
    texinfo_register_init_loading_warning(
        'somebody broke ' .
        'Texinfo::Convert::HTML::default_formatting_function ??'
        );
    *valid_format_key = sub { return 0; };
}
else {
    *valid_format_key = sub {
        my $key = shift;
        return eval {
            no warnings 'all';
            local *carp = sub {};
            return !!texinfo_register_formatting_function($key, 1)
              # pre-7.0: invalid $key carps and returns 0
              # 7.0+: accepts any $key; always returns handler
              &&
              # restore the prior state (not strictly necessary):
              !texinfo_register_formatting_function($key, undef);
        };
    };
}

my $format_key;
for my $fk (qw(format_single_footnote
               format_footnotes_sequence
               format_special_element_body
               special_element_body)) {
    next unless valid_format_key($fk);
    $format_key = $fk;
    last;
}

unless ($format_key) {
    texinfo_register_init_loading_warning(
        "default format handlers are missing ??"
       );
}
elsif ($format_key eq 'format_single_footnote') {
    texinfo_register_formatting_function(
        $format_key => \&format_footnote);
}
else {
    my sub reformat_footnote_sequence {
        my $otext = shift;
        return $otext
          if ($otext !~ m/^<h5/);

        my $ntext = '';
        while ($otext =~ m{ \G
                              <h5.*?>(.*?)</h.>   # $1 = footnote label
                              # work around 6.8 bug (h5 closed by h3)

                              [ \t\n]*(<p\b.*?>)? # $2 = first <p> ?
                              (.*?)               # $3 = rest of note
                              (?:(?=<h5)|\z)
                        }gxsaai) {
            my ($anchor, $start, $rest) = ($1, $2, $3);
            if (my ($id, $href, $mark)
                = $anchor =~ m{<a id="(.*?)" href="(.*?)">[(](.*?)[)]</a>}aai) {
                $anchor = footnote_mark($id, $href, $mark);
            }
            $ntext .= footnote_outer(
                ($start
                 ? qq{$start$anchor&emsp;}
                 : qq{<p>$anchor</p>})
                . $rest
               );
        }
        return $ntext;
    }

    texinfo_register_formatting_function(
        $format_key => sub {
            my $self = shift;
            my $default_fn =
              $self->default_formatting_function($format_key);
            my $otext = $self->$default_fn(@_);
            return $otext
              if ($format_key =~ m/special_element_body$/
                  && $_[0] ne 'Footnotes');
            return reformat_footnote_sequence($otext);
        });
}

1;
