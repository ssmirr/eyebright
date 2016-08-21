# iiif-image-server

Simple Rails IIIF image server.

The intention is for this image server to be deployed behind Passenger (Apache or nginx). This allows for caching image and info.json files to the public directory and having them served up directly by the web server instead of hitting the application. See below for how to clear the cache.

The other level of caching is for image information. This cache is done in Memcached and currently only holds just enough information about each image so that the Extractor can perform its calculations. Currently this includes the image width, height, and scale factors.

## Managing the image file cache

The file cache is in public/iiif. In many cases public/iiif will be a symlink to bulk storage mounted to the server. All of the file paths follow the the IIIF URL pattern so that the images after initial creation can be served up directly by your web server (Apache).

Clearing the cache is just a matter of identifying the files you want to clear out and deleting them. An example rake task is provided which clears out all the files which do not match particular patterns that are commonly used on NCSU Libraries sites in lib/tasks/image_cache.rake.

You will need to define a constant `IIIF_PROFILE` with a list of matching paths that you want to keep in your cache. You can look in config/initializers/iiif_profile.rb for an example. 

`bin/rake iiifis:image_cache:prune_all`

You can also prune the cache for just a single identifier:

`bin/rake iiifis:image_cache:prune[IDENTIFIER]`

## Managing the in-memory information cache

The cache is constrained by the memory limits put on Memcached so it functions as a least recently used cache once the memory limit is reached.

To clear Memcached you can run this rake task:

`bin/rake iiifis:info_cache:flush`

But all this really does is run: `MDC.flush`

You can also use `MDC` with any option provided by the [dalli](https://github.com/petergoldstein/dalli) client.
