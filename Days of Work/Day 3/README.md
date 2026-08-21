# 02 Determining Next Steps & Automating DOMAIN USERS

1. Produced AD schema json file.

    - Added users and groups.
    - Created meta data for each user.

    ```ad_schema.json
    "users": [
        {
            "first_name": "Arthur",
            "last_name": "River",
            "password": "ChangeMe-SURV-001!",
            "username": "arthur_river",
            "department": "Surveillance",
            "job_title": "Surveillance Chief",
            "groups": ["MDA_Surveillance_Chiefs", "MDA_Surveillance"],
            "account_type": "standard"
        },
        {
            "first_name": "Arthur",
            "last_name": "River",
            "password": "ChangeMe-SURV-ADM-001!",
            "username": "adm_arthur_river",
            "department": "Surveillance",
            "job_title": "Surveillance Chief",
            "account_purpose": "department_admin",
            "groups": ["MDA_Surveillance_Admins"],
            "account_type": "privileged"
        }
    ]
    "groups": [
        {"name": "MDA_Surveillance"},
        {"name": "MDA_Surveillance_Chiefs"},
        {"name": "MDA_Surveillance_Admins"},
        {"name": "MDA_IT"},
        {"name": "MDA_IT_Chiefs"},
        {"name": "MDA_IT_Admins"},
        {"name": "MDA_Evaluation"},
        {"name": "MDA_Evaluation_Chiefs"},
        {"name": "MDA_Evaluation_Admins"},
        {"name": "MDA_Registration"},
        {"name": "MDA_Registration_Chiefs"},
        {"name": "MDA_Registration_Admins"},
        {"name": "MDA_Distribution"},
        {"name": "MDA_Distribution_Chiefs"},
        {"name": "MDA_Distribution_Admins"}
    ]
    ```

    - For chiefs, they have to accounts, one standard and one priviledged. As for regular empoyees, they have a single, standard account.

2. Produced a OU structure and permissions model.

    - I am going to preserve the roles I originally established for the lab rather than letting the JSON's temporary job-title wording redefine them.
    - I have five departments, each with one senior employee, and one ordinary employyee.
    - The five senior employees receive seperate privileged accounts.

    ```Personnel Model
    | Department   | Employee       | Position                 | Standard Account | Privileged Account  |
    | ------------ | -------------- | ------------------------ | ---------------- | ------------------- |
    | Surveillance | Arthur River   | Surveillance Chief       | `arthur_river`   | `adm_arthur_river`  |
    | Surveillance | Scott Kang     | Surveillance Agent       | `scott_kang`     | —                   |
    | IT           | Robert Gordon  | Administrator / IT Chief | `robert_gordon`  | `adm_robert_gordon` |
    | IT           | Luke Gibson    | IT Technician            | `luke_gibson`    | —                   |
    | Evaluation   | Lucy Hill      | Chief Evaluator          | `lucy_hill`      | `adm_lucy_hill`     |
    | Evaluation   | Brentley Terry | Evaluator Specialist     | `brentley_terry` | —                   |
    | Registration | Truman Sweet   | Chief Registrar          | `truman_sweet`   | `adm_truman_sweet`  |
    | Registration | Jess Martin    | Registrar Specialist     | `jess_martin`    | —                   |
    | Distribution | Milan Schmidt  | Distribution Chief       | `milan_schmidt`  | `adm_milan_schmidt` |
    | Distribution | Alina Cox      | Distribution Specialist  | `alina_cox`      | —                   |
    ```

    ```OU Structure:
    MDA
    │
    ├── Users
    │   ├── Surveillance
    │   ├── Information Technology
    │   ├── Evaluation
    │   ├── Registration
    │   └── Distribution
    │
    ├── Privileged Accounts
    │   ├── Surveillance
    │   ├── Information Technology
    │   ├── Evaluation
    │   ├── Registration
    │   └── Distribution
    │
    ├── Workstations
    │
    ├── Servers
    │
    └── Groups
    ```

    - This gives a useful distinction between standard user accounts and privileged administrative accounts. Also means they don't reside in the same OU hierarchy.
    - There are now three group layers. Department group, Leadership/business-role group, and Administrative priviledge group. Answering distinct questions.

    ```Table:
    | Group                     | Question                                                        |
    | ------------------------- | --------------------------------------------------------------- |
    | `MDA_Surveillance`        | Does this person work in Surveillance?                          |
    | `MDA_Surveillance_Chiefs` | Does this person hold the Surveillance Chief role?              |
    | `MDA_Surveillance_Admins` | May this account perform delegated Surveillance administration? |
    ```

