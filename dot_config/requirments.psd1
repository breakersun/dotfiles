@{
    PSDependOptions      = @{
        Target = 'CurrentUser'
        Import = $true
    }

    PowerShellGet        = 'latest'
    PSFzf           = @{
        DependsOn = 'PowerShellGet'
    }
    ZLocation       = @{
        DependsOn = 'PowerShellGet'
    }
    'Terminal-Icons'  = @{
        DependsOn = 'PowerShellGet'
    }
    PSReadLine           = @{
        DependsOn  = 'PowerShellGet'
        Install    = $false
        Parameters = @{
            AllowPrerelease = $true
        }
    }
}