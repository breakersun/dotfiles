@{
    PSDependOptions      = @{
        Target = 'CurrentUser'
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