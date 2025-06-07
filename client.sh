#!/bin/bash

# === Compress Client ===
echo "🔧 Compressing client..."
cd Client
zip -r "/mnt/c/Users/Julian/Desktop/beammp_Server/windows/Resources/Client/SumoGamemode.zip" art levels lua scripts ui settings vehicles LICENSE
cd ..

