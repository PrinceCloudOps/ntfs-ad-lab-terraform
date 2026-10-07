# Define the Log File
$logPath = "C:\Users\sysadmin\Desktop\Provisioning_Log.txt"
$header = "--- Active Directory Provisioning Log: $(Get-Date) ---"
Add-Content -Path $logPath -Value$header

# 1. Establish the Active Directory Hierarchy
$domain = "DC=blakecloudsolutions,DC=local"
$baseOU = "OU=EnterpriseUsers,$domain"
$departments = @("HR", "IT", "Sales")

Write-Host "Building Organizational Units & Security Groups..." -ForegroundColor Cyan
try {
    [void](New-ADOrganizationalUnit -Name "EnterpriseUsers" -Path $domain -ProtectedFromAccidentalDeletion$false -ErrorAction Stop)
    Add-Content -Path $logPath -Value "Created Root OU: EnterpriseUsers"

    foreach ($dept in$departments) {
        [void](New-ADOrganizationalUnit -Name $dept -Path $baseOU -ProtectedFromAccidentalDeletion$false -ErrorAction Stop)
        [void](New-ADGroup -Name "SG-$dept" -GroupScope Global -GroupCategory Security -Path "OU=$dept,$baseOU" -ErrorAction Stop)
        Add-Content -Path $logPath -Value "Created OU and Security Group for: $dept"
    }
} catch {
    $errMsg = "ERROR Building Structure: $($_.Exception.Message)"
    Add-Content -Path $logPath -Value$errMsg
    Write-Host "Structure build failed. Check log." -ForegroundColor Red
}

# 2. Simulate an HR Department CSV Export
$csvPath = "C:\Users\sysadmin\Desktop\HR_NewHires.csv"
$users = @()

$mockNames = @(
    "Alice Smith", "Brian Johnson", "Chloe Williams", "Daniel Brown", "Emma Jones",
    "Felix Garcia", "Grace Miller", "Henry Davis", "Isabella Rodriguez", "Jack Martinez",
    "Karen Hernandez", "Liam Lopez", "Mia Gonzalez", "Noah Wilson", "Olivia Anderson",
    "Peter Thomas", "Quinn Taylor", "Rachel Moore", "Samuel Jackson", "Tina Martin",
    "Victor Lee", "Wendy Perez", "Xavier Thompson", "Yvonne White", "Zack Harris",
    "Abigail Sanchez", "Benjamin Clark", "Catherine Ramirez", "David Lewis", "Eleanor Robinson",
    "Frank Walker", "Gabriella Young", "Harrison Allen", "Ivy King", "Jacob Wright",
    "Katherine Scott", "Lucas Torres", "Madeline Nguyen", "Nathan Hill", "Ophelia Flores",
    "Patrick Green", "Quincy Adams", "Rebecca Nelson", "Steven Baker", "Tessa Hall",
    "Ulysses Rivera", "Victoria Campbell", "William Mitchell", "Xena Carter", "Yusuf Roberts"
)

Write-Host "Generating Mock HR CSV Data for 50 Users..." -ForegroundColor Cyan

Set-Content -Path $csvPath -Value '"FirstName","LastName","Username","Department","Password"'

$deptIndex = 0

for ($i=0; $i -lt 50; $i++) {
    $dept =$departments[$deptIndex]$deptIndex++
    if ($deptIndex -eq 3) {$deptIndex = 0 }

    $nameParts = $mockNames[$i] -split " "
    $firstName = $nameParts[0]$lastName = $nameParts[1]$username = "$($firstName.Substring(0,1).ToLower())$($lastName.ToLower())"
    $password = "Welcome2BlakeCloud!"

    $newUser = [PSCustomObject]@{
        FirstName  = $firstName
        LastName   = $lastName
        Username   = $username
        Department = $dept
        Password   = $password
    }
    $users +=$newUser

    $csvLine = "`"$firstName`",`"$lastName`",`"$username`",`"$dept`",`"$password`""
    Add-Content -Path $csvPath -Value$csvLine
}

# 3. Ingest Data, Provision Accounts, and Assign RBAC
Write-Host "Beginning Automated Account Provisioning..." -ForegroundColor Cyan
foreach ($user in$users) {
    $userOU = "OU=$($user.Department),$baseOU"
    $secPass = ConvertTo-SecureString$user.Password -AsPlainText -Force

    try {
        [void](New-ADUser -Name "$($user.FirstName) $($user.LastName)" -GivenName $user.FirstName -Surname$user.LastName -SamAccountName $user.Username -UserPrincipalName "$($user.Username)@blakecloudsolutions.local" -Department $user.Department -Path $userOU -AccountPassword$secPass -Enabled $true -PasswordNeverExpires$true -ErrorAction Stop)
        [void](Add-ADGroupMember -Identity "SG-$($user.Department)" -Members $user.Username -ErrorAction Stop)$successMsg = "Success: Provisioned $($user.Username) -> OU: $($user.Department) | Group: SG-$($user.Department)"
        Write-Host $successMsg -ForegroundColor Green
        Add-Content -Path $logPath -Value$successMsg

    } catch {
        $errorMsg = "FAILED to provision $($user.Username). Reason: $($_.Exception.Message)"
        Write-Host $errorMsg -ForegroundColor Red
        Add-Content -Path $logPath -Value$errorMsg
    }
}

Write-Host "Layer 1 Provisioning Complete! Review Provisioning_Log.txt on your desktop for details." -ForegroundColor Yellow