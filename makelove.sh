#!/bin/sh
NAME="CHRxPNG"
SCRIPTPATH="$( cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 ; pwd -P )"
cd "$SCRIPTPATH/$NAME"
zip -9 -q -r --exclude=*.sh* ../$NAME.love .

# create Windows executable on macOS:
# cat love.exe SuperGame.love > SuperGame.exe