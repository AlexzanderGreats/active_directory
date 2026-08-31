<#
.SYNOPSIS
    Controlled teardown of the Mythical Dungeon Association (MDA)
    Active Directory lab environment.

.DESCRIPTION
    Removes only users and groups explicitly represented in the supplied
    MDA JSON schema.

    Organizational Units are removed only when they are empty.

    The MDA root OU is NOT removed unless -RemoveRootOU is explicitly used.

    Designed as the controlled destruction counterpart to gen_ad.ps1.

.PARAMETER JSONFile
    Path to the MDA schema JSON file.

.PARAMETER RemoveOUs
    Remove MDA organizational units after generated objects have been removed.

.PARAMETER RemoveRootOU
    Remove the MDA root OU after all child OUs have been removed.

.PARAMETER Force
    Skip the final confirmation prompt.

.PARAMETER WhatIf
    Display what would be removed without making changes.

.EXAMPLE
    .\remove_mda.ps1 -JSONFile .\ad_schema.json -WhatIf

.EXAMPLE
    .\remove_mda.ps1 -JSONFile .\ad_schema.json -RemoveOUs

.EXAMPLE
    .\remove_mda.ps1 -JSONFile .\ad_schema.json -RemoveOUs -RemoveRootOU

.EXAMPLE
    .\remove_mda.ps1 -JSONFile .\ad_schema.json -RemoveOUs -RemoveRootOU -Force
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$JSONFile,

    [switch]$RemoveOUs,

    [switch]$RemoveRootOU,

    [switch]$Force
)

Import-Module ActiveDirectory -ErrorAction Stop

# ============================================================
# Configuration
# ============================================================

$DomainDN = (Get-ADDomain).DistinguishedName
$RootOUName = "MDA"
$RootOU = "OU=$RootOUName,$DomainDN"
$OwnershipTag = $null

# ============================================================
# Helper Functions
# ============================================================

function Write-Section {
    param(
        [string]$Title
    )

    Write-Output ""
    Write-Output "========================================"
    Write-Output $Title
    Write-Output "========================================"
}

function Write-Action {
    param(
        [string]$Action,
        [string]$Object
    )

    Write-Output "[$Action] $Object"
}

