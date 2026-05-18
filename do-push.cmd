@echo off
cd /d "%~dp0"
git add -A >> push-log.txt 2>&1
git status --short >> push-log.txt 2>&1
git commit -m "Release 2.0.1: IKFRVP physics-only package" -m "Remove bundled Project Faded Car. Bridge API unchanged." >> push-log.txt 2>&1
git push origin main >> push-log.txt 2>&1
git tag -d v2.0.1 >> push-log.txt 2>&1
git push origin :refs/tags/v2.0.1 >> push-log.txt 2>&1
git tag -a v2.0.1 -m "2.0.1 - Physics-only; PFC separate mod" >> push-log.txt 2>&1
git push origin v2.0.1 >> push-log.txt 2>&1
git log -1 --oneline >> push-log.txt 2>&1
