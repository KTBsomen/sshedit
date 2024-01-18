# sshedit
so this code is a connector to your sshserver with .pem file(you can change the code for passwords )
basically it copy the whole file structure in your local mechine with current date so version controll and backup is automagically done
and then runs a watcher for file changes as you change your files it will updated on the server realtime
# steps to run 
`sudo ./ssheditV2.sh`

it will install some programm if not found,

then it will ask for host of the ssh connection in a GUI window like 3.23.253.5,

then it will ask for the hostname like ubuntu,

then it will ask for the .pem file it will open a file chooser to select ,

then it will ask for the file path to connect to like /home/ubuntu/,

then it will ask for short code of your code editor like code (for vs code) subl (for sublime text)
# for window 
open powershell in administretive mode and run `Set-ExecutionPolicy Unrestricted `
next steps are same but in windows the host and other properties must be provided through cmd

