# LocalizeOneDriveForBusiness

This is a script based on [@brendankarl](https://github.com/brendankarl)'s OneDrive for Business localization script as published on his [TechNet blog](https://blogs.technet.microsoft.com/fromthefield/2015/04/13/office-365-change-the-locale-of-all-onedrive-for-business-sites-using-powershell/).

## Requirements
* An account with SharePoint Administrator rights in Office 365/SharePoint Online
* The `Microsoft.SharePointOnline.CSOM` package, either fron NuGet or via the redist

## Execution
* Download the script and place it in a folder
* Grant permissions to own OneDrive with:

    `GrantPermissionsForOneDrive.ps1 -TenantServiceDomain contoso -Credentials (Get-Credential)`

* Run the script with the following parameters:

    `LocalizeOneDriveForBusiness.ps1 -NewLocaleId 1234 -TenantServiceDomain yourcompany -Credentials (Get-Credential)`

Find your Locale ID [here](https://msdn.microsoft.com/en-us/library/ms912047%28v=winembedded.10%29.aspx?f=255&MSPPError=-2147217396).

Your `TenantServiceDomain` is the bit before `.onmicrosoft.com`. For example, if your domain is 
`contoso.sharepoint.com`, you would specify `contoso` as `TenantServiceDomain`.

## Notes

* These scripts do not support MFA. Sorry. You'll need to create a temporary admin account with MFA disabled to use them.
* If you receive permissions errors, your account may need to be assigned admin permissions on the OneDrive for Business sites. Guidance for this is [here](https://support.office.com/en-gb/article/Assign-eDiscovery-permissions-to-OneDrive-for-Business-sites-422858ff-917b-46d4-9e5b-3397f60eee4d?ui=en-US&rs=en-GB&ad=GB).


## Resources

* [Change the locale of all OneDrive for Business Sites using Powershell](https://blogs.technet.microsoft.com/fromthefield/2015/04/13/office-365-change-the-locale-of-all-onedrive-for-business-sites-using-powershell/)
* [SharePoint Online Client Components SDK](https://www.microsoft.com/en-us/download/details.aspx?id=42038)
* [Assign eDiscovery permissions to OneDrive for Business sites](https://support.office.com/en-gb/article/Assign-eDiscovery-permissions-to-OneDrive-for-Business-sites-422858ff-917b-46d4-9e5b-3397f60eee4d?ui=en-US&rs=en-GB&ad=GB)
* [Microsoft Locale ID Values](https://msdn.microsoft.com/en-us/library/ms912047%28v=winembedded.10%29.aspx?f=255&MSPPError=-2147217396)

## To Do

* Proper comment-based help in the script
* Automatically assign permission to access site if required