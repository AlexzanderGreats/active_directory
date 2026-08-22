# 03 Generating vulnerable schema

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

    - As for the "100 users" idea, I am aiming for starting out with 20 users distributed through the departments I already have for the MDA.
