Param(

    [Parameter(Mandatory = $true)]
    [string]
    $TenantServiceDomain,

    [System.Management.Automation.PSCredential]
    $Credentials,

    [String[]]
    $UsersToProcess
)
# Localizes all OneDrive Sites to a particular locale

# Requirements:
# -- Your GA account may need to be assigned permissions
#    per https://support.office.com/en-gb/article/Assign-eDiscovery-permissions-to-OneDrive-for-Business-sites-422858ff-917b-46d4-9e5b-3397f60eee4d?ui=en-US&rs=en-GB&ad=GB
# -- The latest Microsoft.SharePointOnline.CSOM package must be installed
# -- To automatically localise, the AzureAD version 2 module must be installed

# Based on Brendan Griffin's (@brendankarl) script from here:
# https://blogs.technet.microsoft.com/fromthefield/2015/04/13/office-365-change-the-locale-of-all-onedrive-for-business-sites-using-powershell/

#Add references to SharePoint client assemblies and authenticate to Office 365 site - required for CSOM
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.UserProfiles.dll"

#Specify tenant admin credentials if they weren't provided as part of running the script
if (-not $Credentials) {
    $Credentials = Get-Credential -Message "Provide your SharePoint Online Credentials"
    $credObject = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Credentials.UserName, $Credentials.Password)
}
else {
    $credObject = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Credentials.UserName, $Credentials.Password)
}

Connect-AzureAD -Credential $Credentials

$AllUsers = Get-AzureADUser -All:$true

$UsageLocationToLocaleMapping = Get-Content .\UsageLocationToLocaleMapping.json | ConvertFrom-Json

$siteURL = "https://{0}-my.sharepoint.com/" -f $TenantServiceDomain

#Bind to MySite Host Site Collection
$Context = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
$Context.Credentials = $credObject

#Identify users in the Site Collection
$Users = $Context.Web.SiteUsers
$Context.Load($Users)
$Context.ExecuteQuery()

#Create People Manager object to retrieve profile data
$PeopleManager = New-Object Microsoft.SharePoint.Client.UserProfiles.PeopleManager($Context)
Foreach ($User in $Users) {
    $UPN = $User.LoginName.Split("|")[-1]
    
    $UsageLocation = $AllUsers | Where-Object {$_.UserPrincipalName -eq $UPN} | Select-Object -ExpandProperty UsageLocation

    $NewLocaleId = $UsageLocationToLocaleMapping.$UsageLocation
    if ($NewLocaleId) {
        $UserProfile = $PeopleManager.GetPropertiesFor($User.LoginName)
        $Context.Load($UserProfile)
        $Context.ExecuteQuery()
        # If we have $UsersToProcess, don't do everyone, just do a few as specified
        if (($UsersToProcess) -and ($UsersToProcess -contains $UserProfile.Email) ) {
            If ($UserProfile.Email -ne $null) {
                Write-Verbose "Processing $($User.LoginName) (UPN: $UPN). New Locale ID: $NewLocaleID"
                New-Object -TypeName PSObject -Property @{
                    "UserLoginName" = $User.LoginName
                    "NewLocaleId"   = $NewLocaleId
                }
                #Bind to OD4B Site and change locale
                $OD4BSiteURL = $UserProfile.PersonalUrl
                $Context2 = New-Object Microsoft.SharePoint.Client.ClientContext($OD4BSiteURL)
                $Context2.Credentials = $credObject
                $Context2.ExecuteQuery()
                $Context2.Web.RegionalSettings.LocaleId = $NewLocaleID
                $Context2.Web.Update()
                $Context2.ExecuteQuery()
            }  
        }
        
    }
    else {
        Write-Verbose "Processing $($User.LoginName) (UPN: $UPN). Unable to determine new locale ID for UsageLocation '$UsageLocation'"
    }
}
