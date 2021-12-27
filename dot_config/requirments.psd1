@{
    PSDependOptions      = @{
        Target = 'CurrentUser'
        Import = $true
    }

    PowerShellGet    = 'latest'
    PSFzf            = 'latest'
    ZLocation        = 'latest'
    'Terminal-Icons' = 'latest'
    PSReadLine           = @{
        DependsOn  = 'PowerShellGet'
        Install    = $false
        Parameters = @{
            AllowPrerelease = $true
        }
    }
}