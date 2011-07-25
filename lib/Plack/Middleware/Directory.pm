package Plack::Middleware::Static::Directory;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Plack::App::Directory;

use Plack::Util::Accessor qw( candidates path root encoding pass_through );

sub call {
    my $self = shift;
    my $env  = shift;

    my $res = $self->_handle_static($env);
    if ($res && not ($self->pass_through and $res->[0] == 404)) {
        return $res;
    }

    return $self->app->($env);
}

sub _handle_static {
    my($self, $env) = @_;

    my $path_match = $self->path or return;
    my $path = $env->{PATH_INFO};

    $self->{file} ||= Plack::App::Directory->new({
        root        => $self->root || '.',
        encoding    => $self->encoding
    });
    
    if (@{$self->candidates} && substr($path, -1, 1) eq '/') {
        for my $candidate (@{$self->candidates}) {
            $path .= $candidate;
            my $matched = 'CODE' eq ref $path_match ? $path_match->($path) : $path =~ $path_match;
            if ($matched) {
                local $env->{PATH_INFO} = $path;
                my $res = $self->{file}->call($env);
                if ($res->[0] == 200) {
                    return $res;
                }
            }
        }
    }

    my $matched = 'CODE' eq ref $path_match ? $path_match->($path) : $path =~ $path_match;
    return unless $matched;
    
    local $env->{PATH_INFO} = $path; # rewrite PATH
    return $self->{file}->call($env);
}

1;

__END__

=head1 NAME

Plack::Middleware::Directory - 

=head1 SYNOPSIS

    use Plack::Middleware::Directory;
    Plack::Middleware::Directory->new;

=head1 DESCRIPTION

=head1 METHODS

=head2 new

=head1 AUTHOR

sugama, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by sugama.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
