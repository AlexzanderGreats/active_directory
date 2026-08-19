# 01 — Installing the Domain Controller & Joining Domain

1. Use `sconfig` to:
    - Change the hostname
    - Change the IP adress to static
    - Change the DNS server to our own IP adress.

2. Install the Active Directory Windows Feature

```shell
Install-WindowsFeature AD-Domain-Services -IncludeMangagementTools
```

3. Imported the Module ADDeployment and installed ADDSforest.

    - Gave the server the directory "MDA.com" (Tried MythicalDungeonAssociation.com, but that was too long (max of 15 characters))
    - Modified DNS Server Address on DC1, then took a snapshot of the completed product.

4. Joining WS01 to the `MDA.com` domain

    - Modifed DNSClientServerAddress on WS01
    ```shell
    Get-DNSClientServerAddress

    Set-DNSClientServerAddress -InterfaceIndex 12 -ServerAddress 192.168.244.155
    ```
    - Used Windows Pro "Access work or school" GUI.
    ```credential
    Username: MDA\Administrator
    Password: P@ssw0rd123!
    ``` 
    - Could use power shell with this command to access domain, too.
 ```shell
Add-Computer -DomainName MDA.com -Credential MDA\Administrator -Force -Restart
```