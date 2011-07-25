package Plack::App::File::Extended;
use parent qw(Plack::App::File);
use strict;
use warnings;
use Plack::Util::Accessor
    qw( default path root encoding pass_through permission_check);
    
    sub locate_file {
        my ($self, $env) = @_;
        my ($file, $path_info) = $self->SUPER::locate_file($env);
        return $file if ref $file eq 'ARRAY';
        if ($self->permission_check && ! _permission_ok($file, $self->root)) {
            return $self->return_403;
        }
        return ($file, $path_info);
    }
    
    ### ---
    ### Check if others readable
    ### ---
    sub _permission_ok {
        
        my ($name, $base) = @_;
        $base ||= '';
        if ($^O eq 'MSWin32') {
            return 1;
        }
        if ($name && -f $name && ((stat($name))[2] & 4)) {
            $name =~ s{(^|/)[^/]+$}{};
            while (-d $name) {
                if ($name eq $base) {
                    return 1;
                }
                if (! ((stat($name))[2] & 1)) {
                    return 0;
                }
                $name =~ s{(^|/)[^/]+$}{};
            }
            return 1;
        }
        return 0;
    }

1;

__END__

=head1 NAME

Plack::App::Directory - Serve static files from document root with directory index

=head1 SYNOPSIS

  # app.psgi
  use Plack::App::Directory;
  my $app = Plack::App::Directory->new({ root => "/path/to/htdocs" })->to_app;

=head1 DESCRIPTION

This is a static file server PSGI application with directory index a la Apache's mod_autoindex.

=head1 CONFIGURATION

=over 4

=item root

Document root directory. Defaults to the current directory.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::App::File>

=cut
