﻿SetTimer,UPDATEDSCRIPT,500
ANow := A_DD "." Month(A_MM) "." a_YYYY " " A_Hour "-" A_Min "-" A_Sec "-" A_MSec
If !FileExist(A_ScriptDir "\save\")
FileCreateDir,% A_ScriptDir "\save\"
FileCopy, % A_ScriptFullPath, % A_ScriptDir "\save\" A_ScriptName " save " ANow " .ahk"
/*
https://www.google.com/search?q=site%3Aautohotkey.com+alexa+Triggercmd&rlz=1C1CHBD_deDE898DE898&oq=site%3Aautohotkey.com+alexa+Triggercmd&aqs=chrome..69i57j6i58.10224j0j4&sourceid=chrome&ie=UTF-8

Es ist möglich, AutoHotkey zu verwenden, um Alexa zu steuern. Eine Möglichkeit besteht darin, den Windows-Client 
von Triggercmd zu installieren und Alexa-Befehle als Schalter zu erstellen. Mit Hilfe von Drittprogrammen wie 
AutoHotkey können Sie dann fast alles steuern, was auf Ihrem Computer ausgeführt wird 1. Hier ist eine Kurzanleitung, 
die Ihnen helfen kann, Ihren PC mit Alexa zu steuern 

Erstellen Sie einen Account bei Triggercmd 

Aktivieren Sie den Skill “Triggercmd Smart Home” in Alexa 

Installieren Sie den Windows-Client und geben Sie den Key ein, der in Ihrem Account hinterlegt ist 

Nachdem Sie diese Schritte ausgeführt haben, können Sie Befehle erstellen, um Programme oder Parameter auszuführen. 
Mit AutoHotkey können Sie dann fast alles steuern, was auf Ihrem Computer ausgeführt wird 
*/

	; Ursprüngliches Vorhaben "Skript das jeden Tag bei Sonnenuntergang ausgeführt wird"
	; hier habe ich die Idee für das Script her:
	; https://www.autohotkey.com/boards/viewtopic.php?p=439038#p439038   
	; https://sonnenuntergang-sonnenaufgang.info/koeln ; hier findest du die Sonnenzeiten für deinen Standort

	#SingleInstance force
	;#NoTrayIcon
	#NoEnv
	#Persistent
	FileEncoding, UTF-8
	SetBatchLines, -1
	SetTitleMatchMode, 2
	SetKeyDelay 20
	SetWorkingDir, %A_ScriptDir%

	atickCount := a_tickCount
	GuiLiveTime := (1439.99*60*1000) ; GuiLiveTime bei Guistart 23:59:59 maximale Größe darf nicht überschritten werden, sonst laufen die Zähler nicht korrekt
	MainArray := []

	outOfOrder := 1
	MakeList := 1

	ShowGuiLiveTime := 1 		; F5::
	ToggleGUI := 1			; zeige GUI bei Start
	showOnlyEDIT1Update := 1 	; einfache (Tooltip2GUI) Ausgabe
	showTooltipAlso := 0 		; tooltip und Tooltip2GUI anzeigen

	; 1 = erstellt zuerst eine Liste: Timestamp Sonnenaufgang Sonnenuntergang Sonnenstunden
	; 0 = Anzeige ToolTip, ohne Liste
	ShowMakeList := 0

	; Dieses Script startet bei Sonnenaufgang und Sonnenuntergang je eine Aktion, wie z.B 
	; Jalousie.-Markiesensteuerung und oder Beleuchtung ein bzw. ausschalten.

	; Bei Sonnenaufgang wird RISEfile gestartet
	RISEfile := A_ScriptDir "\screenshot 2 -direktauslösend 1 sekunde delay .ahk"

	; Bei Sonnenuntergang wird SETfile gestartet
	SETfile  := A_ScriptDir "\screenshot 2 -direktauslösend 1 sekunde delay .ahk"

	Gui, Font, 	s12
	Gui, Add, text, xs y+13 w550 h240 vEDIT1 hwndhGUIA  
	Gui, Show, x110 y11 w555 h245,% a_scriptName a_space hGUIA  

	settimer, toolTip, 800
	if !MakeList
	settimer, start, -1


	if MakeList
	{
		try filedelete,% a_scriptDir "\sonnenuntergang-sonnenaufgang-sunrise-sunset.csv"
		for thisMonth, month in strSplit("31,28,31,30,31,30,31,31,30,31,30,31",",") {
			loop,% month 
			{
			thisDay++
			AMM := thisMonth, ADD := thisDay
			gosub start
		;	sleep, 1 ; test
			}
			thisDay:=0
		}
	fileAppend,% thisres,% a_scriptDir "\sonnenuntergang-sonnenaufgang-sunrise-sunset.csv"
	if ShowMakeList
	try run,% a_scriptDir "\sonnenuntergang-sonnenaufgang-sunrise-sunset.csv"
	} 

	if (DayCounter=365)
	MakeList := false
	if !MakeList
	settimer, start, -1
	if !MakeList
	outOfOrder := 0


	return

;///////////////////////////////////////////////////////////////////////////////////////////////////////////




start:
	if MakeList
	x:=strSplit(SunriseSunset(AMM,ADD),"`t")
	else
	x:=strSplit(SunriseSunset(A_MM,A_DD),"`t")

 	Sonnenstunden 	:= ConvertToMilliseconds(x.2 ":" A_Sec "`," A_MSec) 
			 - ConvertToMilliseconds(x.1 ":" A_Sec "`," A_MSec)

	getBevor := 0 ; test
	if getBevor
	{
 	Sonnenaufgang 	:= ConvertToMilliseconds(x.1 ":" A_Sec "`," A_MSec) 
			 - ConvertToMilliseconds(A_Hour ":" A_Min ":" A_Sec "`," A_MSec)
 	Sonnenuntergang := ConvertToMilliseconds(x.2  ":" A_Sec "`," A_MSec) 
			 - ConvertToMilliseconds(A_Hour ":" A_Min ":" A_Sec "`," A_MSec)
	} else {  ; else sorgt dafür das die Zeiten auch nach dem Ereignis für den jweiligen KALENDERTAG erhalten bleiben
 	Sonnenaufgang 	:= ConvertToMilliseconds((MainArray["thisCalendarDaySunRise",A_DD,A_MM]) ":" A_Sec "`," A_MSec) 
			 - ConvertToMilliseconds(A_Hour ":" A_Min ":" A_Sec "`," A_MSec)
 	Sonnenuntergang := ConvertToMilliseconds((MainArray["thisCalendarDaySunSet",A_DD,A_MM])  ":" A_Sec "`," A_MSec) 
			 - ConvertToMilliseconds(A_Hour ":" A_Min ":" A_Sec "`," A_MSec)
	}

	StimeStd := StimeStdNoLTRIM := subStr(ConvertToHHMMSSMS(Sonnenstunden),1,2)
	StimeStd := LTRIM(StimeStd,0)
	StimeMIN := StimeMINnoLTRIM := subStr(ConvertToHHMMSSMS(Sonnenstunden),4,2)
	StimeMIN := LTRIM(StimeMIN,0)
	SAstd 	 := SAstdNoLTRIM := subStr(ConvertToHHMMSSMS(Sonnenaufgang),1,2)
	SAstd 	 := LTRIM(SAstd,0)
	SAmin	 := SAminNoLTRIM := subStr(ConvertToHHMMSSMS(Sonnenaufgang),4,2)
	SAmin	 := LTRIM(SAmin,0)
	SUstd	 := SUstdNoLTRIM := subStr(ConvertToHHMMSSMS(Sonnenuntergang),1,2)
	SUstd 	 := LTRIM(SUstd,0)
	SUmin	 := SUminNoLTRIM := subStr(ConvertToHHMMSSMS(Sonnenuntergang),4,2)
	SUmin	 := LTRIM(SUmin,0)

	MainArray["Aktuelle Zeit"] 	:= A_DD "." Month(A_MM) "." a_YYYY "  " A_Hour ":" A_Min ":" A_Sec " Uhr"
	MainArray["thisRISECounter"] 	:= thisRISECounter
	MainArray["thisSETCounter"] 	:= thisSETCounter
	MainArray["GUI DefaultTime"] 	:= thisSTARTCountTimeout()
	MainArray["GUI Timeout"] 	:= thisGUITimeout()
	MainArray["GUI UPTime"] 	:= thisUPCountTimeout()
	MainArray["GUI LiveTimes"] 	:= "`nLiveTimes:`t`t{"
					. MainArray["LIVETIME TimeStamp"]				; TimeStamp
					. MainArray["LIVETIME downCount"]		 		; downCount
					. MainArray["LIVETIME UPCount"]					; UPCount
 					.  "}"
	MainArray["Sonnenaufgang"] 	:= x.1
	MainArray["Sonnenuntergang"] 	:= x.2
	MainArray["Sonnenstunden"] 	:= StimeStd
	MainArray["Sonnenminuten"] 	:= ((StimeMIN=1)
					? "  " StimeMIN " Minute"
					: (StimeMIN>1) && (StimeMIN<10)
					? "  " StimeMIN " Minuten"
					: (StimeMIN>=10)
					? StimeMIN " Minuten"
					: "") 
	MainArray["Stunden bis zum nächsten Sonnenaufgang"]	:= ((SAstd=1)
								? "  " SAstd " Stunde    "
								: (SAstd>1) && (SAstd<10)
								? "  " SAstd " Stunden "
								: (SAstd>=10)
								? SAstd " Stunden "
								: "") 
	MainArray["Minuten bis zum nächsten Sonnenaufgang"]	:= ((SAmin=1)
								? "  " SAmin " Minute"
								: (SAmin>1) && (SAmin<10)
								? "  " SAmin " Minuten"
								: (SAmin>=10)
								? SAmin " Minuten"
								: (SAstd="") && (SAmin="")
								? thisRISE(RISEfile)
								: "")
	MainArray["Stunden bis zum nächsten Sonnenuntergang"]	:= ((SUstd=1)
								? "  " SUstd " Stunde    "
								: (SUstd>1) && (SUstd<10)
								? "  " SUstd " Stunden "
								: (SUstd>=10)
								? SUstd " Stunden "
								: "") 
	MainArray["Minuten bis zum nächsten Sonnenuntergang"]	:= ((SUmin=1)
								? "  " SUmin " Minute"
								: (SUmin>1) && (SUmin<10)
								? "  " SUmin " Minuten"
								: (SUmin>=10)
								? SUmin " Minuten"
								: (SUstd="") && (SUmin="")
								? thisSET(SETfile)
								: "")

 if !MakeList
 {
 thisGuiUpdate := "Aktuelle Zeit: " A_DD "." Month(A_MM) "." a_YYYY "  " A_Hour ":" A_Min ":" A_Sec " Uhr"
	. "    RISE#: " MainArray["thisRISECounter"] "  SET#: " MainArray["thisSETCounter"]
	. thisGuiTimeOutDownCounter()
;	. "`ntest:`t" MainArray["thisCalendarDaySunRise",A_DD,A_MM] a_space MainArray["thisCalendarDaySunSet",A_DD,A_MM]
	. "`nSonnenaufgang:`t" 		MainArray["Sonnenaufgang"] "`tUhr"
	. "`nSonnenuntergang:`t"	MainArray["Sonnenuntergang"] "`tUhr"
	. "`nSonnenstunden:`t`t`t`t" 	MainArray["Sonnenstunden"] " Stunden " MainArray["Sonnenminuten"]
	. "`nZeit bis zum nächsten Sonnenaufgang:`t`t" 
			. MainArray["Stunden bis zum nächsten Sonnenaufgang"]
			. MainArray["Minuten bis zum nächsten Sonnenaufgang"]
	. "`nZeit bis zum nächsten Sonnenuntergang:`t" 
			. MainArray["Stunden bis zum nächsten Sonnenuntergang"]		
			. MainArray["Minuten bis zum nächsten Sonnenuntergang"]	
	} else {
		DayCounter++
 thisGuiUpdate := "Aktuelle Zeit: " A_DD "." Month(A_MM) "." a_YYYY " " A_Hour ":" A_Min ":" A_Sec " Uhr"
		. ((MakeList=1)
		? "`nListe wird erstellt...`nDatum:`t" ADD "." Month(AMM) "." a_YYYY "`nTag:`t" DayCounter
		: "") 
		firstLine := "Datum`tSonnenaufgang`tSonnenuntergang`tSonnenstunden"
		if (DayCounter=1)
		fileAppend,% firstLine "`n",% a_scriptDir "\sonnenuntergang-sonnenaufgang-sunrise-sunset.csv"
		thisres .= ADD "." 
			. Month(AMM) "`t"
			. x.1 "`t"
			. x.2 "`t"
			. StimeStd ":"
			. StimeMINnoLTRIM "`n"
		MainArray["thisCalendarDaySunRise",ADD,AMM] := MainArray["Sonnenaufgang"]
		MainArray["thisCalendarDaySunSet", ADD,AMM] := MainArray["Sonnenuntergang"]
		}

	if !MakeList
	settimer, start, -900
	return


;-------------------------------------------------------------------------------------------------------------------------------------------------
guiclose:
reload
return


F1::
	thisGuiUpdate := ""
	ToggleGUI := 0
	if ToggleGUI := (ToggleGUI:=!ToggleGUI)
		{
		atickCount := a_tickCount
		GuiLiveTime:=(.09*60*1000) ; 59 sec
		thisGUITimeout()
		thisRISE(RISEfile)
		Gui, Show
	} 
return

F2::
	thisGuiUpdate := ""
	ToggleGUI := 0
	if ToggleGUI := (ToggleGUI:=!ToggleGUI)
		{
		atickCount := a_tickCount
		GuiLiveTime:=(.09*60*1000) ; 59 sec
		thisGUITimeout()
		thisSET(SETfile)
		Gui, Show
	} 
return

F3::
	thisGuiUpdate := ""
	ToggleGUI := 0
	if ToggleGUI := (ToggleGUI:=!ToggleGUI)
		{
		atickCount := a_tickCount
		GuiLiveTime:=(1439.99*60*1000) ; 59 sec
		thisGUITimeout()
		Gui, Show
	}
return

F4::
	thisGuiUpdate := ""
	ToggleGUI := 0
	if ToggleGUI := (ToggleGUI:=!ToggleGUI)
		{
		atickCount := a_tickCount
		GuiLiveTime:=(1439.99*60*1000) ; 59 sec
		thisGUITimeout()
	}
return

F5::
ShowGuiLiveTime := (ShowGuiLiveTime:=!ShowGuiLiveTime)
return

toolTip:
if ToggleGUI
{
if showOnlyEDIT1Update
GuiControl,, EDIT1, %thisGuiUpdate%
thisGuiUpdatex := strReplace(thisGuiUpdate,"nächsten Sonnenaufgang:`t`t","nächsten Sonnenaufgang:`t")
if showTooltipAlso
tooltip,% thisGuiUpdatex
} else {
ToolTip
Gui, Show, hide 
}
return

ToolTipTimeout(min:=1) {
global
ToggleGUI := 1
sleep,% (min*60*1000)
ToggleGUI := 0
}

GUItimeout(min:=.055) {
global
;    ToggleGUI := 1
GuiControl,Text,% hthisTEXTid, %thisGUIUpdate%
Gui, Show
sleep,% (min*60*1000)
;sleep,% GuiLiveTime:=(min*60*1000)
Gui, Show, hide
settimer, start, -1
;    ToggleGUI := 0
}

thisGuiTimeOutDownCounter() {   						; F5::
global

if ShowGuiLiveTime
return    "`nGUI DefaultTime:`t" thisSTARTCountTimeout()
	.  "`nGUI Timeout:`t`t" thisGUITimeout()
	. "`nGUI UPTime:`t`t" thisUPCountTimeout()
else
return ""
}

thisGUITimeout() {
 global 
 atickcountB := a_tickcount-atickcount
 thisdownCount := subStr(ConvertToHHMMSSMS(GuiLiveTime-atickcountB),1,8) 	; downCount
	thisdownCountStd := subStr(thisdownCount,1,2)
	thisdownCountStd := LTRIM(thisdownCountStd,0)
	thisdownCountMIN := subStr(thisdownCount,4,2)
	thisdownCountMIN := LTRIM(thisdownCountMIN,0)
	thisdownCountSEC := subStr(thisdownCount,7,2)
	thisdownCountSEC := LTRIM(thisdownCountSEC,0)
if (thisdownCountStd="") && (thisdownCountMIN="") && (thisdownCountSEC="")
{
Gui, Show, hide
sleep, 1
}else{
 return   	 ((thisdownCountSTD=1)
		? "  " thisdownCountSTD " Stunde "
		: (thisdownCountSTD>1) && (thisdownCountSTD<10)
		? "  " thisdownCountSTD " Stunden "
		: (thisdownCountSTD>=10)
		? thisdownCountSTD " Stunden "
		: "") 
		. ((thisdownCountMIN=1)
		? thisdownCountMIN " Minute "
		: (thisdownCountMIN>1) && (thisdownCountMIN<10)
		? "  " thisdownCountMIN " Minuten "
		: (thisdownCountMIN>=10)
		? thisdownCountMIN " Minuten "
		: "") 
		. ((thisdownCountSEC=1)
		? thisdownCountSEC " Sekunde"
		: (thisdownCountSEC>1) && (thisdownCountSEC<10) || (thisdownCountSEC>=10)
		? thisdownCountSEC " Sekunden"
		: "") 
}}

thisUPCountTimeout() {
 global 
 atickcountC := a_tickcount-atickcount
 thisUPCount := subStr(ConvertToHHMMSSMS(atickcountC),1,8) 	; UPCount
	thisUPCountStd := subStr(thisUPCount,1,2)
	thisUPCountStd := LTRIM(thisUPCountStd,0)
	thisUPCountMIN := subStr(thisUPCount,4,2)
	thisUPCountMIN := LTRIM(thisUPCountMIN,0)
	thisUPCountSEC := subStr(thisUPCount,7,2)
	thisUPCountSEC := LTRIM(thisUPCountSEC,0)
	MainArray["LIVETIME TimeStamp"]	:= subStr(ConvertToHHMMSSMS(GuiLiveTime),1,8)
	MainArray["LIVETIME downCount"]	:= subStr(ConvertToHHMMSSMS(GuiLiveTime-atickcountB),1,8)
	MainArray["LIVETIME UPCount"] 	:= subStr(ConvertToHHMMSSMS(atickcountB),1,8)
 return   	((thisUPCountSTD=1)
		? "  " thisUPCountSTD " Stunde "
		: (thisUPCountSTD>1) && (thisUPCountSTD<10)
		? "  " thisUPCountSTD " Stunden "
		: (thisUPCountSTD>=10)
		? thisUPCountSTD " Stunden "
		: "") 
		. ((thisUPCountMIN=1)
		? thisUPCountMIN " Minute "
		: (thisUPCountMIN>1) && (thisUPCountMIN<10)
		? "  " thisUPCountMIN " Minuten "
		: (thisUPCountMIN>=10)
		? thisUPCountMIN " Minuten "
		: "") 
		. ((thisUPCountSEC=1)
		? thisUPCountSEC " Sekunde"
		: (thisUPCountSEC>1) && (thisUPCountSEC<10) || (thisUPCountSEC>=10)
		? thisUPCountSEC " Sekunden"
		: "") 
 		. "`nLiveTimes:`t`t{"
		. MainArray["LIVETIME TimeStamp"] " / "	; TimeStamp
		. MainArray["LIVETIME downCount"] " / "	; downCount
		. MainArray["LIVETIME UPCount"] 	; UPCount
		.  "}"
}

thisSTARTCountTimeout() {
 global 
; atickcountB := a_tickcount-atickcount
 thisStartTime := subStr(ConvertToHHMMSSMS(GuiLiveTime),1,8) 	; TimeStamp
	thisStartTimeStd := subStr(thisStartTime,1,2)
	thisStartTimeStd := LTRIM(thisStartTimeStd,0)
	thisStartTimeMIN := subStr(thisStartTime,4,2)
	thisStartTimeMIN := LTRIM(thisStartTimeMIN,0)
	thisStartTimeSEC := subStr(thisStartTime,7,2)
	thisStartTimeSEC := LTRIM(thisStartTimeSEC,0)
 return   	((thisStartTimeSTD=1)
		? "  " thisStartTimeSTD " Stunde "
		: (thisStartTimeSTD>1) && (thisStartTimeSTD<10)
		? "  " thisStartTimeSTD " Stunden "
		: (thisStartTimeSTD>=10)
		? thisStartTimeSTD " Stunden "
		: "") 
		. ((thisStartTimeMIN=1)
		? thisStartTimeMIN " Minute "
		: (thisStartTimeMIN>1) && (thisStartTimeMIN<10)
		? "  " thisStartTimeMIN " Minuten "
		: (thisStartTimeMIN>=10)
		? thisStartTimeMIN " Minuten "
		: "") 
		. ((thisStartTimeSEC=1)
		? thisStartTimeSEC " Sekunde"
		: (thisStartTimeSEC>1) && (thisStartTimeSEC<10) || (thisStartTimeSEC>=10)
		? thisStartTimeSEC " Sekunden"
		: "") 
}


Month(thisMonth) {
		Month := strSplit("Jan,Feb,Mrz,Apr,Mai,Jun,Jul,Aug,Sep,Okt,Nov,Dez",",")
		return Month[thisMonth]
}

	thisRISE(RISEfile) {
			global
	if outOfOrder
		return
		ToggleGUI := 0
		if ToggleGUI := (ToggleGUI:=!ToggleGUI)
		{
		atickCount := a_tickCount
		GuiLiveTime:=(.099*60*1000)
		Gui, Show
		thisGUITimeout()
		}
	if inStr(timeStampRISEall, A_DD "." Month(A_MM) "." a_YYYY " Sonnenaufgang") {
	return " `tSUNRISE" 
	} else {
		try run,% RISEfile,, hide, AusgabeVarPID
		timeStampRISEall .= A_DD "." Month(A_MM) "." a_YYYY " Sonnenaufgang " A_Hour ":" A_Min ":" A_Sec "`n"
		fileAppend,% "Sonnenaufgang:`t" A_DD "." Month(A_MM) "." a_YYYY "  " A_Hour ":" A_Min ":" A_Sec " Uhr`n"
				, % a_scriptDir "\" A_ScriptName " timeStampall.txt"
		thisRISECounter++
		return " `tSUNRISE"
	}}


	thisSET(SETfile) {
			global
	if outOfOrder
		return
		ToggleGUI := 0
		if ToggleGUI := (ToggleGUI:=!ToggleGUI)
		{
		atickCount := a_tickCount
		GuiLiveTime:=(.99*60*1000)
		Gui, Show
		thisGUITimeout()
		}
	if inStr(timeStampSETall, A_DD "." Month(A_MM) "." a_YYYY " Sonnenuntergang") {
	return " `tSUNSET" 
	} else {
		try run,% SETfile,, hide, AusgabeVarPID
		timeStampSETall .= A_DD "." Month(A_MM) "." a_YYYY " Sonnenuntergang " A_Hour ":" A_Min ":" A_Sec "`n"
		fileAppend,% "Sonnenuntergang:`t" A_DD "." Month(A_MM) "." a_YYYY "  " A_Hour ":" A_Min ":" A_Sec " Uhr`n"
				, % a_scriptDir "\" A_ScriptName " timeStampall.txt"
		thisSETCounter++
		return " `tSUNSET"
	}}


SunriseSunset(mm,dd){
sunrise=
(
08:32	08:06	07:15	07:06	06:04	05:21	05:20	05:56	06:43	07:30	07:22	08:10
08:32	08:05	07:13	07:04	06:02	05:20	05:20	05:57	06:45	07:32	07:23	08:11
08:32	08:03	07:10	07:02	06:00	05:19	05:21	05:59	06:46	07:33	07:25	08:13
08:32	08:02	07:08	06:59	05:58	05:19	05:22	06:00	06:48	07:35	07:27	08:14
08:32	08:00	07:06	06:57	05:56	05:18	05:23	06:02	06:50	07:37	07:28	08:15
08:31	07:59	07:04	06:55	05:55	05:18	05:24	06:03	06:51	07:38	07:30	08:17
08:31	07:57	07:02	06:53	05:53	05:17	05:24	06:05	06:53	07:40	07:32	08:18
08:31	07:55	07:00	06:51	05:51	05:17	05:25	06:06	06:54	07:41	07:34	08:19
08:30	07:54	06:57	06:48	05:50	05:16	05:26	06:08	06:56	07:43	07:35	08:20
08:30	07:52	06:55	06:46	05:48	05:16	05:27	06:09	06:57	07:45	07:37	08:21
08:29	07:50	06:53	06:44	05:46	05:16	05:28	06:11	06:59	07:46	07:39	08:22
08:28	07:48	06:51	06:42	05:45	05:15	05:29	06:12	07:00	07:48	07:40	08:23
08:28	07:46	06:49	06:40	05:43	05:15	05:30	06:14	07:02	07:50	07:42	08:24
08:27	07:45	06:46	06:38	05:42	05:15	05:32	06:15	07:04	07:51	07:44	08:25
08:26	07:43	06:44	06:36	05:40	05:15	05:33	06:17	07:05	07:53	07:45	08:26
08:25	07:41	06:42	06:33	05:39	05:15	05:34	06:18	07:07	07:55	07:47	08:27
08:25	07:39	06:40	06:31	05:37	05:15	05:35	06:20	07:08	07:56	07:49	08:27
08:24	07:37	06:37	06:29	05:36	05:15	05:36	06:22	07:10	07:58	07:50	08:28
08:23	07:35	06:35	06:27	05:35	05:15	05:38	06:23	07:11	08:00	07:52	08:29
08:22	07:33	06:33	06:25	05:33	05:15	05:39	06:25	07:13	08:01	07:54	08:29
08:21	07:31	06:31	06:23	05:32	05:15	05:40	06:26	07:14	08:03	07:55	08:30
08:19	07:29	06:29	06:21	05:31	05:15	05:41	06:28	07:16	08:05	07:57	08:30
08:18	07:27	06:26	06:19	05:30	05:16	05:43	06:29	07:18	08:06	07:58	08:31
08:17	07:25	06:24	06:17	05:29	05:16	05:44	06:31	07:19	08:08	08:00	08:31
08:16	07:23	06:22	06:15	05:27	05:16	05:46	06:32	07:21	08:10	08:01	08:32
08:15	07:21	07:20	06:13	05:26	05:17	05:47	06:34	07:22	08:11	08:03	08:32
08:13	07:19	07:17	06:11	05:25	05:17	05:48	06:36	07:24	08:13	08:04	08:32
08:12	07:17	07:15	06:09	05:24	05:18	05:50	06:37	07:25	08:15	08:06	08:32
08:11		07:13	06:07	05:23	05:18	05:51	06:39	07:27	07:16	08:07	08:32
08:09		07:11	06:05	05:23	05:19	05:53	06:40	07:29	07:18	08:09	08:32
08:08		07:08		05:22		05:54	06:42		07:20		08:32
)

sunset=
(
16:38	17:24	18:13	20:05	20:54	21:38	21:51	21:21	20:20	19:13	17:09	16:31
16:39	17:26	18:15	20:07	20:56	21:39	21:51	21:19	20:18	19:10	17:07	16:30
16:40	17:28	18:17	20:08	20:57	21:40	21:51	21:17	20:16	19:08	17:05	16:30
16:41	17:29	18:19	20:10	20:59	21:41	21:50	21:16	20:14	19:06	17:04	16:29
16:42	17:31	18:20	20:12	21:00	21:42	21:50	21:14	20:11	19:04	17:02	16:29
16:43	17:33	18:22	20:13	21:02	21:43	21:49	21:12	20:09	19:02	17:00	16:29
16:45	17:35	18:24	20:15	21:04	21:44	21:49	21:10	20:07	18:59	16:59	16:28
16:46	17:36	18:25	20:17	21:05	21:45	21:48	21:09	20:05	18:57	16:57	16:28
16:47	17:38	18:27	20:18	21:07	21:46	21:47	21:07	20:02	18:55	16:56	16:28
16:49	17:40	18:29	20:20	21:08	21:46	21:47	21:05	20:00	18:53	16:54	16:28
16:50	17:42	18:30	20:22	21:10	21:47	21:46	21:03	19:58	18:51	16:53	16:28
16:51	17:44	18:32	20:23	21:11	21:48	21:45	21:01	19:56	18:49	16:51	16:27
16:53	17:45	18:34	20:25	21:13	21:48	21:44	20:59	19:53	18:46	16:50	16:27
16:54	17:47	18:35	20:26	21:14	21:49	21:43	20:58	19:51	18:44	16:48	16:27
16:56	17:49	18:37	20:28	21:16	21:49	21:43	20:56	19:49	18:42	16:47	16:28
16:57	17:51	18:39	20:30	21:17	21:50	21:42	20:54	19:47	18:40	16:46	16:28
16:59	17:52	18:40	20:31	21:19	21:50	21:41	20:52	19:44	18:38	16:44	16:28
17:00	17:54	18:42	20:33	21:20	21:51	21:39	20:50	19:42	18:36	16:43	16:28
17:02	17:56	18:44	20:35	21:22	21:51	21:38	20:48	19:40	18:34	16:42	16:29
17:04	17:58	18:45	20:36	21:23	21:51	21:37	20:46	19:38	18:32	16:41	16:29
17:05	17:59	18:47	20:38	21:24	21:52	21:36	20:44	19:35	18:30	16:40	16:29
17:07	18:01	18:49	20:39	21:26	21:52	21:35	20:42	19:33	18:28	16:39	16:30
17:09	18:03	18:50	20:41	21:27	21:52	21:34	20:39	19:31	18:26	16:38	16:30
17:10	18:05	18:52	20:43	21:28	21:52	21:32	20:37	19:28	18:24	16:37	16:31
17:12	18:06	18:54	20:44	21:30	21:52	21:31	20:35	19:26	18:22	16:36	16:32
17:14	18:08	19:55	20:46	21:31	21:52	21:30	20:33	19:24	18:20	16:35	16:32
17:15	18:10	19:57	20:48	21:32	21:52	21:28	20:31	19:22	18:18	16:34	16:33
17:17	18:12	19:59	20:49	21:33	21:52	21:27	20:29	19:19	18:16	16:33	16:34
17:19		20:00	20:51	21:35	21:52	21:25	20:27	19:17	17:14	16:32	16:35
17:20		20:02	20:52	21:36	21:52	21:24	20:25	19:15	17:13	16:32	16:36
17:22		20:04		21:37		21:22	20:22		17:11		16:37
)

for x,y in strsplit(sunrise,"`n","`r")
	for a,b in strsplit(y,"`t")
		if (x=dd and a=mm)
			res :=    b

for x,y in strsplit(sunset,"`n","`r")
	for a,b in strsplit(y,"`t")
		if (x=dd and a=mm)
return 	res .=    "`t" b
}

;----------------------------------------------------------------------------------------------------------

;https://www.autohotkey.com/boards/viewtopic.php?p=213907#p213907 by just me

ConvertToMilliseconds(HHMMSSMS)
{
   Sekunden := A_YYYY . "0101" . StrReplace(SubStr(HHMMSSMS, 1, 8), ":")
   Sekunden -= A_YYYY, S
   Return (Sekunden * 1000) + SubStr(HHMMSSMS, 10)
}

ConvertToHHMMSSMS(Millisekunden)
{
   Zeitstempel := A_YYYY ; nur der Deutlichkeit halber, AHK rechnet auch mit leeren Variablen
   Zeitstempel += % (Millisekunden // 1000), S
   FormatTime, HHMMSS, %Zeitstempel%, HH:mm:ss
   Return (HHMMSS . Format(",{:03}", Mod(Millisekunden, 1000)))
}



UPDATEDSCRIPT() {
FileGetAttrib,attribs,%A_ScriptFullPath%
            IfInString,attribs,A
             {
                FileSetAttrib,-A,%A_ScriptFullPath%
                SplashTextOn,,,Updated script,
                Sleep,1500 
                Reload             
}}
;SetTimer,UPDATEDSCRIPT,500
;Return
