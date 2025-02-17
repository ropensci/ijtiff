# write_tif() errors correctly

    If `bits_per_sample` is a string, then 'auto' is the only allowable value.
    x You have `bits_per_sample = 'abc'`.

---

    If specifying `bits_per_sample`, it must be one of 8, 16 or 32.
    x You have used '12'.

---

    The lowest allowable negative value in `img` is -3.40282346638529e+38.
    x The lowest value in your `img` is -6.80564693277058e+38.
    i The `write_txt_img()` function allows you to write images without  restriction on the values therein. Maybe you should try that?

---

    If `img` has negative values (which the input `img` does), then the maximum allowed positive value is 3.40282346638529e+38.
    x The largest value in your `img` is 6.80564693277058e+38.
    i The `write_txt_img()` function allows you to write images without  restriction on the values therein. Maybe you should try that?

---

    Your image needs to be written as floating point numbers (not integers). For this, it is necessary to have 32 bits per sample.
    x You have selected 16 bits per sample.

---

    The maximum value in 'img' is 8589934592 which is greater than 2^32 - 1 and therefore too high to be written to a TIFF file.
    i The `write_txt_img()` function allows you to write images without  restriction on the values therein. Maybe you should try that?

---

    You are trying to write a 16-bit image, however the maximum element in `img` is 1048576, which is too big.
    x The largest allowable value in a 16-bit image is 65535.
    i To write your `img` to a TIFF file, you need at least 32 bits per sample.

---

    The ImageJ-written image you're trying to read says in its ImageDescription that it has 13 images of 5 slices of 2 channels. However, with 5 slices of 2 channels, one would expect there to be 5 x 2 = 10 images.
    x This discrepancy means that the `ijtiff` package can't read your image correctly.
    i One possible source of this kind of error is that your image may be temporal and volumetric. `ijtiff` can handle either time-based or volumetric stacks, but not both.

---

    The ImageJ-written image you're trying to read says it has 8 frames AND 5 slices.
    x To be read by the `ijtiff` package, the number of slices OR the number of frames should be specified in the ImageDescription and they're interpreted as the same thing. It does not make sense for them to be different numbers.

# reading certain frames works

    You have requested frame number 7 but there are only 5 frames in total.

