#!/bin/bash

# === Copy Server ===
echo "📁 Copying server..."
cd Server
rm -rf "/mnt/c/Users/Julian/Desktop/beammp_Server/windows/Resources/Server/Sumo"
cp -r Sumo "/mnt/c/Users/Julian/Desktop/beammp_Server/windows/Resources/Server/Sumo"
cd ..

