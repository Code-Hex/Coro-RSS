#! /usr/bin/perl
use strict;
use warnings;
use XML::RSS;
use Coro;
use Coro::LWP;
use LWP::UserAgent;
use HTTP::Request::Common;
use utf8;
use JSON::XS;
use LWP::Protocol::https;
use Encode qw/encode_utf8 decode_utf8/;
use Benchmark;
# use Data::Dumper; Debug

my $ua = LWP::UserAgent->new;
my $rss_url = 'http://feeds.reuters.com/reuters/JPTopNews?format=xml';

#GET URL
my $rss_res = $ua->request(GET $rss_url);
my $rss_result = $rss_res->is_success? $rss_res->content : die sprintf "error %d: %s", $rss_res->code, $rss_res->message;

#RSS
my $rss = XML::RSS->new;
$rss->parse($rss_result);

#OAuth in Google
my $google_url = 'https://www.googleapis.com/urlshortener/v1/url';
my $api_key = ' '; # Your Api keys

#print
my @coros;
for (@{$rss->{items}}) {
    my $encode_title = encode_utf8($_->{title});
    my $json = encode_json({
    key     => $api_key,
    longUrl => $_->{link} });
    push @coros,async {
    my $shorten_req = $ua->request(POST $google_url,
            Content_Type => 'application/json',
            Content      => $json );

    my $shorten_info = decode_json($shorten_req->decoded_content);
    printf decode_utf8("%s\n"), $encode_title;
    printf "%s\n\n", $shorten_info->{id}; # Dumper($result); Debug 
    }
}
$_->join for @coros;
