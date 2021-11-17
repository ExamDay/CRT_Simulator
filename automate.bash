### OPTIONS ###
input_video=./inputs/shortAE.mp4
overlay=./resources/sonyCRTemph.png
audio=../../Music/AttributionOnly/1_Bottomless.mp3
output_video=./outputs/DreamBySalvadorDali_CRT.mp4

### PROCESS ###
# prompt to delete previous output file if it exists:
if [[ -f ${output_video} ]]; then
    read -p "Output file ${output_video} exists. Do you want to delete it? [y/N] " delete
    if [[ $delete == [yY] ]]; then
		rm "${output_video}" && echo "File deleted."
	else
		echo "Exiting..."
		exit 0
    fi
fi

# make temp and output directories if they do not exist:
mkdir -p ./temp
mkdir -p ./outputs

# rescale to max dimensions of 960 by 720 and center-pad to 4:3 aspect ratio as needed:
# Note: pad with off-black to simulate unlit phosphor on an otherwise active screen (most displays
# can't achieve a perfect black when turned on)
rm temp/transitional.mp4  # remove previous temp
ffmpeg -i ${input_video} -vf "scale=960:720:force_original_aspect_ratio=decrease,pad=960:720:(ow-iw)/2:(oh-ih)/2:color=0x151515" -vcodec libx264rgb temp/transitional.mp4

# apply crt curvature, pixelation, interlacing, and other effects:
rm temp/transitional.mp4__crtTV.mp4  # remove previous temp
./crt.bash temp/transitional.mp4

# position video for overlay by padding with black as needed:
# Note: in this provided case the position is appropriate for the sonyCRT* overlays
rm temp/padded.mp4  # remove previous temp
ffmpeg -i temp/transitional.mp4__crtTV.mp4 -filter pad="1920:1080:959-(iw/2):529-(ih/2)" temp/padded.mp4

# add static overlay:
rm temp/silent.mp4  # remove previous temp
ffmpeg -i temp/padded.mp4 -i ${overlay} -filter_complex "[0:v][1:v] overlay=0:0" -c:a copy temp/silent.mp4

# add audio track and finish:
ffmpeg -i temp/silent.mp4 -i ${audio} -c:v copy -c:a aac -strict experimental -shortest ${output_video}

exit 0

# DON'T FORGET TO ATTRIBUTE LOFI GIRL IF YOU USE ANY OF HIS STUFF:
# - Artist(s) name - Track title
# - Provided by Lofi Girl
# - Watch: YouTube link to the music concerned
# - Listen: Spotify link to the music concerned
