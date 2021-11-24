 $password = ConvertTo-SecureString "" -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ("", $password)
$daysbeforeexpirytonotify = 14  
$now = (get-date).ToUniversalTime().ToFileTime()  
$threshold = (get-date).ToUniversalTime().adddays($daysbeforeexpirytonotify).ToFileTime()  
$users = Get-ADUser -filter { Enabled -eq $True -and PasswordNeverExpires -eq $False } ` –Properties "msDS-UserPasswordExpiryTimeComputed",mail ` -searchbase "OU=Users,OU=touchworks,DC=touchworks,DC=T1" |   
   where { $_."msDS-UserPasswordExpiryTimeComputed" -lt $threshold -and `  
           $_."msDS-UserPasswordExpiryTimeComputed" -gt $now } |   
   Select-Object "Name",  
                 "Mail",  
                 @{Name="ExpiryDate";Expression={  
                       [datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")  
                       }  
                 },  
                 @{Name="DaysToExpiry";Expression={  
                        [int](($_."msDS-UserPasswordExpiryTimeComputed" - $now) / 864000000000)  
                        }  
                 } |  
    sort-object name  
  
$users  
  
foreach ($user in $users) {  
   # send-mailmessage -From "admin@touchworks.t1" -To $user.mail  -Subject "Your password will expire in $($user.daystoexpiry) days"   -Body "Your password will expire at $($user.expirydate) (UTC)."  -SmtpServer 'email-smtp.us-east-2.amazonaws.com' -Port '587' -UseSsl
    Send-MailMessage -To $user.mail -Subject "Your password will expire in $($user.daystoexpiry) days"  -Body "Your password will expire at $($user.expirydate) (UTC)." -From ' ' -SmtpServer '' -Port '587' -UseSsl -Credential $Cred 
} 
