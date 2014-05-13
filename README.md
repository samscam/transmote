Transmote
=========

Transmote is an OS X remote control app for the Transmission bittorrent client. *Before you ask, it is NOT a bittorrent client in its own right.*

You can download the latest built binary from here: [Transmote.app](http://samscam.co.uk/transmote/release/Transmote-0.1.32.zip) (v0.1.32)

* It accepts magnet links from browsers and forwards them to your server - useful if you are running Transmission remotely eg on a NAS.
* It *attempts* to fetch artwork and real names for movies and TV shows
* You can *remove* and *delete* torrents from your server
* You can log in to the server with a username and password (optional)

If you are building it yourself and want the metadata lookups to work you'll have to add your own API key in the TRNDefinitions.h file.
