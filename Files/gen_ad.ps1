param(
    [Parameter(Mandatory = $true)]
    [string] $JSONfile,
    [string] $RootOU = "MDA"
)

# ============================================================
# MDA ACTIVE DIRECTORY GENERATOR
# ============================================================
#
# Example:
#
# .\gen_ad.ps1 `
#     -JSONfile ".\ad_schema.json" `
#     -BaseDN "DC=mda,DC=com"
#
# Expected hierarchy:
#
# OU=MDA
# ├── OU=Users
# │   ├── OU=Surveillance
# │   ├── OU=Information Technology
# │   ├── OU=Evaluation
# │   ├── OU=Registration
# │   └── OU=Distribution
# │
# ├── OU=Privileged Accounts
# │   ├── OU=Surveillance
# │   ├── OU=Information Technology
# │   ├── OU=Evaluation
# │   ├── OU=Registration
# │   └── OU=Distribution
# │
# ├── OU=Groups
# ├── OU=Workstations
# └── OU=Servers
#
# ============================================================


# ------------------------------------------------------------
# INITIAL SETUP
# ------------------------------------------------------------

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {

    Write-Error @"
The ActiveDirectory PowerShell module is not installed.

On Windows 10/11, install RSAT with:

Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"

Then reopen PowerShell and run this script again.
"@

    exit 1
}

Import-Module ActiveDirectory -ErrorAction Stop

$BaseDN = (Get-ADDomain).DistinguishedName

if (-not (Test-Path $JSONfile)) {
    throw "JSON file does not exist: $JSONfile"
}

$json = Get-Content $JSONfile -Raw | ConvertFrom-Json

if (-not $json.metadata) {
    throw "Schema is missing required metadata."
}

$ownershipTag = $json.metadata.ownership_tag
$schemaVersion = $json.metadata.schema_version
$generatorName = $json.metadata.generator
$generatorVersion = $json.metadata.generator_version

if (-not $ownershipTag) {
    throw "Schema metadata is missing ownership_tag."
}

if (-not $schemaVersion) {
    throw "Schema metadata is missing schema_version."
}

if (-not $generatorName) {
    throw "Schema metadata is missing generator."
}

if (-not $generatorVersion) {
    throw "Schema metadata is missing generator_version."
}


# ============================================================
# HELPER FUNCTIONS
# ============================================================

function Get-MDAFullName {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $UserObject
    )

    return "$($UserObject.first_name) $($UserObject.last_name)"
}


function Get-MDAUserByUsername {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Username,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $Json
    )

    return $Json.users | Where-Object {
        $_.username -eq $Username
    }
}


function Get-MDAOwnershipDescription {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ObjectType,

        [Parameter(Mandatory = $true)]
        [string] $ObjectName
    )

    return "$ownershipTag | $ObjectType | $ObjectName | Schema $schemaVersion | $generatorName $generatorVersion"
}


function Set-MDAOwnershipMetadata {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ObjectType,

        [Parameter(Mandatory = $true)]
        [string] $ObjectName,

        [Parameter(Mandatory = $true)]
        [string] $ObjectIdentity,

        [AllowNull()]
        [string] $ExistingDescription
    )

    $ownershipDescription = Get-MDAOwnershipDescription `
        -ObjectType $ObjectType `
        -ObjectName $ObjectName

    if ($ExistingDescription -and $ExistingDescription.Contains($ownershipTag)) {
        Write-Output "[OWNERSHIP EXISTS] $ObjectName"
        return
    }

    $newDescription = if ($ExistingDescription) {
        "$ExistingDescription; $ownershipDescription"
    }
    else {
        $ownershipDescription
    }

    Write-Output "[OWNERSHIP ADDED] $ObjectName"

    switch ($ObjectType) {
        "OU" {
            Set-ADOrganizationalUnit `
                -Identity $ObjectIdentity `
                -Description $newDescription
        }
        "Group" {
            Set-ADGroup `
                -Identity $ObjectIdentity `
                -Description $newDescription
        }
        "User" {
            Set-ADUser `
                -Identity $ObjectIdentity `
                -Description $newDescription
        }
        default {
            throw "Unsupported object type '$ObjectType' for ownership metadata update."
        }
    }
}


