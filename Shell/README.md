# Disclaimer
All of the files provided here are provided as reference files.
Please check with your local administrator before running these scripts.

# Usage
These are shell scripts and can be executed as is. (You may need to set the script file as executable, before attempting to run it).

# How to remote execute bash scripts
Below is an explanation of running a script on a local machine on a remote machine (without transferring the file over).
*Any output files will be placed on the remote machine, and not copied to the local machine.

## Usage
```bash
ssh [username]@[ip] "bash -s" -- < [script] "[remote flag key]" "[remote flag value]" -[local flag key] [local flag value]
```
## Example
```bash
ssh serverA "bash -s" -- < ./ex.bash "-time" "bye" -time bye
```
```bash
ssh root@192.168.1.2 "bash -s" < ./PureLinuxBestPracticeCheckerv1.0.sh 

[Stack Exchange Link](https://unix.stackexchange.com/questions/87405/how-can-i-execute-local-script-on-remote-machine-and-include-arguments)
