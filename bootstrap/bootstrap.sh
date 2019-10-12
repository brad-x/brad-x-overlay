#!/bin/bash

set -e

echo "Syncing initial portage tree... "
emerge-webrsync

echo "Installing git... "
USE="-perl -pcre -pcre-jit" emerge dev-vcs/git -v

echo "Deploying our own portage directory configurations... "
rm -rf /etc/portage/
mkdir -pv /etc/portage/repos.conf/
cd /etc/portage/
## Needed make.conf changes for BINHOST usage
curl -LO http://packages.brad-x.com/make.conf
cd /etc/portage/repos.conf/
## Override the gentoo portage tree - use ours as it's in sync with the BINHOSTS (theoretically)
curl -LO http://packages.brad-x.com/brad-x.conf
cd
emerge eselect-repository -v
eselect repository list
eselect repository add brad-x-overlay git git://github.com/brad-x/brad-x-overlay.git
emerge --sync

echo "Setting single locale... "
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "Setting desktop/gnome portage profile... "
eselect profile set brad-x-overlay:desktop/gnome
echo "Ready to go. "
