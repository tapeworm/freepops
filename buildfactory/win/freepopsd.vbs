'FreePOPS & Mail v. 1.5 28/10/2005
'Modified by Rojous to add parameters for updater & log clearing

Option Explicit

Function WriteFile(oFS,mailClientPath,mailProcessName)
  Dim oFSFile
  Set oFSFile = oFS.OpenTextFile(FileName,2,True) 
  oFSFile.Write(100 & VbCrLf & MailClientPath &  VbCrLf & MailProcessName) 
  oFSFile.Close 
End Function

Function ReadFile(oFS,ByRef delay, ByRef mailClientPath,ByRef mailProcessName,ByRef mailClientCla) 
  Dim oFile, oStream
  Set oFile = oFS.GetFile(fileName) 
  Set oStream = oFile.OpenAsTextStream(1,-2)
  delay = CInt(oStream.ReadLine)
  mailClientPath = oStream.ReadLine
  mailProcessName = oStream.ReadLine
  If Not oStream.AtEndOfStream Then
    mailClientCla = oStream.ReadLine
  Else
    mailClientCla = VbCrLf
  End If
  oStream.Close
End Function

Function GetDefaultMailClientPath(sh)
  Dim key,temp,splitted
  key = "HKCR\mailto\shell\open\command\"
  temp = sh.RegRead (key)
  splitted = Split(temp,"""")
  'Debug Istr
  'wScript.echo "MailClientPath = " & Sh.RegRead (key)
  If UBound(splitted) > 0 Then  
    GetDefaultMailClientPath = splitted(1)
  Else
    splitted = Split(temp," ")
    GetDefaultMailClientPath = splitted(0)
    'wScript.echo "MailClientPath = " & splitted(0)
  End If
End Function

Function GetProcessName(mailClientPath)
  Dim arr
  arr = Split(mailClientPath, "\")
  GetProcessName = arr(UBound(arr))
End Function

Function GetIstances (nome,objWMIService)
  Dim colProcess
  Set colProcess = objWMIService.ExecQuery( "Select * from Win32_Process Where Name='" & nome & "'")
  Set GetIstances = colProcess
End Function

Function IsActive (nome,objWMIService)
  Dim objProcess
  For Each objProcess in GetIstances (nome,objWMIService)
     IsActive = True
     Exit Function
  Next
  IsActive = False
End Function

Function TerminateSingleIstance (nome,objWMIService)
  Dim colProcess,objProcess
  Set colProcess = GetIstances(nome, objWMIService)
  For Each objProcess in colProcess
     objProcess.Terminate
     Exit Function
  Next
End Function

'==Modification for a function which deletes the log files
Function DeleteLogs (oFS)
  If oFS.FileExists("log.txt") = True Then
    oFS.DeleteFile("log.txt")
  End If
  If oFS.FileExists("stderr.txt") = True Then
    oFS.DeleteFile("stderr.txt")
  End If
  If oFS.FileExists("stdout.txt") = True Then
    oFS.DeleteFile("stdout.txt")
  End If
End Function
'==End of modification

'==Modification for a function which retrieves FreePOP's path

Function GetFreePOPsPath(sh)
  Dim key,temp
  key = "HKLM\Software\NSIS_FreePOPs\Install_Dir"
  temp = sh.RegRead (key)
  GetFreePOPsPath = temp & "\"
End Function

'==End of modification

Const fileName = "fpm.ini"
Dim sh, objWMIService,active,delay,mailClientPath,mailProcessName,mailClientCla,cla,arg,i,oFs,FPUpdate
Set sh=wScript.CreateObject("wScript.Shell")
Set objWMIService = GetObject("winmgmts:")
Set cla = wScript.Arguments
Set oFS = CreateObject("Scripting.FileSystemObject") 

If oFS.FileExists(fileName) = True Then
  ReadFile oFS,delay,mailClientPath,mailProcessName,mailClientCla
Else
  mailClientPath = GetDefaultMailClientPath(sh)
  mailProcessName = GetProcessName(mailClientPath)
  delay = 100
  mailClientCla = VbCrLf
  WriteFile oFS,mailClientPath,mailProcessName
End If

If IsActive(mailProcessName,objWMIService) = True Then
  wScript.Quit
End If
active = IsActive("freepopsd.exe",objWMIService)
If active = False Then
  arg = ""

  '==Modification to delete the log files prior to running FreePOPs
  For i=0 To cla.Count-1
     If Lcase(cla(i)) = "-clearlogs" Then
       DeleteLogs oFS
     Else
       If Lcase(cla(i)) = "-update" Then
         FPUpdate = True
       Else
         arg = arg & " " & cla(i)
       End If
     End If
  Next
  '==End of modification

  '==Modification to run updater prior to running FreePOPs
  If FPUpdate = True Then
    sh.Run """" & GetFreePOPsPath(sh) & "freepopsd.exe" & """ -e lua\updater.lua php interactive" & """",1,true
  End If
  '==End of modification

  sh.Run("freepopsd.exe" & arg)
  wScript.sleep delay
End If
If mailClientCla = VbCrLf Then
  sh.Run """" & mailClientPath & """",1,true
Else
  sh.Run """" & mailClientPath & """ " & mailClientCla,1,true
End If
If active = False Then
  TerminateSingleIstance "freepopsd.exe",objWMIService
End If
wScript.Quit
