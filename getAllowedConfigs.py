import zipfile
import json
from pathlib import Path

VEHICLES_SOURCE_DIR = Path(r"I:\SteamLibrary\steamapps\common\BeamNG.drive\content\vehicles")
OUTPUT_JSON_FILE = Path(r"Server/Sumo/Data/allowedConfigs.json")

def find_all_vehicle_configs(root_dir: Path):
    pc_file_paths = []
    if not root_dir.is_dir():
        print(f"Error: Source directory not found: {root_dir}")
        return pc_file_paths
    print(f"Scanning for .pc files in zips under {root_dir}...")
    for zip_path in root_dir.rglob('*.zip'):
        try:
            with zipfile.ZipFile(zip_path, 'r') as zip_file:
                for member_path in zip_file.namelist():
                    parts = member_path.split('/')
                    if len(parts) == 3 and parts[0] == 'vehicles' and parts[2].endswith('.pc'):
                        pc_file_paths.append(member_path)
                        # print(f"  -> Found config: {member_path} in {zip_path.name}")
        except zipfile.BadZipFile:
            print(f"Warning: Corrupted zip file, skipping: {zip_path.name}")
    return pc_file_paths

def save_configs_to_file(config_list: list, output_file: Path):
    output_file.parent.mkdir(parents=True, exist_ok=True)
    data_to_save = {"allowedConfigs": config_list}
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data_to_save, f, indent=2)
    print(f"\nSuccessfully saved {len(config_list)} allowed configs to: {output_file}")

def main():
    all_configs = find_all_vehicle_configs(VEHICLES_SOURCE_DIR)
    if all_configs:
        save_configs_to_file(all_configs, OUTPUT_JSON_FILE)
    else:
        print("No vehicle configs found.")
    print("Script finished.")

if __name__ == '__main__':
    main()
