package Dancer::Plugin::Email;
# ABSTRACT: Simple email handling for Dancer applications using Email::Stuff!

use Dancer ':syntax';
use Dancer::Plugin;
use Hash::Merge;
use base 'Email::Stuff';

# use Data::Dumper qw/Dumper/;

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
    
    # process reply_to
    if ($options->{reply_to}) {
        $self->header("Return-Path" => $options->{reply_to});
    }
    
    # process subject
    if ($options->{subject}) {
        $self->subject($options->{subject});
    }
    
    # process message
    if ($options->{message}) {
        if (lc($options->{type}) eq 'html') {
            $self->html_body($options->{message});
        }
        else {
            $self->text_body($options->{message});
        }
    }
    
    # process additional headers
    if ($options->{headers} && ref($options->{headers}) eq "HASH") {
        foreach my $header (keys %{ $options->{headers} }) {
            $self->header( $header => $options->{headers}->{$header} );
        }
    }
    
    # process attachments
    if ($options->{attach}) {
        if (ref($options->{attach}) eq "ARRAY") {
            my %files = @{$options->{attach}};
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
            if ($settings->{host} && $settings->{user} && $settings->{pass}) {
                
                my   @parameters = ();
                push @parameters, 'Host' => $settings->{host} if $settings->{host};
                push @parameters, 'Port'  => $settings->{port} if $settings->{port};
                
                push @parameters, 'username' => $settings->{user} if $settings->{user};
                push @parameters, 'password' => $settings->{pass} if $settings->{pass};
                push @parameters, 'ssl'      => $settings->{ssl} if $settings->{ssl};
                
                push @parameters, 'Proto' => 'tcp';
                push @parameters, 'Reuse' => 1;
                
                push @parameters, 'Debug' => 1 if $settings->{debug};
                
                $self->{send_using} = ['SMTP', @parameters];
            }
            else {
                $self->{send_using} = ['SMTP', Host => $settings->{host}];
            }
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
        # die Dumper $email->as_string;
        return $self->mailer->send( $email );
    }
    else {
        $self->using(@arguments) if @arguments; # Arguments passed to ->using
        my $email = $self->email or return undef;
        return $self->mailer->send( $email );
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
            attach => [
                '/path/to/file' => 'filename'
            ]
        };
    };
    
Important Note! The default email format is plain-text, this can be changed to
html by seeting the option 'type' to 'heml' in the config file or as an argument
in the hashref passed to the email keyword. The following are options that can
be passed to the email function:

    # send message to
    to => $email_recipient
    
    # send messages from
    from => $mail_sender
    
    # email subject
    subject => 'email subject line'
    
    # message body
    message => 'html or plain-text data'
    
    # email message content type
    type => 'text'
    type => 'html'
    
    # carbon-copy other email addresses
    cc => 'user@site.com'
    cc => 'user_a@site.com, user_b@site.com, user_c@site.com'
    cc => join ', ', @email_addresses
    
    # blind carbon-copy other email addresses
    bcc => 'user@site.com'
    bcc => 'user_a@site.com, user_b@site.com, user_c@site.com'
    bcc => join ', ', @email_addresses
    
    # specify where email responses should be directed
    reply_to => 'other_email@website.com'
    
    # attach files to the email
    attach => [
        $file_location => $attachment_name,
    ]
    
    # send additional (specialized) headers
    headers => {
        "X-Mailer" => "Dancer::Plugin::Email 1.23456789"
    }

=head1 CODE COOKBOOK

    # Handle Email Failures
    
    post '/contact' => sub {
    
        my $msg = email {
            to => '...',
            subject => '...',
            message => $msg,
            attach => [
                '/path/to/file' => 'filename'
            ]
        };
        
        warn $msg->{string} if $msg->{type} eq 'failure';
        
    };
    
    # Add More Email Headers
    
    email {
        to => '...',
        subject => '...',
        message => $msg,
        headers => {
            "X-Mailer" => 'This fine Dancer application',
            "X-Accept-Language" => 'en'
        }
    };
    

=head1 CONFIG COOKBOOK

    # Send mail via SMTP with SASL authentication
    
    plugins:
      Email:
        driver: smtp
        host: smtp.website.com
        user: account@gmail.com
        pass: ****
    
    # Send mail to/from google (gmail)
    
    plugins:
      Email:
        ssl: 1
        driver: smtp
        host: smtp.gmail.com
        port: 465
        user: account@gmail.com
        pass: ****
        
    # Send mail to/from google (gmail) using TLS
    
    plugins:
      Email:
        tls: 1
        driver: smtp
        host: smtp.gmail.com
        port: 587
        user: account@gmail.com
        pass: ****
        
    # Debug email server communications
    
    plugins:
      Email:
        debug: 1
        
    # Set default headers to be issued with every message
    
    plugins:
      Email:
        from: ...
        subject: ...
        headers:
          X-Mailer: MyDancer 1.0
          X-Accept-Language: en

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
