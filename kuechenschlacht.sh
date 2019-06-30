#!/bin/bash



# Ensure required bins are present
which wget > /dev/null
if [ $? -eq 0 ]
then
    use_wget=1
else
    use_wget=0
    which curl > /dev/null
    if [ $? -eq 0 ]
    then
        use_curl=1
    else
        echo "wget or curl required but missing. Exiting"
        exit 1
    fi
fi

which ffmpeg > /dev/null
if [ $? -ne 0 ]
then
    echo "ffmpeg is required but missing. Exiting."
    exit 1
else
    which avconv > /dev/null
    if [ $? -eq 0 ]
    then
        echo "It appears that avconv is installed instead of ffmpeg."
        echo "avconv is not support (yet). Exiting."
        exit 1
    fi
fi



# Parse CLI args and display help test:
if [ "$1" = "-h" ]
then
    echo "usage: $0 [DD] [MM] [YY] [QUALITY]"
    echo ""
    echo "Defaults to todays date and 3296000:"
    echo ""
    echo "Default: $0 `date +'%d'` `date +'%m'` `date +'%y'` 3296000"
    echo ""
    echo "Quality options:"
    echo "476000  : BANDWIDTH=388000,RESOLUTION=480x272,CODECS='avc1.77.30, mp4a.40.2'"
    echo "776000  : BANDWIDTH=623000,RESOLUTION=640x360,CODECS='avc1.77.30, mp4a.40.2'"
    echo "1496000 : BANDWIDTH=1193000,RESOLUTION=852x480,CODECS='avc1.77.30, mp4a.40.2'"
    echo "2296000 : BANDWIDTH=1830000,RESOLUTION=1024x576,CODECS='avc1.77.30, mp4a.40.2'"
    echo "3296000 : BANDWIDTH=2583000,RESOLUTION=1280x720,CODECS='avc1.640028, mp4a.40.2'"
    exit 1
fi

day_2="`date +'%d'`"
month_2="`date +'%m'`"
year_2="`date +'%y'`"
quality="3296000"

if [ ! -z "$1" ]
then
    day_2="$1"
fi

if [ ! -z "$2" ]
then
    month_2="$2"
fi

if [ ! -z "$3" ]
then
    year_2="$3"
fi

if [ ! -z "$4" ]
then
    quality="$4"
fi

#date_6="`date +'%y%m%d'`"
date_6="$year_2"
date_6+="$month_2"
date_6+="$day_2"
d="./$date_6/"
mkdir -p "$d"
cd "$d"



# Download the daily playlist file which contains URLs to all the individual
# chunks which make the episode:
playlist_url="https://zdfvodnone-vh.akamaihd.net/i/meta-files/zdf/smil/m3u8/"
playlist_url+="300/$year_2/"
playlist_url+="$month_2/"
playlist_url+="$date_6"
playlist_url+="_sendung_dku/1/$date_6"
playlist_url+="_sendung_dku.smil/index_$quality"
playlist_url+="_av.m3u8"
playlist_filename=`basename "$playlist_url"`

echo "Downloading Die Küchenschlacht episode for $date_6:"
# wget will return a non-zero exist status if the playlist URL is invalid,
# curl will return 0. In the case of curl, an error message is returned by the
# remote server, check for the presence of the error message:
if [ $use_wget -eq 1 ]
then
    wget -nv -N "$playlist_url"
    if [ $? -ne 0 ];
    then
        echo "Playlist download failed. Exiting."
        exit 1
    fi
else
    curl -O "$playlist_url"
    if [ `grep -c "error occurred" "$playlist_filename"` -eq 1 ]
    then
        echo "Playlist download failed. Exiting."
        exit 1
    fi 
fi
part_count=`grep -v "#" "$playlist_filename" | wc -l`



# Download all the chunks in the playlist
if [ $use_wget -eq 1 ]
then
    # Use -N with wget to only download files if they don't already exist (i.e. a poor-man's resume)
    for url in `grep -v "#" "$playlist_filename"`; do  wget -nv --show-progress -N "$url" && echo "Chunk: `ls *.ts | wc -l`/$part_count"; done
else
    # curl doesn't have any sort of no-clobber option like wget
    for url in `grep -v "#" "$playlist_filename"`; do  curl -O "$url" && echo "Chunk: `ls *.ts | wc -l`/$part_count"; done
fi

if (( `ls *.ts | wc -l` != "$part_count" ))
then
    echo "Some parts are missing from the download. Exiting."
    exit 1
fi



# Merge all the chunks into a single video file
ffmpeg -y -i "concat:`ls -1 *.ts | sort -V | tr '\n' '|' | head --bytes -1`" -c copy -bsf:a aac_adtstoasc "$date_6".mp4
if [ $? -eq 0 ]
then
    rm ./*.ts
fi
sync
