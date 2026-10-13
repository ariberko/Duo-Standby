#!/bin/sh
# Copies the shared code into the iPad Swift Playgrounds preview app.
# Playgrounds can't read files outside its own folder, so it keeps a copy.
set -e
cd "$(dirname "$0")/.."
rm -rf StandByStudio.swiftpm/Shared
cp -R Shared StandByStudio.swiftpm/Shared
echo "Synced Shared/ into StandByStudio.swiftpm/Shared"
