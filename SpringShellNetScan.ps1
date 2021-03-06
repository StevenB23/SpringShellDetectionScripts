<#
.Synopsis
   SpringShell scan of ips/hosts
.DESCRIPTION
   Long description
.EXAMPLE
   .\SCRIPTHERE.ps1
.INPUTS
   TBD
.OUTPUTS
   CSV file output provided
.NOTES
   Author: Steven Bracamonte
   REF: https://www.microsoft.com/security/blog/2022/04/04/springshell-rce-vulnerability-guidance-for-protecting-against-and-detecting-cve-2022-22965/
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
$import_path = "C:\temp\externalHosts.csv" #must have the "Address" column and "name" columns
$export_path = "C:\temp\externalHosts_export.csv"

#START TLS/SSL cert bypass
add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
#END OF THE TLS SCRIPT

#Loop through the IPs and add to a psobject to then export to csv
Import-CSV $import_path |
    ForEach-Object {
          write-host $_.'Address'
          $Name = $_.'Name'
          $address = $_.'Address' #empty column
          $result = (Invoke-WebRequest -Uri "$($_.'Address')").statusCode
          try
            {
                $result80 = (Invoke-WebRequest -Uri "http://$($_.'Address')/path?class.module.classLoader.URLs%5B0%5D=0").StatusCode
                # This will only execute if the Invoke-WebRequest is successful.
            }
          catch
            {
                $result80 = $_.Exception.Response.StatusCode.value__
            }
          try
            {
                $result443 = (Invoke-WebRequest -Uri "https://$($_.'Address')/path?class.module.classLoader.URLs%5B0%5D=0").StatusCode
                # This will only execute if the Invoke-WebRequest is successful.
            }
          catch
            {
                $result443 = $_.Exception.Response.StatusCode.value__
            }
           #adding to empty column
           [pscustomobject]@{ #object to hold queried data 
                address=$address
                name=$name
                result=$result
                result80=$result80
                result443=$result443
            }
    } |
    select address,name,result,result80,result443 | Export-CSV $export_path -NoTypeInformation
    
    #TESTING Commands
#$g = curl 192.168.4.4:80/path?class.module.classLoader.URLs%5B0%5D=0
