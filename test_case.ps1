<#
.SYNOPSIS
    Test all files for correctness.

.DESCRIPTION
    This script will test all files in the current directory for correctness and tell you which ones failed
.NOTES
    This expects that the file is located within your Project directory and that the test files are
    located in the same directory as the script.

.EXAMPLE_USAGE
    Open a powershell terminal (type Powershell into Windows search), navigate the terminal ('cd' similar to BASH)
    to the project directory, and run the following command:
   . .\test_case.ps1
#>
# Get all files in the current directory that are .sql
$files = Get-ChildItem -Path . -Filter "*.sql"
# Remove any .sqlite files
$files = $files | Where-Object { $_.Name -notlike "*.sqlite" }

# Check for da dumps
if (!(Test-Path ".\dumps")) {
    New-Item -ItemType Directory -Path ".\dumps" -Force
}
# Remove any old test files
Get-ChildItem -Path ".\dumps" -Filter "*.txt" | Remove-Item -Force

$FailedCount = 0
# Loop through each file
foreach ($file in $files) {
    # Get the file name
    $fileName = $file.Name
    Write-Host "Testing $fileName"

    # Test using python cli.py
    python cli.py $fileName ".\dumps\$fileName`_test.txt"
    python cli.py $fileName ".\dumps\$fileName`_answer.txt" --sqlite

    # Compare the two files
    try
    {
        $diff = Compare-Object -ReferenceObject (Get-Content ".\dumps\$fileName`_test.txt") -DifferenceObject `
        (Get-Content ".\dumps\$fileName`_answer.txt") | Out-String
    }
    catch
    {
        Write-Host "[ !!! ] FAILED" -ForegroundColor Red
        Write-Host "python did not write to file! Internal issue. Suggest debug step through."
        Write-Host "Error: $($_.Exception.Message)"
        $FailedCount++
        continue
    }
    # If there is a difference, print the file name
    if ($diff) {
        Write-Host "$fileName"
        Write-Host "[ !!! ] FAILED" -ForegroundColor Red
        Write-Host $diff
        $FailedCount++
    }
    else {
        Write-Host "[ * ] PASSED" -ForegroundColor Green
    }
}
Write-Host "[ *** ] Testing Completed`n`t[ ? ] Results:" -ForegroundColor Yellow
if ($FailedCount -eq 0) {
    Write-Host "`t[ * ] All tests passed! Nice work!" -ForegroundColor Green
}
else {
    Write-Host "`t[ !!! ] $FailedCount tests failed!" -ForegroundColor Red
}
