/* Writes a WxH 12-bit grayscale TIFF with a per-row horizontal ramp 0..4095.
   Usage: make-gray12 <out.tif> <W> <H> [rows_per_strip]
   Compile: cc make-gray12.c -ltiff -o make-gray12
   12-bit samples are packed big-endian, 2 samples per 3 bytes (matches DE12A/DE12B).
   Each scanline is padded to a whole byte: rowbytes = (W*12 + 7) / 8.
   Uses TIFFWriteScanline so libtiff chunks rows into strips per rows_per_strip
   (pass a value < H to produce a genuine MULTI-STRIP file). */
#include <tiffio.h>
#include <stdlib.h>
#include <string.h>
int main(int argc, char **argv) {
    const int W = atoi(argv[2]), H = atoi(argv[3]);
    const int rps = (argc > 4) ? atoi(argv[4]) : H;   // rows per strip
    TIFF *t = TIFFOpen(argv[1], "w");
    TIFFSetField(t, TIFFTAG_IMAGEWIDTH, W);
    TIFFSetField(t, TIFFTAG_IMAGELENGTH, H);
    TIFFSetField(t, TIFFTAG_BITSPERSAMPLE, 12);
    TIFFSetField(t, TIFFTAG_SAMPLESPERPIXEL, 1);
    TIFFSetField(t, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_MINISBLACK);
    TIFFSetField(t, TIFFTAG_PLANARCONFIG, PLANARCONFIG_CONTIG);
    TIFFSetField(t, TIFFTAG_ROWSPERSTRIP, rps);
    TIFFSetField(t, TIFFTAG_FILLORDER, FILLORDER_MSB2LSB);
    size_t rowbytes = (W * 12 + 7) / 8;
    unsigned char *row = calloc(rowbytes, 1);
    for (int y = 0; y < H; y++) {
        memset(row, 0, rowbytes);
        for (int x = 0; x < W; x += 2) {
            unsigned v0 = (unsigned)((x) * 4095 / (W - 1));
            size_t b = (x / 2) * 3;
            if (x + 1 < W) {                       // full pair -> 3 bytes
                unsigned v1 = (unsigned)((x + 1) * 4095 / (W - 1));
                row[b]     = (v0 >> 4) & 0xff;
                row[b + 1] = ((v0 & 0x0f) << 4) | ((v1 >> 8) & 0x0f);
                row[b + 2] = v1 & 0xff;
            } else {                               // odd trailing sample -> 1.5 bytes
                row[b]     = (v0 >> 4) & 0xff;
                row[b + 1] = (v0 & 0x0f) << 4;     // low nibble is padding (0)
            }
        }
        TIFFWriteScanline(t, row, y, 0);
    }
    free(row);
    TIFFClose(t);
    return 0;
}