3. What should priviledged accounts actually do?

    - Administrative groups should eventually recieve delegated controll over their own departmental OU.
    - For example, Agent River might eventually be permitted to reset Surveillance employee passwords, lock/unlock Surveillance accounts, perhaps modify selected departmental group memberships, manage certain Surveillance resources.
    - But he should not have Domain Controller administration, Evaluation administration, IT administration, permissions to creation of Domain Admins, or unrestricted domain-wide user management.
    - However, Mr. Gordon should eventually possess broader adminitrative authority. Though, he should not be in every privileged group imaginable. I should start with only the permissions necessary for this simulation.
    - Mr. Gibson is intereting, too. As the IT technician, he could eventually recieve limited help-desk permissions without recieving a second priviledged account yet.
    - OR add one later once I understand delagtion well enough to justify it.

4. Resource Permissions.

    - I will eventually need to create departmental shares.

    ```Departmental Shares:
    \\MDA-SRV01\Surveillance
    \\MDA-SRV01\Evaluation
    \\MDA-SRV01\Registration
    \\MDA-SRV01\Distribution
    \\MDA-SRV01\IT
    ```

    - And establish basic rules.

    ```Rules:
    | Resource     | Ordinary Department | Chief          | Other Departments |
    | ------------ | ------------------- | -------------- | ----------------- |
    | Surveillance | Modify              | Modify/Approve | Denied            |
    | Evaluation   | Modify              | Modify/Approve | Limited/Deny      |
    | Registration | Modify              | Modify/Approve | Denied            |
    | Distribution | Modify              | Modify/Approve | Denied            |
    | IT           | Modify              | Administrative | Denied            |
    ```

    - Can modified to be more sophisticated when needed.
    - But makes a good work flow for the MDA so far.

    ```Work Flow:
    EVALUATION
    Evaluates Dungeon #104
            │
            ▼
    Approved Evaluation Record
            │
            ├───────────────┐
            ▼               ▼
    REGISTRATION       DISTRIBUTION
    Records legal      Handles sale/
    ownership          allocation
            │               │
            └───────┬───────┘
                    ▼
            Audit Record
    ```

    - This does arise another question: Does Distribution need access to Evaluation?
    - Probably, but not EVERYTHING. So we could add Ms. Schmidt to "MDA_Evalutation_Approved_Read" and grant that group read-only access to an approved records location.
    - Ironically, introducing me to group nesting.

5. Add the files to the Controll VM.

    - I have stepped away quite substantially from the tutorial, at least in the functionality of the "gen_ad.ps1" file and "ad_schema.json" file.
    - That's not bad, but I created them on my host machine, and not in the Workstation VM. Which is fine for ease of editing and file continuity without worrying about breaking my VMs and losing my progress if I was actively typing something out there and progressing.
    - The good news is, if I just run the DC VM and use New-PSSession and connect to the DC, I can just copy over the files. Thus, that's the plan.
    - Better idea: download Gihub desktop onto the WS01 VM, sign in, get the project, and just copy over the files through the VM.