function Test-ObjectExists {
    param(
        [string]$Identity
    )

    try {
        Get-ADObject -Identity $Identity -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Test-MDAOwnershipMarker {
    param(
        [AllowNull()]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [string]$Tag
    )

    if ([string]::IsNullOrWhiteSpace($Description)) {
        return $false
    }

    return $Description.Contains($Tag)
}

# ============================================================
# Banner
# ============================================================

Write-Section "MDA ACTIVE DIRECTORY CONTROLLED TEARDOWN"

Write-Output "JSON File:       $JSONFile"
Write-Output "Domain DN:       $DomainDN"
Write-Output "Root OU:         $RootOU"
Write-Output "Ownership Tag:   $OwnershipTag"
Write-Output "Remove OUs:      $RemoveOUs"
Write-Output "Remove Root OU:  $RemoveRootOU"
Write-Output "WhatIf:          $WhatIfPreference"
Write-Output "Force:           $Force"

# ============================================================
# Validate JSON
# ============================================================

Write-Section "Loading MDA Schema"

if (-not (Test-Path $JSONFile)) {
    throw "JSON file does not exist: $JSONFile"
}

try {
    $schema = Get-Content $JSONFile -Raw | ConvertFrom-Json
}
catch {
    throw "Unable to parse JSON file: $JSONFile"
}

if (-not $schema.metadata) {
    throw "Schema is missing required metadata."
}

if (-not $schema.metadata.ownership_tag) {
    throw "Schema metadata is missing ownership_tag."
}

if (-not $schema.metadata.schema_version) {
    throw "Schema metadata is missing schema_version."
}

if (-not $schema.metadata.generator) {
    throw "Schema metadata is missing generator."
}

if (-not $schema.metadata.generator_version) {
    throw "Schema metadata is missing generator_version."
}

if (-not $schema.metadata.root_ou) {
    throw "Schema metadata is missing root_ou."
}

if ($null -eq $schema.users) {
    throw "Schema does not contain a users collection."
}

if ($null -eq $schema.groups) {
    throw "Schema does not contain a groups collection."
}

$OwnershipTag = $schema.metadata.ownership_tag
$RootOUName = $schema.metadata.root_ou
$RootOU = "OU=$RootOUName,$DomainDN"

Write-Action "SCHEMA VALID" "MDA schema loaded successfully."

# ============================================================
# Build Object Lists
# ============================================================

Write-Section "Building Destruction Inventory"

$users = @(
    $schema.users |
        Where-Object {
            $_.username
        } |
        ForEach-Object {
            $_.username
        }
)

$groups = @(
    $schema.groups |
        Where-Object {
            $_.name
        } |
        ForEach-Object {
            $_.name
        }
)

Write-Output "Users discovered in schema:  $($users.Count)"
Write-Output "Groups discovered in schema: $($groups.Count)"

# ============================================================
# Resolve Users
# ============================================================

Write-Section "Resolving MDA Users"

$resolvedUsers = @()
$skippedUsers = @()

foreach ($username in $users) {

    try {

        $user = Get-ADUser `
            -Identity $username `
            -Properties Description `
            -ErrorAction Stop

        # Safety boundary:
        # Only remove users explicitly marked by the MDA ownership tag.
        if ($user.DistinguishedName -like "*,$RootOU" -and (Test-MDAOwnershipMarker -Description $user.Description -Tag $OwnershipTag)) {

            $resolvedUsers += $user

            Write-Action "FOUND USER" `
                "$username -> $($user.DistinguishedName)"
        }
        else {

            $skippedUsers += [pscustomobject]@{
                Name = $username
                DistinguishedName = $user.DistinguishedName
                Reason = "Missing ownership marker or outside MDA OU hierarchy"
            }

            Write-Action "SKIP USER" `
                "$username -> Missing ownership marker or outside MDA OU hierarchy"
        }
    }
    catch {

        Write-Action "MISSING USER" $username
    }
}

# ============================================================
# Resolve Groups
# ============================================================

Write-Section "Resolving MDA Groups"

$resolvedGroups = @()
$skippedGroups = @()

foreach ($groupName in $groups) {

    try {

        $group = Get-ADGroup `
            -Identity $groupName `
            -Properties Description `
            -ErrorAction Stop

        # Safety boundary:
        # Only remove groups explicitly marked by the MDA ownership tag.
        if ((Test-MDAOwnershipMarker -Description $group.Description -Tag $OwnershipTag)) {

            $resolvedGroups += $group

            Write-Action "FOUND GROUP" `
                "$groupName -> $($group.DistinguishedName)"
        }
        else {

            $skippedGroups += [pscustomobject]@{
                Name = $groupName
                DistinguishedName = $group.DistinguishedName
                Reason = "Missing ownership marker"
            }

            Write-Action "SKIP GROUP" `
                "$groupName -> Missing ownership marker"
        }
    }
    catch {

        Write-Action "MISSING GROUP" $groupName
    }
}

# ============================================================
# Build Destruction Plan
# ============================================================

Write-Section "DESTRUCTION PLAN"

Write-Output "Users to remove:  $($resolvedUsers.Count)"
Write-Output "Groups to remove: $($resolvedGroups.Count)"

if ($RemoveOUs) {

    Write-Output ""
    Write-Output "OU removal has been requested."

    Write-Output ""
    Write-Output "The following OU hierarchy is eligible:"
    Write-Output "  $RootOU"
}

Write-Section "OWNERSHIP-BASED SUMMARY"
Write-Output "Eligible for removal (ownership tag present):"

if ($resolvedUsers.Count -gt 0) {
    foreach ($user in $resolvedUsers) {
        Write-Output "  REMOVE USER: $($user.SamAccountName) -> $($user.DistinguishedName)"
    }
}
else {
    Write-Output "  (none)"
}

if ($resolvedGroups.Count -gt 0) {
    foreach ($group in $resolvedGroups) {
        Write-Output "  REMOVE GROUP: $($group.Name) -> $($group.DistinguishedName)"
    }
}
else {
    Write-Output "  (none)"
}

Write-Output ""
Write-Output "Skipped because ownership metadata is missing or object is outside the MDA scope:"

if ($skippedUsers.Count -gt 0) {
    foreach ($user in $skippedUsers) {
        Write-Output "  SKIP USER: $($user.Name) -> $($user.DistinguishedName) | $($user.Reason)"
    }
}
else {
    Write-Output "  (none)"
}

if ($skippedGroups.Count -gt 0) {
    foreach ($group in $skippedGroups) {
        Write-Output "  SKIP GROUP: $($group.Name) -> $($group.DistinguishedName) | $($group.Reason)"
    }
}
else {
    Write-Output "  (none)"
}

if ($RemoveOUs) {
    $eligibleOUs = @()
    $skippedOUs = @()

    try {
        $ouCandidates = Get-ADOrganizationalUnit `
            -SearchBase $RootOU `
            -SearchScope Subtree `
            -Properties Description `
            -Filter * `
            -ErrorAction Stop |
            Sort-Object `
                { $_.DistinguishedName.Length } `
                -Descending
    }
    catch {
        $ouCandidates = @()
    }

    foreach ($ou in $ouCandidates) {
        if (Test-MDAOwnershipMarker -Description $ou.Description -Tag $OwnershipTag) {
            $eligibleOUs += $ou
        }
        else {
            $skippedOUs += [pscustomobject]@{
                Name = $ou.Name
                DistinguishedName = $ou.DistinguishedName
                Reason = "Missing ownership marker"
            }
        }
    }

    Write-Output ""
    Write-Output "OU ownership-based summary:"

    if ($eligibleOUs.Count -gt 0) {
        foreach ($ou in $eligibleOUs) {
            Write-Output "  REMOVE OU: $($ou.DistinguishedName)"
        }
    }
    else {
        Write-Output "  (none)"
    }

    if ($skippedOUs.Count -gt 0) {
        foreach ($ou in $skippedOUs) {
            Write-Output "  SKIP OU: $($ou.DistinguishedName) | $($ou.Reason)"
        }
    }
    else {
        Write-Output "  (none)"
    }
}

# ============================================================
# Confirmation
# ============================================================

if (-not $WhatIfPreference -and -not $Force) {

    Write-Output ""
    Write-Output "WARNING:"
    Write-Output "This will remove MDA lab objects from Active Directory."
    Write-Output ""
    Write-Output "This operation should only be performed against the"
    Write-Output "MDA lab domain/environment."
    Write-Output ""

    $confirmation = Read-Host `
        "Type REMOVE-MDA to continue"

    if ($confirmation -ne "REMOVE-MDA") {

        Write-Output ""
        Write-Action "ABORTED" `
            "Confirmation string was not entered."

        exit 0
    }
}

# ============================================================
# Remove Users
# ============================================================

Write-Section "Removing MDA Users"

foreach ($user in $resolvedUsers) {

    if ($PSCmdlet.ShouldProcess(
        $user.DistinguishedName,
        "Remove MDA user account"
    )) {

        try {

            Remove-ADUser `
                -Identity $user `
                -Confirm:$false `
                -ErrorAction Stop

            Write-Action "REMOVED USER" $user.SamAccountName
        }
        catch {

            Write-Action "FAILED USER" `
                "$($user.SamAccountName) -> $($_.Exception.Message)"
        }
    }
    else {

        Write-Action "WOULD REMOVE USER" `
            $user.SamAccountName
    }
}

# ============================================================
# Remove Groups
# ============================================================

Write-Section "Removing MDA Security Groups"

foreach ($group in $resolvedGroups) {

    if ($PSCmdlet.ShouldProcess(
        $group.DistinguishedName,
        "Remove MDA security group"
    )) {

        try {

            Remove-ADGroup `
                -Identity $group `
                -Confirm:$false `
                -ErrorAction Stop

            Write-Action "REMOVED GROUP" $group.Name
        }
        catch {

            Write-Action "FAILED GROUP" `
                "$($group.Name) -> $($_.Exception.Message)"
        }
    }
    else {

        Write-Action "WOULD REMOVE GROUP" `
            $group.Name
    }
}

# ============================================================
# Remove OUs
# ============================================================

if ($RemoveOUs) {

    Write-Section "Removing MDA Organizational Units"

    try {

        $ous = Get-ADOrganizationalUnit `
            -SearchBase $RootOU `
            -SearchScope Subtree `
            -Properties Description `
            -Filter * `
            -ErrorAction Stop |
            Where-Object {
                Test-MDAOwnershipMarker -Description $_.Description -Tag $OwnershipTag
            } |
            Sort-Object `
                { $_.DistinguishedName.Length } `
                -Descending

    }
    catch {

        Write-Action "OU SEARCH FAILED" `
            $_.Exception.Message

        $ous = @()
    }

    foreach ($ou in $ous) {

        try {

            $children = Get-ADObject `
                -SearchBase $ou.DistinguishedName `
                -SearchScope OneLevel `
                -Filter * `
                -ErrorAction Stop

            if ($children.Count -gt 0) {

                Write-Action "SKIP OU" `
                    "$($ou.DistinguishedName) -> Contains objects"

                continue
            }

            if ($PSCmdlet.ShouldProcess(
                $ou.DistinguishedName,
                "Remove empty MDA OU"
            )) {

                Remove-ADOrganizationalUnit `
                    -Identity $ou `
                    -Confirm:$false `
                    -ErrorAction Stop

                Write-Action "REMOVED OU" `
                    $ou.DistinguishedName
            }
            else {

                Write-Action "WOULD REMOVE OU" `
                    $ou.DistinguishedName
            }

        }
        catch {

            Write-Action "FAILED OU" `
                "$($ou.DistinguishedName) -> $($_.Exception.Message)"
        }
    }
}

# ============================================================
# Optional Root OU Removal
# ============================================================

if ($RemoveRootOU) {

    Write-Section "Removing MDA Root OU"

    try {

        $rootChildren = Get-ADObject `
            -SearchBase $RootOU `
            -SearchScope OneLevel `
            -Filter * `
            -ErrorAction Stop

        if ($rootChildren.Count -gt 0) {

            Write-Action "ROOT OU RETAINED" `
                "MDA still contains objects."

        }
        else {

            $rootObject = Get-ADOrganizationalUnit `
                -Identity $RootOU `
                -Properties Description `
                -ErrorAction Stop

            if (-not (Test-MDAOwnershipMarker -Description $rootObject.Description -Tag $OwnershipTag)) {
                Write-Action "ROOT OU RETAINED" `
                    "$RootOU -> Missing ownership marker"
                Write-Output "  SKIP ROOT OU: $RootOU | Missing ownership marker"
                return
            }

            if ($PSCmdlet.ShouldProcess(
                $RootOU,
                "Remove MDA root OU"
            )) {

                Remove-ADOrganizationalUnit `
                    -Identity $rootObject `
                    -Confirm:$false `
                    -ErrorAction Stop

                Write-Action "REMOVED ROOT OU" $RootOU
            }
            else {

                Write-Action "WOULD REMOVE ROOT OU" $RootOU
            }
        }

    }
    catch {

        Write-Action "ROOT OU ERROR" `
            $_.Exception.Message
    }
}

# ============================================================
# Final Report
# ============================================================

Write-Section "MDA TEARDOWN COMPLETE"

Write-Output "Schema Users:       $($users.Count)"
Write-Output "Resolved Users:     $($resolvedUsers.Count)"
Write-Output "Schema Groups:      $($groups.Count)"
Write-Output "Resolved Groups:    $($resolvedGroups.Count)"
Write-Output "OU Removal:         $RemoveOUs"
Write-Output "Root OU Removal:    $RemoveRootOU"

Write-Output ""
Write-Action "COMPLETE" `
    "Controlled MDA teardown finished."