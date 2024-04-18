#heads up, I didn't feel like coding this so I made copilot my bitch and do it. Prepare for unnessacery imports ^^

import os
import zipfile
import re #regular expressions
import json

import shutil #maybe these are not needed if I only use os...
import glob

import copy #fuck python. Why does it not deep copy by default when doing variable1 = variable2, that is so messed up

BEAMMP_CLIENT_FOLDER = "C:/Users/Julian/Desktop/beammp_Server/windows/Resources/Client"
BEAMNG_LEVELS_FOLDER = "I:/SteamLibrary/steamapps/common/BeamNG.drive/content/levels"
MATERIALS_TO_PUT_IN_EVERY_LEVEL = "materialsToCopy"

level_name_pattern = "levels/([^/.]+)/info.json"

def levelsInZips(dir): 
    level_list = set()
    files_in_directory = os.listdir(dir)
    zip_files = [file for file in files_in_directory if file.endswith('.zip')]
    for zip_file in zip_files:
        full_file_path = os.path.join(dir, zip_file)
        with zipfile.ZipFile(full_file_path, 'r') as zip_ref:
            all_files = zip_ref.namelist()
            for s in all_files:
                match = re.search(level_name_pattern, s)
                if match:
                    level_list.add(match.group(1))
    return level_list

def appendMaterials(dir):
    files_in_directory = list_files(MATERIALS_TO_PUT_IN_EVERY_LEVEL)
    json_files = [file for file in files_in_directory if file.endswith('.json')]
    for json_file in json_files: 
        try:
            with open(MATERIALS_TO_PUT_IN_EVERY_LEVEL + "/" + json_file, 'r') as f:
                json_data_to_append = json.load(f)
                files_in_directory = os.listdir(dir)
                zip_files = [file for file in files_in_directory if file.endswith('.zip')]
                for zip_file in zip_files:
                    # for level in levelsInZips(dir):
                    full_file_path = os.path.join(dir, zip_file)
                    try:
                        with zipfile.ZipFile(full_file_path, 'r') as f:
                            all_files = f.namelist()
                            for s in all_files:
                                match = re.search(level_name_pattern, s)
                                if match:
                                    try:
                                        json_path = os.path.dirname(json_file)
                                        level = match.group()
                                        # print(match)
                                        level = level.replace("levels/", "")
                                        level = level.replace("/info.json", "")
                                        json_path = json_path.replace('\\', "/")
                                        # print(full_file_path + '\t\t\tlevels/' + level + '/' + json_path + "/" + 'main.materials.json')    
                                        # try:
                                        with f.open('levels/' + level + '/' + json_path + "/" + 'main.materials.json') as sf:
                                            original_json_data = json.load(sf)
                                            for key, value in original_json_data.items():
                                                json_data_to_append[key] = value #original is now new
                                        # except Exception as e:
                                        #     print("An error occurred:", e)
                                    except KeyError:
                                        match = False
                                    try:
                                        json_path = os.path.dirname(json_file)
                                        json_path = json_path.replace('\\', "/")
                                        os.makedirs('Client/levels/' + level + "/" + json_path, exist_ok=True)
                                        with open('Client/levels/' + level + "/" + json_file, 'w') as output_file:
                                            json_data_to_append_final = copy.deepcopy(json_data_to_append) #I wonder why the creator of python decided it was better to reference by default
                                            replace_nested_json(json_data_to_append_final, level, json_path)
                                            json.dump(json_data_to_append_final, output_file, indent=2)
                                    except FileNotFoundError:
                                        print("no client file " + 'Client/levels/' + level + json_file)
                                    copyMaterialFiles(MATERIALS_TO_PUT_IN_EVERY_LEVEL + "/" + json_path, 'Client/levels/' + level + "/" + json_path) 
                    except FileNotFoundError:
                        print("no original file " + full_file_path)
        except FileNotFoundError:
            print("file to append doesn't exist somehow " + MATERIALS_TO_PUT_IN_EVERY_LEVEL + "/" + json_file)

def copyMaterialFiles(fromDir, toDir):
    # find and copy .dds and .png files
    for file_type in ['*.dds', '*.png']:
        for file_name in glob.glob(fromDir + '/' + file_type):
            shutil.copy(file_name, toDir)

def list_files(path):
    file_paths = []
    for root, dirs, files in os.walk(path):
        for name in files:
            relative_path = os.path.relpath(os.path.join(root, name), path)
            file_paths.append(relative_path)
    return file_paths

def replace_nested_json(json_data, level, json_path):
    for key, value in json_data.items():
        if isinstance(value, str):
            if "/REPLACE_ME/" in value:
                new_value = value.replace("/REPLACE_ME/", 'levels/' + level + "/" + json_path + "/")
                json_data[key] = new_value
        elif isinstance(value, dict):
            replace_nested_json(value, level, json_path)
        elif isinstance(value, list):
            for item in value:
                if isinstance(item, dict):
                    replace_nested_json(item, level, json_path)

appendMaterials(BEAMMP_CLIENT_FOLDER)
appendMaterials(BEAMNG_LEVELS_FOLDER)
