#### Vignette
* Mention that package doesn't work well with volumetric, time based images. It can do volumes (z) or time stacks (t) but not both.
* Include how to deal with error "imagej can only open 8 and 16 bit/channel images" with BioFormats.

#### Size safety
* For writing, put in a max of 1 billion channels and frames.

#### Future goals
* Think about adding support for signed integer type.
* Add full support for alluseful tags listed on https://www.awaresystems.be/imaging/tiff/tifftags.html.
