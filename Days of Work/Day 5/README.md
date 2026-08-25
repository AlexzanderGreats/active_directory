# 4 Testing Program & Experimenting

1. Took a break after writing the code, and today I tested it.

    - I copied the code over into the DC, and ran it.
    - It was supposed to create a new json file, named `out.json`. Which it did, but it failed on some other stuff

    ```shell
    Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
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

2. Testing new script & generating `vuln_schema.json`.

    - Okay, removed the old, put in the new.
    - Tested the file, and got a similar error message.

    - Basically, the loop was not the real problem. It seems now that the error occures before `New-MDARandomUser` can execute.

    ```shell
    Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    ```

    - It appears to be the same problem, actually, I just didn't patch it correctly.
    - Added a proper handeling of the iteration, since the first intended state is empty, then it creats things from there.

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

        [void]$generatedUsers.Add($user)

        [void]$existingUsernames.Add($user.username)

        Write-Output "[GENERATED] Username: $($user.username)"
        Write-Output "[GENERATED] Name: $($user.first_name) $($user.last_name)"
        Write-Output "[GENERATED] Department: $($user.department)"
        Write-Output "[GENERATED] Job Title: $($user.job_title)"
        Write-Output "[GENERATED] Password Class: $($user.password_classification)"
    }
    ```

    - So now, I am going to repeat the test again, and see what changes.
    - I noticed I wes not using the seed function, like I wanted to, but that's okay. I am going to be using this command to repeat the test if it keeps failing

    ```shell
    PS C:\Windows\Tasks> .\generate_vulnerable_schema.ps1 `
    >>     -OutputPath ".\generated_vulnerable_schema.json" `
    >>     -UserCount 20 `
    >>     -WeakPasswordPercent 35 `
    >>     -Seed 5024
    ```

    - Similar erros this time.

    ```shell
    Cannot bind argument to parameter 'ExistingUsernames' because it is an empty collection.
    ```

    - This is happening because $existingUsernames is correctly empty on the first iteration, but the function's parameter definition apparently forbids an empty collection.
    - I need to fix the New-MDARandomUser parameter so an empty collection is valid.
    - My parameter is explicitly typed as `HashSet[string]`, and PowerShell's parameter binder is rejecting the empty collection before the function body executes.
    - Otherwise, the function itself is reasonable. However, there is an even better option for this particular generator: keep the parameter mandatory but explicitly initialize `$existingUsernames` in the calling scope with an actual empty `HashSet[string]` and pass it in.
    - The current error strongly suggests that $existingUsernames itself is already an empty HashSet, so the binder is objecting specifically to an empty collection being supplied to a mandatory collection parameter.
