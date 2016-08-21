# iiif-image-server

Simple Rails IIIF image server.

The intention is for this image server to be deployed behind Passenger (Apache or nginx). All of the cached file paths follow the the IIIF URL pattern. This allows for caching image and info.json files to the public directory and having them served up directly by the web server instead of those requests hitting the application. In many cases public/iiif will be a symlink to bulk storage mounted to the server.

The other level of caching is for image information. This cache is done in Memcached and currently only holds just enough information about each image so that the Extractor can perform its calculations before creating an image. Currently this includes the image width, height, and scale factors.

## Requirements

See the `ansible` directory for all the requirements for running the application in Vagrant. This ought to give you a good start at how to install this on your own servers.

## Managing the image file cache

Clearing the cache is just a matter of identifying the files you want to clear out and deleting them. An example rake task is provided which clears out all the files which do not match particular IIIF URL patterns.

You will need to define a constant `IIIF_PROFILE` with a list of matching paths (from the region on) that you want to keep in your cache. You can look in config/initializers/iiif_profile.rb for an example.

`bin/rake iiifis:image_cache:prune_all`

You can also prune the cache for just a single identifier:

`bin/rake iiifis:image_cache:prune[IDENTIFIER]`

## Managing the in-memory information cache

The cache is constrained by the memory limits put on Memcached so it functions as a least recently used cache once the memory limit is reached.

To clear Memcached you can run this rake task:

`bin/rake iiifis:info_cache:flush`

But all this really does is run: `MDC.flush`

You can also use `MDC` with any option provided by the [dalli](https://github.com/petergoldstein/dalli) client.

## Kakadu Copyright Notice and Disclaimer
 We do not distribute the Kakadu executables. You will need to install the Kakadu binaries/executables available [here](http://kakadusoftware.com/downloads/). The executables available there are made available for demonstration purposes only. Neither the author, Dr. Taubman, nor UNSW Australia accept any liability arising from their use or re-distribution.

That site states:

> Copyright is owned by NewSouth Innovations Pty Limited, commercial arm of the UNSW Australia in Sydney. **You are free to trial these executables and even to re-distribute them, so long as such use or re-distribution is accompanied with this copyright notice and is not for commercial gain. Note: Binaries can only be used for non-commercial purposes.** If in doubt please contact the Kakadu Team at info@kakadusoftware.com.


## Authors

- Jason Ronallo

## License

See MIT-LICENSE
