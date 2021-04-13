# Overview

[![Build Status](https://github.com/duosecurity/duo_api_perl/workflows/Perl%20CI/badge.svg)](https://github.com/duosecurity/duo_api_perl/actions)
[![Issues](https://img.shields.io/github/issues/duosecurity/duo_api_perl)](https://github.com/duosecurity/duo_api_perl/issues)
[![Forks](https://img.shields.io/github/forks/duosecurity/duo_api_perl)](https://github.com/duosecurity/duo_api_perl/network/members)
[![Stars](https://img.shields.io/github/stars/duosecurity/duo_api_perl)](https://github.com/duosecurity/duo_api_perl/stargazers)
[![License](https://img.shields.io/badge/License-View%20License-orange)](https://github.com/duosecurity/duo_api_perl/blob/master/LICENSE)

**duo_api_perl** - Demonstration client to call Duo API methods
with Perl.

# Duo Auth API

The Duo Auth API provides a low-level API for adding strong two-factor
authentication to applications that cannot directly display rich web
content.

For more information see the Duo Auth API guide:

<http://www.duosecurity.com/docs/authapi>

# Duo Admin API

The Duo Admin API provides programmatic access to the administrative
functionality of Duo Security's two-factor authentication platform.
This feature is not available with all Duo accounts.

For more information see the Duo Admin API guide:

<http://www.duosecurity.com/docs/adminapi>

# Duo Accounts API

The Duo Accounts API allows a parent account to create, manage, and
delete other Duo customer accounts. This feature is not available with
all Duo accounts.

For more information see the Duo Accounts API guide:

# Testing

```
$ cpanm --verbose --installdeps --notest .
$ perl Makefile.PM
$ make test
```

<http://www.duosecurity.com/docs/accountsapi>
