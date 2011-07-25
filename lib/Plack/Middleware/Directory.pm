package Plack::Middleware::Directory;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Plack::App::Directory;

use Plack::Util::Accessor qw( default indexes path root encoding pass_through );

sub call {
    my ($self, $env) = @_;
    
    if (! defined $self->indexes) {
        $self->indexes(1);
    }

    my $res = $self->_handle_static($env);
    if ($res && not ($self->pass_through and $res->[0] == 404)) {
        return $res;
    }

    return $self->app->($env);
}

sub _handle_static {
    my($self, $env) = @_;

    my $path_match = $self->path or return;
    my $path = $env->{PATH_INFO} || '';
    
    for ($path) {
        my $matched = ref $path_match eq 'CODE' ? $path_match->($_) : $_ =~ $path_match;
        return unless $matched;
    }
    
    $path ||= '/';
    
    $self->{file} ||= Plack::App::Directory->new({
        root        => $self->root || '.',
        encoding    => $self->encoding,
        path        => $path,
    });
    
    if ($self->default && (length($path) == 0 || substr($path, -1, 1) eq '/')) {
        for my $candidate (@{$self->default}) {
            my $fixed_path = $path . $candidate;
            local $env->{PATH_INFO} = $fixed_path;
            my $res = $self->{file}->call($env);
            if ($res->[0] == 200) {
                return $res;
            }
        }
    }
    
    local $env->{PATH_INFO} = $path;
    
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
