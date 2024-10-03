@echo off
REM Title: lolcheckz.cmd
REM Version: 1.1
REM Description: A script to check local policy settings on the local machine. Does not require Powershell, but does require elevation.
REM Author: Chris Hogarth 
REM Created: March 2019
REM Modified: July 2021

:switchoptions
set logoutput=""
set logdebug=""
set thirdparty=""
if "%1" == "/log" set logoutput=TRUE
if "%2" == "/log" set logoutput=TRUE
if "%1" == "/logdebug" set logdebug=TRUE
if "%2" == "/logdebug" set logdebug=TRUE
if "%1" == "/3rdparty" set thirdparty=TRUE
if "%2" == "/3rdparty" set thirdparty=TRUE
if "%logdebug%" == "TRUE" (echo on & call :LolCheckz > %computername%-debug.txt 2> NUL & echo off & goto LolCheckz)
if "%logoutput%" == "TRUE" (call :LolCheckz > %computername%-output.txt 2> NUL & goto LolCheckz)

if "%1" NEQ "" goto :LolCheckz
:optionscheck
cls
echo WARNING!
echo You do not appear to have specified any log options with this script, it is highly recommended to run with the following:
echo lolcheckz.cmd /log
echo Ideally this should also be run using the following (separately):
echo lolcheckz.cmd /logdebug
echo To enable checking of third party programs, use the following (note: this can be time consuming):
echo lolcheckz.cmd /3rdparty
set /p AREYOUSURE=Are you sure you want to continue? (Y/[N])?
if /i "%AREYOUSURE%" NEQ "Y" goto end
echo.

:LolCheckz
echo Expanding Screen
mode con cols=160 lines=2000

echo Creating TEMP folder
set TEMPDIRECTORY=TEMPCHECKSEC%RANDOM%%RANDOM%
echo %TEMPDIRECTORY%
mkdir %TEMPDIRECTORY%

echo Deleting old log if exists
if exist %computername%-log.txt del %computername%-log.txt

echo Setting default KEY variable
set KEY=NULL

echo Generating Colours config
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a")

echo Checking process is elevated
net session >nul 2>&1
if %errorlevel% == 0 (echo Success: Administrative permissions confirmed.) else (echo Failure: Current permissions inadequate. & exit /b)

echo Checking if Windows 2003 or XP
ver | findstr /c:"Microsoft Windows [Version 5."
if errorlevel 1 (echo This system is NOT running Windows 2003 or XP & set win2003=FALSE) else (echo This system appears to be running Windows 2003 or XP & set win2003=TRUE)

echo Checking if Client or Server Operating System
wmic os get caption | findstr /v Caption > %TEMPDIRECTORY%\os.txt
set /p os= < %TEMPDIRECTORY%\os.txt
type %TEMPDIRECTORY%\os.txt | findstr Server > NUL
if errorlevel 1 (set clientorserver=Client) else (set clientorserver=Server)

:clientserverend
echo %clientorserver% - %os%

goto startchecks

REM Major functions
:log
echo. >> %computername%-log.txt
echo Test: %TEST% >> %computername%-log.txt
echo Status: %STATUS% >> %computername%-log.txt
if %KEY% == NULL set KEY="secedit.exe /export /cfg sec.txt"
echo Location: %KEY% >> %computername%-log.txt
if not "%ACTUAL%" == "" echo Expect: %EXPECTED% >> %computername%-log.txt
if not "%ACTUAL%" == "" echo Actual: "%ACTUAL%" >> %computername%-log.txt
goto :eof

:lognot
call :log
echo SHOULD NOT BE EXPECTED VALUE >> %computername%-log.txt
goto :eof

:set
set TEST=%TEST:"=%
set %TEST%=
set TEST=
set STATUS=
set EXPECTED=
set ACTUAL=
set NUMEXPECTED=
set NUMACTUAL=
set KEY=NULL
set EXCEPT=
set SEARCH=
set LOG=
set FILE=
set SHARES=
set NOT=
set EXPECTEDNESSUS=
set EXPECTEDOR=
set EXPECTEDWARN=
set NUMEXPECTEDWARN=
set NULLSID=
set windirwmi=
set pre2008r2=
set pre2012r2=
set pre2016=
set SysmaxSizeEXPECTED=
set ResetLockoutCountEXPECTED=
set replace=
set PLUGINID=
set LAPSDLL=
set applocker=
set srp=
set fDenyTSConnections=
set version=
goto :eof

:functionCompareTxtNUMATLEAST
set TEST=%1
set EXPECTED=%2
echo Expect: %EXPECTED%
type %TEMPDIRECTORY%\sec.txt | findstr %1 > %TEMPDIRECTORY%\%1.txt
set /p ACTUAL= < %TEMPDIRECTORY%\%1.txt
if "%ACTUAL%" == "" set ACTUAL=NULL
echo Actual: "%ACTUAL%"
set /a NUMEXPECTED = %EXPECTED%
set /a NUMACTUAL = %ACTUAL%
if %NUMACTUAL% GEQ %NUMEXPECTED% (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0c "FAIL" & set STATUS=FAIL)
call :log
if not "%STATUS%" == "PASS" call :startnessustxtfinding
call :set
goto :eof

:functionCompareTxtNUMATLEASTEXCEPT
set TEST=%1
set EXPECTED=%2
set EXCEPT=%3
echo Expect: %EXPECTED%
type %TEMPDIRECTORY%\sec.txt | findstr %1 > %TEMPDIRECTORY%\%1.txt
set /p ACTUAL= < %TEMPDIRECTORY%\%1.txt
if "%ACTUAL%" == "" set ACTUAL=NULL
echo Actual: "%ACTUAL%"
set /a NUMEXPECTED = %EXPECTED%
set /a NUMACTUAL = %ACTUAL%
if "%ACTUAL%" == %EXCEPT% (call :ColourText 0a "PASS" & set STATUS=PASS) else if %NUMACTUAL% GEQ %NUMEXPECTED% (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0c "FAIL" & set STATUS=FAIL)
call :log
if not "%STATUS%" == "PASS" call :startnessustxtfinding
call :set
goto :eof

:functionCompareTxtNUMATLEASTRANGE
set TEST=%1
set EXPECTED=%2
set EXPECTEDWARN=%3
echo Expect: %EXPECTED%
type %TEMPDIRECTORY%\sec.txt | findstr %1 > %TEMPDIRECTORY%\%1.txt
set /p ACTUAL= < %TEMPDIRECTORY%\%1.txt
if "%ACTUAL%" == "" set ACTUAL=NULL
echo Actual: "%ACTUAL%"
set /a NUMEXPECTED = %EXPECTED%
set /a NUMEXPECTEDWARN = %EXPECTEDWARN%
set /a NUMACTUAL = %ACTUAL%
if %NUMACTUAL% GEQ %NUMEXPECTED% (call :ColourText 0a "PASS" & set STATUS=PASS) else if %NUMACTUAL% GEQ %NUMEXPECTEDWARN% (call :ColourText 0e "WARN" & set STATUS=WARN) else (call :ColourText 0c "FAIL" & set STATUS=FAIL)
call :log
if not "%STATUS%" == "PASS" call :startnessustxtfinding
call :set
goto :eof

:functionCompareTxtNUMLESSTHAN
set TEST=%1
set EXPECTED=%2
echo Expect: %EXPECTED%
type %TEMPDIRECTORY%\sec.txt | findstr %1 > %TEMPDIRECTORY%\%1.txt
set /p ACTUAL= < %TEMPDIRECTORY%\%1.txt
echo Actual: "%ACTUAL%"
set /a NUMEXPECTED = %EXPECTED%
set /a NUMACTUAL = %ACTUAL%
if %NUMACTUAL% LEQ %NUMEXPECTED% (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0c "FAIL" & set STATUS=FAIL)
call :log
if not "%STATUS%" == "PASS" call :startnessustxtfinding
call :set
goto :eof

:functionCompareTxtNUMLESSTHANORWARN
set TEST=%1
set EXPECTED=%2
echo Expect: %EXPECTED%
type %TEMPDIRECTORY%\sec.txt | findstr %1 > %TEMPDIRECTORY%\%1.txt
set /p ACTUAL= < %TEMPDIRECTORY%\%1.txt
echo Actual: "%ACTUAL%"
set /a NUMEXPECTED = %EXPECTED%
set /a NUMACTUAL = %ACTUAL%
if %NUMACTUAL% LEQ %NUMEXPECTED% (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0e "WARN" & set STATUS=WARN)
call :log
if not "%STATUS%" == "PASS" call :startnessustxtfinding
call :set
goto :eof

:functionCompareTxtNUMLESSTHANEXCEPT
set TEST=%1
set EXPECTED=%2
set EXCEPT=%3
echo Expect: %EXPECTED%
type %TEMPDIRECTORY%\sec.txt | findstr %1 > %TEMPDIRECTORY%\%1.txt
set /p ACTUAL= < %TEMPDIRECTORY%\%1.txt
echo Actual: "%ACTUAL%"
set /a NUMEXPECTED = %EXPECTED%
set /a NUMACTUAL = %ACTUAL%
if "%ACTUAL%" == %EXCEPT% (call :ColourText 0c "FAIL" & set STATUS=FAIL) else if %NUMACTUAL% LEQ %NUMEXPECTED% (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0c "FAIL" & set STATUS=FAIL)
call :log
if not "%STATUS%" == "PASS" call :startnessustxtfinding
call :set
goto :eof


:functionCompareTxtEXACT
set TEST=%1
set EXPECTED=%2
echo Expect: %EXPECTED%
type %TEMPDIRECTORY%\sec.txt | findstr %1 > %TEMPDIRECTORY%\%1.txt
set /p ACTUAL= < %TEMPDIRECTORY%\%1.txt
echo Actual: "%ACTUAL%"
if "%ACTUAL%" == %EXPECTED% (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0c "FAIL" & set STATUS=FAIL)
call :log
if not "%STATUS%" == "PASS" call :startnessustxtfinding
call :set
goto :eof

