# Crowdstrikefix
Batch file for removing updated file / This will fix the software update issue for windows 
Instructions
Right-click the batch file and select "Run as administrator".
The script will automatically reboot the system into Safe Mode with Networking, perform the file deletion, and then reboot back into normal mode.
Note
The script assumes there is only one file that matches the pattern C-00000291*.sys.
The timeout /t 60 command waits for 60 seconds before executing the next set of commands to give the system time to reboot into Safe Mode. Adjust this value if necessary.
Ensure the host is connected to a wired network for Safe Mode with Networking to function properly.
