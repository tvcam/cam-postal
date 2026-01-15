#!/bin/bash
# Convert PDF to images for OCR processing

PDF_FILE="db/prakas-postal-codes.pdf"
OUTPUT_DIR="db/pdf_images"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "Converting PDF to images..."
pdftoppm -png -r 300 "$PDF_FILE" "$OUTPUT_DIR/page"

echo "Done! Images saved to $OUTPUT_DIR"
ls -la "$OUTPUT_DIR" | head -20
echo "Total images: $(ls "$OUTPUT_DIR"/*.png 2>/dev/null | wc -l)"
