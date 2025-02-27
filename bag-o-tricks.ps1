# Clear OnPremisesImmutableId
Connect-MgGraph -Scopes User.ReadWrite.All
Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/Users/Username@example.com" -body '{"OnPremisesImmutableId": null}'