:functionCompareTxtNOT
set NOT=TRUE
set TEST=%1
set EXPECTED=%2
echo Expect: NOT= %EXPECTED%
type %TEMPDIRECTORY%\sec.txt | findstr %1 > %TEMPDIRECTORY%\%1.txt
set /p ACTUAL= < %TEMPDIRECTORY%\%1.txt
echo Actual: SET= "%ACTUAL%"
if "%ACTUAL%" == %EXPECTED% (call :ColourText 0c "FAIL" & set STATUS=FAIL) else (call :ColourText 0a "PASS" & set STATUS=PASS)
call :lognot
if not "%STATUS%" == "PASS" call :startnessustxtfinding
call :set
goto :eof

:functionCompareRegEXACT
set TEST=%1
set EXPECTED=%2
set KEY=%3
echo Expect: %EXPECTED%
reg query %KEY% /v %1 | findstr /i %1 > %TEMPDIRECTORY%\%1.txt
set /p ACTUAL= < %TEMPDIRECTORY%\%1.txt
echo Actual: "%ACTUAL%"
if "%ACTUAL%" == %EXPECTED% (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0c "FAIL" & set STATUS=FAIL)
call :log
if not "%STATUS%" == "PASS" call :startnessusregfinding
call :set
goto :eof

:functionCompareRegEXACTORNOTSET
set TEST=%1
set EXPECTED=%2
set KEY=%3
echo Expect: %EXPECTED%
reg query %KEY% /v %1 | findstr /i %1 > %TEMPDIRECTORY%\%1.txt
set /p ACTUAL= < %TEMPDIRECTORY%\%1.txt
echo Actual: "%ACTUAL%"
if "%ACTUAL%" == "" (call :ColourText 0a "PASS" & set STATUS=PASS) else if "%ACTUAL%" == %EXPECTED% (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0c "FAIL" & set STATUS=FAIL)
call :log
if not "%STATUS%" == "PASS" call :startnessusregfinding
call :set
goto :eof

:functionCompareRegNOT
set NOT=TRUE
set TEST=%1
set EXPECTED=%2
set KEY=%3
echo Expect: NOT= %EXPECTED%
reg query %KEY% /v %1 | findstr /i %1 > %TEMPDIRECTORY%\%1.txt
set /p ACTUAL= < %TEMPDIRECTORY%\%1.txt
echo Actual: SET= "%ACTUAL%"
if "%ACTUAL%" == %EXPECTED% (call :ColourText 0c "FAIL" & set STATUS=FAIL) else (call :ColourText 0a "PASS" & set STATUS=PASS)
call :lognot
if not "%STATUS%" == "PASS" call :startnessusregfinding
call :set
goto :eof

:functionCompareAuditPolTxtEXACT
set TEST=%1
set EXPECTED=%2
set SEARCH=%3
set KEY="auditpol.exe /get /category:*"
echo Expect: %EXPECTED%
auditpol.exe /get /category:* | findstr /c:%SEARCH% > %TEMPDIRECTORY%\%TEST%.txt
set /p ACTUAL= < %TEMPDIRECTORY%\%TEST%.txt
echo Actual: "%ACTUAL%"
if "%ACTUAL%" == %EXPECTED% (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0c "FAIL" & set STATUS=FAIL)
call :log
if not "%STATUS%" == "PASS" call :startnessusauditfinding
call :set
goto :eof

:functionCompareAuditPolTxtEXACTOR
set TEST=%1
set EXPECTED=%2
set SEARCH=%3
set EXPECTEDOR=%4
set KEY="auditpol.exe /get /category:*"
echo Expect: %EXPECTED%
auditpol.exe /get /category:* | findstr /c:%SEARCH% > %TEMPDIRECTORY%\%TEST%.txt
set /p ACTUAL= < %TEMPDIRECTORY%\%TEST%.txt
echo Actual: "%ACTUAL%"
if "%ACTUAL%" == %EXPECTED% (call :ColourText 0a "PASS" & set STATUS=PASS) else if "%ACTUAL%" == %EXPECTEDOR% (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0c "FAIL" & set STATUS=FAIL)
call :log
if not "%STATUS%" == "PASS" call :startnessusauditfinding
call :set
goto :eof

:functionCompareAuditPolLogOnOffSubTxtEXACT
set TEST=%1
set EXPECTED=%2
set SEARCH=%3
echo Expect: %EXPECTED%
set KEY="auditpol.exe /get /subcategory:%TEST%"
auditpol.exe /get /subcategory:%TEST% | findstr /c:%TEST% | findstr /v /c:"Logon/Logoff" > %TEMPDIRECTORY%\%TEST%.txt
set /p ACTUAL= < %TEMPDIRECTORY%\%TEST%.txt
echo Actual: "%ACTUAL%"
if "%ACTUAL%" == %EXPECTED% (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0c "FAIL" & set STATUS=FAIL)
call :log
if not "%STATUS%" == "PASS" call :startnessusauditfinding
call :set
goto :eof

:functionCompareAuditPolLogOnOffSubTxtEXACTOR
set TEST=%1
set EXPECTED=%2
set SEARCH=%3
set EXPECTEDOR=%4
echo Expect: %EXPECTED%
set KEY="auditpol.exe /get /subcategory:%TEST%"
auditpol.exe /get /subcategory:%TEST% | findstr /c:%TEST% | findstr /v /c:"Logon/Logoff" > %TEMPDIRECTORY%\%TEST%.txt
set /p ACTUAL= < %TEMPDIRECTORY%\%TEST%.txt
echo Actual: "%ACTUAL%"
if "%ACTUAL%" == %EXPECTED% (call :ColourText 0a "PASS" & set STATUS=PASS) else if "%ACTUAL%" == %EXPECTEDOR% (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0c "FAIL" & set STATUS=FAIL)
call :log
if not "%STATUS%" == "PASS" call :startnessusauditfinding
call :set
goto :eof

:functionCompareTxtEvtNUMATLEAST
set TEST=%1
set EXPECTED=%2
set LOG=%3
set KEY="wevtutil gl %LOG% | findstr maxSize"
echo Expect: %EXPECTED%
wevtutil gl %LOG% | findstr maxSize > %TEMPDIRECTORY%\%TEST%.txt
set /p ACTUAL= < %TEMPDIRECTORY%\%TEST%.txt
echo Actual: "%ACTUAL%"
set ACTUAL=%ACTUAL:maxSize: =%
set EXPECTED=%EXPECTED:maxSize: =%
set /a NUMEXPECTED = %EXPECTED%
set /a NUMACTUAL = %ACTUAL%
if %NUMACTUAL% GEQ %NUMEXPECTED% (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0c "FAIL" & set STATUS=FAIL)
call :log
if not "%STATUS%" == "PASS" call :startnessusauditfinding
call :set
goto :eof

:functionCompareTxtEvtRetEXACT
set TEST=%1
set EXPECTED=%2
set LOG=%3
set KEY="wevtutil gl %LOG% | findstr retention"
echo Expect: %EXPECTED%
wevtutil gl %LOG% | findstr retention > %TEMPDIRECTORY%\%TEST%.txt
set /p ACTUAL= < %TEMPDIRECTORY%\%TEST%.txt
echo Actual: "%ACTUAL%"
if "%ACTUAL%" == %EXPECTED% (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0c "FAIL" & set STATUS=FAIL)
call :log
if not "%STATUS%" == "PASS" call :startnessusauditfinding
call :set
goto :eof

REM Colours Function
:ColourText
cd %TEMPDIRECTORY%
<nul set /p ".=%DEL%" > "%~2"
echo|set /p="Status: "
findstr /v /a:%1 /R "^$" "%~2" nul
echo.
del "%~2" > nul 2>&1
cd ..
goto :eof

REM Nessus Canopy Generation
:startnessusheader
echo ^<?xml version="1.0" ?^> >%computername%.nessus
echo ^<LolCheckz^> >>%computername%.nessus
echo ^<Report name="%computername%" xmlns:cm="http://www.nessus.org/cm" ^> >>%computername%.nessus
echo ^<ReportHost name="%computername%"^>^<HostProperties^> >>%computername%.nessus
echo ^</HostProperties^> >>%computername%.nessus
:endnessusheader
goto :eof

:startnessustxtfinding
set PLUGINID=%TEST:"=%
echo ^<ReportItem port="0" svc_name="" protocol="" severity="0" pluginID="Lolz_%PLUGINID%" pluginName=%TEST% pluginFamily="Windows"^> >>%computername%.nessus
echo ^<description^>There's an issue with the %TEST% settings on the host. Please modify the settings for %TEST%^</description^> >>%computername%.nessus
echo ^<plugin_type^>remote^</plugin_type^> >>%computername%.nessus
echo ^<risk_factor^>Low^</risk_factor^> >>%computername%.nessus
echo ^<solution^>CCS Recommends fixing the issues with %TEST% on the host^</solution^> >>%computername%.nessus
echo ^<synopsis^>There's an issue with the %TEST% settings on the host^</synopsis^> >>%computername%.nessus
echo ^<plugin_output^>The following information has been gathered: >>%computername%.nessus
echo.  >>%computername%.nessus
echo Location: %KEY%  >>%computername%.nessus
echo Expect: %EXPECTED%  >>%computername%.nessus
echo Actual: "%ACTUAL%"  >>%computername%.nessus
echo Status: %STATUS%  >>%computername%.nessus
if "%NOT%" == "TRUE" echo SHOULD NOT BE EXPECTED VALUE  >>%computername%.nessus
echo ^</plugin_output^> >>%computername%.nessus
echo ^</ReportItem^> >>%computername%.nessus
:endnessusfinding
goto :eof

:startnessusregfinding
set PLUGINID=%TEST:"=%
set EXPECTED=%EXPECTED:"=%
set ACTUAL=%ACTUAL:    = %
set EXPECTED=%EXPECTED:    = %
if "%ACTUAL%" == "    = " set ACTUAL= Not Set 
echo ^<ReportItem port="0" svc_name="" protocol="" severity="0" pluginID="Lolz_%PLUGINID%" pluginName=%TEST% pluginFamily="Windows"^> >>%computername%.nessus
echo ^<description^>There's an issue with the %TEST% settings on the host. Please modify the settings for %TEST%^</description^> >>%computername%.nessus
echo ^<plugin_type^>remote^</plugin_type^> >>%computername%.nessus
echo ^<risk_factor^>Low^</risk_factor^> >>%computername%.nessus
echo ^<solution^>CCS Recommends fixing the issues with %TEST% on the host^</solution^> >>%computername%.nessus
echo ^<synopsis^>There's an issue with the %TEST% settings on the host^</synopsis^> >>%computername%.nessus
echo ^<plugin_output^>The following information has been gathered: >>%computername%.nessus
echo.  >>%computername%.nessus
echo Location: %KEY%  >>%computername%.nessus
echo Expect:%EXPECTED%  >>%computername%.nessus
echo Actual:%ACTUAL%  >>%computername%.nessus
echo Status: %STATUS%  >>%computername%.nessus
if "%NOT%" == "TRUE" echo SHOULD NOT BE EXPECTED VALUE  >>%computername%.nessus
echo ^</plugin_output^> >>%computername%.nessus
echo ^</ReportItem^> >>%computername%.nessus
:endnessusfinding
goto :eof


