# SyncFolders

SyncFolders.ps1 is a simple PowerShell script that was created to synchronize the contents of two folders: a source and a replica folder. It maintains an identical copy of the source at the replica folder. The synchronization is one-way, meaning that the content of the replica folder is modified to exactly match the content of the source folder.
## Usage
```
Options:
  -sourceFolder       Specifies the path to the source folder.
  -replicaFolder      Specifies the path to the replica folder.
  -logFilePath        Specifies the path to the log file. Default is '$env:TEMP\LogFile.txt'.
  -stopScript         Stops the running SyncFolders.ps1 script.
  -interval           Specifies the time interval (in minutes) for script execution. If not provided, the script will run only once.
  -help               Displays this help message.

Examples:
./SyncFolders.ps1 -sourceFolder <source folder path> -replicaFolder <replica folder path> -logFilePath <log file path>
./SyncFolders.ps1 -stopScript
```
