Write-Host $env:jsonPath
Get-Content $env:jsonPath
#jsonPath coming from azure devops pipeline pointing to output.json from terraform output
Get-Content $env:jsonPath
$data = Get-Content $env:jsonPath | ConvertFrom-Json
Set-Variable -name storage_account_name -value $data."storage-account-name".value
cd $(System.DefaultWorkingDirectory)\azure-static-website-storage-explorer\static-website-template
$containerexists = $(az storage container list --account-name  $storage_account_name --query "[].name" | 
Select-String '\$web').length
if($containerexists -gt 0){
    Write-Host "Deleting container data"
    az storage blob delete-batch -s '$web' --account-name $storage_account_name
}
else {
    Write-host "Creating container"
    az storage container-rm create -n '$web' --storage-account $storage_account_name
}
Write-Host "Uploading files to container"
az storage blob upload-batch -d '$web' -s . --account-name $storage_account_name