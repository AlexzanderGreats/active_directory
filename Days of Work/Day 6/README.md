# 4 Testing Program & Experimenting

1. Took a break after writing the code, and today I tested it.

    - I copied the code over into the DC, and ran it.
    - It was supposed to create a new json file, named `out.json`. Which it did, but it failed on some other stuff

    ```shell
    [192.168.244.155]: PS C:\Windows\Tasks> .\generate_vulnerable_schema.ps1 .\out.json

    ========================================
    MDA VULNERABLE SCHEMA GENERATOR
    ========================================
    Users Requested:        20
    Weak Password Percent:  30%
    Policy Failures:        False
    Output Path:            .\out.json
    ========================================
    New-MDARandomUser : Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:435 char:50
    +     $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    +                                                  ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [New-MDARandomUser], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorEmptyCollectionNotAllowed,New-MDARandomUser

    [GENERATED]  ->  /  /
    New-MDARandomUser : Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:435 char:50
    +     $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    +                                                  ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [New-MDARandomUser], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorEmptyCollectionNotAllowed,New-MDARandomUser

    [GENERATED]  ->  /  /
    New-MDARandomUser : Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:435 char:50
    +     $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    +                                                  ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [New-MDARandomUser], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorEmptyCollectionNotAllowed,New-MDARandomUser

    [GENERATED]  ->  /  /
    New-MDARandomUser : Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:435 char:50
    +     $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    +                                                  ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [New-MDARandomUser], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorEmptyCollectionNotAllowed,New-MDARandomUser

    [GENERATED]  ->  /  /
    New-MDARandomUser : Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:435 char:50
    +     $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    +                                                  ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [New-MDARandomUser], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorEmptyCollectionNotAllowed,New-MDARandomUser

    [GENERATED]  ->  /  /
    New-MDARandomUser : Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:435 char:50
    +     $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    +                                                  ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [New-MDARandomUser], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorEmptyCollectionNotAllowed,New-MDARandomUser

    [GENERATED]  ->  /  /
    New-MDARandomUser : Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:435 char:50
    +     $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    +                                                  ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [New-MDARandomUser], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorEmptyCollectionNotAllowed,New-MDARandomUser

    [GENERATED]  ->  /  /
    New-MDARandomUser : Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:435 char:50
    +     $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    +                                                  ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [New-MDARandomUser], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorEmptyCollectionNotAllowed,New-MDARandomUser

    [GENERATED]  ->  /  /
    New-MDARandomUser : Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:435 char:50
    +     $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    +                                                  ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [New-MDARandomUser], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorEmptyCollectionNotAllowed,New-MDARandomUser

    [GENERATED]  ->  /  /
    New-MDARandomUser : Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:435 char:50
    +     $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    +                                                  ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [New-MDARandomUser], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorEmptyCollectionNotAllowed,New-MDARandomUser

    [GENERATED]  ->  /  /
    New-MDARandomUser : Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:435 char:50
    +     $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    +                                                  ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [New-MDARandomUser], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorEmptyCollectionNotAllowed,New-MDARandomUser

    [GENERATED]  ->  /  /
    New-MDARandomUser : Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:435 char:50
    +     $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    +                                                  ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [New-MDARandomUser], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorEmptyCollectionNotAllowed,New-MDARandomUser

    [GENERATED]  ->  /  /
    New-MDARandomUser : Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:435 char:50
    +     $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    +                                                  ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [New-MDARandomUser], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorEmptyCollectionNotAllowed,New-MDARandomUser

    [GENERATED]  ->  /  /
    New-MDARandomUser : Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:435 char:50
    +     $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    +                                                  ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [New-MDARandomUser], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorEmptyCollectionNotAllowed,New-MDARandomUser

    [GENERATED]  ->  /  /
    New-MDARandomUser : Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:435 char:50
    +     $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    +                                                  ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [New-MDARandomUser], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorEmptyCollectionNotAllowed,New-MDARandomUser

    [GENERATED]  ->  /  /
    New-MDARandomUser : Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:435 char:50
    +     $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    +                                                  ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [New-MDARandomUser], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorEmptyCollectionNotAllowed,New-MDARandomUser

    [GENERATED]  ->  /  /
    New-MDARandomUser : Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:435 char:50
    +     $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    +                                                  ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [New-MDARandomUser], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorEmptyCollectionNotAllowed,New-MDARandomUser

    [GENERATED]  ->  /  /
    New-MDARandomUser : Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:435 char:50
    +     $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    +                                                  ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [New-MDARandomUser], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorEmptyCollectionNotAllowed,New-MDARandomUser

    [GENERATED]  ->  /  /
    New-MDARandomUser : Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:435 char:50
    +     $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    +                                                  ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [New-MDARandomUser], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorEmptyCollectionNotAllowed,New-MDARandomUser

    [GENERATED]  ->  /  /
    New-MDARandomUser : Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:435 char:50
    +     $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    +                                                  ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [New-MDARandomUser], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorEmptyCollectionNotAllowed,New-MDARandomUser

    [GENERATED]  ->  /  /
    Test-MDAGeneratedSchema : Cannot bind argument to parameter 'Users' because it is null.
    At C:\Windows\Tasks\generate_vulnerable_schema.ps1:447 char:12
    +     -Users @($generatedUsers) `
    +            ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [Test-MDAGeneratedSchema], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorNullNotAllowed,Test-MDAGeneratedSchema


    ========================================
    GENERATION SUMMARY
    ========================================
    Total Users:              20
    Weak Password Users:      0
    Stronger Password Users:  0
    Policy-Failure Users:     0
    ========================================

    [COMPLETE] Generated schema written to:
    .\out.json
    ```

    - Did not do what I wanted, but hey. At least its telling us what's wrong.
    - The generator failed while creating the new randomized schema. The key error is: `Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.`
    - I have deemed the failure occures at line 435, where the script calls:

    ```script
    $user = New-MDARandomUser -ExistingUsernames $existingUsernames
    ```

    - I had to do some finagling, but I also recovered the `out.json` file it created to look at. And I can confirm, it did not generate what I wanted.
    - I will need to modify the `New-MDARandomUser` so that an empty username collection is valid on the first iteration.
    - Replaced the old iteration with this:

    ```script
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

    # Add the generated user to the output collection
    [void]$generatedUsers.Add($user)

    # Track the username so future iterations cannot generate duplicates
    [void]$existingUsernames.Add($user.username)

    Write-Output "[GENERATED] Username: $($user.username)"
    Write-Output "[GENERATED] Name: $($user.first_name) $($user.last_name)"
    Write-Output "[GENERATED] Department: $($user.department)"
    Write-Output "[GENERATED] Job Title: $($user.job_title)"
    Write-Output "[GENERATED] Password Class: $($user.password_classification)"
    }
    ```

    - It keeps the existing structure, preserves the username collection, and makes the generated object creation easier to debug now.
    - Now I need to replace the old version of the script with the new on on the DC, I'll attempt to delete the old `generate_vulnerable_schema.ps1` but keep the `out.json` file.
    - I'll name the new json file it creats `vuln_schema.json`.
