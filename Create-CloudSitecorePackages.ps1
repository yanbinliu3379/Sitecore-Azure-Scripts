[CmdletBinding()]
Param(
  [Parameter(Mandatory=$False)]
  [switch]$SkipCargoPayloads = $False,

  [Parameter(Mandatory=$False)]
  [switch]$SkipDevPackages = $False,

  [Parameter(Mandatory=$False)]
  [switch]$SkipTestProdPackages = $False,

  [Parameter(Mandatory=$False)]
  [switch]$SkipNoDbPackages = $False,

  [Parameter(Mandatory=$False)]
  [switch]$SkipSitecorePackages = $False
)


#find the location of the sitecore azure tools
$installationPath = (Get-Item $PSScriptRoot).Parent.Parent.FullName

#current vanilla sitecore installer. Update the name of this package if this changes
$sitecoreSourceFile = 'Sitecore_9.0.2_rev.180604_Cloud_single.scwdp.zip'
$xConnectSourceFile= 'Sitecore 9.0.2 rev. 180604 Cloud_xp0xconnect.scwdp.zip'

#find the location of the resources containing the payloads to build
$resourcePath = [io.path]::combine($installationPath, 'Deploy', 'Resources')
$payloadPath = [io.path]::combine($resourcePath, 'CargoPayloads')
$configPath = [io.path]::combine($resourcePath, 'Configs')
$paramsPath = [io.path]::combine($resourcePath, 'MsDeployXmls')

#find the deploy directory to where to copy the zip
$outputFolder = [io.path]::combine($installationPath, 'Deploy', 'output')

#parameter files
$devParamsPath = [io.path]::combine($paramsPath, 'Sitecore.Dev.parameters.xml')
$devXConnextParamsPath = [io.path]::combine($paramsPath, 'Sitecore.Dev.Parameters.XConnect.xml')


#find the sc and xcon packages source file to package
$sitecoreSource = [io.path]::combine($installationPath, 'Packages', $sitecoreSourceFile)
$xconnectSource = [io.path]::combine($installationPath, 'Packages', $xConnectSourceFile)

#find the sc and xcon packages source file to package
$sitecoreDest = [io.path]::combine($outputFolder, $sitecoreSourceFile)
$xconnectDest = [io.path]::combine($outputFolder, $xConnectSourceFile)


#output settings
Write-Verbose -Message "installationPath : $installationPath" -Verbose
Write-Verbose -Message "toolsPath : $toolsPath" -Verbose
Write-Verbose -Message "resourcePath : $resourcePath" -Verbose
Write-Verbose -Message "payloadPath : $payloadPath" -Verbose
Write-Verbose -Message "configPath : $configPath" -Verbose
Write-Verbose -Message "paramsPath : $paramsPath" -Verbose
Write-Verbose -Message "outputFolder : $outputFolder" -Verbose
Write-Verbose -Message "sitecoreSource : $sitecoreSource" -Verbose
Write-Verbose -Message "xconnectSource : $xconnectSource" -Verbose
Write-Verbose -Message "sitecoreDest : $sitecoreDest" -Verbose
Write-Verbose -Message "xconnectDest : $xconnectDest" -Verbose
Write-Verbose -Message "commandlet : $commandlet" -Verbose
Write-Verbose -Message "commandletDll : $commandletDll" -Verbose

#Prevent warning when running scripts
& $PSScriptRoot\Import-SitecoreAzureCmdlets.ps1

#Copy the packages to output folder
Copy-Item -Path $sitecoreSource -Destination $sitecoreDest
Copy-Item -Path $xconnectSource -Destination $xconnectDest

#Create custom payloads
if ($SkipCargoPayloads -eq $False) {
	Write-Host "Creating Sitecore Cargo Payloads" -ForegroundColor Green
	$customPayloads = Get-ChildItem -Path $payloadPath -Filter Sitecore.Sc.* -Directory

	foreach ($customPayload in $customPayloads) {
		New-SCCargoPayload -Path $customPayload.FullName -Destination $payloadPath -Force -Verbose
	}
}

#Update WDP with the custompayload created above
    Write-Host "Updating SC Package with Custom Cargo Payloads" -ForegroundColor Green
	$customCargoPayloads = Get-ChildItem -Path $payloadPath -Filter Sitecore.Sc.*.sccpl 
    foreach ($customCPayload in $customCargoPayloads) {
        Write-Host "Updating customcpayload : "$customCPayload.FullName "to" $sitecoreDest  -ForegroundColor Green
		Update-SCWebDeployPackage -CargoPayloadPath $customCPayload.FullName -Path $sitecoreDest
	}

#Create No-DB versions of WDPS sitecore
if ($SkipNoDbPackages -eq $False) {
	Write-Host "Creating No-DB Version of Sitecore Packages" -ForegroundColor Green
		& $PSScriptRoot\Remove-DatabaseFromPackage -PackagePath $sitecoreDest -ParamFile $devParamsPath
}

#Create No-DB versions of WDPS xconnect
if ($SkipNoDbPackages -eq $False) {
	Write-Host "Creating No-DB Version of xConnect Packages" -ForegroundColor Green
		& $PSScriptRoot\Remove-DatabaseFromPackage -PackagePath $xconnectDest -ParamFile $devXConnextParamsPath
}