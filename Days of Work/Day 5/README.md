# 04 Generating vulnerable schema

1. John Hammond codes a repeatable AD lab.

    - Randomized identities and weak credentials make later authorized exercises.
        - Domain enumeration, credentials, and testing domainstrations.
    - The script is not polished by the end, though.
        - Password-policy handling, cleanup/removal tooling, and reliable schema imports still need refinement.
    - For me, the randomization concepts are worthwhile.
        - External first/last-name lists, randomized group assignment, generating PowerShell objects/hashtables, exporting them through ConvertTo-Json, duplicate prevention, and dealing correctly with array serialization are all useful PowerShell exercises.
    - I am going to make it match my schema, rather than regressing it.
    - I also discovered that `MDA.com` rejects inadequate passwords, so I am going to keep that and work around it.
    - I am going to first let the generator encounter that problem and then document it.
    - I am going to decide what vulnerability I am deliberately introducing and why second.
        - A vulnerable lab is more educational when I understand which control I weakened, what threat it enables, and how I would remediate it, rather than simply switching security features off until attacks work.

2. The plan!

    ```Status
    BASELINE MDA
    Secure, documented configuration
            │
            ▼
    Introduce controlled misconfiguration
            │
            ▼
    VULNERABLE MDA
            │
            ▼
    Discover / Exploit / Detect
            │
            ▼
    Remediate
            │
            ▼
    Verify restored baseline
    ```

    - As for the `100 users` idea, I am aiming for starting out with 20 users distributed through the departments I already have for the MDA.
    - I will probably want to impoment `Get-Random`, mutable collections, randomized users/groups/passwords, hashtables/objects, duplicate prevention, JSON serialization, array handling, schema validation, and live debigging/ tuning.
    - I however want to generated users that remain in standard accounts, job titles are department-appropriate, and I don't wnt the script to randomly hands somebody `*_Admins` or `*_Chiefs` membership.
    - By default, I want the generator to create 20 users, with 30% receiving intentionally guessable but potentially policy-compliant lab passwords such as `Summer2026!`.
    - The account can still provision while remaining intentionally weak enough to become a later security finding.
    - I will also want controls to escape luck, such as employing a `seed`, or something to recreate a simulation and retest it against what I already have in the `MDA.com` domain.

3. Testing the code.

    - To the code, I added a failure mode for the code, just for the sake of easily undersanding what works and doesn't.

    ```shell
    -IncludePolicyFailures
    ```

    - It should allow me to control the number of deliberately inadequate passwords like `password` or `12345678` to appear.
    - Those may then fail when my existing `gen_ad.ps1` tries to provision them against `MDA.com`.
    - Allowing me to reproduce one of the tutorial's lessons without having the generator silently weaken the domain.
    - I also have it generating a new `JSON` file at whatever path I supply with `-OutputPath`.
    - Another important difference from the baseline I also added metadata to generated users.

    ```shell
    {
    "generated": true,
    "password_classification": "weak",
    "intentional_vulnerability": "Guessable lab password that may satisfy complexity requirements but remains poor security practice."
    }
    ```

    - The current `gen_ad.ps1` should simply ignore those extra fields because its validator only cares about the properties it actually uses.
    - That means the vulnerable schema remains compatible while retaining enough evidence for later analysis.
