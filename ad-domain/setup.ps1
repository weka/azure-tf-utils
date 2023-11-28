Start-Sleep -Seconds 30
# Install AD
Import-Module ADDSDeployment
$password = ConvertTo-SecureString ${password} -AsPlainText -Force
Add-WindowsFeature -Name AD-Domain-Services,DNS -IncludeManagementTools
Install-ADDSForest -CreateDnsDelegation:$false -DomainMode Win2012R2 -DomainName ${active_directory_domain} -DomainNetbiosName ${active_directory_netbios_name} -ForestMode Win2012R2 -InstallDns:$true -SafeModeAdministratorPassword $password -Force:$true

# Install WinRM
winrm quickconfig -q
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="300"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
netsh advfirewall firewall add rule name="WinRM 5985" protocol=TCP dir=in localport=5985 action=allow
netsh advfirewall firewall add rule name="WinRM 5986" protocol=TCP dir=in localport=5986 action=allow
net stop winrm
sc.exe config winrm start=auto
net start winrm

shutdown -r -t 10