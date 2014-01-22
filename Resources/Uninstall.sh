# hard uninstall via command line
sudo rm /Library/LaunchDaemons/BradJasper.focus.HelperTool.plist
sudo rm /Library/PrivilegedHelperTools/BradJasper.focus.HelperTool

sudo security -q authorizationdb remove "BradJasper.focus.focus"
sudo security -q authorizationdb remove "BradJasper.focus.unfocus"
sudo security -q authorizationdb remove "BradJasper.focus.uninstall"

sudo rm -rf '/Library/Managed Preferences/Focus'

sudo launchctl unload /Library/LaunchDaemons/BradJasper.focus.HelperTool.plist
