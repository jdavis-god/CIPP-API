function Invoke-CIPPStandardRotateDKIM {
    <#
    .FUNCTIONALITY
        Internal
    .COMPONENT
        (APIName) RotateDKIM
    .SYNOPSIS
        (Label) Rotate DKIM keys that are 1024 bit to 2048 bit
    .DESCRIPTION
        (Helptext) Rotate DKIM keys that are 1024 bit to 2048 bit
        (DocsDescription) Rotate DKIM keys that are 1024 bit to 2048 bit
    .NOTES
        CAT
            Exchange Standards
        TAG
            "CIS"
        ADDEDCOMPONENT
        IMPACT
            Low Impact
        ADDEDDATE
            2023-03-14
        POWERSHELLEQUIVALENT
            Rotate-DkimSigningConfig
        RECOMMENDEDBY
            "CIS"
            "CIPP"
        UPDATECOMMENTBLOCK
            Run the Tools\Update-StandardsComments.ps1 script to update this comment block
    .LINK
        https://docs.cipp.app/user-documentation/tenant/standards/list-standards/exchange-standards#low-impact
    #>

    param($Tenant, $Settings)
    ##$Rerun -Type Standard -Tenant $Tenant -Settings $Settings 'RotateDKIM'

    $DKIM = (New-ExoRequest -tenantid $tenant -cmdlet 'Get-DkimSigningConfig') | Where-Object { $_.Selector1KeySize -Eq 1024 -and $_.Enabled -eq $true }

    If ($Settings.remediate -eq $true) {

        if ($DKIM) {
            $DKIM | ForEach-Object {
                try {
                    (New-ExoRequest -tenantid $tenant -cmdlet 'Rotate-DkimSigningConfig' -cmdparams @{ KeySize = 2048; Identity = $_.Identity } -useSystemMailbox $true)
                    Write-LogMessage -API 'Standards' -tenant $tenant -message "Rotated DKIM for $($_.Identity)" -sev Info
                } catch {
                    $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
                    Write-LogMessage -API 'Standards' -tenant $tenant -message "Failed to rotate DKIM Error: $ErrorMessage" -sev Error
                }
            }
        } else {
            Write-LogMessage -API 'Standards' -tenant $tenant -message 'DKIM is already rotated for all domains' -sev Info
        }

    }

    if ($Settings.alert -eq $true) {
        if ($DKIM) {
            Write-LogMessage -API 'Standards' -tenant $tenant -message "DKIM is not rotated for $($DKIM.Identity -join ';')" -sev Alert
        } else {
            Write-LogMessage -API 'Standards' -tenant $tenant -message 'DKIM is rotated for all domains' -sev Info
        }
    }

    if ($Settings.report -eq $true) {
        Add-CIPPBPAField -FieldName 'DKIM' -FieldValue $DKIM -StoreAs json -Tenant $tenant
    }
}
