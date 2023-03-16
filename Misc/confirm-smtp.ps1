$From = "danv@mcmusinc.com"
$To = "danv@mcmusinc.com"
$Subject = "Test SMTP Mail"
$Body = "<h2>Body of email!</h2><br><br>"
$SMTPServer = "mcmusinc-com.mail.protection.outlook.com"
$SMTPPort = "25"
Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -BodyAsHtml -SmtpServer $SMTPServer -Port $SMTPPort -UseSsl