:startnessusauditfinding
set PLUGINID=%TEST:"=%
set EXPECTED=%EXPECTED:"=%
set ACTUAL=%ACTUAL:  = %
set EXPECTED=%EXPECTED:  = %
echo ^<ReportItem port="0" svc_name="" protocol="" severity="0" pluginID="Lolz_%PLUGINID%" pluginName=%TEST% pluginFamily="Windows"^> >>%computername%.nessus
echo ^<description^>There's an issue with the %TEST% settings on the host. Please modify the settings for %TEST%^</description^> >>%computername%.nessus
echo ^<plugin_type^>remote^</plugin_type^> >>%computername%.nessus
echo ^<risk_factor^>Low^</risk_factor^> >>%computername%.nessus
echo ^<solution^>CCS Recommends fixing the issues with %TEST% on the host^</solution^> >>%computername%.nessus
echo ^<synopsis^>There's an issue with the %TEST% settings on the host^</synopsis^> >>%computername%.nessus
echo ^<plugin_output^>The following information has been gathered: >>%computername%.nessus
echo.  >>%computername%.nessus
echo Location: %KEY%  >>%computername%.nessus
echo Expect:%EXPECTED%  >>%computername%.nessus
echo Actual:%ACTUAL%  >>%computername%.nessus
echo Status: %STATUS%  >>%computername%.nessus
if "%NOT%" == "TRUE" echo SHOULD NOT BE EXPECTED VALUE  >>%computername%.nessus
echo ^</plugin_output^> >>%computername%.nessus
echo ^</ReportItem^> >>%computername%.nessus
:endnessusfinding
goto :eof

:startnessusfindingreadtxt
if "%NULLSID%" == "TRUE" call :startaccountdomainnotfoundstringreplace
set PLUGINID=%TEST:"=%
echo ^<ReportItem port="0" svc_name="" protocol="" severity="0" pluginID="Lolz_%PLUGINID%" pluginName=%TEST% pluginFamily="Windows"^> >>%computername%.nessus
echo ^<description^>There's an issue with the %TEST% settings on the host. Please modify the settings for %TEST%^</description^> >>%computername%.nessus
echo ^<plugin_type^>remote^</plugin_type^> >>%computername%.nessus
echo ^<risk_factor^>Low^</risk_factor^> >>%computername%.nessus
echo ^<solution^>CCS Recommends fixing the issues with %TEST% on the host^</solution^> >>%computername%.nessus
echo ^<synopsis^>There's an issue with the %TEST% settings on the host^</synopsis^> >>%computername%.nessus
echo ^<plugin_output^>The following information has been gathered: >>%computername%.nessus
echo.  >>%computername%.nessus
echo Location: %KEY%  >>%computername%.nessus
if not "%STATUS%" == "CHECK OUTPUT" echo Expect: %EXPECTED%  >>%computername%.nessus
if not "%STATUS%" == "CHECK OUTPUT" echo Actual: "%ACTUAL%"  >>%computername%.nessus
echo Status: %STATUS%  >>%computername%.nessus
if "%NOT%" == "TRUE" echo SHOULD NOT BE EXPECTED VALUE  >>%computername%.nessus
type %FILE% >>%computername%.nessus
echo ^</plugin_output^> >>%computername%.nessus
echo ^</ReportItem^> >>%computername%.nessus
:endnessusfindingreadtxt
goto :eof

:startnessusfooter
echo ^</ReportHost^>  >>%computername%.nessus
echo ^</Report^>  >>%computername%.nessus
echo ^</LolCheckz^>  >>%computername%.nessus
:endnessusfooter
goto :eof

:startaccountdomainnotfoundstringreplace
set "search=^<Account Domain not found^>"
set "replace=^&lt;Account Domain not found^&gt;"

    setlocal enableextensions disabledelayedexpansion
    set "textFile=%FILE%"
    for /f "delims=" %%i in ('type "%textFile%" ^& break ^> "%textFile%" ') do (
        set "line=%%i"
        setlocal enabledelayedexpansion
        >>"%textFile%" echo(!line:%search%=%replace%!
        endlocal
    )
:endaccountdomainnotfoundstringreplace
goto :eof

:startchecks
echo Checking security configuration of local computer

echo Generating .nessus header for Canopy
call :startnessusheader

echo Exporting Security Policy to File
secedit.exe /export /cfg %TEMPDIRECTORY%\sec.txt > NUL
echo.

REM Checking if domain joined
wmic computersystem get domainrole | findstr -i -v DomainRole > %TEMPDIRECTORY%\domainrole.txt
set /p DomainRole= < %TEMPDIRECTORY%\domainrole.txt

echo.
echo ====OS:
echo.
echo Hostname:
wmic computersystem get name | findstr /v Name
echo NOTES: Provides the hostname of the system
echo IP Addreses:
wmic nicconfig get ipaddress | findstr {
echo NOTES: Provides a list of IPv4 and IPv6 IP addresses on the system
echo.
echo OS Version and Service Pack Level:
wmic os get caption,version,ServicePackMajorVersion | findstr /v Caption
echo NOTES: Provides the name and version of Windows installed on the host
echo.
echo Installed Patches:
wmic qfe | findstr /v Caption
echo NOTES: Treat the above check with caution. On some systems (eg. Windows 10) nothing is reported for the above query even when additonal patches have been installed)
echo.
echo Anti-Virus Installed:
wmic /Namespace:\\root\SecurityCenter2 Path AntiVirusProduct Get displayName | findstr -v displayName
echo NOTES: Treat the above check with caution. On some systems (eg. Server 2016) nothing is reported for the above query even if Windows Defender is installed)

echo.
echo ====Password policy (local):
echo.
echo Password history (KB262):
call :functionCompareTxtNUMATLEASTRANGE "PasswordHistorySize" "PasswordHistorySize = 24" "PasswordHistorySize = 10"
echo NOTES: Should be at least expected value
echo.
echo Maximum password age (KB262):
call :functionCompareTxtNUMLESSTHANORWARN "MaximumPasswordAge" "MaximumPasswordAge = 0"
echo NOTES: Should be at less than or equal to expected value, otherwise warn. Password expiration no longer recommended. 
echo.
echo Minimum password age (KB262):
call :functionCompareTxtEXACT "MinimumPasswordAge" "MinimumPasswordAge = 1"
echo NOTES: Should be expected value
echo.
echo Minimum password length (KB262):
call :functionCompareTxtNUMATLEASTRANGE "MinimumPasswordLength" "MinimumPasswordLength = 12" "MinimumPasswordLength = 8"
echo NOTES: Should be at least expected value. Warn for less than 12. Fail for less than 8. 
echo.
echo Password complexity (KB262):
call :functionCompareTxtNUMLESSTHANORWARN "PasswordComplexity" "PasswordComplexity = 0"
echo NOTES: Should be expected value. Password complexity enforcement no longer recommended. 
echo.
echo Store Passwords using Reversible Encryption (KB262):
call :functionCompareTxtEXACT "ClearTextPassword" "ClearTextPassword = 0"
echo NOTES: Should be expected value
echo.


echo.
echo ====Account lockout policy (local):
echo.
echo Lockout duration (KB263):
call :functionCompareTxtNUMATLEASTEXCEPT "LockoutDuration" "LockoutDuration = 15" "LockoutDuration = -1"
echo NOTES: Should be at least expected value, or alternatively -1.
echo.
echo Lockout threshold (KB263):
call :functionCompareTxtNUMLESSTHANEXCEPT "LockoutBadCount" "LockoutBadCount = 15" "LockoutBadCount = 0"
echo NOTES: Should be less than or equal to expected value, but not 0
echo.
echo Account reset time (KB263):
set ResetLockoutCountEXPECTED=ResetLockoutCount = 15
call :functionCompareTxtNUMATLEAST "ResetLockoutCount" "ResetLockoutCount = 15"
echo NOTES: Should be at least expected value
echo.


echo.
echo ====Security Options (local):
echo.
echo Rename Administrator account (KB309):
call :functionCompareTxtNOT "NewAdministratorName" "NewAdministratorName = "Administrator""
echo NOTES: Should NOT be expected value
echo.
echo Rename Guest account:
call :functionCompareTxtNOT "NewGuestName" "NewGuestName = "Guest""
echo NOTES: Should NOT be expected value
echo.
echo Administrator account status
call :functionCompareTxtEXACT "EnableAdminAccount" "EnableAdminAccount = 0"
echo NOTES: Should be expected value
net user administrator | findstr active
echo NOTES: Account should be disabled, this is the actual current value (as opposed to policy settings)
echo.
echo Guest account status
call :functionCompareTxtEXACT "EnableGuestAccount" "EnableGuestAccount = 0"
echo NOTES: Should be expected value
net user guest | findstr active
echo NOTES: NOTES: Account should be disabled, this is the actual current value (as opposed to policy settings)
echo.
echo Network Access: Allow Anonymous SID/Name Translation:
call :functionCompareTxtEXACT "LSAAnonymousNameLookup" "LSAAnonymousNameLookup = 0"
echo NOTES: Should be expected value
echo.
echo Interactive Logon: Do Not Display Last User Name (KB308):
call :functionCompareRegEXACT "dontdisplaylastusername" "    dontdisplaylastusername    REG_DWORD    0x1" "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System"
echo NOTES: Should be expected value
echo.
echo Interactive Logon: Do Not require CTRL + ALT + DEL:
call :functionCompareRegNOT "DisableCAD" "    DisableCAD    REG_DWORD    0x1" "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System"
echo NOTES: This is often not set, so may error. This value should NOT be set to 0x1
echo.
echo Interactive Logon: Number of Previous Logons to Cache (KB282):
call :functionCompareRegEXACT "CachedLogonsCount" "    CachedLogonsCount    REG_SZ    0" "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
echo NOTES: Should be expected value
echo.
echo Interactive Logon: Message Text for Users Attempting to Log On (KB467):
call :functionCompareRegNOT "legalnoticetext" "    legalnoticetext    REG_SZ    " "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System"
echo NOTES: Should contain some value
echo.
echo Interactive Logon: Message Title for Users Attempting to Log On (KB467):
call :functionCompareRegNOT "legalnoticecaption" "    legalnoticecaption    REG_SZ    " "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System"
echo NOTES: Should contain some value
echo.
echo Network access: Restrict anonymous access to Named Pipes and Shares (KB81):
call :functionCompareRegEXACT "RestrictNullSessAccess" "    RestrictNullSessAccess    REG_DWORD    0x1" "HKLM\System\CurrentControlSet\Services\LanManServer\Parameters"
echo NOTES: Should be expected value
echo.

