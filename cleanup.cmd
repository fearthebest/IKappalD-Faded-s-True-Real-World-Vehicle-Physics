@echo off
cd /d "C:\Users\mpass\Documents\GitHub\IKAPPA~2"
if exist do-push.cmd git rm -f do-push.cmd
if exist push-log.txt git rm -f push-log.txt
if exist gh-release.cmd git rm -f gh-release.cmd
if exist push-log2.txt git rm -f push-log2.txt
git rm -f cleanup.cmd 2>nul
git status --short
git commit -m "chore: remove local push helper scripts"
git push origin main
