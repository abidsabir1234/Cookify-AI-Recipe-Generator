$VenvDir = "venv312"
if (-not (Test-Path $VenvDir)) {
    Write-Host "Not found"
}
else {
    Write-Host "Found"
}
