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

# ============================================================
# Banner
# ============================================================

Write-Section "MDA ACTIVE DIRECTORY CONTROLLED TEARDOWN"

Write-Output "JSON File:       $JSONFile"
Write-Output "Domain DN:       $DomainDN"
Write-Output "Root OU:         $RootOU"
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

if ($null -eq $schema.users) {
    throw "Schema does not contain a users collection."
}

if ($null -eq $schema.groups) {
    throw "Schema does not contain a groups collection."
}

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

foreach ($username in $users) {

    try {

        $user = Get-ADUser `
            -Identity $username `
            -ErrorAction Stop

        # Safety boundary:
        # Only remove users located underneath MDA.
        if ($user.DistinguishedName -like "*,$RootOU") {

            $resolvedUsers += $user

            Write-Action "FOUND USER" `
                "$username -> $($user.DistinguishedName)"
        }
        else {

            Write-Action "SKIP USER" `
                "$username -> Outside MDA OU hierarchy"
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

foreach ($groupName in $groups) {

    try {

        $group = Get-ADGroup `
            -Identity $groupName `
            -ErrorAction Stop

        # Safety boundary:
        # Only remove groups with the expected MDA naming convention.
        if ($group.Name -like "MDA_*") {

            $resolvedGroups += $group

            Write-Action "FOUND GROUP" `
                "$groupName -> $($group.DistinguishedName)"
        }
        else {

            Write-Action "SKIP GROUP" `
                "$groupName -> Does not match MDA naming boundary"
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
            -Filter * `
            -ErrorAction Stop |
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
                -ErrorAction Stop

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