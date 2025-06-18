import os
import zipfile
import shutil
from pathlib import Path

VEHICLE_ZIPS_FOLDER = Path(r"I:\SteamLibrary\steamapps\common\BeamNG.drive\content\vehicles")
DESTINATION_ROOT = Path(r"Client/vehicles")
TEMP_EXTRACT_FOLDER = Path("./temp_extract_pc_files")

def delete_all_pc_files(folder_to_clean: Path):
    print(f"Searching for .pc files to delete in {folder_to_clean}...")
    if not folder_to_clean.is_dir():
        print("Folder does not exist, nothing to delete.")
        return
    for pc_file in folder_to_clean.rglob("*.pc"):
        try:
            pc_file.unlink()
            print(f"Deleted {pc_file}")
        except OSError as e:
            print(f"Error deleting {pc_file}: {e}")

def copy_vehicle_configs():
    if not VEHICLE_ZIPS_FOLDER.is_dir():
        print(f"Error: Source folder not found: {VEHICLE_ZIPS_FOLDER}")
        return
    TEMP_EXTRACT_FOLDER.mkdir(exist_ok=True)
    print(f"Scanning for vehicle zips in: {VEHICLE_ZIPS_FOLDER}")
    for zip_path in VEHICLE_ZIPS_FOLDER.glob("*.zip"):
        vehicle_name = zip_path.stem  # .stem gets the filename without the extension.
        destination_folder = DESTINATION_ROOT / vehicle_name
        if not destination_folder.is_dir():
            print(f"Skipping {vehicle_name}: Destination folder does not exist.")
            continue
        print(f"Processing vehicle: {vehicle_name}")
        try:
            with zipfile.ZipFile(zip_path, 'r') as zip_file:
                for file_in_zip in zip_file.namelist():
                    expected_prefix = f"vehicles/{vehicle_name}/"
                    if file_in_zip.endswith(".pc") and file_in_zip.startswith(expected_prefix):
                        extracted_file_path = Path(zip_file.extract(file_in_zip, TEMP_EXTRACT_FOLDER))
                        relative_path = file_in_zip.replace(expected_prefix, "")
                        final_destination = destination_folder / relative_path
                        final_destination.parent.mkdir(parents=True, exist_ok=True)
                        shutil.move(str(extracted_file_path), str(final_destination))
                        print(f"  -> Copied {file_in_zip} to {final_destination}")
        except zipfile.BadZipFile:
            print(f"Warning: Corrupted zip file, skipping: {zip_path.name}")
    print("Cleaning up temporary files...")
    shutil.rmtree(TEMP_EXTRACT_FOLDER)

if __name__ == "__main__":
    # delete_all_pc_files(DESTINATION_ROOT)
    copy_vehicle_configs()
    print("\nScript finished.")
