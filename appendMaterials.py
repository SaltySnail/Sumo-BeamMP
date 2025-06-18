import os
import zipfile
import re
import json
import shutil
import copy #f python. Why does it not deep copy by default when doing variable1 = variable2, that is so messed up
from pathlib import Path

BEAMMP_CLIENT_FOLDER = Path("C:/Users/Julian/Desktop/beammp_Server/windows/Resources/Client")
BEAMNG_LEVELS_FOLDER = Path("I:/SteamLibrary/steamapps/common/BeamNG.drive/content/levels")
# BEAMNG_MODS_FOLDER = Path("C:/Users/Julian/AppData/Local/BeamNG.drive/0.32/mods") #only for if anyone else needs this
MATERIALS_TO_PUT_IN_EVERY_LEVEL = Path("materialsToCopy")
OUTPUT_FOLDER = Path("Client")

LEVEL_NAME_PATTERN = re.compile(r"levels/([^/.]+)/info.json")


def get_source_materials(source_dir: Path):
    materials = {}
    if not source_dir.is_dir():
        print(f"Error: Source directory '{source_dir}' does not exist.")
        return materials
    # rglob recursively searches all subdirectories
    for path in source_dir.rglob('*.json'):
        with open(path, 'r', encoding='utf-8') as f:
            try:
                relative_path = path.relative_to(source_dir)
                materials[relative_path] = json.load(f)
            except json.JSONDecodeError:
                print(f"Warning: Malformed JSON file ignored: {path}")
    return materials

def replace_placeholders(data, level_name):
    if isinstance(data, dict):
        for key, value in data.items():
            if isinstance(value, str):
                data[key] = value.replace("/REPLACE_ME/", "/art/SumoMaterials/")
            else:
                replace_placeholders(value, level_name)
    elif isinstance(data, list):
        for i, item in enumerate(data):
            if isinstance(item, str):
                data[i] = item.replace("/REPLACE_ME/", "/art/SumoMaterials/")
            else:
                replace_placeholders(item, level_name)

def process_zip_file(zip_path: Path, source_materials: dict):
    try:
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            all_files_in_zip = zip_ref.namelist()
            for file_in_zip in all_files_in_zip:
                match = LEVEL_NAME_PATTERN.search(file_in_zip)
                if not match:
                    continue
                level_name = match.group(1)
                for rel_path, original_material_data in source_materials.items():
                    final_data = copy.deepcopy(original_material_data)
                    relative_dir = rel_path.parent
                    path_to_merge_in_zip = f'levels/{level_name}/{relative_dir}/main.materials.json'
                    try:
                        with zip_ref.open(path_to_merge_in_zip, 'r') as f_merge:
                            data_to_merge = json.load(f_merge)
                            final_data.update(data_to_merge)
                    except (KeyError, json.JSONDecodeError):
                        pass
                    replace_placeholders(final_data, level_name)
                    output_path = OUTPUT_FOLDER / 'levels' / level_name / rel_path
                    output_path.parent.mkdir(parents=True, exist_ok=True)
                    with open(output_path, 'w', encoding='utf-8') as f_out:
                        json.dump(final_data, f_out, indent=2)
    except FileNotFoundError:
        print(f"Error: Zip file not found: {zip_path}")
    except zipfile.BadZipFile:
        print(f"Error: Corrupted zip file: {zip_path}")

def main():
    source_materials = get_source_materials(MATERIALS_TO_PUT_IN_EVERY_LEVEL)
    if not source_materials:
        print("No source materials found. Stopping the script.")
        return
    directories_to_scan = [BEAMMP_CLIENT_FOLDER, BEAMNG_LEVELS_FOLDER]
    # directories_to_scan.append(BEAMNG_MODS_FOLDER)
    for directory in directories_to_scan:
        if not directory.is_dir():
            print(f"Warning: Directory '{directory}' does not exist, skipping.")
            continue
        print(f"\n--- Processing directory: {directory} ---")
        zip_files = list(directory.glob('*.zip'))
        if not zip_files:
            print("No .zip files found in this directory.")
            continue
        for zip_path in zip_files:
            print(f"Analyzing: {zip_path.name}")
            process_zip_file(zip_path, source_materials)
    print("\nScript finished.")

if __name__ == "__main__":
    main()
