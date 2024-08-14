@{
    PSDependOptions      = @{
        Target = 'CurrentUser'
        Import = $true
    }

    PowerShellGet    = 'latest'
    PSFzf            = 'latest'
    'Terminal-Icons' = 'latest'
    PSReadLine           = @{
        DependsOn  = 'PowerShellGet'
        Install    = $false
        Parameters = @{
            AllowPrerelease = $true
        }
    }
}
