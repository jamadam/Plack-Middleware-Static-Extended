package Plack::Middleware::Directory;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Plack::App::File::Extended;
use Plack::Util::Accessor
    qw( default path root encoding pass_through permission_check);
    
    sub call {
        my ($self, $env) = @_;
    
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
            my $matched = ref $path_match eq 'CODE'
                                                    ? $path_match->($_)
                                                    : $_ =~ $path_match;
            return unless $matched;
        }
        
        $path ||= '/';
        
        $self->{file} ||= Plack::App::File::Extended->new({
            root                => $self->root || '.',
            encoding            => $self->encoding,
            path                => $path,
            permission_check    => $self->permission_check,
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

Plack::Middleware::Directory - serve static files like apache

=head1 SYNOPSIS

    use Plack::Builder;
    
    builder {
        enable "Plack::Middleware::Directory",
            path => qr{^/(images|js|css)/},
            root => './htdocs/',
            default => ['index.html', 'index.htm'],
            ;
        $app;
    };
  
=head1 DESCRIPTION

This is a middleware for serving static files with some apache-like features.
This internally uses L<Plack::App::Directory> and implemented like
L<Plack::Middleware::Static>.

=head1 CONFIGURATIONS

=head2 path => regexp or code ref

See L<Plack::App::File>

=head2 root => string

See L<Plack::App::File>

=head2 default => array ref

This option works as apache's DirectoryIndex for overriding index page
if requests path don't ended with file name.

    default => ['index.html', 'index.htm']

=head1 AUTHOR

sugama, E<lt>sugama@jamadam.comE<gt>

=head1 SEE ALSO

L<Plack::App::Directory>,
L<Plack::App::File>,
L<Plack::Middleware::Static>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by sugama.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
