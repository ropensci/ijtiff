# print method works

    Code
      read_tif(test_path("testthat-figs", "Rlogo-banana-red.tif"))
    Message <simpleMessage>
      Reading Rlogo-banana-red.tif: an 8-bit, 155x200 pixel image of
      unsigned integer type. Reading 1 channel and 2 frames . . .
       Done.
    Message <cliMessage>
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
    Message <cliMessage>
      * bits_per_sample: 8
      * samples_per_pixel: 1
      * sample_format: uint
      * planar_config: contiguous
      * rows_per_strip: 155
      * compression: none
      * description: ImageJ=1.51s images=2 slices=2 loop=false
      * color_space: palette
      * color map: matrix with 256 rows and 3 columns (red, green, blue)

