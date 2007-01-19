#!/usr/bin/perl -w
use warnings;
use strict;
use inc::Module::Install;

name            'Test-Mock-LWP';
author          'Luke Closs <test-mock-lwp@awesnob.com>';
build_requires  'Test::More'        => '0.42';
build_requires  'Test::Pod'   => 0;
license         'perl';

# Auto-install all dependencies from CPAN
auto_install;

# Generate the Makefile
WriteAll;
