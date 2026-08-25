# 05 Testing Program & Experimenting

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
    PS C:\Windows\Tasks> .\gen_vuln_schema.ps1 `
    >>     -OutputPath ".\generated_vuln_schema.json" `
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
    - Otherwise, the function itself is reasonable.

    - Unfortunately, I am having the same issue again. The next best thing for me to do is to keep the parameter mandatory but explicitly initialize `$existingUsernames` in the calling scope with an actual empty `HashSet[string]` and pass it in.
    - The current error strongly suggests that $existingUsernames itself is already an empty HashSet, so the binder is objecting specifically to an empty collection being supplied to a mandatory collection parameter.

    - Applied the changes I needed, apparently, I was not pasting in the corrections, or they weren't saving properly. So I made the changes on my host machine, saved it, made a mess, cleaned it, and now I am going to pass the right file into the DC, and finally test it.
    - IT WORKS!!!! LESSSSSSSSSSSSS GOOOOOOOOOOOOOOOOOOO

    ```shell
    [SEED] Random generation seed set to 5024

    ========================================
    MDA VULNERABLE SCHEMA GENERATOR
    ========================================
    Users Requested:        20
    Weak Password Percent:  35%
    Policy Failures:        False
    Output Path:            .\generated_vuln_schema.json
    ========================================
    [GENERATED] felix_grey -> Surveillance / Surveillance Agent / weak
    [GENERATED] ivan_west -> Distribution / Asset Distribution Analyst / stronger
    [GENERATED] elena_dalton -> Distribution / Distribution Specialist / weak
    [GENERATED] julia_dalton -> Distribution / Distribution Specialist / stronger
    [GENERATED] bianca_ellis -> Surveillance / Surveillance Analyst / stronger
    [GENERATED] helena_cole -> Distribution / Auction Operations Specialist / stronger
    [GENERATED] priya_reed -> Distribution / Asset Distribution Analyst / stronger
    [GENERATED] elias_pierce -> Evaluation / Evaluation Specialist / stronger
    [GENERATED] lena_frost -> Registration / Records Specialist / stronger
    [GENERATED] elena_price -> Distribution / Distribution Specialist / stronger
    [GENERATED] yara_vale -> Evaluation / Mythic Assessment Specialist / stronger
    [GENERATED] selene_hayes -> Registration / Guild Registration Analyst / weak
    [GENERATED] helena_turner -> Registration / Registration Specialist / stronger
    [GENERATED] jade_morrow -> Information Technology / IT Operations Analyst / stronger
    [GENERATED] isaac_grey -> Information Technology / IT Operations Analyst / stronger
    [GENERATED] yara_nolan -> Information Technology / Information Technology Technician / stronger
    [GENERATED] diana_archer -> Surveillance / Surveillance Analyst / weak
    [GENERATED] diana_cross -> Surveillance / Surveillance Agent / stronger
    [GENERATED] nadia_ellis -> Evaluation / Evaluation Specialist / stronger
    [GENERATED] orion_owens -> Information Technology / IT Operations Analyst / stronger

    ========================================
    Validating Generated Schema
    ========================================
    [SCHEMA VALID] Generated schema passed validation.

    ========================================
    GENERATION SUMMARY
    ========================================
    Total Users:              20
    Weak Password Users:      4
    Stronger Password Users:  16
    Policy-Failure Users:     0
    ========================================

    [COMPLETE] Generated schema written to:
    .\generated_vuln_schema.json
    ```

    - I was not making the changes I wanted to make, but now, it works. And I copied the generated json file to this project, too.
    - I also reran the script, and it seemed not to break anything.

    ```shell
    [SEED] Random generation seed set to 5024

    ========================================
    MDA VULNERABLE SCHEMA GENERATOR
    ========================================
    Users Requested:        20
    Weak Password Percent:  35%
    Policy Failures:        False
    Output Path:            .\generated_vuln_schema.json
    ========================================
    [GENERATED] felix_grey -> Surveillance / Surveillance Agent / weak
    [GENERATED] ivan_west -> Distribution / Asset Distribution Analyst / stronger
    [GENERATED] elena_dalton -> Distribution / Distribution Specialist / weak
    [GENERATED] julia_dalton -> Distribution / Distribution Specialist / stronger
    [GENERATED] bianca_ellis -> Surveillance / Surveillance Analyst / stronger
    [GENERATED] helena_cole -> Distribution / Auction Operations Specialist / stronger
    [GENERATED] priya_reed -> Distribution / Asset Distribution Analyst / stronger
    [GENERATED] elias_pierce -> Evaluation / Evaluation Specialist / stronger
    [GENERATED] lena_frost -> Registration / Records Specialist / stronger
    [GENERATED] elena_price -> Distribution / Distribution Specialist / stronger
    [GENERATED] yara_vale -> Evaluation / Mythic Assessment Specialist / stronger
    [GENERATED] selene_hayes -> Registration / Guild Registration Analyst / weak
    [GENERATED] helena_turner -> Registration / Registration Specialist / stronger
    [GENERATED] jade_morrow -> Information Technology / IT Operations Analyst / stronger
    [GENERATED] isaac_grey -> Information Technology / IT Operations Analyst / stronger
    [GENERATED] yara_nolan -> Information Technology / Information Technology Technician / stronger
    [GENERATED] diana_archer -> Surveillance / Surveillance Analyst / weak
    [GENERATED] diana_cross -> Surveillance / Surveillance Agent / stronger
    [GENERATED] nadia_ellis -> Evaluation / Evaluation Specialist / stronger
    [GENERATED] orion_owens -> Information Technology / IT Operations Analyst / stronger

    ========================================
    Validating Generated Schema
    ========================================
    [SCHEMA VALID] Generated schema passed validation.

    ========================================
    GENERATION SUMMARY
    ========================================
    Total Users:              20
    Weak Password Users:      4
    Stronger Password Users:  16
    Policy-Failure Users:     0
    ========================================

    [COMPLETE] Generated schema written to:
    .\generated_vuln_schema.json
    ```

    - I did it on purpose, because I thought I didn't copy the information of the first run through, but I did.
    - But, hey! I tested rerunability, too, so two birds, one stone.

