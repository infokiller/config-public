# See many complex examples here:
# https://github.com/PowerShell/PSReadLine/blob/master/PSReadLine/SamplePSReadLineProfile.ps1

# http://powershell-guru.com/powershell-tip-33-increase-the-number-of-commands-of-the-history/
$MaximumHistoryCount = 32000

# Powershell hash tables are case-insensitive, so we need to use a case-sensitive one:
# https://stackoverflow.com/a/24054257/1014208
$MyKeybindings = New-Object System.Collections.Hashtable
$MyKeybindings['Ctrl+w'] = 'BackwardKillWord'
$MyKeybindings['Ctrl+Backspace'] = 'BackwardKillWord'
$MyKeybindings['Ctrl+LeftArrow'] = 'BackwardWord'
$MyKeybindings['Ctrl+RightArrow'] = 'ForwardWord'
$MyKeybindings['Ctrl+c'] = 'CancelLine'
$MyKeybindings['Ctrl+v'] = 'WhatIsKey'
$MyKeybindings['Ctrl+V'] = 'Paste'
# On Windows, this is unbound
$MyKeybindings['Ctrl+p'] = 'PreviousHistory'
# On Windows, this is unbound
$MyKeybindings['Ctrl+n'] = 'NextHistory'
# On Windows, this is bound to SelectAll
$MyKeybindings['Ctrl+a'] = 'BeginningOfLine'
# On Windows, this is unbound
$MyKeybindings['Ctrl+e'] = 'EndOfLine'
# On Windows, this is unbound
$MyKeybindings['Ctrl+x,Ctrl+e'] = 'ViEditVisually'
$MyKeybindings['Alt+_'] = 'Undo'
$MyKeybindings['Alt++'] = 'Redo'
# Ctrl+j (equivalent to Ctrl+Enter) is bound to InsertLineAbove by default on
# Windows. I'm used to Ctrl+j executing the current command, so this is
# confusing to me, hence I'm rebinding it here.
$MyKeybindings['Ctrl+Enter'] = 'AcceptLine'
$MyKeybindings['Tab'] = 'MenuComplete'
# On Windows, this is unbound
$MyKeybindings['Ctrl+d'] = 'DeleteCharOrExit'

foreach ($k in $MyKeybindings.GetEnumerator()) {
    Set-PSReadLineKeyHandler -Key $k.Name -Function $k.Value
}

# On Windows, this is bound to RevertLine
Remove-PSReadLineKeyHandler 'Escape'
# On Windows, this is bound to Undo
Remove-PSReadLineKeyHandler 'Ctrl+z'
# On Windows, this is bound to ForwardDeleteInput
Remove-PSReadLineKeyHandler 'Ctrl+End'

$PSReadLineOptions = @{
    # EditMode = "Emacs"
    HistoryNoDuplicates = $true
    # The docs mention that PSReadLine history is separate from PowerShell
    # history.
    MaximumHistoryCount = 100000
    # From: https://github.com/neilpa/cmd-colors-solarized/blob/master/Set-SolarizedDarkColorDefaults.ps1
    # Changing the color for 'Parameter' is required so that it's not hidden
    # with a solarized color theme, see:
    # https://github.com/microsoft/terminal/issues/6696
    Colors              = @{
        'Command'            = 'Yellow'
        'ContinuationPrompt' = 'DarkBlue'
        'Default'            = 'DarkBlue'
        'Emphasis'           = 'Cyan'
        'Error'              = 'Red'
        'Keyword'            = 'Green'
        'Member'             = 'DarkCyan'
        'Number'             = 'DarkCyan'
        'Operator'           = 'DarkGreen'
        'Parameter'          = 'DarkGreen'
        'String'             = 'Blue'
        'Type'               = 'DarkYellow'
        'Variable'           = 'Green'
    }
}

# This shows a warning when using scp to copy a file to Windows:
# "The predictive suggestion feature cannot be enabled because the console
# output doesn't support virtual terminal processing or it's redirected"
# I identified the code that throws this error:
# https://github.com/PowerShell/PSReadLine/blob/master/PSReadLine/Options.cs#L142-L142
# TODO: Report this bug or a find a way to work around it.
if ($null -ne $(Get-PSReadLineOption).PredictionSource) {
    $PSReadLineOptions['PredictionSource'] = 'History'
}

if ($IsLinux -and $env:HOST_HIST_DIR) {
    $PSReadLineOptions['HistorySavePath'] = Join-Path -Path $env:HOST_HIST_DIR -ChildPath pwsh.txt
}

Set-PSReadLineOption @PSReadLineOptions
