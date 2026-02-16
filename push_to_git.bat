@echo off
git add . > git_log.txt 2>&1
git commit -m "Restored checkout email, updated payment success layout, set status bar color to orange, and upgraded version to 1.2.2+14" >> git_log.txt 2>&1
git push origin main >> git_log.txt 2>&1
type git_log.txt
