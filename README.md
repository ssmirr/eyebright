# Eyebright

Rails [IIIF](http://iiif.io/) [image server](iiif.io/api/image/).

> Eyebright is a traditional medicinal herb used to relieve eye strain.

## Why another IIIF Image server?

The intention is for this image server to be deployed behind Passenger. All of the cached file paths follow the the IIIF URL pattern. This allows for caching image and info.json files to the public directory of the application and having them served up directly by the web server (Apache or nginx) instead of those requests hitting the application. In many cases public/iiif will be a symlink to bulk storage mounted to the server.

In addition the cache can be cleared based on a profile which lists the IIIF URL paths that ought to be kept in the cache longer term. This allows the image server to function more like a just in time static site generator for commonly used images.

The other level of caching is for image information. This cache is done in Memcached and currently only holds just enough information about each image so that the Extractor can perform its calculations before creating an image. Currently this includes the image width, height, and scale factors.

## Status

This image server should pass the [IIIF Image API Validator](http://iiif.io/api/image/validator/results/?server=https%3A%2F%2Fiiif.lib.ncsu.edu&prefix=iiif&identifier=67352ccc-d1b0-11e1-89ae-279075081939&version=2.0&level=2&id_squares=on&info_json=on&id_basic=on&id_error_escapedslash=on&id_error_unescaped=on&id_escaped=on&id_error_random=on&region_error_random=on&region_pixels=on&region_percent=on&size_region=on&size_error_random=on&size_ch=on&size_wc=on&size_percent=on&size_bwh=on&size_wh=on&rot_error_random=on&rot_region_basic=on&rot_full_basic=on&quality_error_random=on&quality_color=on&quality_bitonal=on&quality_grey=on&format_jpg=on&format_error_random=on&format_png=on&jsonld=on&baseurl_redirect=on&cors=on) version 2.0 at level 2. (Note that as of this writing the bitonal test seems to be broken and I believe the check image information test should be more permissive regarding allowing multiple profiles.)

It is used in production at NCSU Libraries on the [Rare and Unique Digital Collections](http://d.lib.ncsu.edu/collections) site as well as others.

It is otherwise untested.

## Quick Start

```
vagrant up
vagrant ssh
cd /vagrant
bundle
```

Currently there is a very simple resolver in `app/models/resolver.rb` that in development expects to find JPEG2000 files in `./test/images`. Add some JP2s there in a directory using the first two characters of the filename. Then you ought to be able to see an image at: <http://localhost:8091/iiif/hubble/full/pct:20/0/default.jpg>

Note, you will have to accept the self-signed certificate to use the version deployed behind Apache and Passenger. If you would like to do development on Eyebright (or avoid accepting the self-signed cert), you will want to run a development server like this:

```
vagrant ssh
cd /vagrant
bundle
bin/rails s -b 0.0.0.0
```

Then on the host machine you can visit <http://localhost:8091/iiif/river/full/600,/0/default.jpg>. And change all the following URLs to "http://localhost:8091".

You can see a list of JPEG2000 images that are included in the development environment below. For convenience of testing images, there is a OpenSeadragon pan/zoom viewer. It can be reached at a URL like: <http://localhost:8091/iiif/hubble/view>

## Requirements

See the `ansible` directory for all the requirements for running the application in Vagrant. This ought to give you a good start at how to install this on your own servers. We use this basic template for provisioning staging and production machines for this application.

## Configuration

On deploy to staging and production the following files in the config directory will need to be updated:
- eyebright.yml
- secrets.yml
- initializers/iiif_profile.rb
- initializers/iiif_url.rb

You may also want to change `config/schedule.rb` to clear the cache on a different schedule.

We deploy with Capistrano and use the linked files feature to replace those files. We can share our basic recipe if you ask.

## Managing the image file cache

Since the cache is on the filesystem, clearing the cache is just a matter of identifying the files you want to clear out and deleting them. An example rake task is provided which clears out all the files which do not match particular IIIF URL patterns called a profile.

You will need to define a constant `IIIF_PROFILE` with a list of matching paths (from the region on) that you want to keep in your cache. You can look in `config/initializers/iiif_profile.rb` for an example.

`bin/rake eyebright:image_cache:prune_all`

You can also prune the cache for just a single identifier:

`bin/rake eyebright:image_cache:prune[river]`

## Managing the in-memory information cache

The cache is constrained by the memory limits put on Memcached so it functions as a least recently used cache once the memory limit is reached.

To clear Memcached you can run this rake task:

`bin/rake eyebright:info_cache:flush`

But all this really does is run: `MDC.flush`

You can also use `MDC` with any option provided by the [dalli](https://github.com/petergoldstein/dalli) client.

## Image API Extension

When we initially implemented square images in the index view of our search application, we discovered an issue we have referred to as the headless VIP or the horses behind problem. If a portrait image was cropped into a square from the center, then someone very important to our university could be shown headless. Or a landscape image
For some images we record along with their descriptive metadata whether they ought to be cropped differently. To make this

This image server implements gravity bangs for square regions. This means that a 'square' region will result in a square region extracted from the center of the image. But if '!square' is used, then the square region will begin at the top for portrait images and at the left for landscape images. Similarly the region 'square!' will anchor the square region to the bottom right of the image.

Naming these other commonly used square regions consistently means that determining a square image of a particular size ought to be left in the file cache can be more easily done. Otherwise the region for a square other than a centered one would use numbers which will vary depending on the image size and dimensions.

You can visit URLs like this to see it in action:

- <http://localhost:8091/iiif/river/square/200,/0/default.jpg>
- <http://localhost:8091/iiif/river/!square/200,/0/default.jpg>
- <http://localhost:8091/iiif/river/square!/200,/0/default.jpg>

See below for other fun extensions.

## Kakadu Copyright Notice and Disclaimer
 We do not distribute the Kakadu executables. You will need to install the Kakadu binaries/executables available [here](http://kakadusoftware.com/downloads/). The executables available there are made available for demonstration purposes only. Neither the author, Dr. Taubman, nor UNSW Australia accept any liability arising from their use or re-distribution.

That site states:

> Copyright is owned by NewSouth Innovations Pty Limited, commercial arm of the UNSW Australia in Sydney. **You are free to trial these executables and even to re-distribute them, so long as such use or re-distribution is accompanied with this copyright notice and is not for commercial gain. Note: Binaries can only be used for non-commercial purposes.** If in doubt please contact the Kakadu Team at info@kakadusoftware.com.

## Test Images

So that you do not get bored during development of Eyebright, a number of fairly high resolution images have been included as JP2s in `test/images`. All the test images are from Unsplash. Following are the list of filenames given to the images linked to the original:

- ![river](https://unsplash.com/photos/qQC8tyG_JVA)
- ![pages](https://unsplash.com/photos/Oaqk7qqNh_c)
- ![craters](https://unsplash.com/photos/jYBy2HCUve0)
- ![hubble](https://unsplash.com/photos/rTZW4f02zY8)
- ![nz](https://unsplash.com/photos/qH36EgNjPJY)
- ![field](https://unsplash.com/photos/DDp-gC81V0w)
- ![waterfall](https://unsplash.com/photos/VB-w_3dnyvI)
- ![bookshelf](https://unsplash.com/photos/cJCQKSP2WC4)
- ![bookstore](https://unsplash.com/photos/o4-YyGi5JBc)
- ![maps](https://unsplash.com/photos/1-29wyvvLJA)

These are the parameters that were used to create these images:

```sh
kdu_compress -rate 0.5 -precise Clevels=6 "Cblk={64,64}" -jp2_space sRGB \
  Cuse_sop=yes Cuse_eph=yes Corder=RLCP ORGgen_plt=yes ORGtparts=R \
  "Stiles={1024,1024}" -double_buffering 10  -num_threads 4 \
  Creversible=no -no_weights  -i river.tif -o river.jp2
```

## Experiments

See `EXPERIMENTS.md` for documentation on experimental support for extracting still images from a video.

## Fun

The following image qualities are available in addition to those specified in the standard:

- dither
- pixelized
- negative
- paint (Only turned on in development because it is slow.)

To turn these features on for a particular environment change the value of the "fun" key to `true`.

These qualities also work (with variable success) in the embedded pan/zoom viewer like so:

<http://localhost:8091/iiif/river/view?eyebright_mode=pixelized>

## Authors

- Jason Ronallo

## License

See MIT-LICENSE
