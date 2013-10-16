applescript-torrent-helper
==========================

Small applescript that can be used with folder actions to move and / or process incoming torrent files.

This script assumes you have XLD and the XLD command line utility installed to perform file conversions.

My process basically looks like this:

1. I download a .torrent file
2. I move that file to a Dropbox folder that is watched (by uTorrent) on my seed box
3. That file gets ingested into uTorrent. When the download is finished it moves the d/l'd files to a "/Seeding" directory.
4. This script is set as a Folder Action on /Seeding. Once the file is fully copied, it will begin processing files in it.
5. The "extension_list" prop is for any file the script will handle. "convert_extension_list" is any file I want to be processed by XLD.
6. Files are either converted or simply copied to a destination path. In my case, this path is on my Dropbox.
7. With LAN sync enabled in Dropbox, on my local network I receive the incoming files instantly. Otherwise they get synced up to DB, then down to my client.