6. Copied "ad_schema.json" and "gen_ad.ps1" to DC01.

    - I also made it easier to enter the DC with $dc and $creds.
    ```shell
    $creds = (Get-Credential)
    echo $creds

    UserName                              Password
    --------                              --------
    MDA\Administrator                   P@ssw0rd123!

    $dc = New-PSSession 192.168.244.155 -Credential $creds
    ```

    ```shell
    cp .\ad_schema.json -ToSession $dc C:\Windows\Tasks
    cp .\gen_ad.ps1 -ToSession $dc C:\Windows\Tasks
    ```

    - Verified that "gen_ad.ps1" can parse "ad_schema.json." It does so successfully with no errors.
    
    ```shell
    [192.168.244.155]: PS C:\windows\Tasks> .\gen_ad.ps1

    cmdlet gen_ad.ps1 at command pipeline position 1
    Supply values for the following parameters:
    JSONfile: .\ad_schema.json

    ========================================
    MDA ACTIVE DIRECTORY GENERATOR
    ========================================
    JSON File: .\ad_schema.json
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
    [CREATING OU] MDA
    [CREATING OU] Users
    [CREATING OU] Privileged Accounts
    [CREATING OU] Groups
    [CREATING OU] Workstations
    [CREATING OU] Servers
    [CREATING OU] Surveillance
    [CREATING OU] Surveillance
    [CREATING OU] Information Technology
    [CREATING OU] Information Technology
    [CREATING OU] Evaluation
    [CREATING OU] Evaluation
    [CREATING OU] Registration
    [CREATING OU] Registration
    [CREATING OU] Distribution
    [CREATING OU] Distribution

    ========================================
    Creating MDA Security Groups
    ========================================
    [CREATING GROUP] MDA_Surveillance
    [CREATING GROUP] MDA_Surveillance_Chiefs
    [CREATING GROUP] MDA_Surveillance_Admins
    [CREATING GROUP] MDA_IT
    [CREATING GROUP] MDA_IT_Chiefs
    [CREATING GROUP] MDA_IT_Admins
    [CREATING GROUP] MDA_Evaluation
    [CREATING GROUP] MDA_Evaluation_Chiefs
    [CREATING GROUP] MDA_Evaluation_Admins
    [CREATING GROUP] MDA_Registration
    [CREATING GROUP] MDA_Registration_Chiefs
    [CREATING GROUP] MDA_Registration_Admins
    [CREATING GROUP] MDA_Distribution
    [CREATING GROUP] MDA_Distribution_Chiefs
    [CREATING GROUP] MDA_Distribution_Admins

    ----------------------------------------
    Processing: Arthur River
    Username: arthur_river
    Department: Surveillance
    Position: Surveillance Chief
    Account Type: standard
    ----------------------------------------
    OU: OU=Surveillance,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Arthur River (arthur_river)
    [ADDING TO GROUP] arthur_river -> MDA_Surveillance_Chiefs
    [ADDING TO GROUP] arthur_river -> MDA_Surveillance

    ----------------------------------------
    Processing: Arthur River
    Username: adm_arthur_river
    Department: Surveillance
    Position: Surveillance Chief
    Account Type: privileged
    ----------------------------------------
    OU: OU=Surveillance,OU=Privileged Accounts,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Arthur River (adm_arthur_river)
    [ADDING TO GROUP] adm_arthur_river -> MDA_Surveillance_Admins

    ----------------------------------------
    Processing: Scott Kang
    Username: scott_kang
    Department: Surveillance
    Position: Surveillance Agent
    Account Type: standard
    ----------------------------------------
    OU: OU=Surveillance,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Scott Kang (scott_kang)
    [ADDING TO GROUP] scott_kang -> MDA_Surveillance

    ----------------------------------------
    Processing: Robert Gordon
    Username: robert_gordon
    Department: Information Technology
    Position: Information Technology Chief
    Account Type: standard
    ----------------------------------------
    OU: OU=Information Technology,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Robert Gordon (robert_gordon)
    [ADDING TO GROUP] robert_gordon -> MDA_IT_Chiefs
    [ADDING TO GROUP] robert_gordon -> MDA_IT

    ----------------------------------------
    Processing: Robert Gordon
    Username: adm_robert_gordon
    Department: Information Technology
    Position: Information Technology Chief
    Account Type: privileged
    ----------------------------------------
    OU: OU=Information Technology,OU=Privileged Accounts,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Robert Gordon (adm_robert_gordon)
    [ADDING TO GROUP] adm_robert_gordon -> MDA_IT_Admins

    ----------------------------------------
    Processing: Luke Gibson
    Username: luke_gibson
    Department: Information Technology
    Position: Information Technology Technician
    Account Type: standard
    ----------------------------------------
    OU: OU=Information Technology,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Luke Gibson (luke_gibson)
    [ADDING TO GROUP] luke_gibson -> MDA_IT

    ----------------------------------------
    Processing: Lucy Hill
    Username: lucy_hill
    Department: Evaluation
    Position: Evaluation Chief
    Account Type: standard
    ----------------------------------------
    OU: OU=Evaluation,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Lucy Hill (lucy_hill)
    [ADDING TO GROUP] lucy_hill -> MDA_Evaluation_Chiefs
    [ADDING TO GROUP] lucy_hill -> MDA_Evaluation

    ----------------------------------------
    Processing: Lucy Hill
    Username: adm_lucy_hill
    Department: Evaluation
    Position: Evaluation Chief
    Account Type: privileged
    ----------------------------------------
    OU: OU=Evaluation,OU=Privileged Accounts,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Lucy Hill (adm_lucy_hill)
    [ADDING TO GROUP] adm_lucy_hill -> MDA_Evaluation_Admins

    ----------------------------------------
    Processing: Brentley Terry
    Username: brentley_terry
    Department: Evaluation
    Position: Evaluation Specialist
    Account Type: standard
    ----------------------------------------
    OU: OU=Evaluation,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Brentley Terry (brentley_terry)
    [ADDING TO GROUP] brentley_terry -> MDA_Evaluation

    ----------------------------------------
    Processing: Truman Sweet
    Username: truman_sweet
    Department: Registration
    Position: Registration Chief
    Account Type: standard
    ----------------------------------------
    OU: OU=Registration,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Truman Sweet (truman_sweet)
    [ADDING TO GROUP] truman_sweet -> MDA_Registration_Chiefs
    [ADDING TO GROUP] truman_sweet -> MDA_Registration

    ----------------------------------------
    Processing: Truman Sweet
    Username: adm_truman_sweet
    Department: Registration
    Position: Registration Chief
    Account Type: privileged
    ----------------------------------------
    OU: OU=Registration,OU=Privileged Accounts,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Truman Sweet (adm_truman_sweet)
    [ADDING TO GROUP] adm_truman_sweet -> MDA_Registration_Admins

    ----------------------------------------
    Processing: Jess Martin
    Username: jess_martin
    Department: Registration
    Position: Registration Specialist
    Account Type: standard
    ----------------------------------------
    OU: OU=Registration,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Jess Martin (jess_martin)
    [ADDING TO GROUP] jess_martin -> MDA_Registration

    ----------------------------------------
    Processing: Milan Schmidt
    Username: milan_schmidt
    Department: Distribution
    Position: Distribution Chief
    Account Type: standard
    ----------------------------------------
    OU: OU=Distribution,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Milan Schmidt (milan_schmidt)
    [ADDING TO GROUP] milan_schmidt -> MDA_Distribution_Chiefs
    [ADDING TO GROUP] milan_schmidt -> MDA_Distribution

    ----------------------------------------
    Processing: Milan Schmidt
    Username: adm_milan_schmidt
    Department: Distribution
    Position: Distribution Chief
    Account Type: privileged
    ----------------------------------------
    OU: OU=Distribution,OU=Privileged Accounts,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Milan Schmidt (adm_milan_schmidt)
    [ADDING TO GROUP] adm_milan_schmidt -> MDA_Distribution_Admins

    ----------------------------------------
    Processing: Alina Cox
    Username: alina_cox
    Department: Distribution
    Position: Distribution Specialist
    Account Type: standard
    ----------------------------------------
    OU: OU=Distribution,OU=Users,OU=MDA,DC=MDA,DC=com
    [CREATING USER] Alina Cox (alina_cox)
    [ADDING TO GROUP] alina_cox -> MDA_Distribution

    ========================================
    MDA ACTIVE DIRECTORY SUMMARY
    ========================================
    Standard Accounts:   10
    Privileged Accounts: 5
    Total Accounts:      15
    Security Groups:     15
    ========================================

    [COMPLETE] MDA Active Directory generation finished.
    ```

    - Verified groups. Parsed without errors as well.

    ```shell
    [192.168.244.155]: PS C:\windows\Tasks> Get-ADGroup

    cmdlet Get-ADGroup at command pipeline position 1
    Supply values for the following parameters:
    (Type !? for Help.)
    Filter: *


    DistinguishedName : CN=Administrators,CN=Builtin,DC=MDA,DC=com
    GroupCategory     : Security
    GroupScope        : DomainLocal
    Name              : Administrators
    ObjectClass       : group
    ObjectGUID        : 885e3cad-51f4-49e1-a9ac-60a2cc5a55bc
    SamAccountName    : Administrators
    SID               : S-1-5-32-544

    ...
    ```

    - Verified Users. Parsed without errors.

    ```shell
    Get-ADUser

    cmdlet Get-ADUser at command pipeline position 1
    Supply values for the following parameters:
    (Type !? for Help.)
    Filter: *


    DistinguishedName : CN=Administrator,CN=Users,DC=MDA,DC=com
    Enabled           : True
    GivenName         :
    Name              : Administrator
    ObjectClass       : user
    ObjectGUID        : bf46ff40-12c4-41d0-8ae9-18cf1bf983c6
    SamAccountName    : Administrator
    SID               : S-1-5-21-4252272573-727251941-1119735190-500
    Surname           :
    UserPrincipalName :

    DistinguishedName : CN=Guest,CN=Users,DC=MDA,DC=com
    Enabled           : False
    GivenName         :
    Name              : Guest
    ObjectClass       : user
    ObjectGUID        : d5a8e6e4-04d5-43b0-91c5-afebd6df6c9c
    SamAccountName    : Guest
    SID               : S-1-5-21-4252272573-727251941-1119735190-501
    Surname           :
    UserPrincipalName :

    ...
    ```

    - Now verifying if it can the automation safely encounter an environment it has already built.

    ```shell
    ========================================
    MDA ACTIVE DIRECTORY GENERATOR
    ========================================
    JSON File: .\ad_schema.json
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
    Processing: Arthur River
    Username: arthur_river
    Department: Surveillance
    Position: Surveillance Chief
    Account Type: standard
    ----------------------------------------
    OU: OU=Surveillance,OU=Users,OU=MDA,DC=MDA,DC=com
    [USER EXISTS] arthur_river
    [MEMBERSHIP EXISTS] arthur_river -> MDA_Surveillance_Chiefs
    [MEMBERSHIP EXISTS] arthur_river -> MDA_Surveillance

    ----------------------------------------
    Processing: Arthur River
    Username: adm_arthur_river
    Department: Surveillance
    Position: Surveillance Chief
    Account Type: privileged
    ----------------------------------------
    OU: OU=Surveillance,OU=Privileged Accounts,OU=MDA,DC=MDA,DC=com
    [USER EXISTS] adm_arthur_river
    [MEMBERSHIP EXISTS] adm_arthur_river -> MDA_Surveillance_Admins

    ----------------------------------------
    Processing: Scott Kang
    Username: scott_kang
    Department: Surveillance
    Position: Surveillance Agent
    Account Type: standard
    ----------------------------------------
    OU: OU=Surveillance,OU=Users,OU=MDA,DC=MDA,DC=com
    [USER EXISTS] scott_kang
    [MEMBERSHIP EXISTS] scott_kang -> MDA_Surveillance

    ----------------------------------------
    Processing: Robert Gordon
    Username: robert_gordon
    Department: Information Technology
    Position: Information Technology Chief
    Account Type: standard
    ----------------------------------------
    OU: OU=Information Technology,OU=Users,OU=MDA,DC=MDA,DC=com
    [USER EXISTS] robert_gordon
    [MEMBERSHIP EXISTS] robert_gordon -> MDA_IT_Chiefs
    [MEMBERSHIP EXISTS] robert_gordon -> MDA_IT

    ----------------------------------------
    Processing: Robert Gordon
    Username: adm_robert_gordon
    Department: Information Technology
    Position: Information Technology Chief
    Account Type: privileged
    ----------------------------------------
    OU: OU=Information Technology,OU=Privileged Accounts,OU=MDA,DC=MDA,DC=com
    [USER EXISTS] adm_robert_gordon
    [MEMBERSHIP EXISTS] adm_robert_gordon -> MDA_IT_Admins

    ----------------------------------------
    Processing: Luke Gibson
    Username: luke_gibson
    Department: Information Technology
    Position: Information Technology Technician
    Account Type: standard
    ----------------------------------------
    OU: OU=Information Technology,OU=Users,OU=MDA,DC=MDA,DC=com
    [USER EXISTS] luke_gibson
    [MEMBERSHIP EXISTS] luke_gibson -> MDA_IT

    ----------------------------------------
    Processing: Lucy Hill
    Username: lucy_hill
    Department: Evaluation
    Position: Evaluation Chief
    Account Type: standard
    ----------------------------------------
    OU: OU=Evaluation,OU=Users,OU=MDA,DC=MDA,DC=com
    [USER EXISTS] lucy_hill
    [MEMBERSHIP EXISTS] lucy_hill -> MDA_Evaluation_Chiefs
    [MEMBERSHIP EXISTS] lucy_hill -> MDA_Evaluation

    ----------------------------------------
    Processing: Lucy Hill
    Username: adm_lucy_hill
    Department: Evaluation
    Position: Evaluation Chief
    Account Type: privileged
    ----------------------------------------
    OU: OU=Evaluation,OU=Privileged Accounts,OU=MDA,DC=MDA,DC=com
    [USER EXISTS] adm_lucy_hill
    [MEMBERSHIP EXISTS] adm_lucy_hill -> MDA_Evaluation_Admins

    ----------------------------------------
    Processing: Brentley Terry
    Username: brentley_terry
    Department: Evaluation
    Position: Evaluation Specialist
    Account Type: standard
    ----------------------------------------
    OU: OU=Evaluation,OU=Users,OU=MDA,DC=MDA,DC=com
    [USER EXISTS] brentley_terry
    [MEMBERSHIP EXISTS] brentley_terry -> MDA_Evaluation

    ----------------------------------------
    Processing: Truman Sweet
    Username: truman_sweet
    Department: Registration
    Position: Registration Chief
    Account Type: standard
    ----------------------------------------
    OU: OU=Registration,OU=Users,OU=MDA,DC=MDA,DC=com
    [USER EXISTS] truman_sweet
    [MEMBERSHIP EXISTS] truman_sweet -> MDA_Registration_Chiefs
    [MEMBERSHIP EXISTS] truman_sweet -> MDA_Registration

    ----------------------------------------
    Processing: Truman Sweet
    Username: adm_truman_sweet
    Department: Registration
    Position: Registration Chief
    Account Type: privileged
    ----------------------------------------
    OU: OU=Registration,OU=Privileged Accounts,OU=MDA,DC=MDA,DC=com
    [USER EXISTS] adm_truman_sweet
    [MEMBERSHIP EXISTS] adm_truman_sweet -> MDA_Registration_Admins

    ----------------------------------------
    Processing: Jess Martin
    Username: jess_martin
    Department: Registration
    Position: Registration Specialist
    Account Type: standard
    ----------------------------------------
    OU: OU=Registration,OU=Users,OU=MDA,DC=MDA,DC=com
    [USER EXISTS] jess_martin
    [MEMBERSHIP EXISTS] jess_martin -> MDA_Registration

    ----------------------------------------
    Processing: Milan Schmidt
    Username: milan_schmidt
    Department: Distribution
    Position: Distribution Chief
    Account Type: standard
    ----------------------------------------
    OU: OU=Distribution,OU=Users,OU=MDA,DC=MDA,DC=com
    [USER EXISTS] milan_schmidt
    [MEMBERSHIP EXISTS] milan_schmidt -> MDA_Distribution_Chiefs
    [MEMBERSHIP EXISTS] milan_schmidt -> MDA_Distribution

    ----------------------------------------
    Processing: Milan Schmidt
    Username: adm_milan_schmidt
    Department: Distribution
    Position: Distribution Chief
    Account Type: privileged
    ----------------------------------------
    OU: OU=Distribution,OU=Privileged Accounts,OU=MDA,DC=MDA,DC=com
    [USER EXISTS] adm_milan_schmidt
    [MEMBERSHIP EXISTS] adm_milan_schmidt -> MDA_Distribution_Admins

    ----------------------------------------
    Processing: Alina Cox
    Username: alina_cox
    Department: Distribution
    Position: Distribution Specialist
    Account Type: standard
    ----------------------------------------
    OU: OU=Distribution,OU=Users,OU=MDA,DC=MDA,DC=com
    [USER EXISTS] alina_cox
    [MEMBERSHIP EXISTS] alina_cox -> MDA_Distribution

    ========================================
    MDA ACTIVE DIRECTORY SUMMARY
    ========================================
    Standard Accounts:   10
    Privileged Accounts: 5
    Total Accounts:      15
    Security Groups:     15
    ========================================

    [COMPLETE] MDA Active Directory generation finished.
    ```

    - The second run shows that the script recognized every existing OU, security group, user account, and group membership instead of trying to recreate them.
    - It can be rerun safely against the current state without producing duplicates or obvious configuration drift.
