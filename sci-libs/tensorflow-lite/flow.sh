#!/bin/bash

mv ~/Downloads/tensorflow-lite-9999.ebuild .
mv ~/Downloads/tensorflow-lite-2.21.0.ebuild .
sudo ebuild tensorflow-lite-2.21.0.ebuild digest
git add .
git commit -m 'fix'
git push
sudo emerge --sync brad-x-overlay
