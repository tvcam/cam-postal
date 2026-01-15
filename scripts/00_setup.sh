#!/bin/bash
# Setup OCR dependencies for Khmer postal code extraction

echo "Installing Tesseract OCR with Khmer support..."
sudo apt-get update
sudo apt-get install -y tesseract-ocr tesseract-ocr-khm tesseract-ocr-eng

echo ""
echo "Installing Python dependencies..."
pip3 install pytesseract pillow

echo ""
echo "Verifying installation..."
tesseract --version
tesseract --list-langs | grep -E "(khm|eng)"

echo ""
echo "Setup complete! Now run:"
echo "  1. ./scripts/01_pdf_to_images.sh"
echo "  2. python3 scripts/02_ocr_to_csv.py"
