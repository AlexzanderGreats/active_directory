# active_directory

Notes and Recourses for my Active Directory Lab
Based on the Youtube series Active Directory from <https://youtube.com/@_JohnHammond>, I am currently following the tutorial day by day.

Objective:
    The objective of this project is to simulate a small enterprise domain environment in which a Windows Server functions as an Active Directory Domain Controller and provides centralized identity, authentication, access, and policy management for domain-joined client systems and users. The environment will be used to gain practical experience in deploying and administering Active Directory Domain Services (AD DS), managing organizational units, users, security groups, and permissions, and applying role-based access control and least-privilege principles to organizational resources. The project will also simulate common administrative processes such as employee onboarding and offboarding, Group Policy configuration, account and security-policy management, and access validation. As the environment evolves, intentional security misconfigurations and administrative errors will be introduced, investigated, documented, remediated, and retested to build practical experience in troubleshooting and security analysis. All significant configurations, changes, incidents, security decisions, and lessons learned will be documented to demonstrate not only how the environment was built and administered, but why particular technical and security decisions were made.

Scenario
    The Mythical Dungeon Association (MDA) is an organization of the United Colonies of Gaia (UCG), founded around 5024 with the express purpose of overseeing unregistered and registered Magic, magical beings known as Mythics, naturally forming structures called dungeons, and organized groups of Mythics known as Guilds throughout the UCG. Although the MDA maintains separate operations within individual colonies, each colonial branch is led by a director who ultimately reports to the Association's original headquarters in Klato. Acting under the authority of the Chairman and the central administration in Klato, the MDA's mission is to inform, protect, and serve both the mythicless and mythical populations.
    For this lab, the MDA will serve as a simulated government enterprise requiring centralized administration of users, computers, organizational departments, permissions, and security policies. Employees will have access to organizational resources based on their roles and responsibilities, while administrative and sensitive resources will require elevated authorization. The environment will therefore emphasize centralized identity management, role-based access control (RBAC), least privilege, separation of standard and privileged accounts, authentication policies, security logging and auditing, and controlled employee onboarding and offboarding. These requirements will provide the organizational basis for designing and securing the Active Directory environment.

Organization Name: Mythical Dungeon Association (MDA).
Parent Organization: United Colonies of Gaia (UCG).
Industry: Federal/Central Government Regulatory & Public Safety Agency.
Headquarters: Klato.
Number of Departments: 5 (Surveillance Department; IT Department; Evaluation Department; Registration Department; Distribution Department)
Number of Users: 10
Number of User Accounts: 20
Security Requirements: Centralized identity and authentication; role-based access control; least privilege; privileged-account separation; account and access auditing; security logging; password and account-lockout policies; controlled onboarding and offboarding.