echo Network Access: Shares that can be accessed anonymously:
call :functionCompareRegEXACTORNOTSET "NullSessionShares" "    NullSessionShares    REG_MULTI_SZ    " "HKLM\System\CurrentControlSet\Services\LanManServer\Parameters"
echo NOTES: This is often not set, so may error. This value should always be empty

echo.
echo Network Access: Do not allow Anonymous Enumeration of SAM Accounts (KB81):
call :functionCompareRegEXACT "RestrictAnonymous" "    RestrictAnonymous    REG_DWORD    0x1" "HKLM\System\CurrentControlSet\Control\Lsa"
echo NOTES: Should be expected value
echo.
echo Network Access: Do not allow Anonymous Enumeration of SAM Accounts and Shares:
call :functionCompareRegEXACT "RestrictAnonymousSAM" "    RestrictAnonymousSAM    REG_DWORD    0x1" "HKLM\System\CurrentControlSet\Control\Lsa"
echo NOTES: Should be expected value
echo.
echo Network Security: Do not store LAN Manager password hash value on next password change (KB510):
call :functionCompareRegEXACT "NoLMHash" "    NoLMHash    REG_DWORD    0x1" "HKLM\System\CurrentControlSet\Control\Lsa"
echo NOTES: Should be expected value
echo.

echo Network Security: LAN Manager Authentication Level (KB436):
REM NONFUNCTION
set TEST="LmCompatibilityLevel"
set EXPECTED="    LmCompatibilityLevel    REG_DWORD    0x5"
set KEY=HKLM\System\CurrentControlSet\Control\Lsa
echo Expect: %EXPECTED%
reg query %KEY% /v %TEST%  | findstr /i %TEST% > %TEMPDIRECTORY%\%TEST%.txt
set /p ACTUAL= < %TEMPDIRECTORY%\%TEST%.txt
echo Actual: "%ACTUAL%"
if "%ACTUAL%" == %EXPECTED% (call :ColourText 0a "PASS" & set STATUS=PASS) else if "%ACTUAL%" =="    LmCompatibilityLevel    REG_DWORD    0x4" (call :ColourText 0e "WARN"  & set STATUS=WARN) else if "%ACTUAL%" =="    LmCompatibilityLevel    REG_DWORD    0x3" (call :ColourText 0e "WARN"  & set STATUS=WARN) else (call :ColourText 0c "FAIL" & set STATUS=FAIL)
call :log
if not "%STATUS%" == "PASS" call :startnessusregfinding
call :set
echo NOTES: Should be at least 0x3, ideally 0x5
echo.


echo.
echo ====Auditing (KB438):
echo.
echo Audit account logon events:
call :functionCompareTxtNUMATLEAST "AuditAccountLogon" "AuditAccountLogon = 3"
echo NOTES: Should be at least expected value
echo.
echo Audit account management:
call :functionCompareTxtNUMATLEAST "AuditAccountManage" "AuditAccountManage = 3"
echo NOTES: Should be at least expected value
echo.
echo Audit directory service:
call :functionCompareTxtNUMATLEAST "AuditDSAccess" "AuditDSAccess = 3"
echo NOTES: Should be at least expected value
echo.
echo Audit logon events:
call :functionCompareTxtNUMATLEAST "AuditLogonEvents" "AuditLogonEvents = 3"
echo NOTES: Should be at least expected value
echo.
echo Audit object access:
call :functionCompareTxtNUMATLEAST "AuditObjectAccess" "AuditObjectAccess = 3"
echo NOTES: Should be at least expected value
echo.
echo Audit policy change:
call :functionCompareTxtNUMATLEAST "AuditPolicyChange" "AuditPolicyChange = 3"
echo NOTES: Should be at least expected value
echo.
echo Audit privilege use
call :functionCompareTxtNUMATLEAST "AuditPrivilegeUse" "AuditPrivilegeUse = 2"
echo NOTES: Should be at least expected value
echo.
echo Audit process tracking:
call :functionCompareTxtNUMATLEAST "AuditProcessTracking" "AuditProcessTracking = 2"
echo NOTES: Should be at least expected value
echo.
echo Audit system events:
call :functionCompareTxtNUMATLEAST "AuditSystemEvents" "AuditSystemEvents = 2"
echo NOTES: Should be at least expected value
echo.

if %win2003% EQU TRUE goto :skip2003
echo.
echo ====Advanced Auditing (KB438):
echo.
echo Audit Policy: System: IPsec Driver:
call :functionCompareAuditPolTxtEXACT "IPSecDriver" "  IPsec Driver                            Success and Failure" "IPsec Driver"
echo NOTES: Should be at least expected value
echo.
echo Audit Policy: System: Security State Change:
call :functionCompareAuditPolTxtEXACT "SecurityStateChange" "  Security State Change                   Success and Failure" "Security State Change"
echo NOTES: Should be at least expected value
echo.
echo Audit Policy: System: Security System Extension:
call :functionCompareAuditPolTxtEXACT "SecuritySystemExtension" "  Security System Extension               Success and Failure" "Security System Extension"
echo NOTES: Should be at least expected value
echo.
echo Audit Policy: System: System Integrity:
call :functionCompareAuditPolTxtEXACT "SystemIntegrity" "  System Integrity                        Success and Failure" "System Integrity"
echo NOTES: Should be at least expected value
echo.

echo Audit Policy: Logon-Logoff: Logoff:
call :functionCompareAuditPolLogOnOffSubTxtEXACTOR "Logoff" "  Logoff                                  Success" "Logoff" "  Logoff                                  Success and Failure"
echo NOTES: Should be at least expected value
echo.
echo Audit Policy: Logon-Logoff: Logon:
call :functionCompareAuditPolLogOnOffSubTxtEXACT "Logon" "  Logon                                   Success and Failure" "Logon"
echo NOTES: Should be at least expected value
echo.

echo Audit Policy: Logon-Logoff: Special Logon:
call :functionCompareAuditPolTxtEXACTOR "SpecialLogon" "  Special Logon                           Success" "Special Logon" "  Special Logon                           Success and Failure"
echo NOTES: Should be at least expected value
echo.
echo Audit Policy: Object Access: File System:
call :functionCompareAuditPolTxtEXACTOR "FileSystem" "  File System                             Failure" "File System" "  File System                             Success and Failure"
echo NOTES: Should be at least expected value
echo.
echo Audit Policy: Object Access: Registry:
call :functionCompareAuditPolTxtEXACTOR "Registry" "  Registry                                Failure" "Registry" "  Registry                                Success and Failure"
echo NOTES: Should be at least expected value
echo.
echo Audit Policy: Privilege Use: Sensitive Privilege Use:
REM Filthy fix here by adding 2 spaces to 3rd parameter, to avoid it finding 'Non Sensitive Privilege Use' first. It works, so who cares :)
call :functionCompareAuditPolTxtEXACT "SensitivePrivilegeUse" "  Sensitive Privilege Use                 Success and Failure" "  Sensitive Privilege Use"
echo NOTES: Should be at least expected value
echo.
echo Audit Policy: Detailed Tracking: Process Creation:
call :functionCompareAuditPolTxtEXACTOR "ProcessCreation" "  Process Creation                        Success" "Process Creation" "  Process Creation                        Success and Failure"
echo NOTES: Should be at least expected value
echo.
echo Audit Policy: Policy Change: Audit Policy Change:
call :functionCompareAuditPolTxtEXACT "AuditPolicyChange" "  Audit Policy Change                     Success and Failure" "Audit Policy Change"
echo NOTES: Should be at least expected value
echo.
echo Audit Policy: Policy Change: Authentication Policy Change:
call :functionCompareAuditPolTxtEXACTOR "AuthenticationPolicyChange" "  Authentication Policy Change            Success" "Authentication Policy Change" "  Authentication Policy Change            Success and Failure"
echo NOTES: Should be at least expected value
echo.
echo Audit Policy: Account Management: Computer Account Management:
call :functionCompareAuditPolTxtEXACT "ComputerAccountManagement" "  Computer Account Management             Success and Failure" "Computer Account Management"
echo NOTES: Should be at least expected value
echo.
echo Audit Policy: Account Management: Other Account Management Events:
call :functionCompareAuditPolTxtEXACT "Other Account Management Events" "  Other Account Management Events         Success and Failure" "Other Account Management Events"
echo NOTES: Should be at least expected value
echo.
echo Audit Policy: Account Management: Security Group Management
call :functionCompareAuditPolTxtEXACT "SecurityGroupManagement" "  Security Group Management               Success and Failure" "Security Group Management"
echo NOTES: Should be at least expected value
echo.
echo Audit Policy: Account Management: User Account Management:
call :functionCompareAuditPolTxtEXACT "UserAccountManagement" "  User Account Management                 Success and Failure" "User Account Management"
echo NOTES: Should be at least expected value
echo.
echo Audit Policy: Account Logon: Credential Validation:
call :functionCompareAuditPolTxtEXACT "CredentialValidation" "  Credential Validation                   Success and Failure" "Credential Validation"
echo NOTES: Should be at least expected value
echo.


