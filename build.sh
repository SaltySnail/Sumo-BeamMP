#!/bin/bash

set -e  # Stop on error

# === Compress Client ===
#echo "🔧 Compressing client..."
#cd Client
#zip -r "/mnt/c/Users/Julian/Desktop/beammp_Server/windows/Resources/Client/SumoGamemode.zip" art levels lua scripts ui settings vehicles LICENSE
#cd ..
./client.sh

# === Copy Server ===
#echo "📁 Copying server..."
#cd Server
#rm -rf "/mnt/c/Users/Julian/Desktop/beammp_Server/windows/Resources/Server/Sumo"
#cp -r Sumo "/mnt/c/Users/Julian/Desktop/beammp_Server/windows/Resources/Server/Sumo"
#cd ..
./server.sh

# === Compress Release ===
#echo "📦 Compressing release..."
#cd export

# Clean previous outputs
#rm -rf Client BeamMP-Sumo.zip

# Prepare structure
#mkdir -p Client

# Copy zipped client archive into this Client folder
#cp ../Client/SumoGamemode.zip Client/

# Create final bundle
#zip -r BeamMP-Sumo.zip Client ../Server

#cd ..
echo "✅ All complete, King Julian!"
