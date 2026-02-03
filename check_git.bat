@echo off
git status > git_log.txt 2>&1
git branch >> git_log.txt 2>&1
git remote -v >> git_log.txt 2>&1
