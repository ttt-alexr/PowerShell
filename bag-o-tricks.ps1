# Clear OnPremisesImmutableId
Connect-MgGraph -Scopes User.ReadWrite.All
Invoke-MgGraphRequest -Method PATCH -Uri 'https://graph.microsoft.com/v1.0/users/Username@example.com' -Body @{onPremisesImmutableId = $null}