use strict;
use warnings;
use Test::More;
use Plack::Middleware::Static;
use Plack::Builder;
use Plack::Util;
use HTTP::Request::Common;
use HTTP::Response;
use Plack::Test;

test_psgi (
    client => sub {
        my $cb  = shift;
        my $res;
        $res = $cb->(GET "http://localhost/..%2f..%2f..%2fetc%2fpasswd.t");
        is $res->code, 403;
        $res = $cb->(GET "http://localhost/..%2fMakefile.PL");
        is $res->code, 403, 'directory traversal';
        $res = $cb->(GET "http://localhost/foo/not_found.t");
        is $res->code, 404, 'not found';
        is $res->content, 'not found';
        $res = $cb->(GET "http://localhost/share/face.jpg");
        is $res->content_type, 'image/jpeg';
        $res = $cb->(GET "http://localhost/share-pass/faceX.jpg");
        is $res->code, 200, 'pass through';
        is $res->content, 'ok';
    },
    app => builder {
        enable "Plack::Middleware::Directory",
            path => sub {s!^/share/!!;}, root => "share";
        enable "Plack::Middleware::Directory",
            path => sub {s!^/share-pass/!!}, root => "share", pass_through => 1;
        enable "Plack::Middleware::Directory",
            path => qr{\.(t|PL|txt)$}i, root => '.';
        sub {
            [200, ['Content-Type' => 'text/plain', 'Content-Length' => 2], ['ok']]
        };
    },
);

test_psgi (
    client => sub {
        my $cb  = shift;
        my $res;
        $res = $cb->(GET "http://localhost/share/");
        is $res->code, 200;
        is $res->content, 'index.html', 'default file name suffixed';
        $res = $cb->(GET "http://localhost/share/foo/");
        is $res->code, 200;
        is $res->content, 'foo/index.htm', 'default file name suffixed';
    },
    app => builder {
        enable "Plack::Middleware::Directory",
            path => sub {s!^/share/!!;},
            default => ['index.html', 'index.htm'], root => 'share';
        sub {
            [404, [], ['File not found']]
        };
    },
);

done_testing;
