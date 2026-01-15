#!/usr/bin/env python3
"""
OCR postal code images and extract to CSV
Requires: tesseract-ocr tesseract-ocr-khm tesseract-ocr-eng
Install: sudo apt-get install tesseract-ocr tesseract-ocr-khm tesseract-ocr-eng
         pip3 install pytesseract pillow

Data is hierarchical:
- Province (code ends 0000) e.g., 010000
- District (code ends 00) e.g., 010100 - belongs to province above
- Commune (6 digits) e.g., 010101 - belongs to district above
"""

import os
import re
import csv
import subprocess
from pathlib import Path

# Paths
IMAGES_DIR = Path("db/pdf_images")
OUTPUT_CSV = Path("db/postal_codes.csv")
RAW_TEXT_DIR = Path("db/ocr_raw")

# Track current hierarchy context
current_province = None
current_province_km = None
current_province_en = None
current_district = None
current_district_km = None
current_district_en = None

def ocr_image(image_path):
    """Run tesseract OCR on an image with Khmer+English"""
    try:
        result = subprocess.run(
            ["tesseract", str(image_path), "stdout", "-l", "khm+eng", "--psm", "6"],
            capture_output=True,
            text=True,
            timeout=120
        )
        return result.stdout
    except Exception as e:
        print(f"Error OCR {image_path}: {e}")
        return ""

def parse_line(line):
    """
    Parse a single line to extract postal code entry.
    Returns dict with code info or None if not a valid entry.

    Expected format variations:
    - "1 010000 បន្ទាយមានជ័យ Banteay Meanchey 010000"
    - "010000 បន្ទាយមានជ័យ Banteay Meanchey 010000"
    """
    line = line.strip()
    if not line or len(line) < 10:
        return None

    # Pattern: optional row number, 6-digit code, Khmer text, English text, postal code
    # The code appears twice - once as location code, once as postal code
    patterns = [
        # With row number: "1 010000 ..."
        r'^\d+\s+(\d{6})\s+(.+?)\s+([A-Za-z][A-Za-z\s\-\'\.]+?)\s+(\d{6})\s*$',
        # Without row number: "010000 ..."
        r'^(\d{6})\s+(.+?)\s+([A-Za-z][A-Za-z\s\-\'\.]+?)\s+(\d{6})\s*$',
        # Flexible: find two 6-digit codes with text between
        r'(\d{6})\s+(.+?)\s+([A-Za-z][A-Za-z\s\-\'\.]+?)\s+(\d{6})',
    ]

    for pattern in patterns:
        match = re.search(pattern, line)
        if match:
            code = match.group(1)
            name_km = match.group(2).strip()
            name_en = match.group(3).strip()
            postal = match.group(4)

            # Clean up Khmer name (remove any leading numbers/spaces)
            name_km = re.sub(r'^[\d\s]+', '', name_km).strip()

            return {
                'code': code,
                'name_km': name_km,
                'name_en': name_en,
                'postal_code': postal
            }

    return None

def process_entry(entry):
    """
    Process an entry and determine its type based on code pattern.
    Updates global hierarchy tracking and returns full entry dict.
    """
    global current_province, current_province_km, current_province_en
    global current_district, current_district_km, current_district_en

    code = entry['code']

    # Determine type based on code pattern
    if code.endswith('0000'):
        # Province
        loc_type = 'province'
        current_province = code
        current_province_km = entry['name_km']
        current_province_en = entry['name_en']
        current_district = None  # Reset district when new province
        current_district_km = None
        current_district_en = None
        province_code = code
        district_code = ''

    elif code.endswith('00') and not code.endswith('0000'):
        # District - belongs to current province
        loc_type = 'district'
        current_district = code
        current_district_km = entry['name_km']
        current_district_en = entry['name_en']
        province_code = current_province or code[:2] + '0000'
        district_code = code

    else:
        # Commune - belongs to current district and province
        loc_type = 'commune'
        province_code = current_province or code[:2] + '0000'
        district_code = current_district or code[:4] + '00'

    return {
        'postal_code': entry['postal_code'],
        'name_km': entry['name_km'],
        'name_en': entry['name_en'],
        'type': loc_type,
        'province_code': province_code,
        'district_code': district_code,
        'province_name_km': current_province_km or '',
        'province_name_en': current_province_en or '',
        'district_name_km': current_district_km or '' if loc_type == 'commune' else '',
        'district_name_en': current_district_en or '' if loc_type == 'commune' else '',
    }

def main():
    global current_province, current_district
    global current_province_km, current_province_en
    global current_district_km, current_district_en

    # Reset hierarchy tracking
    current_province = None
    current_province_km = None
    current_province_en = None
    current_district = None
    current_district_km = None
    current_district_en = None

    # Create raw text output dir
    RAW_TEXT_DIR.mkdir(exist_ok=True)

    # Get all images sorted (important for hierarchy tracking!)
    images = sorted(IMAGES_DIR.glob("*.png"))
    print(f"Found {len(images)} images to process")

    all_entries = []
    stats = {'province': 0, 'district': 0, 'commune': 0}

    for i, img_path in enumerate(images, 1):
        print(f"Processing {i}/{len(images)}: {img_path.name}")

        # OCR the image
        text = ocr_image(img_path)

        # Save raw text for debugging
        raw_file = RAW_TEXT_DIR / f"{img_path.stem}.txt"
        raw_file.write_text(text, encoding='utf-8')

        # Process each line maintaining order (crucial for hierarchy)
        page_entries = 0
        for line in text.split('\n'):
            parsed = parse_line(line)
            if parsed:
                entry = process_entry(parsed)
                all_entries.append(entry)
                stats[entry['type']] += 1
                page_entries += 1

        print(f"  Found {page_entries} entries (Province: {current_province_en or 'N/A'})")

    # Remove duplicates by postal_code, keeping first occurrence (preserves hierarchy order)
    seen = set()
    unique_entries = []
    for entry in all_entries:
        key = entry['postal_code']
        if key not in seen:
            seen.add(key)
            unique_entries.append(entry)

    # Write CSV
    print(f"\n=== Summary ===")
    print(f"Provinces: {stats['province']}")
    print(f"Districts: {stats['district']}")
    print(f"Communes: {stats['commune']}")
    print(f"Total unique entries: {len(unique_entries)}")

    print(f"\nWriting to {OUTPUT_CSV}")
    with open(OUTPUT_CSV, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'postal_code', 'name_km', 'name_en', 'type',
            'province_code', 'district_code',
            'province_name_km', 'province_name_en',
            'district_name_km', 'district_name_en'
        ])
        writer.writeheader()
        writer.writerows(unique_entries)

    print("Done!")

if __name__ == "__main__":
    main()
