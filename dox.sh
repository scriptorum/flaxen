#!/bin/bash

set -e

echo === Creating XML ===
haxe dox.hxml

# OpenFL 3.x with Haxe 3.1x generates improperly escaped characters \" and \&
# This fixes the problem in the intermediate documentation file.
echo === Fixing XML ===
sed -i "" -e 's/\\\"/\&quot;/g' -e 's/\\\&/\&amp;/g' dox.xml

echo === Creating documentation ===
mkdir -p export
haxelib run dox -o export/dox -i dox.xml --title "Flaxen API `date +"%d-%b-%y"`" -D source-path "https://github.com/scriptorum/flaxen/blob/master/source/" -in flaxen

echo === Removing leftovers ===
rm dox.xml
rm dox.swf

echo === Opening HTML ===
open export/dox/flaxen/Flaxen.html