echo.
echo ====Event Logging:
echo.
echo Application Event Log Maximum Size:
call :functionCompareTxtEvtNUMATLEAST "AppmaxSize" "  maxSize: 16777216" Application
echo NOTES: Value should be at least the value of maxSize
echo.
echo Application Log Retention Method:
call :functionCompareTxtEvtRetEXACT "AppLogRetention" "  retention: false" Application
echo NOTES: Retention should be false to ensure event log rollover
echo.
echo Security Event Log Maximum Size (KB449):
call :functionCompareTxtEvtNUMATLEAST "SecmaxSize" "  maxSize: 83886080" Security
echo NOTES: Value should be at least the value of maxSize
echo.
echo Security Log Retention Method:
call :functionCompareTxtEvtRetEXACT "SecLogRetention" "  retention: false" Security
echo NOTES: Retention should be false to ensure event log rollover
echo.
echo System Event Log Maximum Size:
set SysmaxSizeEXPECTED=  maxSize: 16777216
call :functionCompareTxtEvtNUMATLEAST "SysmaxSize" "  maxSize: 16777216" System
echo NOTES: Value should be at least the value of maxSize
echo.
echo System Log Retention Method:
call :functionCompareTxtEvtRetEXACT "SysLogRetention" "  retention: false" System
echo NOTES: Retention should be false to ensure event log rollover
echo.

echo ====Event Log forwarding (KB468):
REM NONFUNCTION
set TEST="eventlogforward"
SET KEY="sc query Wecsvc | findstr STATE"
set EXPECTED="        STATE              : 4  RUNNING "
echo Expect: %EXPECTED%
sc query Wecsvc | findstr STATE > %TEMPDIRECTORY%\%TEST%.txt
set /p ACTUAL= < %TEMPDIRECTORY%\%TEST%.txt
echo Actual: "%ACTUAL%"
if "%ACTUAL%" == %EXPECTED% (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0e "WARN" & set STATUS=WARN)
call :log
if not "%STATUS%" == "PASS" call :startnessusauditfinding
call :set
echo NOTES: Basic check to see if event logs are forwarded to collector or SIEM. This doesn't check 3rd party solutions
echo NOTES: This only checks whether the forwarder service is running, it doesn't go deeper than that
:skip2003

echo.
REM NONFUNCTION
echo ====Group Memberships (KB232):
set TEST="localadmins"
set FILE=%TEMPDIRECTORY%\localadmins.txt
set KEY="net localgroup Administrators"
set EXPECTED=""
echo.
echo Local Accounts and Groups:
net localgroup Administrators | findstr /v /c:"Alias name" /c:"Comment" /c:"Members" /c:"-------------" /c:"The command completed successfully." > %FILE%
type %FILE%
REM TODO: CHECK ACCOUNTS IF ACTIVE, MAYBE USE WMI? ALSO SHOULD CHECK DOMAIN USERS IF IN DOMAIN
(call :ColourText 09 "CHECK OUTPUT" & set STATUS=CHECK OUTPUT)
call :log
if not "%STATUS%" == "PASS" call :startnessusfindingreadtxt
call :set
echo NOTES: This currently does not check domain users for active accounts
echo.


echo.
echo ====Shares:
REM NONFUNCTION
REM TODO: NOT CHECKING SHARES WITH SPACES IN PATH DUE TO ISSUES WITH WMIC OUTPUT
echo.
echo ====Shares and Permissions (KB519):
set TEST="sharesandpermissions"
set FILE=%TEMPDIRECTORY%\sharesoutput.txt
set KEY="wmic share get Name,Path"
set NULLSID=TRUE
set EXPECTED=""
wmic share WHERE "NOT Caption like 'Remote Admin' AND NOT Caption like 'Default share' AND NOT Caption like 'Remote IPC' AND NOT Path like '%% %%'" get Name,path | findstr /v Name > %TEMPDIRECTORY%\sharestemp.txt
type %TEMPDIRECTORY%\sharestemp.txt | findstr . > %TEMPDIRECTORY%\shares.txt
for /f "tokens=1,2" %%a in (%TEMPDIRECTORY%\shares.txt) do echo Share Name: %%a  >> %FILE% & cacls %%b >> %FILE% & echo. >> %FILE%
set /p SHARES= < %TEMPDIRECTORY%\shares.txt
echo.
type %FILE%
if "%SHARES%" == "" (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 09 "CHECK OUTPUT" & set STATUS=CHECK OUTPUT)
call :log
if not "%STATUS%" == "PASS" call :startnessusfindingreadtxt
call :set
echo NOTES: Check share NTFS and share permissions for weak ACLs. Ideally this value will be empty


echo.
echo ====Permissions:
if exist %systemroot%\system32\icacls.exe (set acls=icacls.exe) else (set acls==cacls.exe)
REM NONFUNCTION
echo.
echo PATH Permissions (KB470):
set TEST="pathpermissions"
set FILE=%TEMPDIRECTORY%\pathperms.txt
set KEY="cacls [paths]"
set NULLSID=TRUE
set EXPECTED=""
for %%A in ("%path:;=";"%") do cacls "%%~A" >> %FILE%
type %FILE%
(call :ColourText 09 "CHECK OUTPUT" & set STATUS=CHECK OUTPUT)
call :log
if not "%STATUS%" == "PASS" call :startnessusfindingreadtxt
call :set
echo NOTES: Check for weak permissions on folders in PATH variable

echo .
echo Drive Permissions (KB516):
set TEST="drivepermissions"
set FILE=%TEMPDIRECTORY%\driveperms.txt
set KEY="%acls% [drive]:\"
set NULLSID=TRUE
set EXPECTED=""
for %%B in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (if exist %%B:\ (%acls% %%B:\ >> %FILE%))
type %FILE%
echo.
(call :ColourText 09 "CHECK OUTPUT" & set STATUS=CHECK OUTPUT)
call :log
if not "%STATUS%" == "PASS" call :startnessusfindingreadtxt
call :set
echo NOTES: Check for weak permissions on drive root folder
echo.

echo.
echo ====Firewall (KB237):
REM NONFUNCTION
set TEST="windowsfirewall"
set FILE=%TEMPDIRECTORY%\windowsfirewall.txt
set KEY="netsh advfirewall monitor show firewall | findstr /c:Profile /c:State | findstr -v Stateful"
set EXPECTED="State                                 ON"
echo.
echo Firewall status:
echo Expect: State                                 ON
netsh advfirewall monitor show firewall | findstr /c:Profile /c:State | findstr -v Stateful > %FILE%
echo.>> %FILE%
echo Active Profile(s): >> %FILE%
netsh advfirewall monitor show current | findstr /v /c:Ok. /c:- | findstr . >> %FILE%
type %FILE%
echo.
findstr OFF %FILE% > nul
if errorlevel 1 (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0c "FAIL" & set STATUS=FAIL & set ACTUAL=State                                 OFF)
call :log
if not "%STATUS%" == "PASS" call :startnessusfindingreadtxt
call :set
echo NOTES: Firewall Should be enabled for all profiles, double check with 'wf.msc'
echo.

echo.
echo ======WSUS Settings (KB305):
REM NONFUNCTION
set TEST="WSUS"
set FILE=%TEMPDIRECTORY%\WSUS.txt
SET KEY="HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate"
set EXPECTED=""
echo.
echo ====WSUS status:
reg query "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" | findstr /v /i /c:"WindowsUpdate\AU" > %FILE%
type %FILE%
findstr WindowsUpdate %FILE% > NUL
if %errorlevel% == 0 (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0e "CHECK OUTPUT" & set STATUS=CHECK OUTPUT)
call :log
if not "%STATUS%" == "PASS" echo Host does not appear to be using WSUS
call :set
echo.
echo ====WSUS Using HTTPS:
set TEST="WSUSHTTPS"
set FILE=%TEMPDIRECTORY%\WSUS.txt
SET KEY="HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate"
set EXPECTED=""
findstr /c:"http://" %FILE%
if errorlevel 1 (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0c "FAIL" & set STATUS=FAIL & set EXPECTED="https" & set ACTUAL=http)
call :log
if not "%STATUS%" == "PASS" call :startnessusfindingreadtxt
call :set
echo NOTES: Keys should be present if using WSUS. WSUS server should be HTTPS
echo.
echo.
echo ====WSUS Service Running:
set TEST="WSUSDisabled"
set FILE=%TEMPDIRECTORY%\WSUSDisabled.txt
SET KEY="wmic service where 'name like "wuauserv"' get startmode"
set EXPECTED="NOT Disabled"
wmic service where 'name like "wuauserv"' get startmode | findstr -v StartMode | findstr . > %FILE%
findstr /v Disabled %FILE%
if %errorlevel% == 0 (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0c "FAIL" & set STATUS=FAIL & set ACTUAL=Disabled)
call :log
if not "%STATUS%" == "PASS" call :startnessusfindingreadtxt
call :set
echo NOTES: The wuauserv service should NOT be disabled
echo.

echo ====IIS Passwords (KB631):
set FILE=%TEMPDIRECTORY%\IISPasswords.txt
set TEST="IISPasswords"
set KEY="%systemroot%\system32\inetsrv\appcmd.exe list [apppool/site/vdir] /text:*"
set EXPECTED=""
if exist %systemroot%\system32\inetsrv\appcmd.exe (
echo.
REM NONFUNCTION
echo.
%systemroot%\system32\inetsrv\appcmd.exe list apppool /text:* | findstr "userName password" > %FILE%
%systemroot%\system32\inetsrv\appcmd.exe list site /text:* | findstr "userName password" >> %FILE%
%systemroot%\system32\inetsrv\appcmd.exe list vdir /text:* | findstr "userName password" >> %FILE%
type %FILE%
(call :ColourText 09 "CHECK OUTPUT" & set STATUS=CHECK OUTPUT)
call :log
if not "%STATUS%" == "PASS" call :startnessusfindingreadtxt
echo NOTES: Check for domain user passwords that could be used elsewhere
echo.) else (
echo.
echo IIS Tools not found
call :ColourText 0a "PASS"
echo.)
call :set

