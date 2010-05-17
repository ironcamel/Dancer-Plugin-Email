package Dancer::Plugin::Email;
# ABSTRACT: Simple email handling for Dancer applications using Email::Stuff!

use Dancer ':syntax';
use Dancer::Plugin;
use Hash::Merge;
use base 'Email::Stuff';

my $settings = plugin_setting;

register email => sub {
    my ($options, @arguments)  = @_;
    my $self = Email::Stuff->new;
    
    $options = Hash::Merge->new( 'LEFT_PRECEDENT' )->merge($settings, $options);
    
    # process to
    if ($options->{to}) {
        $self->to($options->{to});
    }
    
    # process from
    if ($options->{from}) {
        $self->from($options->{from});
    }
    
    # process cc
    if ($options->{cc}) {
        $self->cc(
        join ",", ( map { $_ =~ s/(^\s+|\s+$)//g; $_ } split /[\,\s]/, $options->{cc} ) );
    }
    
    # process bcc
    if ($options->{bcc}) {
        $self->bcc(
        join ",", ( map { $_ =~ s/(^\s+|\s+$)//g; $_ } split /[\,\s]/, $options->{bcc} ) );
    }
    
    # process subject
    if ($options->{subject}) {
        $self->subject($options->{subject});
    }
    
    # process message
    if ($options->{message}) {
        if (lc($options->{type}) eq 'text') {
            $self->text_body($options->{message});
        }
        else {
            $self->html_body($options->{message});
        }
    }
    
    # process attachments
    if ($options->{attachments}) {
        if (ref($options->{attachments}) eq "ARRAY") {
            my %files = @{$options->{attachments}};
            foreach my $file (keys %files) {
                $self->attach($file, 'filename' => $files{$file});
            }
        }
    }

    if (defined $settings->{driver}) {
        if (lc($settings->{driver}) eq lc("sendmail")) {
            $self->{send_using} = ['Sendmail', $settings->{path}];
            # failsafe
            $Email::Send::Sendmail::SENDMAIL = $settings->{path} unless
                $Email::Send::Sendmail::SENDMAIL;
        }
        if (lc($settings->{driver}) eq lc("smtp")) {
            $self->{send_using} = ['SMTP', $settings->{host}];
        }
        if (lc($settings->{driver}) eq lc("qmail")) {
            $self->{send_using} = ['Qmail', $settings->{path}];
            # failsafe
            $Email::Send::Qmail::QMAIL = $settings->{path} unless
                $Email::Send::Qmail::QMAIL;
        }
        if (lc($settings->{driver}) eq lc("nntp")) {
            $self->{send_using} = ['NNTP', $settings->{host}];
        }
        my $email = $self->email or return undef;
        $self->mailer->send( $email );
    }
    else {
        $self->using(@arguments) if @arguments; # Arguments passed to ->using
        my $email = $self->email or return undef;
        $self->mailer->send( $email );
    }
};

=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::Email;
    
    post '/contact' => sub {
        email {
            to => '...',
            subject => '...',
            message => $msg,
            attachment => [
                '/path/to/file' => 'filename'
            ]
        };
    };
    
Important Note! The default email format is html, this can be changed to text by
seeting the option 'type' to 'text' in the config file or as a key/value in the
hashref passed to the email keyword.

=head1 CONFIGURATION

Connection details will be taken from your Dancer application config file, and
should be specified as, for example: 

    plugins:
      Email:
        driver: sendmail # must be an Email::Send driver
        path: /usr/bin/sendmail # for Sendmail
        host: localhost # for SMTP
        from: me@website.com
        
=head1 DESCRIPTION

Provides an easy way of handling text or html email messages with or without
attachments. Simply define how you wish to send the email in your application's
YAML configuration file, then call the email keyword passing the neccessary
parameters as outlined above.

=cut

register_plugin;

1;
