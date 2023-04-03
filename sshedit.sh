#!/bin/sh
sudo apt install inotify-tools
clear
echo "ssh edit code locally by somen6562@gmail.com(webnima.in)"

#read -p 'Host Ip: ' host
#read -p 'Username: ' user
#read -p 'name of keyfile with_full_path: ' key
#read -p 'path of remote dir [with / at ending]: ' dir
host=$(zenity --entry --width 500 --title "Host Ip" --text "Enter the Host Ip")
user=$(zenity --entry --width 500 --title "Host Username" --text "Enter the username to connect")
key=$(zenity --file-selection --title "Select Key file( *.pem )" --file-filter="*.pem")
dir=$(zenity --entry --width 500 --title "Remote Directory" --text "Enter the path of remote directory with / at the ending")

if [ ! -d "$host" ]; then

mkdir $host
  echo "$host directory is created and entering into it"
 cd $host
else
newfile=$host"_"$(date "+%Y.%m.%d-%H.%M.%S")
mkdir $newfile
    echo "$newfile directory is created and entering into it"
cd $newfile
fi
echo "copying files from remote this might take time if this taking too much of time to output anything then close the programm something is wrong "

sudo scp -i $key -r $hostname@$host:$dir* .
sudo zip "../Backup_File_of_$(pwd)"$(date "+%Y.%m.%d-%H.%M.%S").zip -r .
clear
#read -p 'Type the sortcut command of the editor to open this directory :' 
editor=$(zenity --entry --width 500 --title "favourite Editor" --text "Enter the command to open your fevourite text editor (without . )")

sudo $editor . &
targetDir="."
inotifywait -mr $targetDir -e create -e moved_to -e modify --exclude '/\..+'|
    while read path action file; do
                 
                 echo "$path It's a change there in  $file so updating to server"
                 result=$(echo $path | sed "s@./@@")
                 sudo scp -i $key $path$file $hostname@$host:$dir$result
                 




        # do something with the file
    done