echo ====IIS Sites Permissions (KB518):
set TEST="IISPermissions"
set FILE=%TEMPDIRECTORY%\IISPermissions.txt
set KEY="cacls [paths]"
set NULLSID=TRUE
set EXPECTED=""
if exist %systemroot%\system32\inetsrv\appcmd.exe (
echo.
REM NONFUNCTION
echo.
echo Listing Sites:
echo.
%systemroot%\system32\inetsrv\appcmd.exe list app /xml | %systemroot%\system32\inetsrv\appcmd.exe list vdir /in /text:APP.NAME
echo.
echo Getting Permissions:
echo.
%systemroot%\system32\inetsrv\appcmd.exe list app /xml | %systemroot%\system32\inetsrv\appcmd.exe list vdir /in /text:physicalPath > %TEMPDIRECTORY%\sitespaths.txt
for /f "tokens=*"  %%D in (%TEMPDIRECTORY%\sitespaths.txt) do (echo cacls "%%D" >> %TEMPDIRECTORY%\caclssites.cmd)
call %TEMPDIRECTORY%\caclssites.cmd > %FILE%
type %FILE%
(call :ColourText 09 "CHECK OUTPUT" & set STATUS=CHECK OUTPUT)
call :log
if not "%STATUS%" == "PASS" call :startnessusfindingreadtxt
echo NOTES: Check for weak permissions, such as 'Users' group present
echo.) else (
echo.
echo IIS Tools not found
call :ColourText 0a "PASS"
echo.)
call :set


echo.
echo ====Unquoted Service Paths (KB222):
REM NONFUNCTION
set TEST="unquotedservicepaths"
set FILE=%TEMPDIRECTORY%\unquotedservicepaths.txt
set KEY="wmic service"
set EXPECTED=""
echo.
set windirwmi=%windir:\=\\%
wmic service WHERE "NOT PathName like '%%PROGRA~%%\\%%' AND NOT PathName like '"%%"%%' AND PathName like '%% %%' AND NOT PathName like '%windirwmi%\\%%'" get name,displayname,pathname | findstr /v DisplayName | findstr /v DisplayName > %FILE%
findstr ":" %FILE%
if errorlevel 1 (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0c "FAIL" & set STATUS=FAIL & set EXPECTED="No Services should be listed" & set ACTUAL=Services listed)
call :log
if not "%STATUS%" == "PASS" call :startnessusfindingreadtxt
call :set
echo NOTES: No services should be listed here
echo.

echo ====WDigest Registry Key (KB504):
REM check for presence of wdigest key set to 1 = fail
call :functionCompareRegNOT "UseLogonCredential" "    UseLogonCredential    REG_DWORD    0x1" "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest"
REM if Pre2012r2, check if key set to 0x0
for /f %%i in ('wmic os get version ^| findstr . ^| findstr /v Version') do set version=%%i
echo %version% | findstr "10 6.3" > NUL
if errorlevel 1 (set pre2012r2=true) else (set pre2012r2=false)
if %pre2012r2% == true call :functionCompareRegEXACT "UseLogonCredential" "    UseLogonCredential    REG_DWORD    0x0" "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest"
echo NOTES: If before Windows 2012r2/Windows 8.1, key should be present and set to 0x0. Also requires KB2871997
echo.

echo ====AlwaysInstallElevated Registry Key:
call :functionCompareRegEXACTORNOTSET "AlwaysInstallElevated" "    AlwaysInstallElevated    REG_DWORD    0x0" "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer"
echo NOTES: Should always be empty, so normally this check will error. Note only the HKLM key has been checked for this issue.
echo.


echo ====Remote Desktop NLA (KB422):
REM PARTIAL NONFUNCTION
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections | findstr /i fDenyTSConnections > %TEMPDIRECTORY%\fDenyTSConnections.txt
set /p fDenyTSConnections= < %TEMPDIRECTORY%\fDenyTSConnections.txt
echo %fDenyTSConnections% | findstr "0x1" > NUL
if errorlevel 1 (echo Terminal Services Enabled & goto CheckNLA) else (echo Terminal Services Not Enabled & goto SkipNLA)
:CheckNLA
call :functionCompareRegEXACT "UserAuthentication" "    UserAuthentication    REG_DWORD    0x1" "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
goto RDPEnd
:SkipNLA
(call :ColourText 0a "PASS" & set STATUS=PASS)
:RDPEnd
echo NOTES: Should be set to 0x1 if Terminal Services is enabled. Bear this in mind if value does not match expected value
echo NOTES: I've also found this to be problematic on some hosts, so check the gui using 'control.exe sysdm.cpl,,5'
echo.


echo.
echo ======Software Restriction Policies and AppLocker (KB430 + KB450):
echo.
REM NONFUNCTION
set TEST="SRPAppLocker"
set FILE=%TEMPDIRECTORY%\SRPAppLocker.txt
set EXPECTED=""
set KEY="HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\safer\codeidentifiers\0 and HKEY_LOCAL_Machine\Software\Policies\Microsoft\Windows\SrpV2"
echo ====Software Restriction Policies:
reg query HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\safer\codeidentifiers\0 >> %FILE%
if errorlevel 1 (echo SRP Not Enabled & set srp=false) else (echo SRP Enabled & set srp=true)
echo ====AppLocker:
reg query HKEY_LOCAL_Machine\Software\Policies\Microsoft\Windows\SrpV2 >> %FILE%
if errorlevel 1 (echo AppLocker Not Enabled & set applocker=false) else (echo AppLocker Enabled & set applocker=true)

if %srp% == true goto srpapplockerfound
if %applocker% == true goto srpapplockerfound
:srpapplockernotfound
(call :ColourText 0c "FAIL" & set STATUS=FAIL & set EXPECTED="SRP or AppLocker found" & set ACTUAL=SRP or AppLocker not found)
goto srpapplockerend

:srpapplockerfound
(call :ColourText 0a "PASS" & set STATUS=PASS)
:srpapplockerend
call :log
if not "%STATUS%" == "PASS" call :startnessusfindingreadtxt
call :set
echo NOTES: This is a basic check to see if SRP or AppLocker are enabled by checking for presence in the registry
echo NOTES: The policies are not enumerated, so this needs checking manually if you see PASS
echo.

echo ====NoAutoplayfornonVolume (KB680):
call :functionCompareRegEXACT "NoAutoplayfornonVolume" "    NoAutoplayfornonVolume    REG_DWORD    0x1" "HKLM\SOFTWARE\policies\Microsoft\Windows\Explorer"
echo NOTES: Should be expected value
echo.

echo ====SEHOP (KB690):
call :functionCompareRegEXACT "DisableExceptionChainValidation" "    DisableExceptionChainValidation    REG_DWORD    0x0" "HKLM\System\CurrentControlSet\Control\Session Manager\Kernel"
echo NOTES: Should be expected value
echo.

echo ====LLMNR (KB437):
call :functionCompareRegEXACT "EnableMulticast" "    EnableMulticast    REG_DWORD    0x0" "HKLM\Software\Policies\Microsoft\Windows NT\DNSClient"
echo NOTES: Should be expected value
echo.

echo ====NetBIOS Over TCP/IP (KB693):
REM NONFUNCTION
REM START PREREQ CHECK
reg query HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\NetBT\Parameters /v NodeType | findstr /i 0x2 > NUL
if %errorlevel% == 0 goto skipnetbiosovertcpip
REM END PREREQ CHECK
set TEST="NetBIOSoverTCP"
set FILE=%TEMPDIRECTORY%\NetBIOSoverTCPoutput.txt
set KEY="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces\Tcpip_[guid]"
set EXPECTED="    NetbiosOptions    REG_DWORD    0x2"
set EXPECTEDNESSUS=NetbiosOptions REG_DWORD 0x2
wmic nic where "guid like '%%'" get guid | findstr /v GUID | findstr {*} > %TEMPDIRECTORY%\netbiosovertcp.txt
for /f %%A in (%TEMPDIRECTORY%\netbiosovertcp.txt) do (
setlocal enabledelayedexpansion
echo Interface Name:
wmic nic where "guid like '%%A'" get Name | findstr /v Name
echo Interface Value:
reg query HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces\Tcpip_%%A /v NetbiosOptions | findstr NetbiosOptions > %TEMPDIRECTORY%\NetbiosOptions.txt
set /p ACTUAL= < %TEMPDIRECTORY%\NetbiosOptions.txt
echo Expect: %EXPECTED%
echo Actual: "!ACTUAL!"

set ACTUALNESSUS=!ACTUAL:    = !
echo. >> %FILE%
echo Interface Name: >> %FILE%
wmic nic where "guid like '%%A'" get Name | findstr /v Name >> %FILE%
echo Interface Value: >> %FILE%
echo Expect: %EXPECTEDNESSUS% >> %FILE%
echo Actual:!ACTUALNESSUS! >> %FILE%

if "!ACTUAL!" == %EXPECTED% (call :ColourText 0a "PASS" & echo Status: PASS >> %FILE%) else (call :ColourText 0c "FAIL" & echo Status: FAIL >> %FILE%)
echo.
endlocal
)

call :log
findstr FAIL %FILE% > NUL
if errorlevel 1 (set STATUS=PASS) else (set STATUS=FAIL & set ACTUAL=    NetbiosOptions    REG_DWORD    0x0)
if not "%STATUS%" == "PASS" call :startnessusfindingreadtxt
call :set
echo NOTES: Values should be set to 2
echo.
goto netbiosovertcpipdone

:skipnetbiosovertcpip
REM HARDCODED NONFUNCTION
set TEST="NetBIOSoverTCP"
set KEY="HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\NetBT\Parameters"
set EXPECTED="    NodeType    REG_DWORD    0x2"
set ACTUAL=    NodeType    REG_DWORD    0x2
echo EXPECT: %EXPECTED%
echo ACTUAL: "%ACTUAL%"
(call :ColourText 0a "PASS" & set STATUS=PASS)
call :log
call :set
echo NOTES: NodeType appears to be set to 0x2, skipping NetBIOS Over TCP/IP checks
echo.
:netbiosovertcpipdone


echo ====SMB Server Signing (KB78):
call :functionCompareRegEXACT "RequireSecuritySignature" "    RequireSecuritySignature    REG_DWORD    0x1" "HKLM\System\CurrentControlSet\Services\LanManServer\Parameters"
echo NOTES: Should be expected value
echo.

echo ====Require Strong (Windows 2000 or Later) Session Key:
call :functionCompareRegEXACT "RequireStrongKey" "    RequireStrongKey    REG_DWORD    0x1" "HKLM\System\CurrentControlSet\Services\Netlogon\Parameters"
echo NOTES: Should be expected value
echo.

