import os
import zipfile
import json
from pathlib import Path

def collect_pc_paths(root_dir):
    """
    Traverse all .zip files under root_dir, collect .pc file paths inside zips
    following the pattern vehicles/<vehicle>/<config>.pc
    """
    pc_paths = []

    # Walk through directory tree
    for dirpath, _, filenames in os.walk(root_dir):
        for fname in filenames:
            if fname.lower().endswith('.zip'):
                zip_path = Path(dirpath) / fname
                try:
                    with zipfile.ZipFile(zip_path, 'r') as zf:
                        for member in zf.namelist():
                            # Normalize forward slashes
                            parts = member.split('/')
                            if len(parts) == 3 and parts[0] == 'vehicles' and parts[2].endswith('.pc'):
                                # Store the path within the zip
                                pc_paths.append(member)
                except zipfile.BadZipFile:
                    print(f"Warning: Failed to read zip file: {zip_path}")
    return pc_paths


def save_allowed_configs(pc_paths, output_file):
    """
    Save the list of PC paths to a JSON file under Server/Data
    """
    output_path = Path(output_file)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    data = {"allowedConfigs": pc_paths}
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)
    print(f"Saved allowed configs ({len(pc_paths)}) to {output_path}")


if __name__ == '__main__':
    # Change these paths as needed
    steam_vehicles_dir = Path(r"I:/SteamLibrary/steamapps/common/BeamNG.drive/content/vehicles")
    output_json = Path(r"Server/Sumo/Data/allowedConfigs.json")

    print("Collecting .pc paths from zip files...")
    paths = collect_pc_paths(steam_vehicles_dir)
    save_allowed_configs(paths, output_json)
