$data = Get-Content C:\Users\ian\Desktop\Appstore.txt 
foreach ($line in $data){
   get-appxpackage -alluser -Name $line | Remove-AppxPackage
    }

