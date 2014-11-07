LazyLoadingSample
=================

A sample to demonstrate the lazy loading and saving the downloaded image in the tmp dir.

The files are downloaded from the server using lazy loading and the it saves those files to a temporary directory.

Here is the simple flow

if (image_in_memory) load image
else if (image_in_storage) load image
else download image from the server

After downloading image save it to disk and load it into the memory
