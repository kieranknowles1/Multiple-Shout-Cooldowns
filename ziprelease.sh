#!/usr/bin/env bash
set -euo pipefail

MODNAME=MultipleShoutCooldowns

if [[ -f "$MODNAME.zip" ]]; then
    rm "$MODNAME.zip"
fi

zip -r $MODNAME.zip \
    Interface \
    MCM \
    Scripts \
    Source \
    $MODNAME.esp \
    readme.md
