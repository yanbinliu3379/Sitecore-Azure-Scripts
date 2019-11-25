param(
    [string]$Url
)

Write-Host
Write-Host -ForegroundColor Green "Checking site"
Write-Host
Write-Host "Opening page: $Url"

$ServerErrors = 0;

do {
    $StatusCode = 0
    $IsFail = $false

    try {
        $Page = Invoke-WebRequest $Url -TimeoutSec 60 -UseBasicParsing
        $StatusCode = $Page.StatusCode
    }
    catch [System.Net.WebException] {
        if ($_ -like "*This web app is stopped*" -or ($_ -like "*The operation has timed out*")) {
            Write-Host "Site not up yet"
            Start-Sleep -s 10
        }
        else {
            $Response = $_.Exception.Response;

            if ($Response.StatusCode -eq [System.Net.HttpStatusCode]::InternalServerError -and $ServerErrors -lt 3)
            {
                $ServerErrors++
                Write-Host "Site has an error"
                Start-Sleep -s 15
            }
            else {
                $IsFail = $true
                Write-Error $_.Exception.Message
            }
        }
    }
} until ($StatusCode -eq 200 -or $IsFail)

if ($StatusCode -eq 200) {
    Write-Host "Site is up"
}

Write-Host
Write-Host -ForegroundColor Green "Finished"
Write-Host