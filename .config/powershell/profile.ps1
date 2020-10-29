# http://powershell-guru.com/powershell-tip-33-increase-the-number-of-commands-of-the-history/
$MaximumHistoryCount = 32000

Set-PSReadLineKeyHandler -Key Ctrl+w -Function BackwardKillWord

$PSReadLineOptions = @{
    # EditMode = "Emacs"
    HistoryNoDuplicates = $true
    # The docs mention that PSReadLine history is separate from PowerShell
    # history.
    MaximumHistoryCount = 100000
    # Colors = @{
    #     "Command" = "#8181f7"
    # }
}
Set-PSReadLineOption @PSReadLineOptions
