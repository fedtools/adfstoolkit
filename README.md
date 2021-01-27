# ADFSToolkit

A PowerShell Module for optimal handling of SAML2 multi-lateral federation aggregates for Microsoft's AD FS.

ADFSToolkit reduces installation and configuration time to minutes for proper handling of metadata aggregates from Research and Education (R&E) Federated Identity Management service federations. This allows AD FS to behave as a viable IdP in a SAML2 R&E federation.


# Table Of Contents
* [Installation](./doc/README.md)
* [Upgrading](./doc/upgrade.md)



## Attribute Release Practices of ADFSToolkit 
Built for and by the Research and Educational(R&E) community, ADFSToolkit embraces scalable attribute release management principles of R&E federations. 
One of these techniques is the use of Entity Categories for attribute release. 
Entity Categories are tags in SAML2 metadata on an entity that indicate membership in a given category of service. 
The attribute release model using Entity Categories has a release policy set against the category, not the entity. 
 When ADFSToolkit parses entities to load into AD FS and encounters an Entity Category called ‘Research and Scholarship’, it automatically creates multiple AD FS transform rules that reflect the minimal set of attributes released, not much different than your public directory pages. For R&S these are:
- eduPersonPrincipalName (left hand of the at sign of the UPN concatenated with your domain)
- mail
- displayName
- givenName
- sn (Surname)
- eduPersonScopedAffiliation (controlled vocabulary mapped from groups in AD)

This is the default behaviour of ADFSToolkit. Contact your Federation Operator to also tag your IdP entity as supporting R&S Entity Category and improve the user experience for all your users.

# ADFSToolkit's Contributors and Users
- CANARIE's Canadian Access Federation: https://www.canarie.ca/identity/support/fim-tools/
- Sweden's Sunet - SWAMID: https://wiki.sunet.se/display/SWAMID/How+to+consume+SWAMID+metadata+with+ADFS+Toolkit