3. Logging into a generated account.

    - We are going to log into the WS01 with Felix Grey.

    ```script
    "first_name":  "Felix",
    "last_name":  "Grey",
    "password":  "Password2026!",
    "username":  "felix_grey",
    ```

    - Neither River or Felix works, now. I think I might need to diconnect the WS01 from the domain, and reconnect it to update it. HOWEVER, it does not say neither exists, but that the password or username might be wrong...
    - Okay, I did some tests.
    - For River:

    ```shell
    DistinguishedName : CN=Arthur River,OU=Surveillance,OU=Users,OU=MDA,DC=MDA,DC=com
    Enabled           : True
    GivenName         : Arthur
    LockedOut         : False
    Name              : Arthur River
    ObjectClass       : user
    ObjectGUID        : 3fafd3e7-82b2-4539-b5d7-6d78be4a085e
    PasswordExpired   : True
    SamAccountName    : arthur_river
    SID               : S-1-5-21-4252272573-727251941-1119735190-1119
    Surname           : River
    UserPrincipalName : arthur_river@MDA.com
    ```

    - For Felix Grey:

    ```shell
    first_name                : Felix
    last_name                 : Grey
    password                  : Password2026!
    username                  : felix_grey
    department                : Surveillance
    job_title                 : Surveillance Agent
    groups                    : {MDA_Surveillance}
    account_type              : standard
    generated                 : True
    password_classification   : weak
    intentional_vulnerability : Guessable lab password that may satisfy complexity requirements but remains poor security
                                practice.
    ```

    - The WS01's Local admin:

    ```shell
    PS C:\Users\Local_Admin> whoami
    workstation\local_admin
    PS C:\Users\Local_Admin> $env:USERDNSDOMAIN
    PS C:\Users\Local_Admin> ipconfig /all

    Windows IP Configuration

    Host Name . . . . . . . . . . . . : Workstation
    Primary Dns Suffix  . . . . . . . : MDA.com
    Node Type . . . . . . . . . . . . : Hybrid
    IP Routing Enabled. . . . . . . . : No
    WINS Proxy Enabled. . . . . . . . : No
    DNS Suffix Search List. . . . . . : MDA.com
                                        localdomain

    Ethernet adapter Ethernet0:

    Connection-specific DNS Suffix  . : localdomain
    Description . . . . . . . . . . . : Intel(R) 82574L Gigabit Network Connection
    Physical Address. . . . . . . . . : 00-0C-29-02-B2-AF
    DHCP Enabled. . . . . . . . . . . : Yes
    Autoconfiguration Enabled . . . . : Yes
    Link-local IPv6 Address . . . . . : fe80::5cb9:e8c:9ff7:3692%4(Preferred)
    IPv4 Address. . . . . . . . . . . : 192.168.244.139(Preferred)
    Subnet Mask . . . . . . . . . . . : 255.255.255.0
    Lease Obtained. . . . . . . . . . : Tuesday, August 25, 2026 2:47:46 PM
    Lease Expires . . . . . . . . . . : Tuesday, August 25, 2026 3:47:49 PM
    Default Gateway . . . . . . . . . : 192.168.244.2
    DHCP Server . . . . . . . . . . . : 192.168.244.254
    DHCPv6 IAID . . . . . . . . . . . : 83889193
    DHCPv6 Client DUID. . . . . . . . : 00-01-01-00-32-16-A6-CA-00-0C-29-02-B2-AF
    DNS Servers . . . . . . . . . . . : 192.168.244.155
    Primary WINS Server . . . . . . . : 192.168.244.2
    NetBIOS over Tcpip. . . . . . . . : Enabled
    PS C:\Users\Local_Admin> Test-ComputerSecureChannel -Verbose
    VERBOSE: Performing the operation "Test-ComputerSecureChannel" on target "WORKSTATION".
    True
    VERBOSE: The secure channel between the local computer and the domain MDA.com is in good condition.
    ```

    - For River's account, his latest password doesn't work, and the "change me" password doesn't either. Plus, Felix's generated password did not work.
    - Fortunately, the evidence narrows this considerably.
    - First, I tested whether the password is actually what AD thinks it is by resetting it myself on DC1. Then verified their experiation after.

    ```shell
    PS C:\Windows\Tasks> Set-ADAccountPassword `
    >>     -Identity "adm_arthur_river" `
    >>     -Reset `
    >>     -NewPassword (ConvertTo-SecureString "AMD_R!v3rAnrth3r_123!" -AsPlainText -Force)
    
    PS C:\Windows\Tasks> Set-ADAccountPassword `
    >>     -Identity "arthur_river" `
    >>     -Reset `
    >>     -NewPassword (ConvertTo-SecureString "R!v3rAnrth3r_123!" -AsPlainText -Force)
    
    PS C:\Windows\Tasks> Get-ADUser "arthur_river" -Properties PasswordExpired,PasswordLastSet,Enabled,LockedOut |
    >>     Select-Object SamAccountName,Enabled,LockedOut,PasswordExpired,PasswordLastSet


    SamAccountName  : arthur_river
    Enabled         : True
    LockedOut       : False
    PasswordExpired : False
    PasswordLastSet : 8/25/2026 3:27:05 PM
    
    PS C:\Windows\Tasks> Get-ADUser "adm_arthur_river" -Properties PasswordExpired,PasswordLastSet,Enabled,LockedOut |
    >>     Select-Object SamAccountName,Enabled,LockedOut,PasswordExpired,PasswordLastSet


    SamAccountName  : adm_arthur_river
    Enabled         : True
    LockedOut       : False
    PasswordExpired : False
    PasswordLastSet : 8/25/2026 3:26:41 PM
    ```

    - Then I logged in as river's base standard account, it worked. I followed that by logging into River's priviledged account.
    - It now also works, again.
    - Now I am going to rechange their passwords, to match the spelling of their name, again. Cause I think I butchered it again.
    - Tested Felix Grey, and he does not exist as an object in the AD. While the `gen_vuln_schema.ps1` ran successfully, and generated `genereated_vuln_schema.json`, it did not add what it created into the AD itself.
    - I have a failed identity-provisioning workflow, but I am identifying why.
    - First, I checked for Felix on DC1, but it came up with errors that he does not exist.

    ```shell
    PS C:\Windows\Tasks> Set-ADAccountPassword `
    >>     -Identity "felix_grey" `
    >>     -Reset `
    >>     -NewPassword (ConvertTo-SecureString "gr3yf3l!x123!" -AsPlainText -Force)
    Set-ADAccountPassword : Cannot find an object with identity: 'felix_grey' under: 'DC=MDA,DC=com'.
    At line:1 char:1
    + Set-ADAccountPassword `
    + ~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : ObjectNotFound: (felix_grey:ADAccount) [Set-ADAccountPassword], ADIdentityNotFoundException
    + FullyQualifiedErrorId : ActiveDirectoryCmdlet:Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException,Microsoft.ActiveDirectory.Management.Commands.SetADAccountPassword

    PS C:\Windows\Tasks> Get-ADUser "felix_grey" -Properties PasswordExpired,PasswordLastSet,Enabled,LockedOut |
    >>     Select-Object SamAccountName,Enabled,LockedOut,PasswordExpired,PasswordLastSet
    Get-ADUser : Cannot find an object with identity: 'felix_grey' under: 'DC=MDA,DC=com'.
    At line:1 char:1
    + Get-ADUser "felix_grey" -Properties PasswordExpired,PasswordLastSet,E ...
    + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : ObjectNotFound: (felix_grey:ADUser) [Get-ADUser], ADIdentityNotFoundException
    + FullyQualifiedErrorId : ActiveDirectoryCmdlet:Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException,M
   icrosoft.ActiveDirectory.Management.Commands.GetADUser
   ```

    - I then checked the existing ADUsers.

    ```shell
    PS C:\Windows\Tasks> Get-ADUser -Filter * |
    >>     Select-Object SamAccountName, UserPrincipalName, Enabled |
    >>     Sort-Object SamAccountName

    SamAccountName    UserPrincipalName         Enabled
    --------------    -----------------         -------
    adm_arthur_river  adm_arthur_river@MDA.com     True
    adm_lucy_hill     adm_lucy_hill@MDA.com        True
    adm_milan_schmidt adm_milan_schmidt@MDA.com    True
    adm_robert_gordon adm_robert_gordon@MDA.com    True
    adm_truman_sweet  adm_truman_sweet@MDA.com     True
    Administrator                                  True
    alina_cox         alina_cox@MDA.com            True
    arthur_river      arthur_river@MDA.com         True
    brentley_terry    brentley_terry@MDA.com       True
    Guest                                         False
    jess_martin       jess_martin@MDA.com          True
    krbtgt                                        False
    lucy_hill         lucy_hill@MDA.com            True
    luke_gibson       luke_gibson@MDA.com          True
    milan_schmidt     milan_schmidt@MDA.com        True
    robert_gordon     robert_gordon@MDA.com        True
    scott_kang        scott_kang@MDA.com           True
    truman_sweet      truman_sweet@MDA.com         True
    ```

    - .
