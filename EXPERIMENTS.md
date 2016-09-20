# Experiments

Documentation for experiments for non-standard IIIF APIs.

## Video Stills

This image server includes experimental support for extracting still images from a video.

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
