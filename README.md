Retina
======

Retina is a command line tool which performs individual or batch retina to standard resolution image conversion for iOS/Mac app development (that is, ```image@2x.png``` → ```image.png``` and vice versa).

Retina can be used as part of your build toolchain to automatically produce standard resolution versions of retina assets so you don't need to manually produce or maintain a standard resolution set.

Installing
----------

The easiest way to install Retina is to use the installer script ```install.sh```, which will build and install Retina via ```xcodebuild```:

    $ cd /path/to/Retina  # The path to the Retina source directory
    $ sudo ./install.sh   # Build and install Retina

The installer script installs Retina under the prefix ```/usr/local```, which is why you have to run the install with ```sudo``` (or otherwise have permission to write to that directory).

Usage
-----

To convert all of the ```@2x``` retina resolution images in the directory ```Project/images```, you can use the following command. Only out-of-date images will be converted:

    $ retina -S Project/images

Or to convert an individual image. The image will be converted only if it is out-of-date:

    $ retina -S Project/images/Default@2x.png

Or to scale up standard resolution assets to retina (…for some reason):

    $ retina -R Project/images

To convert all suitable images, regardless of whether they are out of date:

    $ retina -S -f Project/images
    
To see which images would be converted, but without actually performing any conversion:

    $ retina -S -p Project/images

For help and more options, use:

    $ retina -h

Or view the Retina manpage:

    $ man retina
  
