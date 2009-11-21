# tokenizer.pl: tokenize Perl scripts as gonzui langscan format
#
# Author:  Tatsuhiko Miyagawa <miyagawa@bulknews.net>
# License: Same as Perl (Artistic/GPL2)
#

use strict;
use PPI::Tokenizer;
$PPI::Tokenizer::ALLOW_NONASCII = 1;

our $Debug = 0;
$| = 1;

# TODO:
# 'string' is abused
# regexp is string
# PPI fails to tokenize source code with UTF-8 binary

our(%TokenMap, %ReservedWords, %BuiltinFunctions);

if ($ARGV[0] && $ARGV[0] eq '-d') {
    # debug mode
    open my $fh, $ARGV[1] or die "$ARGV[1]: $!";
    my $code = join '', <$fh>;
    Tokenizer->new->tokenize(\$code);
} else {
    # persistent mode
    my $tokenizer = Tokenizer->new;
    while (1) {
	chomp(my $length = <STDIN>);
	last unless defined $length;
	read(STDIN, my($code), $length);
	$tokenizer->tokenize(\$code);
	$tokenizer->reset();
    }
}

package Tokenizer;

sub new {
    my $class = shift;
    my $self = bless { }, $class;
    $self->reset();
    $self;
}

sub reset {
    my $self = shift;
    $self->{lineno}     = 0;
    $self->{byteno}     = 0;
    $self->{heredoc}    = undef;
    $self->{in_sub}     = undef;
    $self->{in_package} = undef;
    $self->{in_arrow}   = undef;
    $self->{in_usereq}  = undef;
}

sub tokenize {
    my($self, $coderef) = @_;
    my $tokenizer = PPI::Tokenizer->new($coderef) or die "Can't tokenize code: $$coderef";
    while (my $token = $tokenizer->get_token) {
	$self->dump_element($token);
    }
    my $code_length = length $$coderef;
    $self->{byteno} == $code_length or die "Tokenize error: $self->{byteno}:$code_length";
}

sub dump_element {
    my($self, $element) = @_;
    if ($element->isa('PPI::Token::HereDoc')) {
	$self->_dump("punct", $element->content);
	$self->{heredoc} ||= [];
	push @{$self->{heredoc}}, {
	    body => $element->{_heredoc},
	    eof  => $element->{_terminator_line},
	};
	return;
    } elsif ($self->{heredoc} && $element->isa('PPI::Token::Whitespace') && $element->content eq "\n") {
	$self->_dump(token_name($element), $element->content);
	for my $heredoc (@{$self->{heredoc}}) {
	    $self->_dump(string => join "", @{$heredoc->{body}});
	    $self->_dump(punct  => $heredoc->{eof});
	}
	$self->{heredoc} = undef;
	return;
    } elsif ($element->isa('PPI::Token::Word') && $element->content eq 'sub') {
	$self->{in_sub} = 1;
    } elsif ($element->isa('PPI::Token::Word') && $element->content eq 'package') {
	$self->{in_package} = 1;
    } elsif ($element->isa('PPI::Token::Word') && ($element->content eq 'use' || $element->content eq 'require')) {
	$self->{in_usereq} = 1;
    } elsif ($element->isa('PPI::Token::Operator') && $element->content eq '->') {
	$self->{in_arrow} = 1;
    } elsif ($self->{in_sub} && !$element->isa('PPI::Token::Whitespace')) {
	$self->{in_sub} = undef;
	if ($element->isa('PPI::Token::Word')) {
	    warn "sub $element->{content}\n" if $Debug;
	    $self->_dump(fundef => $element->content);
	    return;
	}
    } elsif ($self->{in_package} && !$element->isa('PPI::Token::Whitespace')) {
	$self->{in_package} = undef;
	if ($element->isa('PPI::Token::Word')) {
	    warn "package $element->{content}\n" if $Debug;
	    $self->_dump(classdef => $element->content);
	    return;
	}
    } elsif ($self->{in_arrow} && !$element->isa('PPI::Token::Whitespace')) {
	$self->{in_arrow} = undef;
	if ($element->isa('PPI::Token::Word')) {
	    warn "->$element->{content}\n" if $Debug;
	    $self->_dump(funcall => $element->content);
	    return;
	}
    } elsif ($self->{in_usereq} && !$element->isa('PPI::Token::Whitespace')) {
	$self->{in_usereq} = undef;
	if ($element->isa('PPI::Token::Word')) {
	    warn "use $element->{content}\n" if $Debug;
	    $self->_dump(classref => $element->content);
	    return;
	}
    }
    $self->_dump(token_name($element), $element->content);
}

