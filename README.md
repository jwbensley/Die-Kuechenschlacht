# Download Die Küchenschlacht

BASH script to download (by default) todays episode of Die Küchenschlacht from ZDF Mediathek.

Requires `wget` or `curl` and `ffmpeg` (NOT `avconv`!).

```bash
$ date +'%d%m%y'
100920

$ ./kuechenschlacht.sh -h
usage: ./kuechenschlacht.sh [DD] [MM] [YY] [QUALITY] [-c]

 -c     : Enabled clobber; overwrite existing episode file.
 -h     : This help text.

Defaults to todays date and maximum quality (2128):

Default: ./kuechenschlacht.sh 10 09 20 2128

Quality options (for single-file episodes):
368     : NAME=Hoch,BANDWIDTH=368kbps,RESOLUTION=480x270,CODEC=Google/On2 VP9
1128    : NAME=Sehr Hoch,BANDWIDTH=1128Kbps,RESOLUTION=960x540,CODEC=Google/On2 VP9
2128    : NAME=HD,BANDWIDTH=2129Kbps,RESOLUTION=1280x720,CODEC=Google/On2 VP9

Quality options (for multi-file episodes):
476000  : BANDWIDTH=388000,RESOLUTION=480x272,CODECS='avc1.77.30, mp4a.40.2'
508000  : BANDWIDTH=424000,RESOLUTION=480x270,CODECS='avc1.77.30, mp4a.40.2'
776000  : BANDWIDTH=623000,RESOLUTION=640x360,CODECS='avc1.77.30, mp4a.40.2'
808000  : BANDWIDTH=665000,RESOLUTION=640x360,CODECS='avc1.77.30, mp4a.40.2'
1496000 : BANDWIDTH=1193000,RESOLUTION=852x480,CODECS='avc1.77.30, mp4a.40.2'
1628000 : BANDWIDTH=1314000,RESOLUTION=960x540,CODECS='avc1.77.30, mp4a.40.2'
2296000 : BANDWIDTH=1830000,RESOLUTION=1024x576,CODECS='avc1.77.30, mp4a.40.2'
3296000 : BANDWIDTH=2583000,RESOLUTION=1280x720,CODECS='avc1.640028, mp4a.40.2'
3328000 : BANDWIDTH=2652000,RESOLUTION=1280x720,CODECS='avc1.640028, mp4a.40.2'

Note: Not all episodes are available at every quality, if the download fails
try another quality.
```

If the script is interrupted whilst downloading the segments of an episode, `wget` will resume from the most resent segment, `curl` will re-download all existing segments.