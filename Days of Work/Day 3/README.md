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
