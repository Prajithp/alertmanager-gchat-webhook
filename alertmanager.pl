#!/usr/bin/perl

use strict;

package Card;

use Mojo::Base -base;

has texts => sub { [] };
has labels => sub { +{} };

sub render {
    my $self = shift;

    my $paragraphWidgets = [ 
        map { +{ 'textParagraph' => { 'text' => $_ } } } $self->texts->@* 
    ];

    my $labelWidgets = [];
    foreach my $labelKey ( keys $self->labels->%* ) {
        my $content = {
            'keyValue' => {
                'topLabel'         => $labelKey,
                'content'          => $self->labels->{$labelKey},
                'contentMultiline' => 'false'
            }
        };
        push $labelWidgets->@*, $content;
    }
    my $sections = [ 
        map { +{ 'widgets' => $_ } } ( $paragraphWidgets->@*, $labelWidgets->@* ) 
    ];
    my $cards = { 'cards' => [] };
    push $cards->{'cards'}->@*, { 'sections' => $sections };

    return $cards;
}

package main;

use Mojolicious::Lite -signatures;
use Mojo::JSON qw<decode_json>;
use YAML::Tiny;
use feature 'state';

helper cache => sub {
   state $cache = Mojo::Cache->new;
};

helper yamlLoader => sub { 
    state $loader = YAML::Tiny->new;
};

helper colorMap => sub {
    +{
        'warning' => '#ffc107',
        'critical' => '#ff0000'
    };
};

helper alertSettings => sub {
    my $self = shift;

    my $lastModifiedTime = $self->cache->get('lastModifiedTime') // 0;
    
    my $path = $self->app->home->rel_file('alerts.yml');
    my $stat = $path->stat;
    state $config = {};
    if ($stat->mtime > $lastModifiedTime) {
        app->log->info('reloading config file');
        $config = $self->yamlLoader->read($path)->[0];
        $self->cache->set('lastModifiedTime', $stat->mtime);
    }
    return $config->{'channels'};
};

helper notify => sub {
    my ( $self, $channel, $body ) = @_;

    my $settings  = $self->alertSettings;
    my $roomRef   = [ grep { $_->{'name'} eq $channel } $settings->@* ];
    my $room      = $roomRef->[0] // die "Could not find $channel";
   
    my $url       = $room->{'url'};
    my $label_key = $room->{'labels'} // [];
    push $label_key->@*, 'severity';
    
    foreach my $alert ($body->{'alerts'}->@*) {
        my %labels = map { $_ => $alert->{'labels'}->{$_} // 'null' } $label_key->@*;
        my $description = $alert->{'annotations'}->{'description'};
        my $summary     = $alert->{'annotations'}->{'description'} // $labels{'alertname'};
    
        my $header = sprintf(
            "<b>%s - <font color=\"%s\">%s</font></b>", 
            $summary, $self->colorMap->{$labels{'severity'}}, 
            uc($labels{'severity'})
        );

        my $card = Card->new(
            texts => [$header, $description], 
            labels => \%labels
        );
    
        $self->ua->post_p($url => json => $card->render)->then(sub {
            my $tx = shift;
            app->log->debug("Sent google notification successfully");
        })->catch(sub {
            my $err = shift;
            app->log->error("Connection error: $err");
        })->wait;
    }
};

post '/notify' => sub {
    my $c = shift;
    $c->render_later;
    
    my $channel = $c->param('channel');
    my $body    = $c->req->json;
    $c->notify($channel, $body);

    return $c->render( text => 'Ok' );
};

app->start;


