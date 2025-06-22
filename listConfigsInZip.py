#call this with something like: python3 listConfigsInZip.py /mnt/c/Users/Julian/Downloads/heavyclass.zip
import zipfile
import json
import os
import sys

def list_vehicle_configs(zip_path):
    zip_path = os.path.normpath(zip_path)
    with zipfile.ZipFile(zip_path, 'r') as z:
        results = []
        for f in z.namelist():
            if f.lower().endswith('.pc'):
                parts = f.replace('\\','/').split('/')
                if len(parts) >= 2:
                    folder = parts[-2]
                    filename = parts[-1]
                    results.append(f"vehicles/{folder}/{filename}")
        return results

def main():
    if len(sys.argv) != 2:
        print("Usage: python script.py <path_to_zip>")
        sys.exit(1)
    configs = list_vehicle_configs(sys.argv[1])
    print(json.dumps(configs))

if __name__ == "__main__":
    main()

