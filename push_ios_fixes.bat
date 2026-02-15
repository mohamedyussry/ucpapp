@echo off
git add .
git commit -m "fix: Link Runner.entitlements to xcode project and set aps-environment to production for iOS push notifications"
git push origin main
echo Done.
