
Option Explicit

Function GetDefaultMailClientPath(sh)
  Dim key,temp
  key = "HKCR\mailto\shell\open\command\"
  temp = Split(sh.RegRead (key),"""")
  'Debug Istr
  'wScript.echo MailClientPath = Sh.RegRead (key)
  GetDefaultMailClientPath = temp(1)
End Function

Function GetMailProcessName(mailClientPath)
  Dim arr
  arr = Split(mailClientPath, "\")
  GetMailProcessName = arr(UBound(arr))
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

Function TerminateIstances (nome,objWMIService)
  Dim colProcess,objProcess
  Set colProcess = GetIstances(nome, objWMIService)
  For Each objProcess in colProcess
     objProcess.Terminate
  Next
End Function

Dim sh, objWMIService,active,mailClientPath,mailProcessName,cla,arg,i
Set sh=wScript.CreateObject("wScript.Shell")
Set objWMIService = GetObject("winmgmts:")
Set cla = wScript.Arguments

mailClientPath = GetDefaultMailClientPath(sh)
mailProcessName = GetMailProcessName(mailClientPath)

If IsActive(mailProcessName,objWMIService) = True Then
  wScript.Quit
End If
active = IsActive("freepopsd.exe",objWMIService)
If active = False Then
  arg = ""
  For i=0 To cla.Count-1
     arg = arg & " " & cla(i)
  Next
  sh.Run("freepopsd.exe" & arg)
End If
wScript.sleep 100
sh.Run """" & mailClientPath & """",1,true
If active = False Then
  TerminateIstances "freepopsd.exe",objWMIService
End If
wScript.Quit
