import numpy as np, tifffile, pathlib
out = pathlib.Path("inst/img")
out.mkdir(parents=True, exist_ok=True)

# signed 16-bit grayscale, with genuine negatives
a = np.linspace(-30000, 30000, 32 * 32).reshape(32, 32).astype(np.int16)
tifffile.imwrite(out / "signed16.tif", a)

# tiled RGB (uint8), contiguous (chunky) — reads on the DIRECT path today; used
# to prove convert="auto" leaves tiled-contig images unchanged.
rgb = (np.random.default_rng(0).integers(0, 256, (40, 48, 3))).astype(np.uint8)
tifffile.imwrite(out / "tiled_rgb.tif", rgb, tile=(16, 16), photometric="rgb")

# tiled + PLANAR (separate) RGB — spp>1 non-contig tiled is structurally
# undecodable by the strip/tile path (errors today); used to test the
# convert="auto" RGBA rescue and the convert="never" error.
# NOTE: tifffile requires the samples axis at the 3rd-from-last dimension
# (channels-first) when planarconfig="separate" -- passing the channels-last
# `rgb` array as-is silently produces a corrupt tag set (ImageWidth=3,
# SamplesPerPixel=40). Move the channel axis to the front before writing.
rgb_planar = np.moveaxis(rgb, -1, 0)  # (3, 40, 48)
tifffile.imwrite(out / "tiled_planar.tif", rgb_planar, tile=(16, 16), photometric="rgb",
                 planarconfig="separate")

# YCbCr via JPEG compression (photometric=6). Reads as GARBAGE today (not an
# error); convert="force" decodes it to RGB.
tifffile.imwrite(out / "ycbcr.tif", rgb, photometric="ycbcr", compression="jpeg")

# CMYK (separated, photometric=5), uncompressed contiguous. Reads today as a
# correct 4-channel C,M,Y,K array on the direct path; convert="force" -> RGB.
cmyk = (np.random.default_rng(1).integers(0, 256, (40, 48, 4))).astype(np.uint8)
tifffile.imwrite(out / "cmyk.tif", cmyk, photometric="separated")
print("wrote signed16, tiled_rgb, tiled_planar, ycbcr, cmyk")
