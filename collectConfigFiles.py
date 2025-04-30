import os
import zipfile
import shutil

# Paths
source_folder = r"I:\SteamLibrary\steamapps\common\BeamNG.drive\content\vehicles"
destination_base = r"Client/vehicles"

def delete_pc_files(base_folder):
    """Delete all .pc files in the specified folder and its subdirectories."""
    for root, _, files in os.walk(base_folder):
        for file in files:
            if file.endswith(".pc"):
                file_path = os.path.join(root, file)
                os.remove(file_path)
                print(f"Deleted {file_path}")

# # Example usage of the delete_pc_files function
# delete_pc_files(r"Client/vehicles")

# Iterate through all zip files in the source folder
for zip_filename in os.listdir(source_folder):
    if zip_filename.endswith(".zip"):
        zip_path = os.path.join(source_folder, zip_filename)
        vehicle_name = os.path.splitext(zip_filename)[0]
        destination_folder = os.path.join(destination_base, vehicle_name)

        # Check if the destination folder exists
        if os.path.exists(destination_folder):
            with zipfile.ZipFile(zip_path, 'r') as zip_file:
                # Iterate through files in the zip
                for file in zip_file.namelist():
                    if file.endswith(".pc") and file.startswith(f"vehicles/{vehicle_name}/"):
                        # Extract the .pc file to a temporary location
                        temp_path = zip_file.extract(file, "/tmp")
                        # Construct the destination path
                        relative_path = os.path.relpath(file, f"vehicles/{vehicle_name}/")
                        final_destination = os.path.join(destination_folder, relative_path)
                        # Ensure the destination directory exists
                        os.makedirs(os.path.dirname(final_destination), exist_ok=True)
                        # Move the file to the destination
                        shutil.move(temp_path, final_destination)
                        print(f"Copied {file} to {final_destination}")
        else:
            print(f"Destination folder does not exist for vehicle: {vehicle_name}")
