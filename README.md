# NAME

Dancer::Plugin::Email - Simple email sending for Dancer applications

# VERSION

version 1.0400

# SYNOPSIS

    use Dancer;
    use Dancer::Plugin::Email;
    
    post '/contact' => sub {
        email {
            from    => 'bob@foo.com',
            to      => 'sue@foo.com',
            subject => 'allo',
            body    => 'Dear Sue, ...',
            attach  => '/path/to/attachment',
        };
    };

# DESCRIPTION

This plugin tries to make sending emails from [Dancer](https://metacpan.org/pod/Dancer) applications as simple
as possible.
It uses [Email::Sender](https://metacpan.org/pod/Email::Sender) under the hood.
In a lot of cases, no configuration is required.
For example, if your app is hosted on a unix-like server with sendmail
installed, calling `email()` will just do the right thing.

IMPORTANT: Version 1.x of this module is not backwards compatible with the
0.x versions.
This module was originally built on Email::Stuff which was built on
Email::Send which has been deprecated in favor of Email::Sender.
Versions 1.x and on have be refactored to use Email::Sender.
I have tried to keep the interface the same as much as possible.
The main difference is the configuration.
If there are features missing that you were using in older versions,
then please let me know by creating an issue on 
[github](https://github.com/ironcamel/Dancer-Plugin-Email).

# FUNCTIONS

This module by default exports the single function `email`.

## email

This function sends an email.
It takes a single argument, a hashref of parameters.
Default values for the parameters may be provided in the headers section of
the ["CONFIGURATION"](#configuration).
Paramaters provided to this function will override the corresponding
configuration values if there is any overlap.
An exception is thrown if sending the email fails,
so wrapping calls to `email` with try/catch is recommended.

    use Dancer;
    use Dancer::Plugin::Email;
    use Try::Tiny;

    post '/contact' => sub {
        try {
            email {
                sender  => 'bounces-here@foo.com', # optional
                from    => 'bob@foo.com',
                to      => 'sue@foo.com, jane@foo.com',
                bcc     => 'sam@foo.com',
                subject => 'allo',
                body    => 'Dear Sue, ...<img src="cid:blabla">',
                multipart => 'related', # optional, see below
                attach  => [
                    '/path/to/attachment1',
                    '/path/to/attachment2',
                    {
                        Path => "/path/to/attachment3",
                        # Path is required when passing a hashref.
                        # See Mime::Entity for other optional values.
                        Id => "blabla",
                    }
                ],
                type    => 'html', # can be 'html' or 'plain'
                # Optional extra headers
                headers => {
                    "X-Mailer"          => 'This fine Dancer application',
                    "X-Accept-Language" => 'en',
                }
            };
        } catch {
            error "Could not send email: $_";
        };
    };

# CONFIGURATION

No configuration is necessarily required.
[Email::Sender::Simple](https://metacpan.org/pod/Email::Sender::Simple) tries to make a good guess about how to send the
message.
It will usually try to use the sendmail program on unix-like systems
and SMTP on Windows.
However, you may explicitly configure a transport in your configuration.
Only one transport may be configured.
For documentation for the parameters of the transport, see the corresponding
Email::Sender::Transport::\* module.
For example, the parameters available for the SMTP transport are documented
here ["ATTRIBUTES" in Email::Sender::Transport::SMTP](https://metacpan.org/pod/Email::Sender::Transport::SMTP#ATTRIBUTES).

You may also provide default headers in the configuration:

    plugins:
      Email:
        # Set default headers (OPTIONAL)
        headers:
          sender: 'bounces-here@foo.com'
          from: 'bob@foo.com'
          subject: 'default subject'
          X-Mailer: 'MyDancer 1.0'
          X-Accept-Language: 'en'
        # Explicity set a transport (OPTIONAL)
        transport:
          Sendmail:
            sendmail: '/usr/sbin/sendmail'

Example configuration for sending mail via Gmail:

    plugins:
      Email:
        transport:
          SMTP:
            ssl: 1
            host: 'smtp.gmail.com'
            port: 465
            sasl_username: 'bob@gmail.com'
            sasl_password: 'secret'

Use the Sendmail transport using the sendmail program in the system path:

    plugins:
      Email:
        transport:
          Sendmail:

Use the Sendmail transport with an explicit path to the sendmail program:

    plugins:
      Email:
        transport:
          Sendmail:
            sendmail: '/usr/sbin/sendmail'

## Multipart messages

You can embed images in HTML messages this way: first, set the `type`
to `html`. Then pass the attachments as hashrefs, setting `Path` and
`Id`. In the HTML body, refer to the attachment using the `Id`,
prepending `cid:` in the `src` attribute. This works for popular
webmail clients like Gmail and OE, but is not enough for Thunderbird,
which wants a `multipart/related` mail, not the default
`multipart/mixed`. You can fix this adding the `multipart` parameter
set to `related`, which set the desired subtype when you pass
attachments.

Example:

    email {
           from    => $from,
           to      => $to,
           subject => $subject,
           body    => q{<p>Image embedded: <img src="cid:mycid"/></p>},
           type    => 'html',
           attach  => [ { Id => 'mycid', Path => '/path/to/file' }],
           multipart => 'related'
          };

The `attach` value accepts either a single attachment or an arrayref
of attachment. Each attachment may be a scalar, with the path of the
file to attach, or an hashref, in which case the hashref is passed to
the [Mime::Entity](https://metacpan.org/pod/Mime::Entity)'s `attach` method.

# CONTRIBUTORS

- Marco Pessotto <melmothx@gmail.com>
- Oleg A. Mamontov <oleg@mamontov.net>
- Rusty Conover <https://github.com/rustyconover>
- Stefan Hornburg <racke@linuxia.de>

# SEE ALSO

- [Email::Sender](https://metacpan.org/pod/Email::Sender)
- [MIME::Entity](https://metacpan.org/pod/MIME::Entity)

# AUTHORS

- Naveed Massjouni <naveed@vt.edu>
- Al Newkirk <awncorp@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
