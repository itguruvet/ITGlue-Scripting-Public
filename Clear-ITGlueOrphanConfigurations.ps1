

Function Clear-ITGlueOrphanConfigurations {
<#
.SYNOPSIS
    This is a template meant as a quick start for creating an IT Glue capable script

 
.NOTES
    Name: Clear-ITGlueOrphanConfigurations
    Author: Adam Ellch (adam@itguru.vet / adam@sysadmin-solutions.net)
    Version: 1.0
    DateCreated: 6/22/23

.PARAMETER ITG_APIKey
    This should contain the IT Glue API Key you wish to use.  It is a mandatory parameter.

.PARAMETER ITG_OrgID
    This should contain the IT Glue ORGID you wish to connect to
    
    example: 
    1111111
        (Your ORgID should be a 7 digit number)

.PARAMETER ITG_APIEndpoint
    This should contain the IT Glue API Endpoint. 
    This parameter is optional, By default it will use the US Endpoint, which is 'https://api.itglue.com' -- if you wish to connect to a different endpoint, it can be defined here.

.PARAMETER AutoRemoveOrphans
    This is an optional parameter which will determine whether or not the orphans will all be auto-removed from IT Glue when ran, or if instead the user will be propmted to confirm each orphan manually
    This can be useful if you want to check things out and check to verify the status across platforms while doing removals, or to get comfortable with the script before fully running it unattended
    Example:
    $false (default setting - this will cause the user to be prompted for each removal)
    $true - This will cause all orphans to be removed automatically in a single batch

.PARAMETER exportCsvPath
    This is an optional parameter that can be used to export the list of orphaned device to a CSV file prior to any action being taken -- all orphans will be exported to the CSV, whether or not you choose to remove them.
    Example:
    C:\ITG\Reports

.EXAMPLE

    The SUGGESTED use case if you want to monitor the removals as they are used, and ensure that you capture a CSV report of the orphan list while explicitly stating your options without relying on default behavior
    Clear-ITGlueOrphanConfigurations -ITG_APIKey APIKEYHERE -ITG_OrgID ITLUEORGIDHERE -AutoRemoveOrphans $false -exportCsvPath C:\ITG\Reports

    The SUGGESTED use case if you want to monitor the removals as they are used, and ensure that you capture a CSV report of the orphan list while explicitly stating your options without relying on default behavior
    Clear-ITGlueOrphanConfigurations -ITG_APIKey APIKEYHERE -ITG_OrgID ITLUEORGIDHERE -AutoRemoveOrphans $true -exportCsvPath C:\ITG\Reports
    


    The most basic use case, with the least required input -- this will default to prompting for orphan deletion, and will not store the CSV list at all
    Clear-ITGlueOrphanConfigurations -ITG_APIKey APIKEYHERE -ITG_OrgID ITLUEORGIDHERE

    The second most basic use case, with the least required input -- this will default to prompting for orphan deletion, but will store the orphan list in CSV format
    Clear-ITGlueOrphanConfigurations -ITG_APIKey APIKEYHERE -ITG_OrgID ITLUEORGIDHERE -exportCsvPath C:\ITG\Reports

  

    Prompt the user to confirm each removal individually and export the orphan list to a CSV, while explicitly stating the ITG_APIEndpoint to use (which will default to the US endpoint if not set) - see https://api.itglue.com/developer/ for a list of endpoint alternatives
    Clear-ITGlueOrphanConfigurations -ITG_APIKey APIKEYHERE -ITG_OrgID ITLUEORGIDHERE -ITG_APIEndpoint https://api.itglue.com -AutoRemoveOrphans $false -exportCsvPath C:\ITG\Reports

     
.LINK
    https://www.linkedin.com/in/adam-ellch
#>
 
    [CmdletBinding()]
        param(
            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $false,
                ValueFromPipelineByPropertyName = $true,
                Position = 0,
                HelpMessage = "This should contain the IT Glue API Key you wish to use.  It is a mandatory parameter."
                )]
            [string[]]  $ITG_ApiKey,
            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $false,
                ValueFromPipelineByPropertyName = $true,
                Position = 1,
                HelpMessage = "This is a mandatory parameter, and should contain the IT Glue ORGID you wish to connect to -- example: 1111111"
                )]
            [string[]]  $ITG_OrgID,
            [Parameter(
                Mandatory = $false,
                ValueFromPipeline = $false,
                ValueFromPipelineByPropertyName = $true,
                Position = 2,
                HelpMessage = "This should contain the IT Glue API Endpoint.  By default it will use the US Endpoint, which is 'https://api.itglue.com' -- if you wish to connect to a different endpoint, it can be defined here."
                )]
            [string[]]  $ITG_APIEndpoint = "https://api.itglue.com",
            [Parameter(
                Mandatory = $false,
                ValueFromPipeline = $false,
                ValueFromPipelineByPropertyName = $false,
                Position = 3,
                HelpMessage = "Set this to `$true if you want the orphan devices to be automatically removed - otherwise you will be prompted for each removal"
                )]
            [bool[]]  $AutoRemoveOrphans = $false,
            [Parameter(
                Mandatory = $false,
                ValueFromPipeline = $false,
                ValueFromPipelineByPropertyName = $false,
                Position = 3,
                HelpMessage = "This is an optional parameter that will allow you to export the orphan list to a CSV prior to any removals being done - it will export the complete list, regardless of whether you removed them or not. Example: C:\ITG\Reports"
                )]
            [string[]]  $exportCsvPath = $null
        )#End Parameter Declarations



 
    #Begin the core function logic
    BEGIN {

        Write-Host "INFO: Beginning Script with the following parameters:`n"
        $paramDetails = "
                     ITG_ApiKey = $($ITG_ApiKey)
                      ITG_OrgID = $($ITG_OrgID)
                ITG_APIEndpoint = $($ITG_APIEndpoint)
              AutoRemoveOrphans = $($AutoRemoveOrphans)
                  exportCsvPath = $($exportCsvPath)
              "

        Write-Host $paramDetails -BackgroundColor Magenta

        #Verify that PowerShell version 5 (at minimum) is in use, otherwise key functionality will not be possible
        if ($PSVersionTable.PSVersion.Major -ge 5)
        {
            Write-Output "PowerShell Version: $($PSVersionTable.PSVersion.Major) -- PASSED"
        }
        else
        {
            Write-Error "PowerShell Version imcompatible with Script Funciton: IT Glue upload -- Please upgrade powershell using the Windows Management Framework Update Component and try again.`n"
            Write-Host "PowerShell Version imcompatible with Script Funciton: IT Glue upload Please upgrade powershell using the Windows Management Framework Update Component and try again.`n"
            return
        }

        #Import/Install Required Dependancies - configure TLS so that if any packages need to be installed from the internet they will be able to
        Write-Host "INFO: Beginning the import/install of required dependancies" -BackgroundColor DarkGreen
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls11,Tls12'
    
        #Try to import the PowerShellGet Module, and then install it and importing if not
        try {
           #Write-Host "INFO: Attempting to import the PowerShellGet module if it is already isntalled on the machine, and installing if it is not found."
           Import-Module PowerShellGet
        }catch{
           #Write-Host "INFO: Unable to import PowerShellGet -- attempting to install and import" 
           try {
               Install-Module PowerShellGet -force
               Import-Module PowerShellGet -force
           }catch {
                Write-Host "ERROR: Unable to install PowerShellGet - exiting script, please try to install the PowerShellGet module manually and try again." -BackgroundColor DarkRed
                return
           }#End trying to install PowerShellGet
        }#End try/catch to import + install PowerShellGet
        Get-Module -Name PowerShellGet | Select-Object -Property Name, Version

        #Try to import the NuGet PackageProvider, and then install it and import if not
        try {
           #Write-Host "INFO: Attempting to import the NuGet PackageProver if it is already isntalled on the machine, and installing if it is not found."
           Import-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201
        }catch{
           #Write-Host "INFO: Unable to import the NuGet PackageProver -- attempting to install and import" 
           try {
               Write-Host "INFO: Attempting to import the NuGet PackageProver if it is already isntalled on the machine, and installing if it is not found."
               Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201
               Import-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201
           }catch {
                Write-Host "ERROR: Unable to install + import NuGet PackageProver - exiting script, please try to install the PowerShellGet module manually and try again." -BackgroundColor DarkRed
                return
           }#End trying to install PowerShellGet
        }#End try/catch to import + install NuGet PackageProvider
        Get-PackageProvider -Name NuGet | Select-Object -Property Name, Version

        #Try to set the PSGallery repository to trusted if it is not already - note that it will be set back to the existing policy when the script completes
        $initialPSGalleryInstallationPolicyStatus = (Get-PSRepository -Name PSGallery).InstallationPolicy
        if ($initialPSGalleryInstallationPolicyStatus -eq "Trusted") {
            Write-Host "INFO: The PSGallery PSRepository is already set to trusted - skipping step which would change it to trusted."
        }else{
            try {
                Write-Host "INFO: Attempting to set the PSGallery Repository to trusted -- the current setting is '$($initialPSGalleryInstallationPolicyStatus)' - it will be reverted to this setting at the end of the script." -BackgroundColor DarkYellow
                Set-PSRepository -InstallationPolicy Trusted -Name PSGallery 
            }catch{
                Write-Host "ERROR: Unable to set PSGallery to trusted -- IT Glue submission functionality will not work" -BackgroundColor DarkRed
            }#Endd Try/Catch set PSGallery Repository to Trusted
        }
        
        Get-PSRepository -Name PSGallery

        #Try to import the ITGlueAPI Module, and if unable to do so then attempt to install and import it
        #Load the ITGlue API 
        If(Get-Module -ListAvailable -Name "ITGlueAPI") {
            try {  
                Import-module ITGlueAPI
            }
            catch{
                Write-Host "IT Glue module not present -- attempting to install and import"
            }
        } Else {
            try {
                Install-Module ITGlueAPI -Force
                Import-Module ITGlueAPI
            }
            catch {
                Write-Error "Unable to install + import ITGlueAPI module -- IT Glue submission functionality will not work. Exiting script."
                return
            }
    
        }#Ebd If Get-Module ITGlueAPI

        #Attempt to connect to ITGlue using the provided parameters
        #Settings IT-Glue logon information
        [string]$APIKEy =  $ITG_ApiKey
        [string]$APIEndpoint = $ITG_APIEndpoint
        try {
            Write-Host "INFO: Connecting to IT Glue using the parameters provided"
            Add-ITGlueBaseURI -base_uri $APIEndpoint
            Add-ITGlueAPIKey $APIKEy
        }catch{
            Write-Host "ERROR: Unable to connect to IT Glue API using the provided parameters -- please check your parameters and try again"
            return
        }

        


        #Generate Global Variable - $ConfigurationTypes - by default OrgINFO does not pull down in an easy to parse way for humans.  This appends the ID  to the Attributes, and then cleans it all up so it is at the root of the ConfigurationTypes variable
        $pageNumberCounter = 1
        $ConfigurationTypesRaw = Get-ITGlueConfigurationTypes -page_size 1000 -page_number $pageNumberCounter
        $ConfigurationTypesUnmodified = $ConfigurationTypesRaw.data
        $pageTotal = $ConfigurationTypesRaw.meta.'total-pages'
        $itemsTotal = $ConfigurationTypesRaw.meta.'total-count'
        Write-Host "INFO: Gathering IT Glue 'ConfigurationTypes' Data"
        $ConfigurationTypesUnmodified.attributes | Add-Member Noteproperty -Name ID -value $null
        foreach ($_ in $ConfigurationTypesUnmodified) {
             $_.attributes.ID = $_.id   
        }
        $ConfigurationTypes = $ConfigurationTypesUnmodified.attributes
        if ($pageTotal -gt 1) {
            $pageNumberCounter++
                DO {
                    Write-Host "INFO: There are $($pageTotal) pages of items available - querying page $($pageNumberCounter) too add to 'ConfigurationTypes'"
                    $ConfigurationTypesUnmodified = (Get-ITGlueConfigurationTypes -page_size 1000 -page_number $pageNumberCounter).data
                    $ConfigurationTypesUnmodified.attributes | Add-Member Noteproperty -Name ID -value $null
                    foreach ($_ in $ConfigurationTypesUnmodified) {
                         #$_.attributes
                         $_.attributes.ID = $_.id    
                    }
                    $ConfigurationTypes = $ConfigurationTypes + $ConfigurationTypesUnmodified.attributes
                    $pageNumberCounter++
                }Until ($pageNumberCounter -eq ($pageTotal + 1))
            Write-Host "INFO: Data collection finished after $($pageNumberCounter - 1) pages with a total number of $($ConfigurationTypes.Count) objects"
            if ($itemsTotal -ne $ConfigurationTypes.Count) {
                Write-Host "WARNING: There may be more data in IT Glue than was retireved - the API page limit has been reached and no more 'ConfigurationTypes' can be pulled." -BackgroundColor DarkRed
                Write-Host "            - Narrow in on further filtering in your script if you are focusing on 'ConfigurationTypes' to be sure you have all the data you need -" -BackgroundColor DarkRed
                Write-Host "            - See https://support.itglue.com/hc/en-us/articles/360004934057-Pagination-in-the-IT-Glue-API for more information on the page limits" -BackgroundColor DarkYellow
                Write-Host " Expected $($itemsTotal) items but due to API limitations could only capture $($ConfigurationTypes.Count)" -BackgroundColor DarkYellow -ForegroundColor Black

            }
        }#End If
        Write-Host "INFO: The ConfigurationTypes data for all configuration item types has been saved in the 'ConfigurationTypes' variable - there were $($ConfigurationTypes.Count) detected"
     

        #Generate Global Variable - $ConfigurationStatuses - by default OrgINFO does not pull down in an easy to parse way for humans.  This appends the ID  to the Attributes, and then cleans it all up so it is at the root of the ConfigurationStatuses variable
        $pageNumberCounter = 1
        $ConfigurationStatusesRaw = Get-ITGlueConfigurationStatuses -page_size 1000 -page_number $pageNumberCounter
        $ConfigurationStatusesUnmodified = $ConfigurationStatusesRaw.data
        $pageTotal = $ConfigurationStatusesRaw.meta.'total-pages'
        $itemsTotal = $ConfigurationStatusesRaw.meta.'total-count'
        Write-Host "INFO: Gathering IT Glue 'ConfigurationStatuses' Data"
        $ConfigurationStatusesUnmodified.attributes | Add-Member Noteproperty -Name ID -value $null
        foreach ($_ in $ConfigurationStatusesUnmodified) {
             $_.attributes.ID = $_.id   
        }
        $ConfigurationStatuses = $ConfigurationStatusesUnmodified.attributes
        if ($pageTotal -gt 1) {
            $pageNumberCounter++
                DO {
                    Write-Host "INFO: There are $($pageTotal) pages of items available - querying page $($pageNumberCounter) too add to 'ConfigurationStatuses'"
                    $ConfigurationStatusesUnmodified = (Get-ITGlueConfigurationStatuses -page_size 1000 -page_number $pageNumberCounter).data
                    $ConfigurationStatusesUnmodified.attributes | Add-Member Noteproperty -Name ID -value $null
                    foreach ($_ in $ConfigurationStatusesUnmodified) {
                         #$_.attributes
                         $_.attributes.ID = $_.id    
                    }
                    $ConfigurationStatuses = $ConfigurationStatuses + $ConfigurationStatusesUnmodified.attributes
                    $pageNumberCounter++
                }Until ($pageNumberCounter -eq ($pageTotal + 1))
            Write-Host "INFO: Data collection finished after $($pageNumberCounter - 1) pages with a total number of $($ConfigurationStatuses.Count) objects"
            if ($itemsTotal -ne $ConfigurationStatuses.Count) {
                Write-Host "WARNING: There may be more data in IT Glue than was retireved - the API page limit has been reached and no more 'ConfigurationStatuses' can be pulled." -BackgroundColor DarkRed
                Write-Host "            - Narrow in on further filtering in your script if you are focusing on 'ConfigurationStatuses' to be sure you have all the data you need -" -BackgroundColor DarkRed
                Write-Host "            - See https://support.itglue.com/hc/en-us/articles/360004934057-Pagination-in-the-IT-Glue-API for more information on the page limits" -BackgroundColor DarkYellow
                Write-Host " Expected $($itemsTotal) items but due to API limitations could only capture $($ConfigurationStatuses.Count)" -BackgroundColor DarkYellow -ForegroundColor Black

            }
        }#End If
        Write-Host "INFO: The ConfigurationStatuses data for all configuration item types has been saved in the 'ConfigurationStatuses' variable - there were $($ConfigurationStatuses.Count) detected"


        #Generate Global Variable - $Configurations - by default OrgINFO does not pull down in an easy to parse way for humans.  This appends the ID  to the Attributes, and then cleans it all up so it is at the root of the Configurations variable
        $pageNumberCounter = 1
        $ConfigurationsRaw = Get-ITGlueConfigurations -page_size 1000 -page_number $pageNumberCounter
        $ConfigurationsUnmodified = $ConfigurationsRaw.data
        $pageTotal = $ConfigurationsRaw.meta.'total-pages'
        $itemsTotal = $ConfigurationsRaw.meta.'total-count'
        Write-Host "INFO: Gathering IT Glue 'Configurations' Data"
        $ConfigurationsUnmodified.attributes | Add-Member Noteproperty -Name ID -value $null
        foreach ($_ in $ConfigurationsUnmodified) {
             $_.attributes.ID = $_.id   
        }
        $Configurations = $ConfigurationsUnmodified.attributes
        if ($pageTotal -gt 1) {
            $pageNumberCounter++
                DO {
                    Write-Host "INFO: There are $($pageTotal) pages of items available - querying page $($pageNumberCounter) too add to 'Configurations'"
                    $ConfigurationsUnmodified = (Get-ITGlueConfigurations -page_size 1000 -page_number $pageNumberCounter).data
                    $ConfigurationsUnmodified.attributes | Add-Member Noteproperty -Name ID -value $null
                    foreach ($_ in $ConfigurationsUnmodified) {
                         #$_.attributes
                         $_.attributes.ID = $_.id    
                    }
                    $Configurations = $Configurations + $ConfigurationsUnmodified.attributes
                    $pageNumberCounter++
                }Until ($pageNumberCounter -eq ($pageTotal + 1))
            Write-Host "INFO: Data collection finished after $($pageNumberCounter - 1) pages with a total number of $($Configurations.Count) objects"
            if ($itemsTotal -ne $Configurations.Count) {
                Write-Host "WARNING: There may be more data in IT Glue than was retireved - the API page limit has been reached and no more 'Configurations' can be pulled." -BackgroundColor DarkRed
                Write-Host "            - Narrow in on further filtering in your script if you are focusing on 'Configurations' to be sure you have all the data you need -" -BackgroundColor DarkRed
                Write-Host "            - See https://support.itglue.com/hc/en-us/articles/360004934057-Pagination-in-the-IT-Glue-API for more information on the page limits" -BackgroundColor DarkYellow
                Write-Host " Expected $($itemsTotal) items but due to API limitations could only capture $($Configurations.Count)" -BackgroundColor DarkYellow -ForegroundColor Black
            }
        }#End If
        Write-Host "INFO: The Configurations data for all configuration item types has been saved in the 'Configurations' variable - there were $($Configurations.Count) detected"


        #Generate Global Variable - $orphanedDevices - this will contain all onfiguration which are not already archived and which have a psa-integration status of 'orphaned', which will ultimately be our cleanup targets
        $orphanedDevices = $Configurations | Where-Object -Property psa-integration -eq "orphaned" | Where-Object -Property archived -ne "True"

        #Display information about all of the Global Variables that have been pre-populated
        $GlobalVarInfoString = "
        Global Variables Populated       Number of Enries
           
       
        ConfigurationTypes               $($ConfigurationTypes.Count)
        configStatuses                   $($ConfigurationStatuses.count)
        Configurations                   $($Configurations.count)
        Orphans                          $($orphanedDevices.count)
        AutoRemoveOrphans                $($AutoRemoveOrphans)

        "

        Write-Host " - Global Variables have been pre-popluated, displaying information -" -BackgroundColor Cyan -ForegroundColor Black
        Write-Host $GlobalVarInfoString


    }#End 'Begin' section

    
    PROCESS {
        #Beginning Process Section - Start by exporting the orphan list to csv if that option was selected

        #Export orphan list to CSV if a path has been set prior to processing any devices for removal from IT Glue
        if ($exportCsvPath) {
            $date = Get-Date -format MM-dd-yyyy
            Write-Host "INFO: Exporting CSV list of orphans to: $($exportCsvPath)"
            $orphanedDevices | Export-Csv -NoTypeInformation -Path "$($exportCsvPath)\OrphanedDeviceList-$($date).csv"
        }else{
            Write-Host "INFO: Skipping CSV export - parameter not defined"
        }
        

        Write-Host "Detected $($orphanedDevices.count) orphaned devices - processing for removal"
        Write-Host "Number of Orphaned Accounts detected: $($orphanedDevices.count)"
        Write-Host "NOTE: AutoRemoveOrphans is set to $($AutoRemoveOrphans)"
        foreach ($orphan in $orphanedDevices) {
            Write-Host "INFO: Processing $($orphan.name) - $($orphan.'resource-url')"
            $orphan
            if ($AutoRemoveOrphans -eq $true) {
                  #Removing the device without user confirmation
                  Write-Host "Removing $($orphan.name) without confirmation"
                  Remove-ITGlueConfigurations -id $orphan.ID -Verbose
            }else{
                Write-Host "AutoRemoveOrphans is set to false - providing an opportunity to skip removal for this device:"
                $confirmation = Read-Host "Are you Sure You Want To Proceed with Removal of $($orphan.name) - $($orphan.'resouce-url')"
                if ($confirmation -eq 'y') {
                    #Removing the orphan device after user confirmation
                    Write-Host "Removing $($orphan.name) after user confirmation"
                    Remove-ITGlueConfigurations -id $orphan.ID -Verbose
                }#End if Confirmation



            }#End if AutoRemoveOptions Else
           
        }#End ForEach Orpahan

    }#End Process
    


    END {
        Write-Host "INFO: 'End' Process has started - cleaning up any changes (if necessary)" -BackgroundColor DarkYellow

        #If the PSGallery Repository was not already set to trusted when the script started, setting it back to it's original state so that the script doesn't make any changes on the target machine that the user does not expect to stay changed.
        if ($initialPSGalleryInstallationPolicyStatus -ne "Trusted") {
            Write-Host "INFO: The PSGallery Repository was initially set to '$($initialPSGalleryInstallationPolicyStatus)' when this script started - setting the PSGallery InstallationPolicy back to $($initialPSGalleryInstallationPolicyStatus)."
            try {
                Write-Host "INFO: Attempting to set the PSGallery Repository InstallationPolicy to '$($initialPSGalleryInstallationPolicyStatus)'"
                Set-PSRepository -InstallationPolicy $($initialPSGalleryInstallationPolicyStatus) -Name PSGallery
                Get-PSRepository -Name PSGallery 
            }catch{
                Write-Host "ERROR: Unable to set PSGallery InstallationPolicy to $($initialPSGalleryInstallationPolicyStatus)" -BackgroundColor DarkRed
            }#Endd Try/Catch set PSGallery Repository to Trusted
        }else{
            Write-Host "INFO: No changes required to the PSGallery Repository Installation Policy - it was already set to '$($initialPSGalleryInstallationPolicyStatus)' when the script started.  Skipping reversion step."
        }

        #Notifying the user the script has come to an end
        Write-Host "INFO: The script run has been completed."
    }#End 'End'
}

Clear-ITGlueOrphanConfigurations -ITG_APIKey APIKEYHERE  -ITG_OrgID ITLUEORGIDHERE -AutoRemoveOrphans $false -exportCsvPath C:\Temp


