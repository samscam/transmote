Transmote
=========

[![Build Status](https://www.bitrise.io/app/24bbdac53cd2fc51.svg?token=P2QwlLUlLmIa38HFgP66tw&branch=develop)](https://www.bitrise.io/app/24bbdac53cd2fc51)

Transmote is a macOS remote control app for the Transmission bittorrent client. It's partiularly useful if you are running Transmission remotely, eg on a NAS.

*Before you ask, it is NOT a bittorrent client in its own right.*

You can download the latest binary [from here](https://samscam.co.uk/transmote/).

* It catches magnet links from browsers and adds them to your server
* It attempts to fetch metadata and artwork for movies and TV shows
* You can *remove* and *delete* torrents from your server
* It supports basic authentication

## Building it yourself
You will need Xcode >27

Dependencies are managed using SPM.

## API Keys for TMBD metadata lookups(this doesn't work - looking into it)

If you are building it yourself and want the metadata lookups to work you'll have to add your own TMDB API key:
Create a file called `secrets.sh` in the Scripts directory.

```
#!/bin/bash
export TMDB_API_KEY='your-api-key-goes-here'
```

and make it executable.