function ConvertTo-MDAOUName {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Department
    )

    switch ($Department) {

        "Surveillance" {
            return "Surveillance"
        }

        "Information Technology" {
            return "Information Technology"
        }

        "Evaluation" {
            return "Evaluation"
        }

        "Registration" {
            return "Registration"
        }

        "Distribution" {
            return "Distribution"
        }

        default {
            throw "Unknown department: $Department"
        }
    }
}


function Get-MDAOrganizationalUnit {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $UserObject
    )

    $departmentOU = ConvertTo-MDAOUName $UserObject.department

    if ($UserObject.account_type -eq "privileged") {

        return "OU=$departmentOU,OU=Privileged Accounts,OU=$RootOU,$BaseDN"

    }
    elseif ($UserObject.account_type -eq "standard") {

        return "OU=$departmentOU,OU=Users,OU=$RootOU,$BaseDN"

    }
    else {

        throw "Unknown account type '$($UserObject.account_type)' for user '$($UserObject.username)'"

    }
}


# ============================================================
# OU FUNCTIONS
# ============================================================

function New-MDAOrganizationalUnit {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $existingOU = Get-ADOrganizationalUnit `
        -Filter "Name -eq '$Name'" `
        -SearchBase $Path `
        -SearchScope OneLevel `
        -Properties Description `
        -ErrorAction SilentlyContinue

    if ($existingOU) {

        Write-Output "[OU EXISTS] $Name"
        Set-MDAOwnershipMetadata `
            -ObjectType "OU" `
            -ObjectName $Name `
            -ObjectIdentity $existingOU.DistinguishedName `
            -ExistingDescription $existingOU.Description

        return
    }

    $ownershipDescription = Get-MDAOwnershipDescription `
        -ObjectType "OU" `
        -ObjectName $Name

    Write-Output "[CREATING OU] $Name"

    $newOU = New-ADOrganizationalUnit `
        -Name $Name `
        -Path $Path `
        -ProtectedFromAccidentalDeletion $true

    Set-ADOrganizationalUnit `
        -Identity $newOU.DistinguishedName `
        -Description $ownershipDescription
}


function Initialize-MDAOUStructure {

    Write-Output ""
    Write-Output "========================================"
    Write-Output "Creating MDA Organizational Units"
    Write-Output "========================================"

    # Root MDA OU
    $rootPath = $BaseDN

    New-MDAOrganizationalUnit `
        -Name $RootOU `
        -Path $rootPath


    $mdaPath = "OU=$RootOU,$BaseDN"

    # Main OUs
    $mainOUs = @(
        "Users",
        "Privileged Accounts",
        "Groups",
        "Workstations",
        "Servers"
    )

    foreach ($ou in $mainOUs) {

        New-MDAOrganizationalUnit `
            -Name $ou `
            -Path $mdaPath
    }


    # Department OUs
    $departments = @(
        "Surveillance",
        "Information Technology",
        "Evaluation",
        "Registration",
        "Distribution"
    )

    foreach ($department in $departments) {

        New-MDAOrganizationalUnit `
            -Name $department `
            -Path "OU=Users,$mdaPath"

        New-MDAOrganizationalUnit `
            -Name $department `
            -Path "OU=Privileged Accounts,$mdaPath"
    }
}


# ============================================================
# GROUP FUNCTIONS
# ============================================================

function New-MDAGroup {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $GroupObject
    )

    $groupName = $GroupObject.name
    $ownershipDescription = Get-MDAOwnershipDescription `
        -ObjectType "Group" `
        -ObjectName $groupName

    $existingGroup = Get-ADGroup `
        -Filter "SamAccountName -eq '$groupName'" `
        -Properties Description `
        -ErrorAction SilentlyContinue

    if ($existingGroup) {

        Write-Output "[GROUP EXISTS] $groupName"
        Set-MDAOwnershipMetadata `
            -ObjectType "Group" `
            -ObjectName $groupName `
            -ObjectIdentity $existingGroup.DistinguishedName `
            -ExistingDescription $existingGroup.Description
        return
    }

    Write-Output "[CREATING GROUP] $groupName"

    New-ADGroup `
        -Name $groupName `
        -SamAccountName $groupName `
        -GroupCategory Security `
        -GroupScope Global `
        -Path "OU=Groups,OU=$RootOU,$BaseDN" `
        -Description $ownershipDescription
}


function Initialize-MDAGroups {

    Write-Output ""
    Write-Output "========================================"
    Write-Output "Creating MDA Security Groups"
    Write-Output "========================================"

    foreach ($group in $json.groups) {
        New-MDAGroup -GroupObject $group
    }
}


# ============================================================
# USER FUNCTIONS
# ============================================================

function New-MDAUser {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $UserObject,

        [Parameter(Mandatory = $true)]
        [string] $OU
    )

    $username = $UserObject.username
    $fullName = Get-MDAFullName -UserObject $UserObject
    $ownershipDescription = Get-MDAOwnershipDescription `
        -ObjectType "User" `
        -ObjectName $username

    $existingUser = Get-ADUser `
        -Filter "SamAccountName -eq '$username'" `
        -Properties Description `
        -ErrorAction SilentlyContinue

    if ($existingUser) {

        Write-Output "[USER EXISTS] $username"
        Set-MDAOwnershipMetadata `
            -ObjectType "User" `
            -ObjectName $username `
            -ObjectIdentity $existingUser.DistinguishedName `
            -ExistingDescription $existingUser.Description
        return
    }

    Write-Output "[CREATING USER] $fullName ($username)"

    $securePassword = ConvertTo-SecureString `
        $UserObject.password `
        -AsPlainText `
        -Force


    New-ADUser `
        -Name $fullName `
        -GivenName $UserObject.first_name `
        -Surname $UserObject.last_name `
        -DisplayName $fullName `
        -SamAccountName $username `
        -UserPrincipalName "$username@$((Get-ADDomain).DNSRoot)" `
        -Department $UserObject.department `
        -Title $UserObject.job_title `
        -Description $ownershipDescription `
        -Path $OU `
        -AccountPassword $securePassword `
        -Enabled $true `
        -ChangePasswordAtLogon $true
}


function Add-MDAUserToGroups {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $UserObject
    )

    $username = $UserObject.username

    foreach ($groupName in $UserObject.groups) {

        $group = Get-ADGroup `
            -Filter "SamAccountName -eq '$groupName'" `
            -ErrorAction SilentlyContinue

        if (-not $group) {

            Write-Warning "Group '$groupName' does not exist. Skipping $username."
            continue
        }

        $alreadyMember = Get-ADGroupMember `
            -Identity $groupName `
            -Recursive `
            -ErrorAction SilentlyContinue |
            Where-Object {
                $_.SamAccountName -eq $username
            }

        if ($alreadyMember) {

            Write-Output "[MEMBERSHIP EXISTS] $username -> $groupName"

        }
        else {

            Write-Output "[ADDING TO GROUP] $username -> $groupName"

            Add-ADGroupMember `
                -Identity $groupName `
                -Members $username
        }
    }
}


function Test-MDAUser {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $UserObject
    )

    $username = $UserObject.username

    $adUser = Get-ADUser `
        -Identity $username `
        -Properties Department, Title, MemberOf `
        -ErrorAction SilentlyContinue

    if (-not $adUser) {

        Write-Warning "[VALIDATION FAILED] User $username was not found."
        return $false
    }

    Write-Output "[VALIDATED] $username"

    return $true
}


function New-MDAUserFromSchema {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $UserObject
    )

    $fullName = Get-MDAFullName -UserObject $UserObject

    Write-Output ""
    Write-Output "----------------------------------------"
    Write-Output "Processing: $fullName"
    Write-Output "Username: $($UserObject.username)"
    Write-Output "Department: $($UserObject.department)"
    Write-Output "Position: $($UserObject.job_title)"
    Write-Output "Account Type: $($UserObject.account_type)"
    Write-Output "----------------------------------------"

    $ou = Get-MDAOrganizationalUnit `
        -UserObject $UserObject

    Write-Output "OU: $ou"

    New-MDAUser `
        -UserObject $UserObject `
        -OU $ou

    Add-MDAUserToGroups `
        -UserObject $UserObject

    Test-MDAUser `
        -UserObject $UserObject | Out-Null
}


# ============================================================
# SCHEMA VALIDATION
# ============================================================

function Test-MDASchema {

    Write-Output ""
    Write-Output "========================================"
    Write-Output "Validating JSON Schema"
    Write-Output "========================================"

    if (-not $json.metadata) {
        throw "Schema is missing required metadata."
    }

    if (-not $json.metadata.ownership_tag) {
        throw "Schema metadata is missing ownership_tag."
    }

    if (-not $json.metadata.schema_version) {
        throw "Schema metadata is missing schema_version."
    }

    if (-not $json.metadata.generator) {
        throw "Schema metadata is missing generator."
    }

    if (-not $json.metadata.generator_version) {
        throw "Schema metadata is missing generator_version."
    }

    if (-not $json.metadata.root_ou) {
        throw "Schema metadata is missing root_ou."
    }

    if (-not $json.users) {
        throw "Schema is missing the users collection."
    }

    if (-not $json.groups) {
        throw "Schema is missing the groups collection."
    }

    $validAccountTypes = @(
        "standard",
        "privileged"
    )

    $validDepartments = @(
        "Surveillance",
        "Information Technology",
        "Evaluation",
        "Registration",
        "Distribution"
    )


    $usernames = @()

    foreach ($user in $json.users) {

        if (-not $user.first_name) {
            throw "User entry is missing first_name."
        }

        if (-not $user.last_name) {
            throw "User entry is missing last_name."
        }

        if (-not $user.username) {
            throw "User entry is missing username."
        }

        if (-not $user.password) {
            throw "User '$($user.username)' is missing password."
        }

        if (-not $user.department) {
            throw "User '$($user.username)' is missing department."
        }

        if (-not $user.job_title) {
            throw "User '$($user.username)' is missing job_title."
        }

        if (-not $user.account_type) {
            throw "User '$($user.username)' is missing account_type."
        }


        if ($user.account_type -notin $validAccountTypes) {

            throw "User '$($user.username)' has invalid account type '$($user.account_type)'."

        }


        if ($user.department -notin $validDepartments) {

            throw "User '$($user.username)' has invalid department '$($user.department)'."

        }


        if ($user.username -in $usernames) {

            throw "Duplicate username detected: $($user.username)"

        }

        $usernames += $user.username


        foreach ($groupName in $user.groups) {

            if ($groupName -notin $json.groups.name) {

                throw "User '$($user.username)' references unknown group '$groupName'."

            }
        }
    }

    Write-Output "[SCHEMA VALID] No blocking errors detected."
}


# ============================================================
# SUMMARY
# ============================================================

function Show-MDASummary {

    $standardAccounts = @(
        $json.users |
        Where-Object {
            $_.account_type -eq "standard"
        }
    ).Count

    $privilegedAccounts = @(
        $json.users |
        Where-Object {
            $_.account_type -eq "privileged"
        }
    ).Count

    $totalAccounts = @($json.users).Count
    $totalGroups = @($json.groups).Count


    Write-Output ""
    Write-Output "========================================"
    Write-Output "MDA ACTIVE DIRECTORY SUMMARY"
    Write-Output "========================================"

    Write-Output "Standard Accounts:   $standardAccounts"
    Write-Output "Privileged Accounts: $privilegedAccounts"
    Write-Output "Total Accounts:      $totalAccounts"
    Write-Output "Security Groups:     $totalGroups"

    Write-Output "========================================"
}


# ============================================================
# MAIN
# ============================================================

Write-Output ""
Write-Output "========================================"
Write-Output "MDA ACTIVE DIRECTORY GENERATOR"
Write-Output "========================================"
Write-Output "JSON File: $JSONfile"
Write-Output "Base DN: $BaseDN"
Write-Output "Root OU: $RootOU"
Write-Output "========================================"


# Validate schema before changing Active Directory
Test-MDASchema


# Build OU hierarchy
Initialize-MDAOUStructure


# Create groups
Initialize-MDAGroups


# Create users and memberships
foreach ($user in $json.users) {

    New-MDAUserFromSchema `
        -UserObject $user

}


# Final summary
Show-MDASummary


Write-Output ""
Write-Output "[COMPLETE] MDA Active Directory generation finished."