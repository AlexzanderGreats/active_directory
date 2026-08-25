# 06 Debugging & Logging onto generated vulnerable accounts

1. Logging into a generated account.

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

    - Now I am going to check the script, because it seems the AD provisioning script is apparently still operating against the original schema/account set, or isn't being invoked against the newly generated schema at all.
    - Okay, realiziation time. I did not run the `generated_vuln_schema.json` at all through `gen_ad.ps1` to add Felix or the others to the AD.
    - Good news: I figured out what was going on. Bad news: I need to do more work.

    - Checked the `gen_ad.ps1` file, just in case, and if I run what I was supposed to run, it would not harm anything that I already have. But, what I will do, is shut down DC1, take a snapshot of it, then run go through this part that I skipped.
    - I ran the JSON file through the script, and it produced the new users.

    ```shell
    [192.168.244.155]: PS C:\Windows\Tasks> .\gen_ad.ps1 -JSONfile ".\generated_vuln_schema.json"

    ========================================
    MDA ACTIVE DIRECTORY GENERATOR
    ========================================
    JSON File: .\generated_vuln_schema.json
    Base DN: DC=MDA,DC=com
    Root OU: MDA
    ========================================

    ========================================
    Validating JSON Schema
    ========================================
    [SCHEMA VALID] No blocking errors detected.

    ========================================
    Creating MDA Organizational Units
    ========================================
    [OU EXISTS] MDA
    [OU EXISTS] Users
    [OU EXISTS] Privileged Accounts
    [OU EXISTS] Groups
    [OU EXISTS] Workstations
    [OU EXISTS] Servers
    [OU EXISTS] Surveillance
    [OU EXISTS] Surveillance
    [OU EXISTS] Information Technology
    [OU EXISTS] Information Technology
    [OU EXISTS] Evaluation
    [OU EXISTS] Evaluation
    [OU EXISTS] Registration
    [OU EXISTS] Registration
    [OU EXISTS] Distribution
    [OU EXISTS] Distribution

    ========================================
    Creating MDA Security Groups
    ========================================
    [GROUP EXISTS] MDA_Surveillance
    [GROUP EXISTS] MDA_Surveillance_Chiefs
    [GROUP EXISTS] MDA_Surveillance_Admins
    [GROUP EXISTS] MDA_IT
    [GROUP EXISTS] MDA_IT_Chiefs
    [GROUP EXISTS] MDA_IT_Admins
    [GROUP EXISTS] MDA_Evaluation
    [GROUP EXISTS] MDA_Evaluation_Chiefs
    [GROUP EXISTS] MDA_Evaluation_Admins
    [GROUP EXISTS] MDA_Registration
    [GROUP EXISTS] MDA_Registration_Chiefs
    [GROUP EXISTS] MDA_Registration_Admins
    [GROUP EXISTS] MDA_Distribution
    [GROUP EXISTS] MDA_Distribution_Chiefs
    [GROUP EXISTS] MDA_Distribution_Admins

    ----------------------------------------
    Processing: Felix Grey
    Username: felix_grey
    Department: Surveillance
    Position: Surveillance Agent
    Account Type: standard
    ----------------------------------------
    OU: OU=Surveillance,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Felix Grey (felix_grey)
    [ADDING TO GROUP] felix_grey -> MDA_Surveillance

    ----------------------------------------
    Processing: Ivan West
    Username: ivan_west
    Department: Distribution
    Position: Asset Distribution Analyst
    Account Type: standard
    ----------------------------------------
    OU: OU=Distribution,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Ivan West (ivan_west)
    [ADDING TO GROUP] ivan_west -> MDA_Distribution

    ----------------------------------------
    Processing: Elena Dalton
    Username: elena_dalton
    Department: Distribution
    Position: Distribution Specialist
    Account Type: standard
    ----------------------------------------
    OU: OU=Distribution,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Elena Dalton (elena_dalton)
    [ADDING TO GROUP] elena_dalton -> MDA_Distribution

    ----------------------------------------
    Processing: Julia Dalton
    Username: julia_dalton
    Department: Distribution
    Position: Distribution Specialist
    Account Type: standard
    ----------------------------------------
    OU: OU=Distribution,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Julia Dalton (julia_dalton)
    [ADDING TO GROUP] julia_dalton -> MDA_Distribution

    ----------------------------------------
    Processing: Bianca Ellis
    Username: bianca_ellis
    Department: Surveillance
    Position: Surveillance Analyst
    Account Type: standard
    ----------------------------------------
    OU: OU=Surveillance,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Bianca Ellis (bianca_ellis)
    [ADDING TO GROUP] bianca_ellis -> MDA_Surveillance

    ----------------------------------------
    Processing: Helena Cole
    Username: helena_cole
    Department: Distribution
    Position: Auction Operations Specialist
    Account Type: standard
    ----------------------------------------
    OU: OU=Distribution,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Helena Cole (helena_cole)
    [ADDING TO GROUP] helena_cole -> MDA_Distribution

    ----------------------------------------
    Processing: Priya Reed
    Username: priya_reed
    Department: Distribution
    Position: Asset Distribution Analyst
    Account Type: standard
    ----------------------------------------
    OU: OU=Distribution,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Priya Reed (priya_reed)
    [ADDING TO GROUP] priya_reed -> MDA_Distribution

    ----------------------------------------
    Processing: Elias Pierce
    Username: elias_pierce
    Department: Evaluation
    Position: Evaluation Specialist
    Account Type: standard
    ----------------------------------------
    OU: OU=Evaluation,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Elias Pierce (elias_pierce)
    [ADDING TO GROUP] elias_pierce -> MDA_Evaluation

    ----------------------------------------
    Processing: Lena Frost
    Username: lena_frost
    Department: Registration
    Position: Records Specialist
    Account Type: standard
    ----------------------------------------
    OU: OU=Registration,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Lena Frost (lena_frost)
    [ADDING TO GROUP] lena_frost -> MDA_Registration

    ----------------------------------------
    Processing: Elena Price
    Username: elena_price
    Department: Distribution
    Position: Distribution Specialist
    Account Type: standard
    ----------------------------------------
    OU: OU=Distribution,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Elena Price (elena_price)
    [ADDING TO GROUP] elena_price -> MDA_Distribution

    ----------------------------------------
    Processing: Yara Vale
    Username: yara_vale
    Department: Evaluation
    Position: Mythic Assessment Specialist
    Account Type: standard
    ----------------------------------------
    OU: OU=Evaluation,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Yara Vale (yara_vale)
    [ADDING TO GROUP] yara_vale -> MDA_Evaluation

    ----------------------------------------
    Processing: Selene Hayes
    Username: selene_hayes
    Department: Registration
    Position: Guild Registration Analyst
    Account Type: standard
    ----------------------------------------
    OU: OU=Registration,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Selene Hayes (selene_hayes)
    [ADDING TO GROUP] selene_hayes -> MDA_Registration

    ----------------------------------------
    Processing: Helena Turner
    Username: helena_turner
    Department: Registration
    Position: Registration Specialist
    Account Type: standard
    ----------------------------------------
    OU: OU=Registration,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Helena Turner (helena_turner)
    [ADDING TO GROUP] helena_turner -> MDA_Registration

    ----------------------------------------
    Processing: Jade Morrow
    Username: jade_morrow
    Department: Information Technology
    Position: IT Operations Analyst
    Account Type: standard
    ----------------------------------------
    OU: OU=Information Technology,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Jade Morrow (jade_morrow)
    [ADDING TO GROUP] jade_morrow -> MDA_IT

    ----------------------------------------
    Processing: Isaac Grey
    Username: isaac_grey
    Department: Information Technology
    Position: IT Operations Analyst
    Account Type: standard
    ----------------------------------------
    OU: OU=Information Technology,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Isaac Grey (isaac_grey)
    [ADDING TO GROUP] isaac_grey -> MDA_IT

    ----------------------------------------
    Processing: Yara Nolan
    Username: yara_nolan
    Department: Information Technology
    Position: Information Technology Technician
    Account Type: standard
    ----------------------------------------
    OU: OU=Information Technology,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Yara Nolan (yara_nolan)
    [ADDING TO GROUP] yara_nolan -> MDA_IT

    ----------------------------------------
    Processing: Diana Archer
    Username: diana_archer
    Department: Surveillance
    Position: Surveillance Analyst
    Account Type: standard
    ----------------------------------------
    OU: OU=Surveillance,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Diana Archer (diana_archer)
    [ADDING TO GROUP] diana_archer -> MDA_Surveillance

    ----------------------------------------
    Processing: Diana Cross
    Username: diana_cross
    Department: Surveillance
    Position: Surveillance Agent
    Account Type: standard
    ----------------------------------------
    OU: OU=Surveillance,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Diana Cross (diana_cross)
    [ADDING TO GROUP] diana_cross -> MDA_Surveillance

    ----------------------------------------
    Processing: Nadia Ellis
    Username: nadia_ellis
    Department: Evaluation
    Position: Evaluation Specialist
    Account Type: standard
    ----------------------------------------
    OU: OU=Evaluation,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Nadia Ellis (nadia_ellis)
    [ADDING TO GROUP] nadia_ellis -> MDA_Evaluation

    ----------------------------------------
    Processing: Orion Owens
    Username: orion_owens
    Department: Information Technology
    Position: IT Operations Analyst
    Account Type: standard
    ----------------------------------------
    OU: OU=Information Technology,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Orion Owens (orion_owens)
    [ADDING TO GROUP] orion_owens -> MDA_IT

    ========================================
    MDA ACTIVE DIRECTORY SUMMARY
    ========================================
    Standard Accounts:   20
    Privileged Accounts: 0
    Total Accounts:      20
    Security Groups:     15
    ========================================

    [COMPLETE] MDA Active Directory generation finished.
    ```

    - I am going to test Felix again this time, and then log into the WS01 through his account.
    - He exists!

    ```shell
    [192.168.244.155]: PS C:\Windows\Tasks> Get-ADUser "felix_grey" -Properties PasswordExpired,PasswordLastSet,Enabled,LockedOut |
    >>     Select-Object SamAccountName,Enabled,LockedOut,PasswordExpired,PasswordLastSet


    SamAccountName  : felix_grey
    Enabled         : True
    LockedOut       : False
    PasswordExpired : True
    PasswordLastSet :
    ```

    - I am going to real quick check if the others exist, too.

    ```shell
    Get-ADUser -Filter * |
    Select-Object SamAccountName, UserPrincipalName, Enabled |
    Sort-Object SamAccountName
    
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
    bianca_ellis      bianca_ellis@MDA.com         True
    brentley_terry    brentley_terry@MDA.com       True
    diana_archer      diana_archer@MDA.com         True
    diana_cross       diana_cross@MDA.com          True
    elena_dalton      elena_dalton@MDA.com         True
    elena_price       elena_price@MDA.com          True
    elias_pierce      elias_pierce@MDA.com         True
    felix_grey        felix_grey@MDA.com           True
    Guest                                         False
    helena_cole       helena_cole@MDA.com          True
    helena_turner     helena_turner@MDA.com        True
    isaac_grey        isaac_grey@MDA.com           True
    ivan_west         ivan_west@MDA.com            True
    jade_morrow       jade_morrow@MDA.com          True
    jess_martin       jess_martin@MDA.com          True
    julia_dalton      julia_dalton@MDA.com         True
    krbtgt                                        False
    lena_frost        lena_frost@MDA.com           True
    lucy_hill         lucy_hill@MDA.com            True
    luke_gibson       luke_gibson@MDA.com          True
    milan_schmidt     milan_schmidt@MDA.com        True
    nadia_ellis       nadia_ellis@MDA.com          True
    orion_owens       orion_owens@MDA.com          True
    priya_reed        priya_reed@MDA.com           True
    robert_gordon     robert_gordon@MDA.com        True
    scott_kang        scott_kang@MDA.com           True
    selene_hayes      selene_hayes@MDA.com         True
    truman_sweet      truman_sweet@MDA.com         True
    yara_nolan        yara_nolan@MDA.com           True
    yara_vale         yara_vale@MDA.com            True
    ```

    - Now am going to log in as Felix. Log in worked, and it prompted me to change the password! Besides that, everything works as it should.
