#!/usr/bin/env python3
"""
Process the valid Khmer names from postal_data_with_khmer.txt
and create khmer_names.txt for use with add_khmer_names.py
"""

def extract_valid_khmer_names():
    """Extract Khmer names from the valid portion of postal_data_with_khmer.txt"""
    valid_entries = []

    with open('db/postal_data_with_khmer.txt', 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue

            parts = line.split('|')
            if len(parts) >= 3:
                postal_code = parts[0].strip()
                khmer_name = parts[2].strip()

                # Check if the Khmer name is valid (not corrupted)
                if 'org' not in khmer_name and khmer_name:
                    valid_entries.append((postal_code, khmer_name))

    return valid_entries

def write_khmer_names(entries):
    """Write khmer_names.txt"""
    with open('db/khmer_names.txt', 'w', encoding='utf-8') as f:
        f.write("# Khmer names for Cambodia postal codes\n")
        f.write("# Format: postal_code|Khmer Name\n\n")

        for postal_code, khmer_name in entries:
            f.write(f"{postal_code}|{khmer_name}\n")

    print(f"Written {len(entries)} Khmer names to db/khmer_names.txt")

def main():
    entries = extract_valid_khmer_names()
    print(f"Found {len(entries)} valid Khmer name entries")
    write_khmer_names(entries)

if __name__ == '__main__':
    main()
