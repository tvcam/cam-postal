#!/usr/bin/env python3
"""
Build postal codes CSV from simple input data.
Automatically determines type and hierarchy from postal code pattern.
"""

import csv

# Province codes (ending in 0000)
PROVINCES = {
    "010000": ("ខេត្ត បន្ទាយមានជ័យ", "Banteay Meanchey Province"),
    "020000": ("ខេត្ត បាត់ដំបង", "Battambang Province"),
    "030000": ("ខេត្ត កំពង់ចាម", "Kampong Cham Province"),
    "040000": ("ខេត្ត កំពង់ឆ្នាំង", "Kampong Chhnang Province"),
    "050000": ("ខេត្ត កំពង់ស្ពឺ", "Kampong Speu Province"),
    "060000": ("ខេត្ org org org org org org", "Kampong Thom Province"),
    "070000": ("org org org org org org org", "Kampot Province"),
    "080000": ("org org org org org org org", "Kandal Province"),
    "090000": ("org org org org org org org", "Koh Kong Province"),
    "100000": ("org org org org org org org", "Kratie Province"),
    "110000": ("org org org org org org org", "Mondul Kiri Province"),
    "120000": ("org org org org org org org", "Phnom Penh Capital"),
    "130000": ("org org org org org org org", "Preah Vihear Province"),
    "140000": ("org org org org org org org", "Prey Veng Province"),
    "150000": ("org org org org org org org", "Pursat Province"),
    "160000": ("org org org org org org org", "Ratanak Kiri Province"),
    "170000": ("org org org org org org org", "Siem Reap Province"),
    "180000": ("org org org org org org org", "Sihanoukville Province"),
    "190000": ("org org org org org org org", "Stung Treng Province"),
    "200000": ("org org org org org org org", "Svay Rieng Province"),
    "210000": ("org org org org org org org", "Takeo Province"),
    "220000": ("org org org org org org org", "Oddar Meanchey Province"),
    "230000": ("org org org org org org org", "Kep Province"),
    "240000": ("org org org org org org org", "Pailin Province"),
    "250000": ("org org org org org org org", "Tboung Khmum Province"),
}

def get_type_and_hierarchy(postal_code):
    """Determine type and parent codes from postal code pattern."""
    code = postal_code.zfill(6)

    if code.endswith("0000"):
        return "province", code, ""
    elif code.endswith("00"):
        province_code = code[:2] + "0000"
        return "district", province_code, code
    else:
        province_code = code[:2] + "0000"
        district_code = code[:4] + "00"
        return "commune", province_code, district_code

def main():
    # Input data: (postal_code, name_km, name_en)
    # This will be populated from the PDF images
    data = []

    # Read from input file if exists
    try:
        with open("db/postal_data_input.txt", "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                parts = line.split("|")
                if len(parts) >= 2:
                    postal_code = parts[0].strip()
                    name_en = parts[1].strip()
                    name_km = parts[2].strip() if len(parts) > 2 else ""
                    data.append((postal_code, name_km, name_en))
    except FileNotFoundError:
        print("No input file found. Please create db/postal_data_input.txt")
        print("Format: postal_code|English Name|Khmer Name (optional)")
        return

    # Generate CSV
    output = []
    for postal_code, name_km, name_en in data:
        loc_type, province_code, district_code = get_type_and_hierarchy(postal_code)
        output.append({
            "postal_code": postal_code,
            "name_km": name_km,
            "name_en": name_en,
            "type": loc_type,
            "province_code": province_code,
            "district_code": district_code,
        })

    # Write CSV
    with open("db/postal_codes.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=[
            "postal_code", "name_km", "name_en", "type", "province_code", "district_code"
        ])
        writer.writeheader()
        writer.writerows(output)

    print(f"Generated {len(output)} entries")

if __name__ == "__main__":
    main()
