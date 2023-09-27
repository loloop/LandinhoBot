#!/bin/bash

git fetch
git pull origin main
swift build
sudo systemctl restart landinho.service
