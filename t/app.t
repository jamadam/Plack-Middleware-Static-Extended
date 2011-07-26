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
        enable "Static::Extended",
            path => sub {s!^/share/!!;}, root => "share";
        enable "Static::Extended",
            path => sub {s!^/share-pass/!!}, root => "share", pass_through => 1;
        enable "Static::Extended",
            path => qr{\.(t|PL|txt)$}i, root => '.';
        sub {
            [200, ['Content-Type' => 'text/plain', 'Content-Length' => 2], ['ok']]
        };
    },
);

BEGIN {
    chmod(0755, 'share/permission_check/permission_ok');
    chmod(0744, 'share/permission_check/permission_ng');
    chmod(0755, 'share/permission_check/permission_ok/permission_ok.html');
    chmod(0700, 'share/permission_check/permission_ok/permission_ng.html');
    chmod(0755, 'share/permission_check/permission_ng/permission_ok.html');
    chmod(0700, 'share/permission_check/permission_ng/permission_ng.html');
}

test_psgi (
    client => sub {
        my $cb  = shift;
        my $res;
        $res = $cb->(GET "http://localhost/share/permission_check/permission_ok/permission_ok.html");
        is $res->code, 200, '200 ok';
        $res = $cb->(GET "http://localhost/share/permission_check/permission_ok/permission_ng.html");
        is $res->code, 403, '403 fobbiden';
        $res = $cb->(GET "http://localhost/share/permission_check/permission_ng/permission_ok.html");
        is $res->code, 403, '403 fobbiden';
        $res = $cb->(GET "http://localhost/share/permission_check/permission_ng/permission_ng.html");
        is $res->code, 403, '403 fobbiden';
    },
    app => builder {
        enable "Static::Extended",
            path => sub {s!^/share/!!;},
            permission_check => 1,
            root => 'share';
        sub {
            [404, [], ['File not found']]
        };
    },
);

done_testing;
