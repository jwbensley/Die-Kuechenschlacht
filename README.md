# Download Die küchenschlacht

BASH script to download (by default) todays episode of Die küchenschlacht from ZDF Mediathek.

Requires `wget` and `ffmpeg`.

```bash
$ date +'%y%m%d'
190628

$ ./kuechenschlacht.sh -h
usage: ./kuechenschlacht.sh [DD] [MM] [YY] [QUALITY]

Defaults to todays date and 3296000:

Default: ./kuechenschlacht.sh 28 06 19 3296000

Quality options:
476000  : BANDWIDTH=388000,RESOLUTION=480x272,CODECS='avc1.77.30, mp4a.40.2'
776000  : BANDWIDTH=623000,RESOLUTION=640x360,CODECS='avc1.77.30, mp4a.40.2'
1496000 : BANDWIDTH=1193000,RESOLUTION=852x480,CODECS='avc1.77.30, mp4a.40.2'
2296000 : BANDWIDTH=1830000,RESOLUTION=1024x576,CODECS='avc1.77.30, mp4a.40.2'
3296000 : BANDWIDTH=2583000,RESOLUTION=1280x720,CODECS='avc1.640028, mp4a.40.2'
```
