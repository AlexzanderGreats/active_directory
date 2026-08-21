# 01 — Installing the Domain Controller & Joining Domain

1. Use `sconfig` to:
    - Change the hostname
    - Change the IP address to static
    - Change the DNS server to our own IP address.

2. Install the Active Directory Windows Feature

    ```shell
    Install-WindowsFeature AD-Domain-Services -IncludeMangagementTools
    ```

3. Imported the ADDeployment module and installed ADDSforest.

    - Gave the server the directory "MDA.com" (Tried MythicalDungeonAssociation.com, but that was too long (max of 15 characters))
    - Modified DNS Server Address on DC1, then took a snapshot of the completed product.

4. Joining WS01 to the `MDA.com` domain

    - Modified DNSClientServerAddress on WS01

    ```shell
    Get-DNSClientServerAddress

    Set-DNSClientServerAddress -InterfaceIndex 12 -ServerAddress 192.168.244.155
    ```

    - Used Windows Pro "Access work or school" GUI.

    ```credential
    Username: MDA\Administrator
    Password: P@ssw0rd123!
    ```

    - Could use PowerShell with this command to access the domain, too.

    ```shell
    Add-Computer -DomainName MDA.com -Credential MDA\Administrator -Force -Restart
    ```

5. Produced a User list for the lab.

    - Originally produced this list on Discord, messaging an Alt account, where I tend to leave notes for myself, and so forth.

    ```MDA DA Lab Users:
    ## *Surveillance Department:*

    ***Agent Arthur River (Surveillance Chief)*** — `2 Accounts.`

    ***Agent Scott Kang (Surveillance Employee)*** — `1 Account.`

    ———

    ## *IT Department:*

    ***Robert Gordon (Administrator)*** — `2 Accounts.`

    ***Luke Gibson (Technician)*** — `1 Account.`

    ———

    ## *Evaluation Department:*

    ***Lucy Hill (Chief Evaluator)*** — `2 Accounts.`

    ***Brentley Terry (Evaluator Specialist)*** — `1 Account.`

    ———

    ## *Registration Department:*

    ***Truman Sweet (Chief Registrar)*** — `2 Accounts.`

    ***Jess Martin (Registrar Specialist)*** — `1 Account.`

    ———

    ## *Distribution Department:*

    ***Milan Schmidt (Distribution Chief)*** — `2 Accounts.`

    ***Alina Cox (Distribution Specialist)*** — `1 Account.`
    ```

    - It looked prettier there.