echo ====Users Can Add Printer Drivers (KB522):
call :functionCompareRegEXACT "AddPrinterDrivers" "    AddPrinterDrivers    REG_DWORD    0x1" "HKLM\System\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers"
echo NOTES: Should be expected value
echo.
echo ====Disable HTTP Printing (KB627):
call :functionCompareRegEXACT "DisableHTTPPrinting" "    DisableHTTPPrinting    REG_DWORD    0x1" "HKLM\SOFTWARE\policies\Microsoft\windows NT\Printers"
echo NOTES: Should be expected value
echo.
echo ====Disable WebPnP Download (KB674):
call :functionCompareRegEXACT "DisableWebPnPDownload" "    DisableWebPnPDownload    REG_DWORD    0x1" "HKLM\SOFTWARE\policies\Microsoft\windows NT\Printers"
echo NOTES: Should be expected value
echo.

echo ====Print Spooler Service Disabled:
set TEST="PrintSpoolerDisabled"
set FILE=%TEMPDIRECTORY%\SpoolerDisabled.txt
SET KEY="wmic service where 'name like "spooler"' get startmode"
set EXPECTED="Disabled"
wmic service where 'name like "spooler"' get startmode | findstr -v StartMode | findstr . > %FILE%
findstr /v Disabled %FILE%
if %errorlevel% == 1 (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0c "FAIL" & set STATUS=FAIL & set ACTUAL=Enabled)
REM call :log
REM if not "%STATUS%" == "PASS" call :startnessusfindingreadtxt
if "%STATUS%" == "PASS" goto SkipRegisterSpoolerRemoteRpcEndPoint
call :set
echo.
echo ====Remote Print Spooler Registration:
call :functionCompareRegEXACT "RegisterSpoolerRemoteRpcEndPoint" "    RegisterSpoolerRemoteRpcEndPoint    REG_DWORD    0x2" "HKLM\SOFTWARE\policies\Microsoft\windows NT\Printers"
echo NOTES: Should be expected value
:SkipRegisterSpoolerRemoteRpcEndPoint
echo NOTES: The spooler service should be disabled, unless RegisterSpoolerRemoteRpcEndPoint is set to 2.
echo.

echo ====Block UNC/SMB/WebDAV DLL loading (KB668):
call :functionCompareRegEXACT "CWDIllegalInDLLSearch" "    CWDIllegalInDLLSearch    REG_DWORD    0x2" "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager"
echo NOTES: Should be expected value
echo.

echo ====Server SPN target name validation level (KB521):
call :functionCompareRegEXACT "SmbServerNameHardeningLevel" "    SmbServerNameHardeningLevel    REG_DWORD    0x2" "HKLM\System\CurrentControlSet\Services\LanManServer\Parameters"
echo NOTES: Should be at least 0x1, ideally 0x2
echo.

echo ====Localsystem NULL session fallback (KB666):
REM if not Pre2008r2, run check
for /f %%i in ('wmic os get version ^| findstr . ^| findstr /v Version') do set version=%%i
echo %version% | findstr "10 6.3 6.2" > NUL
if errorlevel 1 (set pre2008r2=true) else (set pre2008r2=false)
if %pre2008r2% == true (call :functionCompareRegEXACT "allownullsessionfallback" "    allownullsessionfallback    REG_DWORD    0x0" "HKLM\System\CurrentControlSet\Control\Lsa\MSV1_0 /v allownullsessionfallback") else (echo This option is disabled by default on the host, skipping check. & call :ColourText 0a "PASS" & set STATUS=PASS)
echo NOTES: Should be expected value depending on OS
echo NOTES: Should be set to 0 if before 2008 R2/Win 7, otherwise disabled by default
echo.

echo ====Allow LocalSystem to use computer identity for NTLM:
call :functionCompareRegEXACT "UseMachineId" "    UseMachineId    REG_DWORD    0x1" "HKLM\System\CurrentControlSet\Control\Lsa"
echo NOTES: Should be expected value
echo.

echo ====Disable TS Drive redirection (KB452):
call :functionCompareRegEXACT "fDisableCdm" "    fDisableCdm    REG_DWORD    0x1" "HKLM\SOFTWARE\policies\Microsoft\windows NT\Terminal Services"
echo NOTES: Should be expected value
echo.

echo ====Restrictions for Unauthenticated RPC Clients (KB623):
call :functionCompareRegEXACT "RestrictRemoteClients" "    RestrictRemoteClients    REG_DWORD    0x1" "HKLM\SOFTWARE\policies\Microsoft\windows NT\Rpc"
echo NOTES: Should be expected value
echo.

echo ====RDP Session host: Require Secure RPC comms (KB675):
call :functionCompareRegEXACT "fEncryptRPCTraffic" "    fEncryptRPCTraffic    REG_DWORD    0x1" "HKLM\SOFTWARE\policies\Microsoft\windows NT\Terminal Services"
echo NOTES: Should be expected value
echo.

echo ====RPC Endpoint Mapper Client Authentication (KB623):
call :functionCompareRegEXACT "EnableAuthEpResolution" "    EnableAuthEpResolution    REG_DWORD    0x1" "HKLM\SOFTWARE\policies\Microsoft\windows NT\Rpc"
echo NOTES: Should be expected value
echo.

echo ====Additional LSA Protection (KB671):
REM if not Pre2012r2, run check
for /f %%i in ('wmic os get version ^| findstr . ^| findstr /v Version') do set version=%%i
echo %version% | findstr "10 6.3" > NUL
if errorlevel 1 (set pre2012r2=true) else (set pre2012r2=false)
if %pre2012r2% == false (call :functionCompareRegEXACT "RunAsPPL" "    RunAsPPL    REG_DWORD    0x1" "HKLM\System\CurrentControlSet\Control\Lsa") else (echo This option is not supported on the host, skipping check. & call :ColourText 0a "PASS" & set STATUS=PASS)
echo NOTES: Should be expected value depending on OS
echo.

echo ====Insecure Guest SMB2 Logons (KB686):
REM if not Pre2016/win10 run check
for /f %%i in ('wmic os get version ^| findstr . ^| findstr /v Version') do set version=%%i
echo %version% | findstr "10" > NUL
if errorlevel 1 (set pre2016=true) else (set pre2016=false)
if %pre2016% == true (call :functionCompareRegEXACT "AllowInsecureGuestAuth" "    AllowInsecureGuestAuth    REG_DWORD    0x0" "HKLM\Software\Policies\Microsoft\Windows\LanmanWorkstation") else (echo This option is disabled by default on the host, skipping check. & call :ColourText 0a "PASS" & set STATUS=PASS)
echo NOTES: Should be expected value depending on OS
echo.

echo ====Winlogon Automatic Restart Sign-On ARSO (KB670):
REM if not Pre2012r2, run check
for /f %%i in ('wmic os get version ^| findstr . ^| findstr /v Version') do set version=%%i
echo %version% | findstr "10 6.3" > NUL
if errorlevel 1 (set pre2012r2=true) else (set pre2012r2=false)
if %pre2012r2% == true (call :functionCompareRegEXACT "DisableAutomaticRestartSignOn" "    DisableAutomaticRestartSignOn    REG_DWORD    0x1" "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System") else (echo This option is disabled by default on the host, skipping check. & call :ColourText 0a "PASS" & set STATUS=PASS)
echo NOTES: Should be expected value depending on OS
echo.

echo ====UAC Enabled (KB517):
REM Should be set to 1 if 2008/Win Vista and above, prior to that doesn't support UAC so still a finding
call :functionCompareRegEXACT "EnableLUA" "    EnableLUA    REG_DWORD    0x1" "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
echo NOTES: Should be expected value depending on OS
echo NOTES: Can also check in GUI in Win 7 and above using UserAccountControlSettings.exe
echo.

echo ====UAC Prompt Behaviour (KB269):
REM TODO: ADD OS LOGIC
REM Need to check OS. Should be set to 0 if 2008/Win Vista and above
call :functionCompareRegNOT "ConsentPromptBehaviorAdmin" "    ConsentPromptBehaviorAdmin    REG_DWORD    0x0" "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
echo NOTES: Should NOT be expected value
echo NOTES: Can also check in GUI in Win 7 and above using UserAccountControlSettings.exe
echo.

echo ====Password reveal option at logon (KB621):
REM if not Pre2012r2, run check
for /f %%i in ('wmic os get version ^| findstr . ^| findstr /v Version') do set version=%%i
echo %version% | findstr "10 6.3" > NUL
if errorlevel 1 (set pre2012r2=true) else (set pre2012r2=false)
if %pre2012r2% == false (call :functionCompareRegEXACT "DisablePasswordReveal" "    DisablePasswordReveal    REG_DWORD    0x1" "HKLM\Software\Policies\Microsoft\Windows\CredUI") else (echo This option is not supported on the host, skipping check. & call :ColourText 0a "PASS" & set STATUS=PASS)
echo NOTES: Should be expected value depending on OS
echo.

echo ====Non-Zero Screen Saver Grace Period (KB515):
call :functionCompareRegEXACT "ScreenSaverGracePeriod" "    ScreenSaverGracePeriod    REG_SZ    0" "HKLM\Software\Microsoft\Windows NT\CurrentVersion\winlogon"
echo NOTES: Should be expected value
echo.

REM Needs AD Tools so removing this for now, will probably use ADSI in vbscript instead when I have time.
REM Maybe use a stripped down version of https://github.com/GAThrawnMIA/Work-Scripts/blob/master/VbScript/LAPS-Password.vbs
REM echo ====Search domain for LAPS passwords:
REM dsquery * -attr name ms-MCS-AdmPwd -limit 9999999999 -filter ms-MCS-AdmPwd=*
REM echo NOTES: More AD specific, but useful for privesc if local machine is in there

