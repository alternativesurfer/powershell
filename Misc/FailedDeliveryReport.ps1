$failedTraces = Get-Messagetrace -StartDate (Get-Date).Adddays(-7) -EndDate (Get-Date) | Where-Object { $_.Status -eq 'Failed'}
$failedTraces | Foreach-Object{
     $trace = $_     
     $stats = $trace |Get-MessageTraceDetail -event FAIL  
     New-Object -TypeName PSObject -Property @{
     MessageTime = $trace.Received
     Sender = $trace.SenderAddress
     Recipients = $trace.RecipientAddress
     Subject =$trace.Subject
     MessageSize = $trace.Size     
     StatusMessage =$stats.Detail
   }} |
Export-CSV "C:\Office365NonDeliveryReport.csv" -NoTypeInformation -Encoding UTF8