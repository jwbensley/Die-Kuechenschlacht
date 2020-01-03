#!/bin/bash


# Ensure required bins are present
which wget > /dev/null
if [ $? -eq 0 ]
then
    use_wget=1
    echo "Using wget"
else
    use_wget=0
    which curl > /dev/null
    if [ $? -eq 0 ]
    then
        use_curl=1
        echo "Using curl"
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
fi

if [ $(ffmpeg 2>&1 | grep -c "Libav") -gt 0 ]
then
    echo "It appears that avconv is installed instead of ffmpeg."
    echo "avconv is not support (yet). Exiting."
    exit 1
fi


# Parse CLI args and display help test:
args=("$@")
if [[ " ${args[@]} " =~ "-h" ]]
then
    echo "usage: $0 [DD] [MM] [YY] [QUALITY]"
    echo ""
    echo "Defaults to todays date and maximum quality (3328000):"
    echo ""
    echo "Default: $0 `date +'%d'` `date +'%m'` `date +'%y'` 3328000"
    echo ""
    echo "Quality options:"
    echo "476000  : BANDWIDTH=388000,RESOLUTION=480x272,CODECS='avc1.77.30, mp4a.40.2'"
    echo "508000  : BANDWIDTH=424000,RESOLUTION=480x270,CODECS='avc1.77.30, mp4a.40.2'"
    echo "776000  : BANDWIDTH=623000,RESOLUTION=640x360,CODECS='avc1.77.30, mp4a.40.2'"
    echo "808000  : BANDWIDTH=665000,RESOLUTION=640x360,CODECS='avc1.77.30, mp4a.40.2'"
    echo "1496000 : BANDWIDTH=1193000,RESOLUTION=852x480,CODECS='avc1.77.30, mp4a.40.2'"
    echo "1628000 : BANDWIDTH=1314000,RESOLUTION=960x540,CODECS='avc1.77.30, mp4a.40.2'"
    echo "2296000 : BANDWIDTH=1830000,RESOLUTION=1024x576,CODECS='avc1.77.30, mp4a.40.2'"
    echo "3296000 : BANDWIDTH=2583000,RESOLUTION=1280x720,CODECS='avc1.640028, mp4a.40.2'"
    echo "3328000 : BANDWIDTH=2652000,RESOLUTION=1280x720,CODECS='avc1.640028, mp4a.40.2'"
    echo ""
    echo "Note: Not all episodes are available every qualities"
    echo ""
    exit 1
fi

day_2="`date +'%d'`"
month_2="`date +'%m'`"
year_2="`date +'%y'`"
quality="3328000"

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
# segments which make the episode:
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
# remote server, check for the presence of the error message in the output file:
if [ $use_wget -eq 1 ]
then
    wget -nv "$playlist_url"
    if [ $? -ne 0 ]
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



# Download all the segments in the playlist
if [ $use_wget -eq 1 ]
then
    echo -e "\nUsing wget:"
    # wget args:
    # -nv, --no-verbose    turn off verboseness, without being quiet.
    # -N,  --timestamping  don't re-retrieve files unless newer than local.
    # Not all wget versions (i.e. Ubuntu) support --show-progress
    # wget exit status 8 means "Server issued an error response", the server
    # sends a 405 message when we have a file clobber (we already have this
    # segment) so it's safe to ignore.
    for url in `grep -v "#" "$playlist_filename"`
    do
        wget -nv -N "$url"
        ret="$?"
        if [ $ret -ne 0 ] && [ $ret -ne 8 ]; then exit 1; fi
        echo -e "Segment: `ls *.ts | wc -l`/$part_count\n\n"
    done
else
    echo -e "\nUsing curl:"
    # curl doesn't have any sort of no-clobber option like wget
    for url in `grep -v "#" "$playlist_filename"`
    do
        curl -O "$url"
        if [ $? -ne 0 ]; then exit 1; fi
        echo -e "Segment: `ls *.ts | wc -l`/$part_count\n\n"
    done
fi

if (( `ls *.ts | wc -l` != "$part_count" ))
then
    echo "Some parts are missing from the download. Exiting."
    exit 1
fi



# Merge all the segments into a single video file.
# If there are more than 100 segments, merge them in to 100-segment files and
# then merge those 100-segment files. This is to prevent open file limits from
# being reached.
if [ $part_count -gt 100 ]
then

    # Merge 100 segments at a time
    for i in `seq 0 $((($part_count/100)-1))`
    do
        seg_list=`ls -1 segment*.ts | sort -V | head -n $((100+(100*$i))) | tail -n 100 | tr '\n' '|' | rev | cut -c 2- | rev`
        ffmpeg -y -i "concat:$seg_list" -c copy -bsf:a aac_adtstoasc "$i".mp4
    done

    # Merge whatever is left
    let i=i+1
    diff=$(($part_count-(i*100)))
    seg_list=`ls -1 segment*.ts | sort -V | tail -n $diff | tr '\n' '|' | rev | cut -c 2- | rev`
    ffmpeg -y -i "concat:$seg_list" -c copy -bsf:a aac_adtstoasc "$i".mp4

    # Merge the 100-segment chunks.
    # Can't use "concat:" method for mp4 files with ffmpeg.
    for f in `ls *.mp4`; do echo "file $f"; done | ffmpeg -protocol_whitelist file,pipe -f concat -i - -c copy "$date_6".mp4
    if [ $? -eq 0 ]
    then
        for j in `seq 0 $i`
        do
            rm "./$j.mp4"
        done
        rm ./*.ts
        rm ./*.m3u8

    fi

else
    # On Linux we can use the following to get all the segment file names seperated by a vertical pipes:
    # ls -1 *.ts | sort -V | tr '\n' '|' | head --bytes -1
    #
    # On Mac the bytes option for 'head' uses a different argument, -c, and it doesn't support minus values.
    # The following filth works on Mac and Linux
    # ls -1 *.ts | sort -V | tr '\n' '|' | rev | cut -c 2- | rev
    #
    # This is to avoid an...
    # if [ $(uname) == "Darwin" ]; then ...
    seg_list=`ls -1 *.ts | sort -V | tr '\n' '|' | rev | cut -c 2- | rev`
    ffmpeg -y -i "concat:$seg_list" -c copy -bsf:a aac_adtstoasc "$date_6".mp4
    if [ $? -eq 0 ]
    then
        rm ./*.ts
    fi
fi

sync
echo "Finished"
