#!/bin/bash
echo $(date) >> log.txt
git add .
git commit -m "Action test"
git push origin main