Retina
======

Retina is a command line tool which performs individual or batch retina to standard resolution image conversion for iOS/Mac app development.

Usage
-----

To convert all of the ```@2x``` retina resolution images in the directory ```MyProject/images```, you can use the following command:

    $ retina -S MyProject/images

Or to convert an individual image:

    $ retina -S MyProject/images/Default@2x.png

Or to scale up standard resolution assets to retina (for some reason…):

    $ retina -R MyProject/images

And to see which images would be converted, but without actually performing any conversion, you can use:

    $ retina -S -p MyProject/images

For help and more options, use:

    $ retina -h
