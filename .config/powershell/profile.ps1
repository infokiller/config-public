# See many complex examples here:
# https://github.com/PowerShell/PSReadLine/blob/master/PSReadLine/SamplePSReadLineProfile.ps1

# http://powershell-guru.com/powershell-tip-33-increase-the-number-of-commands-of-the-history/
$MaximumHistoryCount = 32000

Set-PSReadLineKeyHandler -Key Ctrl+w -Function BackwardKillWord
Set-PSReadLineKeyHandler -Key Ctrl+LeftArrow -Function BackwardWord
Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function ForwardWord
Set-PSReadLineKeyHandler -Key Ctrl+v -Function WhatIsKey
# NOTE: Undo doesn't work, seems that pwsh can't recognize it.
# Set-PSReadLineKeyHandler -Key Alt+_ -Function Undo
Set-PSReadLineKeyHandler -Key Alt++ -Function Redo

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
