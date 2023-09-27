#!/bin/bash

git fetch
git pull origin main
cd telegram
swift build
sudo systemctl restart landinho.service
cd ..
cd backend
docker compose up -d