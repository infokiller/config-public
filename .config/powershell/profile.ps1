# http://powershell-guru.com/powershell-tip-33-increase-the-number-of-commands-of-the-history/
$MaximumHistoryCount = 32000

Set-PSReadLineKeyHandler -Key Ctrl+w -Function BackwardKillWord

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

if ($IsLinux -And $env:HOST_HIST_DIR) {
    $PSReadLineOptions['HistorySavePath'] = Join-Path -Path $env:HOST_HIST_DIR -ChildPath pwsh.txt
}

Set-PSReadLineOption @PSReadLineOptions
