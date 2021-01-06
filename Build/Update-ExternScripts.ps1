param(
    [string]$RootPath = "..\src",
    [string]$HeaderLineMatch = "#Master Template:",
    [switch]$IncludeLastCommitVersioning
)

$files = Get-ChildItem $RootPath -Recurse | Where-Object { $_.VersionInfo.FileName -like "*\extern\*" }

foreach ($file in $files) {
    $backup = $file.VersionInfo.FileName.Replace(".ps1", ".bak")
    $content = Get-Content $file

    $templateLine = $content[0]
    if ($templateLine.Contains($HeaderLineMatch)) {
        $webUri = $templateLine.Replace($HeaderLineMatch, "").Trim()
        $webRequest = Invoke-WebRequest $webUri -UseBasicParsing

        if ($webRequest.StatusCode -ne 200) {
            throw "Failed to return a 200 status back from web request"
        }

        $updatedScript = @()
        $webContent = $webRequest.Content

        $updatedScript += $templateLine
        if ($IncludeLastCommitVersioning) {
            #TODO: git log -n 1 --format="%ad" --date=rfc $file
        }

        foreach ($line in $webContent) {
            $updatedScript += $line
        }

    } else {
        throw "Failed to find Header Line Match for file $file"
    }

    Copy-Item $file -Destination $backup
    Remove-Item $file

    $updatedScript | Out-File $file -Encoding utf8
}