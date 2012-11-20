REM Variables.
SETLOCAL EnableDelayedExpansion
SET FtpSiteName=%1%
SET FtpDirectory=%2%
SET PublicPort=%3%
SET DynamicPortFirst=%4%
SET DynamicPortLast=%5%
SET DynamicPortRange=%DynamicPortFirst%-%DynamicPortLast%
SET PublicIP=%6%

REM Install FTP.
start /w pkgmgr /iu:IIS-WebServerRole;IIS-FTPSvc;IIS-FTPServer;IIS-ManagementConsole

REM Create directory.
IF NOT EXIST "%FtpDirectory%" (MKDIR "%FtpDirectory%") 
cacls "%FtpDirectory%" /G IUSR:W /T /E 
cacls "%FtpDirectory%" /G IUSR:R /T /E 

REM Configuring FTP site.
pushd %windir%\system32\inetsrv 
appcmd add site /name:%FtpSiteName% /bindings:ftp://*:%PublicPort% /physicalpath:"%FtpDirectory%" 
appcmd set config -section:system.applicationHost/sites /[name='%FtpSiteName%'].ftpServer.security.ssl.controlChannelPolicy:"SslAllow" 
appcmd set config -section:system.applicationHost/sites /[name='%FtpSiteName%'].ftpServer.security.ssl.dataChannelPolicy:"SslAllow" 
appcmd set config -section:system.applicationHost/sites /[name='%FtpSiteName%'].ftpServer.security.authentication.basicAuthentication.enabled:true 
appcmd set config %FtpSiteName% /section:system.ftpserver/security/authorization /-[users='*'] /commit:apphost
appcmd set config %FtpSiteName% /section:system.ftpserver/security/authorization /+[accessType='Allow',permissions='Read,Write',roles='',users='*'] /commit:apphost
appcmd set config /section:system.ftpServer/firewallSupport /lowDataChannelPort:%DynamicPortFirst% /highDataChannelPort:%DynamicPortLast%
appcmd set config -section:system.applicationHost/sites /siteDefaults.ftpServer.firewallSupport.externalIp4Address:"%PublicIP%" /commit:apphost

REM Configure firewall.
netsh advfirewall firewall add rule name="FTP Public Port" dir=in action=allow protocol=TCP localport=%PublicPort%
netsh advfirewall firewall add rule name="FTP Passive Dynamic Ports" dir=in action=allow protocol=TCP localport=%DynamicPortRange%

REM Restart the FTP service.

net stop ftpsvc