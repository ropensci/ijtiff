# print method works

    Code
      read_tif(test_path("testthat-figs", "Rlogo-banana-red.tif"))
    Message
      Reading image from testthat-figs/Rlogo-banana-red.tif
      Reading an 8-bit, float image with dimensions 155x200x1x2 (y,x,channel,frame) . . .
      155x200 pixel ijtiff_img with 1 channel and 2 frames.
      Preview (top left of first channel of first frame):
    Output
           [,1] [,2] [,3] [,4] [,5] [,6]
      [1,]  255  255  255  255  255  255
      [2,]  255  255  255  255  255  255
      [3,]  255  255  255  255  255  255
      [4,]  255  255  255  255  255  255
      [5,]  255  255  255  255  255  255
      [6,]  255  255  255  255  255  255
      -- TIFF tags -------------------------------------------------------------------
    Message
      * ImageWidth: 200
      * ImageLength: 155
      * ImageDepth: 1
      * BitsPerSample: 8
      * SamplesPerPixel: 1
      * SampleFormat: unsigned integer data
      * PlanarConfiguration: contiguous
      * RowsPerStrip: 155
      * Compression: none
      * Threshholding: 1
      * ResolutionUnit: inch
      * Orientation: top_left
      * ImageDescription: ImageJ=1.51s images=2 slices=2 loop=false
      * PhotometricInterpretation: Palette
      * ColorMap: matrix with 256 rows and 3 columns (red, green, blue)

