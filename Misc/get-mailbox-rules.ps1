$users = get-mailbox -resultsize unlimited

$results=ForEach ($user in $users)
{
        $rules = get-InboxRule -Mailbox $user.name
        if ($rules.length -gt 0) {
                echo ""
                echo $user.name
                echo ""
                $rules | select name, priority, description | fl
                echo ""
        }
} 
$results | Out-File -FilePath "C:\rulesoutput.txt" -Append