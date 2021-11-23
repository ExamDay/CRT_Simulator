# make binaries accessible from commandline:
cd into"FFMPEG/bin/"
sudo ln -s "${PWD}/ffmpeg" /usr/local/bin/
sudo ln -s "${PWD}/ffmpeg" /usr/bin/
sudo ln -s "${PWD}/ffprobe" /usr/local/bin/
sudo ln -s "${PWD}/ffprobe" /usr/bin/

# recompile video to higher compression level: (crf 28 is good for most things)
ffmpeg -i input.mp4 -vcodec libx264rgb -crf 28 output.mp4

# get 3 second slice of video:
ffmpeg -i input.mp4 -ss 00:00:03 -to 00:00:06 -async 1 sliceOfInput.mp4

# restamp video to different framerate (in this case 30 fps)
ffmpeg -i input.mp4 -map 0:v -c:v copy -bsf:v h264_mp4toannexb raw.h264
ffmpeg -fflags +genpts -r 30 -i raw.h264 -c:v copy output.mp4

# smooth by optical flow to a higher framerate (in this case 60 fps)
ffmpeg -i input.mp4 -filter:v "minterpolate='mi_mode=mci:mc_mode=aobmc:vsbmc=1:fps=60'" output.mp4

# rescale video to standard definition with black padding instead of stretching:
ffmpeg -i input.mp4 -vf "scale=960:720:force_original_aspect_ratio=decrease,pad=960:720:(ow-iw)/2:(oh-ih)/2:color=0x151515" -vcodec libx264rgb output.mp4

# apply CRT simulation filter-chain
./crt.bash input.mp4

# pad to specific alignment inside larger frame (in this case tuned to center inside picture of CRT monitor)
ffmpeg -i input.mp4 -filter pad="1920:1080:959-(iw/2):529-(ih/2)" output.mp4

# overlay image (in this case tuned for picture of CRT monitor)
ffmpeg -i input.mp4 -i overlay.png -filter_complex "[0:v][1:v] overlay=0:0" -c:a copy output.mp4

# add audio to video
ffmpeg -i video.mp4 -i audio.mp3 -c:v copy -c:a aac -strict experimental -shortest output.mp4

# concatenate videos
cat vidlist.txt
file '/path/to/file1'
file '/path/to/file2'
file '/path/to/file3'

ffmpeg -f concat -safe 0 -i vidlist.txt -c copy output.mp4
