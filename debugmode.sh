#!/bin/bash

# Update MAX_ALIVE in Sumo.lua
sed -i 's/MAX_ALIVE = 1/MAX_ALIVE = 0/' /mnt/c/Users/Julian/Desktop/beammp_Server/windows/Resources/Server/Sumo/Sumo.lua

# Update playersNeededForGame in settings.json
sed -i 's/"playersNeededForGame": *2/"playersNeededForGame": 1/' /mnt/c/Users/Julian/Desktop/beammp_Server/windows/Resources/Server/Sumo/Data/settings.json

