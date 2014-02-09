# NAME

Dancer::Plugin::Email - Simple email sending for Dancer applications

# VERSION

version 1.0101

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

This plugin tries to make sending emails from [Dancer](http://search.cpan.org/perldoc?Dancer) applications as simple
as possible.
It uses [Email::Sender](http://search.cpan.org/perldoc?Email::Sender) under the hood.
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
the ["CONFIGURATION"](#CONFIGURATION).
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
                from    => 'bob@foo.com',
                to      => 'sue@foo.com, jane@foo.com',
                subject => 'allo',
                body    => 'Dear Sue, ...<img src="cid:blabla">',
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
[Email::Sender::Simple](http://search.cpan.org/perldoc?Email::Sender::Simple) tries to make a good guess about how to send the
message.
It will usually try to use the sendmail program on unix-like systems
and SMTP on Windows.
However, you may explicitly configure a transport in your configuration.
Only one transport may be configured.
For documentation for the parameters of the transport, see the corresponding
Email::Sender::Transport::\* module.
For example, the parameters available for the SMTP transport are documented
here ["ATTRIBUTES" in Email::Sender::Transport::SMTP](http://search.cpan.org/perldoc?Email::Sender::Transport::SMTP#ATTRIBUTES).

You may also provide default headers in the configuration:

    plugins:
      Email:
        # Set default headers (OPTIONAL)
        headers:
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

# CONTRIBUTORS

- Marco Pessotto <melmothx@gmail.com>
- Oleg A. Mamontov <oleg@mamontov.net>
- Rusty Conover <https://github.com/rustyconover>
- Stefan Hornburg <racke@linuxia.de>

# SEE ALSO

- [Email::Sender](http://search.cpan.org/perldoc?Email::Sender)
- [MIME::Entity](http://search.cpan.org/perldoc?MIME::Entity)

# AUTHORS

- Naveed Massjouni <naveed@vt.edu>
- Al Newkirk <awncorp@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
