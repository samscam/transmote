Transmote
=========

Transmote is an OS X remote control app for the Transmission bittorrent client. It's partiularly useful if you are running Transmission remotely, eg on a NAS.

*Before you ask, it is NOT a bittorrent client in its own right.*

You can download the latest built binary from here: [Transmote.app](https://samscam.co.uk/transmote/release/latest.zip) (v0.1.32)

* It catches magnet links from browsers and adds them to your server
* It attempts to fetch metadata and artwork for movies and TV shows
* You can *remove* and *delete* torrents from your server
* Note: authentication is currently not supported - this will be back at some point

== Building it yourself

Dependencies are managed using Carthage. Prior to building you will want to run `carthage bootstrap --platform macOS` from the project root.

If you are building it yourself and want the metadata lookups to work you'll have to add your own TMDB API key in the TRNDefinitions.h file.