if %DomainRole% == 1 goto lapsstart
if %DomainRole% == 3 goto lapsstart
goto lapsend
:lapsstart
echo ====LAPS Installed Locally (KB258):
REM NONFUNCTION
set TEST="lapsinstalledlocal"
set FILE=%TEMPDIRECTORY%\laps.txt
set LAPSDLL="c:\program files\LAPS\CSE\Admpwd.dll"
set KEY="dir "%LAPSDLL%""
set EXPECTED=""
echo dir %LAPSDLL% > %FILE%
echo. >> %FILE%
dir %LAPSDLL% >> %FILE%
dir %LAPSDLL% 2>> %FILE%
if exist %LAPSDLL% (echo LAPS Installed & call :ColourText 0a "PASS" & set STATUS=PASS) else (echo LAPS Not Installed & call :ColourText 0c "FAIL" & set STATUS=FAIL & set EXPECTED="LAPS DLL found" & set ACTUAL=LAPS DLL not found)
call :log
if not "%STATUS%" == "PASS" call :startnessusfindingreadtxt
call :set
echo NOTES: DLL should be present if installed
echo NOTES: This doesn't check whether DLL is registered however
echo.
:lapsend

if %DomainRole% == 1 goto checkdenylogonstart
if %DomainRole% == 3 goto checkdenylogonstart
goto checkdenylogonend
:checkdenylogonstart
echo ====Check Deny Logon Rights (KB479):
echo Checking denyrights
REM NONFUNCTION
set TEST="CheckDenyLogon"
set FILE=%TEMPDIRECTORY%\checkdenylogon.txt
set KEY="secedit.exe /export /cfg sec.txt &amp; type sec.txt | findstr LogonRight"
set EXPECTED=""
type %TEMPDIRECTORY%\sec.txt | findstr LogonRight > %FILE%
echo Deny Rights:
type %FILE% | findstr SeDeny > %TEMPDIRECTORY%\SeDeny.txt
type %TEMPDIRECTORY%\SeDeny.txt
echo Allow Rights:
type %FILE% | findstr -v SeDeny > %TEMPDIRECTORY%\seAllow.txt
type %TEMPDIRECTORY%\seAllow.txt
REM Sort output and merge into nessus finding:
type %TEMPDIRECTORY%\seAllow.txt > %FILE%
type %TEMPDIRECTORY%\seDeny.txt >> %FILE%
(call :ColourText 09 "CHECK OUTPUT" & set STATUS=CHECK OUTPUT)
call :log
if not "%STATUS%" == "PASS" call :startnessusfindingreadtxt
call :set
echo NOTES: Domain Admins generally should have SeDeny rights to logon locally, via terminal services, batch job, service and network
echo NOTES: Privileged accounts should NOT be able to logon to standard member servers
echo NOTES: See https://support.microsoft.com/en-gb/help/243330/well-known-security-identifiers-in-windows-operating-systems for list of well known sids
echo.
:checkdenylogonend

echo ====Checking Powershell Version (KB667):
REM NONFUNCTION
set TEST="powershellversion"
set FILE=%TEMPDIRECTORY%\psversion.txt
set KEY="powershell.exe $PSVersionTable.PSVersion.Major"
set EXPECTED="5"
if exist %SYSTEMDRIVE%\Windows\System32\WindowsPowerShell\v1.0\powershell.exe powershell.exe $PSVersionTable.PSVersion.Major > %FILE%
echo Expect: %EXPECTED%
set /p ACTUAL= < %FILE%
if "%ACTUAL%" == "" set ACTUAL=NULL
echo Actual: "%ACTUAL%"
set /a NUMEXPECTED = %EXPECTED%
set /a NUMACTUAL = %ACTUAL%
if %NUMACTUAL% GEQ %NUMEXPECTED% (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0c "FAIL" & set STATUS=FAIL)
call :log
if not "%STATUS%" == "PASS" (call :startnessustxtfinding & set powershelladditionalstart=true) else (set powershelladditionalstart=false)
call :set
echo NOTES: Should be running Powershell 5 or above
echo.

if not %powershelladditionalstart% == true (goto :powershelladditionalstart) else (goto :powershelladditionalend)
:powershelladditionalstart
echo ====Checking Powershell Version 2:
REM NONFUNCTION
set TEST="powershellversion2"
set FILE=%TEMPDIRECTORY%\psversion2.txt
set KEY="powershell.exe -version 2 $PSVersionTable.PSVersion.Major"
set EXPECTED="5"
if exist %SYSTEMDRIVE%\Windows\System32\WindowsPowerShell\v1.0\powershell.exe powershell.exe -version 2 $PSVersionTable.PSVersion.Major > %FILE%
type %FILE% | findstr /c:"Version v2.0.50727 of the .NET Framework is not installed and it is required to run version 2 of Windows PowerShell."
if errorlevel 1 (set ACTUAL=5) else (set ACTUAL=%ACTUAL%)
echo Expect: %EXPECTED%
set /p ACTUAL= < %FILE%
if "%ACTUAL%" == "" set ACTUAL=NULL
echo Actual: "%ACTUAL%"
set /a NUMEXPECTED = %EXPECTED%
set /a NUMACTUAL = %ACTUAL%
if %NUMACTUAL% GEQ %NUMEXPECTED% (call :ColourText 0a "PASS" & set STATUS=PASS) else (call :ColourText 0c "FAIL" & set STATUS=FAIL)
call :log
if not "%STATUS%" == "PASS" call :startnessustxtfinding
call :set
echo NOTES: Should NOT be able to run Powershell v2. 
echo.

echo ====PowerShell Module Logging:
call :functionCompareRegEXACT "EnableModuleLogging" "    EnableModuleLogging    REG_DWORD    0x1" "HKLM\Software\Policies\Microsoft\Windows\Powershell\ModuleLogging"
echo NOTES: Should be expected value
echo.

echo ====PowerShell Script Block Logging Logging:
call :functionCompareRegEXACT "EnableScriptBlockLogging" "    EnableScriptBlockLogging    REG_DWORD    0x1" "HKLM\Software\Policies\Microsoft\Windows\Powershell\ScriptBlockLogging"
echo NOTES: Should be expected value
echo.

echo ====PowerShell Transcription Logging:
call :functionCompareRegEXACT "EnableTranscripting" "    EnableTranscripting    REG_DWORD    0x1" "HKLM\Software\Policies\Microsoft\Windows\Powershell\Transcription"
echo NOTES: Should be expected value
echo.
:powershelladditionalend
set powershelladditionalstart=

echo ====PowerShell Execution Policy:
call :functionCompareRegNOT "ExecutionPolicy" "    ExecutionPolicy    REG_SZ    Unrestricted" "HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell"
echo NOTES: Should contain some value
echo.

if "%thirdparty%" == "TRUE" (goto 3rdparty) else (goto cleanup)
:3rdparty
echo ====Checking 3rd Party Apps:
REM NONFUNCTION
set TEST="3rdpartyapps"
set FILE=%TEMPDIRECTORY%\3rdpartyapps.txt
set KEY="where.exe /R [driveletter]:\ iexplore.exe chrome.exe firefox.exe java.exe bla.exe"
set EXPECTED=""
REM Need to test names for additional products, if missing add below
wmic process get name | findstr -v "svchost.exe winlogon.exe RuntimeBroker.exe TrustedInstaller.exe TiWorker.exe conhost.exe WmiPrvSE.exe dllhost.exe cmd.exe ShellExperienceHost.exe ctfmon.exe cmd.exe findstr.exe System smss.exe explorer.exe crss.exe SearchUI.exe ServerManager.exe sihost.exe fontdrvhost.exe rdpclip.exe smartscreen.exe LogonUI.exe mctray.exe csrss.exe dwm.exe UpdaterUI.exe tasklist.exe nlp.exe mmc.exe VSSVC.exe services.exe spoolsv.exe lsass.exe wininit.exe taskhostw.exe ApplicationFrameHost.exe MFEConsole.exe mfemms.exe mfevtps.exe mfeesp.exe mfefire.exe mfehcs.exe mfeensppl.exe mfetp.exe mfemactl.exe macompatsvc.exe macmnsvc.exe masvc.exe Taskmgr.exe cscript.exe ASMHost.exe MonitoringHost.exe HealthService.exe WindowsAzureGuestAgent WindowsAzureNetAgent.exe WindowsAzureTelemetryServ MMAExtensionHeartbeatServ WaSecAgentProv.exe WaAppAgent.exe VFPlugin.exe msdtc.exe sort.exe WMIC.exe rundll32.exe sppsvc.exe vds.exe WUDFHost.exe unsecapp.exe WmiApSrv.exe w3wp.exe mqsvc.exe powershell.exe backgroundTaskHost.exe InetMgr.exe Name Registry" > %TEMPDIRECTORY%\processes.txt
for /f %%a in (%TEMPDIRECTORY%\processes.txt) do (
<nul set /p processes=%%a 
) >> %TEMPDIRECTORY%\processes2.txt
set /p processes=<%TEMPDIRECTORY%\processes2.txt
for %%D IN (a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z) do (if exist %%D:\ echo Checking %%D:\ & where.exe /R %%D:\ iexplore.exe chrome.exe firefox.exe java.exe vpnui.exe putty.exe winscp.exe wireshark.exe 7z.exe flash.ocx acrobat.exe AcroRd32.exe SwHelper_*.exe clr.dll %processes% | findstr -v -i "Windows\WinSxS Windows\Installer" | findstr -v -i "Windows\servicing" >> %TEMPDIRECTORY%\3rdpartyfiles.txt)
for /f "delims=" %%G in (%TEMPDIRECTORY%\3rdpartyfiles.txt) do (
setlocal enabledelayedexpansion
set "line=%%G"
set "line=!line:\=\\!"
wmic datafile where Name="!line!" get Version | findstr /v Version > %TEMPDIRECTORY%\3rdpartyfile.txt
set /p Version= < %TEMPDIRECTORY%\3rdpartyfile.txt
echo File: %%G Version: !version! >> %FILE%
del %TEMPDIRECTORY%\3rdpartyfile.txt
endlocal
timeout /t 1 > NUL
)
type %FILE%
del %TEMPDIRECTORY%\3rdpartyfiles.txt
(call :ColourText 09 "CHECK OUTPUT" & set STATUS=CHECK OUTPUT)
call :log
if not "%STATUS%" == "PASS" call :startnessusfindingreadtxt
call :set
echo.


:cleanup
echo.
echo Generating .nessus footer for Canopy
call :startnessusfooter
echo Cleaning up
rd /q /s %TEMPDIRECTORY% > NUL
set DEL=
set AREYOUSURE=
set DomainRole=
set win2003=
set os=
set clientorserver=
set logdebug=
set logoutput=
set thirdparty=
set KEY=

:end
