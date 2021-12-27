@{
    PSDependOptions      = @{
        Target = 'CurrentUser'
        Import = $true
    }

    PSFzf           = 'latest'
    ZLocation       = 'latest'
    'Terminal-Icons'  = 'latest'
    PSReadLine      = @{
        Parameters = @{
            AllowPrerelease = $true
        }
    }
}