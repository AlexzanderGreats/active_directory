# 01 — Installing the Domain Controller

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
    - Modified DNS Server Address, then took a snapshot of the completed product.
    - 

4. 