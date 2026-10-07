$departments = @("HR", "IT", "Sales")
$basePath = "C:\EnterpriseShares"

# Hardcoding the known NetBIOS name since FS01 does not have AD PowerShell modules installed
$domainNetBIOS = "BCLOUDSOLUTIONS" 

Write-Host "Creating Enterprise Shares and Configuring NTFS Permissions for $domainNetBIOS..." -ForegroundColor Cyan

# Create the root directory
New-Item -Path $basePath -ItemType Directory -Force | Out-Null

foreach ($dept in $departments) {
    $folderPath = "$basePath\$dept"
    $shareName = "$dept-Data"
    
    # 1. Create the local Directory
    New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
    
    # 2. Create the SMB Share 
    New-SmbShare -Name $shareName -Path $folderPath -FullAccess "Everyone" -Description "$dept Department Share" -ErrorAction SilentlyContinue | Out-Null
    
    # 3. Configure Strict NTFS Permissions
    $acl = Get-Acl -Path $folderPath
    
    # Disable inheritance and remove existing inherited rules
    $acl.SetAccessRuleProtection($true, $false)
    
    # Define Access Rules
    $groupRule = New-Object System.Security.AccessControl.FileSystemAccessRule("$domainNetBIOS\SG-$dept", "Modify", "ContainerInherit, ObjectInherit", "None", "Allow")
    $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("$domainNetBIOS\Domain Admins", "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
    $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\SYSTEM", "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")

    # Apply rules to the ACL object
    $acl.AddAccessRule($groupRule)
    $acl.AddAccessRule($adminRule)
    $acl.AddAccessRule($systemRule)
    
    # Commit the ACL back to the folder
    Set-Acl -Path $folderPath -AclObject $acl
    
    Write-Host "Success: Created Share \\FS01\$shareName and locked NTFS to $domainNetBIOS\SG-$dept" -ForegroundColor Green
}

Write-Host "File Server Configuration Complete!" -ForegroundColor Yellow