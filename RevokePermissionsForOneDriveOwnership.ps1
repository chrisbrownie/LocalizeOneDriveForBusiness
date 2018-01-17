Param(
    
    [Parameter(Mandatory = $true)]
    [string]
    $TenantServiceDomain,

    [Parameter(Mandatory = $true)]
    [System.Management.Automation.PSCredential]
    $Credentials
)

$AdminUrl = "https://{0}-admin.sharepoint.com" -f $TenantServiceDomain

Connect-SPOService -Url $AdminUrl -Credential $Credentials

$loadInfo1 = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client")
$loadInfo2 = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime")
$loadInfo3 = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.UserProfiles")

$spCreds = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Credentials.UserName, $Credentials.Password)

$ProxyAddress = "{0}/_vti_bin/UserProfileService.asmx?wsdl" -f $AdminUrl

$UserProfileService = New-WebServiceProxy -Uri $ProxyAddress -UseDefaultCredential:$false
$UserProfileService.Credentials = $spcreds

$strAuthCookie = $spcreds.GetAuthenticationCookie($AdminUrl)
$uri = New-Object System.Uri($AdminUrl)
$container = New-Object System.Net.CookieContainer
$container.SetCookies($uri, $strAuthCookie)
$UserProfileService.CookieContainer = $container

$UserProfileResult = $UserProfileService.GetUserProfileByIndex(-1)

$NumProfiles = $UserProfileService.GetUserProfileCount()
$i = 1

# As long as the next User profile is NOT the one we started with (at -1)...
While ($UserProfileResult.NextValue -ne -1) {

    # Look for the Personal Space object in the User Profile and pull it out
    # (PersonalSpace is the name of the path to a user's mysite)
    $Prop = $UserProfileResult.UserProfile | Where-Object { $_.Name -eq "PersonalSpace" } 
    $Url = $Prop.Values[0].Value

    # If "PersonalSpace" (which we've copied to $Url) exists, log it to our file...
    if ($Url) {
        $mySiteUrl = "https://{0}-my.sharepoint.com{1}" -f $TenantServiceDomain, $Url
        $mySiteUrl = $mySiteUrl.TrimEnd("/")
        try { 
            Set-SPOUser -Site $mySiteUrl -LoginName $Credentials.Username -IsSiteCollectionAdmin:$false | Out-Null
            New-Object -TypeName PSObject -Property @{
                "Site"                  = $mySiteUrl
                "LoginName"             = $Credentials.UserName
                "IsSiteCollectionAdmin" = $false
                "Error"                 = $false
            }
        }
        catch {
            New-Object -TypeName PSObject -Property @{
                "Site"                  = $mySiteUrl
                "LoginName"             = $Credentials.UserName
                "IsSiteCollectionAdmin" = $null
                "Error"                 = $true
            }
        }
    }

    # And now we check the next profile the same way...
    $UserProfileResult = $UserProfileService.GetUserProfileByIndex($UserProfileResult.NextValue)
    $i++
}

