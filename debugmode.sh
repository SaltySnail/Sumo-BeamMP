#!/bin/bash

# Fix line endings (optional if already correct)
dos2unix /mnt/c/Users/Julian/Desktop/beammp_Server/windows/Resources/Server/Sumo/Sumo.lua
dos2unix /mnt/c/Users/Julian/Desktop/beammp_Server/windows/Resources/Server/Sumo/Data/settings.json

# Patch Sumo.lua
sed -i 's/MAX_ALIVE = 1/MAX_ALIVE = 0/' /mnt/c/Users/Julian/Desktop/beammp_Server/windows/Resources/Server/Sumo/Sumo.lua

# Patch settings.json
sed -i 's/"playersNeededForGame": *2/"playersNeededForGame": 1/' /mnt/c/Users/Julian/Desktop/beammp_Server/windows/Resources/Server/Sumo/Data/settings.json

