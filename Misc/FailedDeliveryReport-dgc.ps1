﻿Get-MessageTrace -StartDate (Get-Date).Adddays(-7) -EndDate (Get-Date) -Status Failed | Select-Object -Property Received,SenderAddress,RecipientAddress,Subject,Size,Detail,Status | Export-CSV -path C:\Office365NonDeliveryReport.csv -Encoding UTF8