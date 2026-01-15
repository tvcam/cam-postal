#!/usr/bin/env python3
"""
Add Khmer names to postal codes CSV.
Reads khmer_names.txt and merges with existing postal_data_input.txt
"""

import csv

# Khmer names mapping: postal_code -> khmer_name
# This will be populated from the PDF images
KHMER_NAMES = {}

def load_khmer_names(filename):
    """Load Khmer names from a simple text file."""
    names = {}
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                parts = line.split('|')
                if len(parts) >= 2:
                    postal_code = parts[0].strip()
                    khmer_name = parts[1].strip()
                    names[postal_code] = khmer_name
    except FileNotFoundError:
        print(f"File {filename} not found")
    return names

def main():
    # Load existing data
    data = []
    with open('db/postal_data_input.txt', 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = line.split('|')
            if len(parts) >= 2:
                postal_code = parts[0].strip()
                name_en = parts[1].strip()
                data.append((postal_code, name_en))

    # Load Khmer names
    khmer_names = load_khmer_names('db/khmer_names.txt')

    # Determine type and hierarchy
    def get_type_and_hierarchy(postal_code):
        code = postal_code.zfill(6)
        if code.endswith('0000'):
            return 'province', code, ''
        elif code.endswith('00'):
            province_code = code[:2] + '0000'
            return 'district', province_code, code
        else:
            province_code = code[:2] + '0000'
            district_code = code[:4] + '00'
            return 'commune', province_code, district_code

    # Generate output
    output = []
    for postal_code, name_en in data:
        loc_type, province_code, district_code = get_type_and_hierarchy(postal_code)
        name_km = khmer_names.get(postal_code, '')
        output.append({
            'postal_code': postal_code,
            'name_km': name_km,
            'name_en': name_en,
            'type': loc_type,
            'province_code': province_code,
            'district_code': district_code,
        })

    # Write CSV
    with open('db/postal_codes.csv', 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'postal_code', 'name_km', 'name_en', 'type', 'province_code', 'district_code'
        ])
        writer.writeheader()
        writer.writerows(output)

    # Stats
    with_khmer = sum(1 for row in output if row['name_km'])
    print(f"Generated {len(output)} entries")
    print(f"  With Khmer names: {with_khmer}")
    print(f"  Without Khmer names: {len(output) - with_khmer}")

if __name__ == '__main__':
    main()
