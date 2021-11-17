#!/bin/bash

### SETTINGS ###

# compression resolution (resolution to down-sample to for pixelation effect) 
# Note: must be 4:3 aspect ratio for automate.bash
compX=640  # was 320 (Most convincing @ 180)
compY=480  # was 240 (Most convincing @ 144)

# precurvature resolution (resolution to sample back up to before lensing and other effects)
# Note: must be 4:3 aspect ratio for automate.bash
compX=640  # was 320 (Most convincing @ 180)
interX=1200  # (Most convincing @ 720)
interY=900  # (Most convincing @ 576)

# post-curvature (final) resolution (only used to fit final video to specific overlay)
# Note: must be 4:3 aspect ratio for automate.bash
compX=640  # was 320 (Most convincing @ 180)
finX=988  # slightly larger than 960 to account for unavoidable padding around lenscorrection.
finY=741  # slightly larger than 720 for same reason as above.

### FILTERS ###

# reduce for pixelation processing
shrink="scale=-2:${compY}"

# crop to reduced size
crop="crop=${compX}:${compY}"

# scale to final size
finScale="scale=${finX}:${finY}"

# create RGB chromatic aberration
rgbFX="split=3[red][green][blue];
      [red] lutrgb=g=0:b=0,
            scale=${compX}x${compY},
            crop=${compX}:${compY} [red];
      [green] lutrgb=r=0:b=0,
              scale=${compX}x${compY},
              crop=${compX}:${compY} [green];
      [blue] lutrgb=r=0:g=0,
             scale=${compX}x${compY},
             crop=${compX}:${compY} [blue];
      [red][blue] blend=all_mode='addition' [rb];
      [rb][green] blend=all_mode='addition',
                  format=gbrp"

# create YUV chromatic aberration
yuvFX="split=3[y][u][v];
      [y] lutyuv=u=0:v=0,
		  scale=(${compX}*1.066):${compY},
          crop=${compX}:${compY} [y];
      [u] lutyuv=v=0:y=0,
          scale=(${compX}*1.044)x${compY},
          crop=${compX}:${compY} [u];
      [v] lutyuv=u=0:y=0,
          scale=${compX}x${compY},
          crop=${compX}:${compY} [v];
      [y][v] blend=all_mode='lighten' [yv];
      [yv][u] blend=all_mode='lighten'"

# create edge contour effect
edgeFX="edgedetect=mode=colormix:high=0"

# add noise to each frame
noiseFX="noise=c0s=7:allf=t"

# Add interlaced fields effect
interlaceFX="split[a][b];
             [a] curves=darker [a];
             [a][b] blend=all_expr='if(eq(0,mod(Y,2)),A,B)':shortest=1"

# re-scale to pre-curvature resolution with linear pixel (optional neighbor flag for extra)
scale2PC="scale=${interX}:${interY}:flags=neighbor"

# add magnetic damage effect
screenGauss="[base];
             nullsrc=size=${interX}x${interY},
                drawtext=
                   fontfile=/usr/share/fonts/truetype/freefont/FreeSerif.ttf:
                   text='@':
                   x=800:
                   y=40:
                   fontsize=85:
                   fontcolor=red@1.0,
             boxblur=40 [gauss];
             [gauss][base] blend=all_mode=screen:shortest=1"

# add reflections
reflections="[base];
             nullsrc=size=${interX}x${interY},
             format=gbrp,
             drawtext=
               fontfile=/usr/share/fonts/truetype/freefont/FreeSerif.ttf:
               text='€':
               x=${interX}*0.85:
               y=${interY}*0.15:
               fontsize=45:
               fontcolor=white,
             drawtext=
               fontfile=/usr/share/fonts/truetype/freefont/FreeSerif.ttf:
               text='J':
               x=${interX}*0.20:
               y=${interY}*0.85:
               fontsize=30:
               fontcolor=white,
             boxblur=12.5 [lights];
             [lights][base] blend=all_mode=screen:shortest=1"

# add more detailed highlight
highlight="[base];
             nullsrc=size=${interX}x${interY},
             format=gbrp,
             drawtext=
               fontfile=/usr/share/fonts/truetype/freefont/FreeSerif.ttf:
               text='¡':
               x=107:
               y=80:
               fontsize=45:
               fontcolor=white,
             boxblur=3.5 [lights];
             [lights][base] blend=all_mode=screen:shortest=1"

# curve to mimic curvature of crt screen
curveImage="vignette,
            format=gbrp,
            lenscorrection=k1=0.06:k2=0.06:fc=black"

# add bloom effect
bloomEffect="split [a][b];
             [b] boxblur=13,
                    format=gbrp [b];
             [b][a] blend=all_mode=screen:shortest=1"

# interpolate to higher framerate
interpolate="minterpolate='mi_mode=mci:mc_mode=aobmc:vsbmc=1:fps=30'"

### FFMPEG FILTERCHAIN (final command) ###

ffmpeg \
   -i "$1" \
   -vf "
		 ${shrink},
		 ${crop},
		 ${rgbFX},
         ${noiseFX},
         ${interlaceFX},
         ${scale2PC}
         ${screenGauss}
         ${reflections}
         ${highlight},
         ${curveImage},
		 ${finScale},
         ${bloomEffect}
      " \
	-vcodec libx264rgb -crf 28 \
   "${1}__crtTV.mp4"

exit 0
