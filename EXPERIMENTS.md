# Experiments

Documentation for experiments for non-standard IIIF APIs.

## Video Stills

This image server includes experimental support for extracting still images from a video. Note that info.json is not yet implemented.

You can see the sample videos here:
<https://github.com/NCSU-Libraries/eyebright/tree/master/test/videos>
No attempt is made yet to serve the actual video file but just still images from the video.

If you have the development server running you can visit:
<http://localhost:8090/iiifv/water/8/full/600,/0/default.jpg>

Otherwise use the included Apache server:
<https://localhost:8444/iiifv/water/8/full/600,/0/default.jpg>

The URL structure is the following:

`/prefix/identifier/time_in_seconds/region/size/rotation/quality.format`

Included CC0 videos from [Pexels](https://videos.pexels.com/video-license):

- bee
- forest
- water

### Video Stills: TODOs
- consider using [yadif filter](http://ffmpeg.org/ffmpeg-all.html#yadif) for deinterlacing and [scale filter](http://ffmpeg.org/ffmpeg-all.html#scale) for resizing, especially if getting the full image region: `-filter:v 'yadif,scale=420:270'`
- If a full sized image is already available on the file system use that instead of extracting a still from the video using ffmpeg again.