sub _dump {
    my($self, $type, $text) = @_;
    my $bodysize = length $text;
    print <<DUMP;
$type
$self->{lineno}
$self->{byteno}
$bodysize
$text
DUMP
    ;
    $self->{byteno} += $bodysize;
    $self->{lineno} += $text =~ tr/\n//d;
}

sub token_name {
    my $token = shift;
    if ($token->isa('PPI::Token::Word')) {
	return $ReservedWords{$token->content} ? "keyword" :
	    $BuiltinFunctions{$token->content} ? "funcall" : "word";
    } elsif (ref($token) eq 'PPI::Token::Number') {
	return $token->{_subtype} eq 'base256' ? "floating" : "integer";
    }
    $TokenMap{ref($token)} || "word";
}

BEGIN {
    %TokenMap = qw(
PPI::Token::ArrayIndex            ident
PPI::Token::Attribute             fundef
PPI::Token::Cast                  punct
PPI::Token::Comment               text
PPI::Token::DashedWord            punct
PPI::Token::Data                  text
PPI::Token::End                   punct
PPI::Token::HereDoc               *
PPI::Token::Label                 word
PPI::Token::Magic                 punct
PPI::Token::Number                *
PPI::Token::Operator              punct
PPI::Token::Pod                   text
PPI::Token::Prototype             punct
PPI::Token::Quote::Double         string
PPI::Token::Quote::Interpolate    string
PPI::Token::Quote::Literal        string
PPI::Token::Quote::Single         string
PPI::Token::QuoteLike::Backtick   string
PPI::Token::QuoteLike::Command    string
PPI::Token::QuoteLike::Readline   string
PPI::Token::QuoteLike::Regexp     string
PPI::Token::QuoteLike::Words      string
PPI::Token::Regexp::Match         word
PPI::Token::Regexp::Substitute    word
PPI::Token::Regexp::Transliterate word
PPI::Token::Separator             punct
PPI::Token::Structure             punct
PPI::Token::Symbol                ident
PPI::Token::Unknown               punct
PPI::Token::Whitespace            punct
PPI::Token::Word                  *
);

    # borrowed from Apache::PrettyPerl, with slight fixes
    %ReservedWords = map { $_ => 1 } qw(
	while until for foreach unless if elsif else do
	package use no require import and or eq ne cmp
        my our local next last redo goto return sub
    );
    %BuiltinFunctions = map { $_ => 1 } qw(
	abs accept alarm atan2 bind binmode bless
	caller chdir chmod chomp chop chown chr
	chroot close closedir connect continue cos
	crypt dbmclose dbmopen defined delete die
	dump each endgrent endhostent endnetent
	endprotoent endpwent endservent eof eval
	exec exists exit exp fcntl fileno flock
	fork format formline getc getgrent getgrgid
	getgrnam gethostbyaddr gethostbyname gethostent
	getlogin getnetbyaddr getnetbyname getnetent
	getpeername getpgrp getppid getpriority
	getprotobyname getprotobynumber getprotoent
	getpwent getpwnam getpwuid getservbyname
	getservbyport getservent getsockname
	getsockopt glob gmtime goto grep hex index
	int ioctl join keys kill last lc lcfirst
	length link listen local localtime log
	lstat map mkdir msgctl msgget msgrcv
	msgsnd my next oct open opendir ord our pack
	pipe pop pos print printf prototype push
	quotemeta rand read readdir readline
	readlink readpipe recv redo ref rename
	reset return reverse rewinddir rindex
	rmdir scalar seek seekdir select semctl
	semget semop send setgrent sethostent
	setnetent setpgrp setpriority setprotoent
	setpwent setservent setsockopt shift shmctl
	shmget shmread shmwrite shutdown sin sleep
	socket socketpair sort splice split sprintf
	sqrt srand stat study sub substr symlink
	syscall sysopen sysread sysread sysseek
	system syswrite tell telldir tie tied
	time times truncate uc ucfirst umask undef
	unlink unpack unshift untie utime values
	vec wait waitpid wantarray warn write
    );
}
