#!/bin/sh
if [ ! -f doku.php ]; then
  echo "Not a dokuwiki installation."
  exit 1;
fi

chown www:www conf
if [ ! -d data ]; then
  mkdir data
fi
chown www:www data

if [ ! -d data/pages ]; then
  mkdir data/pages
fi
chown www:www data/pages

if [ ! -d data/attic ]; then
  mkdir data/attic
fi
chown www:www data/attic

if [ ! -d data/media ]; then
  mkdir data/media
fi
chown www:www data/media

if [ ! -d data/media_attic ]; then
  mkdir data/media_attic
fi
chown www:www data/media_attic

if [ ! -d data/media_meta ]; then
  mkdir data/media_meta
fi
chown www:www data/media_meta

if [ ! -d data/meta ]; then
  mkdir data/meta
fi
chown www:www data/meta

if [ ! -d data/cache ]; then
  mkdir data/cache
fi
chown www:www data/cache

if [ ! -d data/locks ]; then
  mkdir data/locks
fi
chown www:www data/locks

if [ ! -d data/index ]; then
  mkdir data/index
fi
chown www:www data/index

if [ ! -d data/tmp ]; then
  mkdir data/tmp
fi
chown www:www data/tmp

# vim: tabstop=2 shiftwidth=2 expandtab:
