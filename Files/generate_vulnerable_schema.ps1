param(
    [Parameter(Mandatory = $true)]
    [string] $OutputPath,

    [int] $UserCount = 20,

    [int] $WeakPasswordPercent = 30,

    [switch] $IncludePolicyFailures,

    [int] $Seed
)

# ============================================================
# MDA VULNERABLE SCHEMA GENERATOR
# ============================================================
#
# PURPOSE
# -------
# Generate randomized, MDA-compatible Active Directory test users
# for an isolated home lab.
#
# This script DOES NOT modify Active Directory.
# It only produces JSON that can later be reviewed and supplied
# to the existing gen_ad.ps1 provisioning script.
#
# DESIGN GOALS
# ------------
# 80% tutorial concepts:
#   - Get-Random
#   - mutable collections
#   - randomized users/groups/passwords
#   - hashtables / PSCustomObject
#   - ConvertTo-Json
#   - duplicate prevention
#   - array handling
#   - live validation / debugging
#
# 20% MDA-specific divergence:
#   - preserves the five-department MDA structure
#   - generates department-appropriate job titles
#   - preserves standard/privileged separation
#   - avoids randomly granting administrative privilege
#   - marks generated vulnerabilities explicitly
#   - supports reproducible randomization with -Seed
#
# EXAMPLE
# -------
# .\generate_vulnerable_schema.ps1 `
#     -OutputPath ".\generated_vulnerable_schema.json" `
#     -UserCount 20 `
#     -WeakPasswordPercent 35 `
#     -Seed 5024
#
# Optional:
#   -IncludePolicyFailures
#
# This intentionally allows some generated passwords that may fail
# the current domain password policy so the failure can be observed
# and documented. It does NOT weaken domain policy automatically.
#
# ============================================================


# ------------------------------------------------------------
# BASIC VALIDATION
# ------------------------------------------------------------

if ($UserCount -lt 1) {
    throw "UserCount must be at least 1."
}

if ($WeakPasswordPercent -lt 0 -or $WeakPasswordPercent -gt 100) {
    throw "WeakPasswordPercent must be between 0 and 100."
}

if ($PSBoundParameters.ContainsKey("Seed")) {
    Get-Random -SetSeed $Seed | Out-Null
    Write-Output "[SEED] Random generation seed set to $Seed"
}


# ============================================================
# SOURCE DATA
# ============================================================

# These are intentionally fictional names for the lab.
$firstNames = [System.Collections.ArrayList]@(
    "Aiden", "Amara", "Caleb", "Celine", "Darius",
    "Elena", "Felix", "Freya", "Gavin", "Helena",
    "Isaac", "Jade", "Kai", "Lena", "Marcus",
    "Nadia", "Orion", "Priya", "Quinn", "Rhea",
    "Silas", "Talia", "Victor", "Willow", "Xavier",
    "Yara", "Zane", "Mira", "Noah", "Selene",
    "Adrian", "Bianca", "Cedric", "Diana", "Elias",
    "Fiona", "Grant", "Hazel", "Ivan", "Julia"
)

$lastNames = [System.Collections.ArrayList]@(
    "Archer", "Bennett", "Cross", "Dalton", "Everett",
    "Foster", "Graves", "Hayes", "Irving", "Jordan",
    "Keller", "Lane", "Mercer", "Nolan", "Owens",
    "Pierce", "Quade", "Reed", "Stone", "Turner",
    "Underwood", "Vale", "Walker", "Young", "Zimmer",
    "Black", "Cole", "Drake", "Ellis", "Frost",
    "Grey", "Hart", "Knox", "Morrow", "North",
    "Price", "Rowe", "Shaw", "Thorne", "West"
)


# Weak-but-policy-compliant passwords:
# These are intentionally guessable and should be treated as public lab credentials.
$weakPolicyCompliantPasswords = @(
    "Summer2026!",
    "Welcome123!",
    "Password2026!",
    "MDAworker1!",
    "Dungeon123!",
    "ChangeMe1!",
    "Klato2026!",
    "Magic1234!"
)

# Stronger lab passwords.
$strongPasswords = @(
    "MDA_R3dCedar!7421",
    "Kl@to_Guard!9284",
    "DunG30n#Watch_651",
    "M!thic_R0ute#381",
    "UCG_Access!5739",
    "Reg!stry_Gate#2048",
    "Surv3il!Signal_918",
    "Evalu8#Stone_4721"
)

# Deliberately noncompliant examples.
# These are used only when -IncludePolicyFailures is supplied.
$policyFailurePasswords = @(
    "password",
    "12345678",
    "agent",
    "welcome",
    "mda123",
    "qwerty"
)


# ============================================================
# MDA DEPARTMENT MODEL
# ============================================================

$departmentModel = @{
    "Surveillance" = @{
        BaseGroup = "MDA_Surveillance"
        JobTitles = @(
            "Surveillance Agent",
            "Surveillance Analyst",
            "Field Surveillance Specialist"
        )
    }

    "Information Technology" = @{
        BaseGroup = "MDA_IT"
        JobTitles = @(
            "Information Technology Technician",
            "Systems Support Specialist",
            "IT Operations Analyst"
        )
    }

    "Evaluation" = @{
        BaseGroup = "MDA_Evaluation"
        JobTitles = @(
            "Evaluation Specialist",
            "Dungeon Evaluation Analyst",
            "Mythic Assessment Specialist"
        )
    }

    "Registration" = @{
        BaseGroup = "MDA_Registration"
        JobTitles = @(
            "Registration Specialist",
            "Guild Registration Analyst",
            "Records Specialist"
        )
    }

    "Distribution" = @{
        BaseGroup = "MDA_Distribution"
        JobTitles = @(
            "Distribution Specialist",
            "Auction Operations Specialist",
            "Asset Distribution Analyst"
        )
    }
}

$departmentNames = @($departmentModel.Keys)


# ============================================================
# MDA GROUPS
# ============================================================

# Preserve the same group structure used by ad_schema.json.
$groups = @(
    @{ name = "MDA_Surveillance" },
    @{ name = "MDA_Surveillance_Chiefs" },
    @{ name = "MDA_Surveillance_Admins" },

    @{ name = "MDA_IT" },
    @{ name = "MDA_IT_Chiefs" },
    @{ name = "MDA_IT_Admins" },

    @{ name = "MDA_Evaluation" },
    @{ name = "MDA_Evaluation_Chiefs" },
    @{ name = "MDA_Evaluation_Admins" },

    @{ name = "MDA_Registration" },
    @{ name = "MDA_Registration_Chiefs" },
    @{ name = "MDA_Registration_Admins" },

    @{ name = "MDA_Distribution" },
    @{ name = "MDA_Distribution_Chiefs" },
    @{ name = "MDA_Distribution_Admins" }
)


# ============================================================
# HELPER FUNCTIONS
# ============================================================

function ConvertTo-MDAUsername {
    param(
        [Parameter(Mandatory = $true)]
        [string] $FirstName,

        [Parameter(Mandatory = $true)]
        [string] $LastName,

        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]] $ExistingUsernames
    )

    $baseUsername = (
        "$($FirstName.ToLower())_$($LastName.ToLower())" `
        -replace "[^a-z0-9_]", ""
    )

    $candidate = $baseUsername
    $suffix = 2

    while ($ExistingUsernames.Contains($candidate)) {
        $candidate = "$baseUsername$suffix"
        $suffix++
    }

    $ExistingUsernames.Add($candidate) | Out-Null
    return $candidate
}


function Get-MDAPasswordProfile {
    param(
        [Parameter(Mandatory = $true)]
        [int] $WeakPercent,

        [switch] $AllowPolicyFailure
    )

    $roll = Get-Random -Minimum 1 -Maximum 101

    if ($AllowPolicyFailure) {
        # Keep policy-failure cases uncommon so most users still provision.
        $policyFailureRoll = Get-Random -Minimum 1 -Maximum 101

        if ($policyFailureRoll -le 10) {
            return [PSCustomObject]@{
                Password = Get-Random -InputObject $policyFailurePasswords
                Classification = "policy_failure"
                Vulnerability = "Password intentionally expected to violate domain password policy."
            }
        }
    }

    if ($roll -le $WeakPercent) {
        return [PSCustomObject]@{
            Password = Get-Random -InputObject $weakPolicyCompliantPasswords
            Classification = "weak"
            Vulnerability = "Guessable lab password that may satisfy complexity requirements but remains poor security practice."
        }
    }

    return [PSCustomObject]@{
        Password = Get-Random -InputObject $strongPasswords
        Classification = "stronger"
        Vulnerability = $null
    }
}


function New-MDARandomUser {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]] $ExistingUsernames
    )

    $firstName = Get-Random -InputObject $firstNames
    $lastName  = Get-Random -InputObject $lastNames

    $username = ConvertTo-MDAUsername `
        -FirstName $firstName `
        -LastName $lastName `
        -ExistingUsernames $ExistingUsernames

    $department = Get-Random -InputObject $departmentNames
    $departmentData = $departmentModel[$department]

    $jobTitle = Get-Random -InputObject $departmentData.JobTitles

    $passwordProfile = Get-MDAPasswordProfile `
        -WeakPercent $WeakPasswordPercent `
        -AllowPolicyFailure:$IncludePolicyFailures

    # IMPORTANT:
    # Random users remain STANDARD users.
    # We do not randomly generate Chief/Admin privilege.
    $groupsForUser = @(
        $departmentData.BaseGroup
    )

    return [PSCustomObject]@{
        first_name = $firstName
        last_name = $lastName
        password = $passwordProfile.Password
        username = $username
        department = $department
        job_title = $jobTitle

        # Force array shape even when there is one group.
        groups = @($groupsForUser)

        account_type = "standard"

        # Extra metadata for lab documentation.
        generated = $true
        password_classification = $passwordProfile.Classification
        intentional_vulnerability = $passwordProfile.Vulnerability
    }
}


function Test-MDAGeneratedSchema {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $Users,

        [Parameter(Mandatory = $true)]
        [object[]] $Groups
    )

    Write-Output ""
    Write-Output "========================================"
    Write-Output "Validating Generated Schema"
    Write-Output "========================================"

    $validDepartments = @(
        "Surveillance",
        "Information Technology",
        "Evaluation",
        "Registration",
        "Distribution"
    )

    $validGroupNames = @($Groups | ForEach-Object { $_.name })
    $seenUsernames = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($user in $Users) {

        if (-not $user.first_name) {
            throw "Generated user is missing first_name."
        }

        if (-not $user.last_name) {
            throw "Generated user is missing last_name."
        }

        if (-not $user.username) {
            throw "Generated user is missing username."
        }

        if (-not $seenUsernames.Add($user.username)) {
            throw "Duplicate generated username detected: $($user.username)"
        }

        if ($user.department -notin $validDepartments) {
            throw "Generated user '$($user.username)' has invalid department '$($user.department)'."
        }

        if ($user.account_type -ne "standard") {
            throw "Generated user '$($user.username)' unexpectedly received non-standard account type."
        }

        foreach ($groupName in @($user.groups)) {
            if ($groupName -notin $validGroupNames) {
                throw "Generated user '$($user.username)' references unknown group '$groupName'."
            }
        }
    }

    Write-Output "[SCHEMA VALID] Generated schema passed validation."
}


# ============================================================
# GENERATION
# ============================================================

Write-Output ""
Write-Output "========================================"
Write-Output "MDA VULNERABLE SCHEMA GENERATOR"
Write-Output "========================================"
Write-Output "Users Requested:        $UserCount"
Write-Output "Weak Password Percent:  $WeakPasswordPercent%"
Write-Output "Policy Failures:        $($IncludePolicyFailures.IsPresent)"
Write-Output "Output Path:            $OutputPath"
Write-Output "========================================"

$generatedUsers = [System.Collections.ArrayList]::new()
$existingUsernames = [System.Collections.Generic.HashSet[string]]::new()

for ($i = 1; $i -le $UserCount; $i++) {

    Write-Output ""
    Write-Output "----------------------------------------"
    Write-Output "Generating user $i of $UserCount"
    Write-Output "----------------------------------------"

    $user = New-MDARandomUser `
        -ExistingUsernames $existingUsernames

    if ($null -eq $user) {
        Write-Warning "[FAILED] User generation returned no object."
        continue
    }

    [void]$generatedUsers.Add($user)

    [void]$existingUsernames.Add($user.username)

    Write-Output "[GENERATED] Username: $($user.username)"
    Write-Output "[GENERATED] Name: $($user.first_name) $($user.last_name)"
    Write-Output "[GENERATED] Department: $($user.department)"
    Write-Output "[GENERATED] Job Title: $($user.job_title)"
    Write-Output "[GENERATED] Password Class: $($user.password_classification)"
}


# ============================================================
# VALIDATION
# ============================================================

Test-MDAGeneratedSchema `
    -Users @($generatedUsers) `
    -Groups $groups


# ============================================================
# SUMMARY
# ============================================================

$weakUsers = @(
    $generatedUsers |
    Where-Object { $_.password_classification -eq "weak" }
).Count

$strongerUsers = @(
    $generatedUsers |
    Where-Object { $_.password_classification -eq "stronger" }
).Count

$policyFailureUsers = @(
    $generatedUsers |
    Where-Object { $_.password_classification -eq "policy_failure" }
).Count

Write-Output ""
Write-Output "========================================"
Write-Output "GENERATION SUMMARY"
Write-Output "========================================"
Write-Output "Total Users:              $($generatedUsers.Count)"
Write-Output "Weak Password Users:      $weakUsers"
Write-Output "Stronger Password Users:  $strongerUsers"
Write-Output "Policy-Failure Users:     $policyFailureUsers"
Write-Output "========================================"


# ============================================================
# EXPORT
# ============================================================

$schema = [ordered]@{
    metadata = [ordered]@{
        schema_type = "MDA vulnerable lab schema"
        generated_at = (Get-Date).ToString("o")
        user_count = $generatedUsers.Count
        weak_password_percent = $WeakPasswordPercent
        includes_policy_failures = $IncludePolicyFailures.IsPresent
        seed = if ($PSBoundParameters.ContainsKey("Seed")) { $Seed } else { $null }
        warning = "All credentials are disposable lab-only credentials for an isolated test environment."
    }

    users = @($generatedUsers)

    groups = @($groups)
}

$jsonOutput = $schema | ConvertTo-Json -Depth 8

Set-Content `
    -Path $OutputPath `
    -Value $jsonOutput `
    -Encoding UTF8

Write-Output ""
Write-Output "[COMPLETE] Generated schema written to:"
Write-Output $OutputPath
