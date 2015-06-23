#!/usr/bin/env perl

use strict;
use warnings;

my $DIR_IN = 'in/';
my $DIR_OUT = 'out/';

&process_dir($DIR_IN, $DIR_OUT);

sub process_dir {
	my $dir_in = shift;
	my $dir_out = shift;
	
	opendir(my $dir_handler, $dir_in);
	while (my $dir_item = readdir($dir_handler)) {
		next if ($dir_item eq "." or $dir_item eq "..");
		#if ($dir_item !~ /^(\.|\.\.)$/) {
			my $file_in = join('/', ($dir_in, $dir_item));
			my ($file_out_jp, $file_out_en) = &prepare($dir_item, $dir_out);
			my $text = &readfile($file_in);
			my @lrc = &findlrc($text);
			my ($orig_title, $en_title) = &findnamae($text);
			print "$orig_title\t$en_title\n";
			my ($romaji, $eng) = &s_lrc(@lrc);
			$romaji = $orig_title . $romaji;
			$eng = $en_title . $eng;
			#print $romaji;
			#print $eng;
			&writefile($file_out_jp, $romaji);
			&writefile($file_out_en, $eng);
			print "\n\nDone\n\n";
		#}
	}
	closedir($dir_handler);
}

sub prepare {
	my $file = shift;
	my $dir_out = shift;
	
	my ($filename, $ext) = $file =~ /^(.+)\.(.+)$/;
	my $out_romaji = $dir_out . $filename . "_romaji" . '.' . $ext;
	my $out_eng = $dir_out . $filename . "_eng" . '.' . $ext;
	
	return ($out_romaji, $out_eng);
}

sub readfile {
	my $f_name = shift;
	my $text = "";
	open(my $f, $f_name);
	while(my $line = <$f>) {
		$text .= $line;
	}
	close($f);
	return $text;
}

sub writefile {
	my $f_name = shift;
	my $text = shift;
	open(my $f, '>', $f_name);
	print $f $text;
	close($f);
}

sub s_lrc {
	my @lrc = @_;
	my @romaji;
	my @eng;
	
	my $WHITELINES = 2;
	for (my $i = 0; $i < $WHITELINES + 1; $i++) {
		push(@romaji, '');
		push(@eng, '');
	}
	#push(@romaji, ($orig_title, '', ''));
	#push(@eng, ($en_title, '', ''));
	foreach my $line (@lrc) {
		if ($line =~ /^\s+$/) {
			#push(@romaji, $line);
			#push(@eng, $line);
			push(@romaji, '');
			push(@eng, '');
		}
		elsif ($line =~ /^\s+/) {
			($line) = $line =~ /\s+(.+)/;
			push(@eng, $line);
		}
		else {
			push(@romaji, $line);
		}
	}
	return (join("\n", @romaji), join("\n", @eng));
}

# find english and original (romaji) title
sub findnamae {
	my $text = shift;
	
	my $orig_title = '';
	my $eng_title = '';
	my @lines = split('\n', $text);
	foreach my $line (@lines) {
		if ($line =~ /^.+-{1}.+-{1}/) {
			my @names = split(' - ', $line);
			if (scalar(@names) == 4) {
				$orig_title = shift(@names);
				$eng_title = shift(@names);
			} 
			elsif (scalar(@names) == 3) {
				$orig_title = shift(@names);
				$eng_title = $orig_title;
			}
			last;
		}
	}
	return ($orig_title, $eng_title);
}

sub findlrc {
	my $text = shift;
	my @lrc = ();
	
	my @lines = split('\n', $text);
	my $i = 0;
	foreach my $line (@lines) {
		$i++;
		#lyrics are placed between 90 "-" chars
		if ($line =~ /-{90,}/) {
			for (my $j = $i; $j < scalar(@lines); $j++) {
				$line = $lines[$j];
				if ($line =~ /-{90,}/) {
					last;
				}
##				if (index($line, "That kind of heart") != -1) {
##					print $line;
##					print "\n";
##				}
				# print "$line\n";
				push(@lrc, $line);
			}
			last;
		}
	}
	return @lrc; 
}

