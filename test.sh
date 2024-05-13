#!/bin/sh

# This is a check to make sure that a manual fix to an IG wasn't reverted by mistake, because
# it causes global problems for the validator in a shared environment given how we are using it.
# This needs to be fixed within the validator wrapper service, and when it does, this test can be removed.

# See PR link below for more information.

zgrep "\"global\"" lib/inferno_platform_template/igs/*.tgz && \
  {>&2  echo "Found global set in some IG loaded in /igs/.  This can cause bad behavior in the validator. "\
  "See https://github.com/onc-healthit/inferno-deployment/pull/25"; exit 1;} 

exit 0
