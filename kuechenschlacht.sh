#!/bin/bash

# $1 == ep_url
# $2 == use_wget
function dl_single() {

    if [ $2 -eq 1 ]
    then
        echo -e "\nUsing wget:"
        # wget args:
        # -c, --continue       resume getting a partially-downloaded file
        # Not all wget versions (i.e. Ubuntu) support --show-progress
        # wget exit status 8 means "Server issued an error response", the server
        # sends a 405 message when we have a file clobber (we already have this
        # episode) so it's safe to ignore.
        wget -c "$1"
        ret="$?"
        if [ $ret -ne 0 ] && [ $ret -ne 8 ]; then return 1; fi
    else
        echo -e "\nUsing curl:"
        # -C -                 resume
        curl -C - -O "$1"
        if [ $? -ne 0 ]; then return 1; fi
    fi

    return 0

}


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


# Parse CLI args and display help test:
args=("$@")
if [[ " ${args[@]} " =~ "-h" ]]
then
    echo "usage: $0 [DD] [MM] [YY] [QUALITY]"
    echo ""
    echo "Defaults to todays date and maximum quality (2128):"
    echo ""
    echo "Default: $0 `date +'%d'` `date +'%m'` `date +'%y'` 2128"
    echo ""
    echo "Quality options (for whole episodes):"
    echo "368     : NAME=Hoch,BANDWIDTH=368kbps,RESOLUTION=480x270,CODEC=Google/On2 VP9"
    echo "1128    : NAME=Sehr Hoch,BANDWIDTH=1128Kbps,RESOLUTION=960x540,CODEC=Google/On2 VP9"
    echo "2128    : Name=HD,BANDWIDTH=2129Kbps,RESOLUTION=1280x720,CODEC=Google/On2 VP9"
    echo ""
    echo "Quality options (for chunked episodes):"
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
    echo "Note: Not all episodes are available at every quality"
    echo ""
    exit 1
fi


# Set default args
day_2="`date +'%d'`"
month_2="`date +'%m'`"
year_2="`date +'%y'`"
quality="2128"

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

date_6="$year_2"
date_6+="$month_2"
date_6+="$day_2"
d="./$date_6/"
mkdir -p "$d"
cd "$d"
echo "Downloading Die Küchenschlacht episode for $date_6:"


# Older episodes are available in chunks,
# newer episodes are available as a single video file.
# Try to download as a single file...
if [ "$quality" -eq "368" ]
then
    qual="368k_p16v15"
elif [ "$quality" -eq "1128" ]
then
    qual="1128k_p17v15"
else
    qual="2128k_p18v15"
fi
ep_url="https://nrodlzdf-a.akamaihd.net/none/zdf/"
ep_url+="$year_2/$month_2/"
ep_url+="$year_2$month_2"
ep_url+="$day_2"
ep_url+="_sendung_1415_dku/1/"
ep_url+="$year_2$month_2"
ep_url+="$day_2"
ep_url+="_sendung_1415_dku_$qual.webm"
dl_single $ep_url $use_wget
if [ $? -eq 0 ]
then
    sync
    echo "Finished"
    exit 0
fi


# If the single file download failed, try the chunked file method.
# If a chunked version of an episode is being downloaded, ffmpeg is required
# to concatenate the chunks together:
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


# wget will return a non-zero exist status if the playlist URL is invalid,
# curl will return 0. In the case of curl, an error message is returned by the
# remote server, check for the presence of the error message in the output file:
if [ -f $playlist_filename ]
then
    rm -f "./$playlist_filename"
fi
if [ $use_wget -eq 1 ]
then
    wget -nv "$playlist_url"
    if [ $? -ne 0 ]
    then
        echo "Playlist download failed. Exiting."
        echo "Hint: Try another quality setting, each episode is not not available in all qualities."
        exit 1
    fi
else
    curl -O "$playlist_url"
    if [ `grep -c "error occurred" "$playlist_filename"` -eq 1 ]
    then
        echo "Playlist download failed. Exiting."
        echo "Hint: Try another quality setting, each episode is not not available in all qualities."
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

if [ `ls *.ts | wc -l` -ne "$part_count" ]
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
    # We can't use "concat:" method for mp4 files with ffmpeg.
    #
    # Also the following method doesnt work on all ffmpeg vesions,
    # they don't all have the -protocol_whitelist option:
    # for f in `ls *.mp4`; do echo "file $f"; done | ffmpeg -protocol_whitelist file,pipe -f concat -i - -c copy "$date_6".mp4
    #
    # Instead write a list of mp4 to a file and feed that to ffmpeg,
    # this seems to be supported by most/all versions:
    for f in `ls *.mp4`; do echo "file $f" >> $$.tmp; done
    ffmpeg -f concat -i $$.tmp -c copy "$date_6".mp4
    if [ $? -eq 0 ]
    then
        for j in `seq 0 $i`
        do
            rm "./$j.mp4"
        done
        rm ./*.ts
        rm ./*.m3u8
        rm ./$$.tmp
    fi

else
    # On Linux we can use the following one-liner to get all the segment 
    # filenames, each seperated by a vertical pipe:
    # ls -1 *.ts | sort -V | tr '\n' '|' | head --bytes -1
    #
    # On Mac the bytes option for 'head' uses a different argument,
    # -c, and it doesn't support minus values.
    # The following filth works on Mac and Linux:
    # ls -1 *.ts | sort -V | tr '\n' '|' | rev | cut -c 2- | rev
    #
    # The following works on both and avoids an: if [ $(uname) == "Darwin" ]; then ...
    seg_list=`ls -1 *.ts | sort -V | tr '\n' '|' | rev | cut -c 2- | rev`
    ffmpeg -y -i "concat:$seg_list" -c copy -bsf:a aac_adtstoasc "$date_6".mp4
    if [ $? -eq 0 ]
    then
        rm ./*.ts
        rm ./*.m3u8
    fi
fi

sync
echo "Finished"
