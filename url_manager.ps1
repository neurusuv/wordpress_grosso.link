# WordPress URL Manager
# 管理WordPress URL的完整解决方案

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "status",
    [Parameter(Mandatory=$false)]
    [string]$NewUrl = "",
    [Parameter(Mandatory=$false)]
    [string]$Port = "9898"
)

function Show-Status {
    Write-Host "WordPress URL Status" -ForegroundColor Green
    Write-Host "===================" -ForegroundColor Green
    
    # Check Docker containers
    $containers = docker-compose ps
    if ($containers -match "Up") {
        Write-Host "✓ Docker containers are running" -ForegroundColor Green
    } else {
        Write-Host "✗ Docker containers are not running" -ForegroundColor Red
        return
    }
    
    # Get current URLs from database
    $homeUrl = docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "SELECT option_value FROM wp_options WHERE option_name = 'home';" | Select-String "http" | ForEach-Object { $_.Line.Trim() }
    $siteUrl = docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "SELECT option_value FROM wp_options WHERE option_name = 'siteurl';" | Select-String "http" | ForEach-Object { $_.Line.Trim() }
    
    Write-Host "Database Home URL: $homeUrl" -ForegroundColor Cyan
    Write-Host "Database Site URL: $siteUrl" -ForegroundColor Cyan
    
    # Check wp-config.php
    $configContent = Get-Content "wp_data/wp-config.php" -Raw
    if ($configContent -match "WP_HOME.*getenv_docker") {
        Write-Host "✓ wp-config.php uses environment variables" -ForegroundColor Green
    } else {
        Write-Host "⚠ wp-config.php has hardcoded URLs" -ForegroundColor Yellow
    }
    
    # Check docker-compose.yml
    $composeContent = Get-Content "docker-compose.yml" -Raw
    if ($composeContent -match "WORDPRESS_HOME") {
        Write-Host "✓ docker-compose.yml has environment variables" -ForegroundColor Green
    } else {
        Write-Host "⚠ docker-compose.yml missing environment variables" -ForegroundColor Yellow
    }
}

function Update-URL {
    param([string]$Url)
    
    if (-not $Url) {
        Write-Host "Error: URL is required" -ForegroundColor Red
        return
    }
    
    Write-Host "Updating WordPress URL to: $Url" -ForegroundColor Green
    
    # Get current URL
    $currentUrl = docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "SELECT option_value FROM wp_options WHERE option_name = 'home';" | Select-String "http" | ForEach-Object { $_.Line.Trim() }
    
    if ($currentUrl -eq $Url) {
        Write-Host "URL is already set to: $Url" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Current URL: $currentUrl" -ForegroundColor Yellow
    Write-Host "New URL: $Url" -ForegroundColor Yellow
    
    # Update database
    Write-Host "Updating database..." -ForegroundColor Cyan
    docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "UPDATE wp_options SET option_value = REPLACE(option_value, '$currentUrl', '$Url') WHERE option_value LIKE '%$currentUrl%';"
    docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "UPDATE wp_posts SET post_content = REPLACE(post_content, '$currentUrl', '$Url') WHERE post_content LIKE '%$currentUrl%';"
    docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, '$currentUrl', '$Url') WHERE meta_value LIKE '%$currentUrl%';"
    docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "UPDATE wp_comments SET comment_content = REPLACE(comment_content, '$currentUrl', '$Url') WHERE comment_content LIKE '%$currentUrl%';"
    docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "UPDATE wp_usermeta SET meta_value = REPLACE(meta_value, '$currentUrl', '$Url') WHERE meta_value LIKE '%$currentUrl%';"
    
    # Clear cache
    docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "DELETE FROM wp_options WHERE option_name LIKE '_transient_%';"
    
    Write-Host "✓ URL update completed!" -ForegroundColor Green
}

function Set-Port {
    param([string]$Port)
    
    if (-not $Port) {
        Write-Host "Error: Port is required" -ForegroundColor Red
        return
    }
    
    Write-Host "Setting port to: $Port" -ForegroundColor Green
    
    # Update docker-compose.yml
    $composeContent = Get-Content "docker-compose.yml" -Raw
    $newComposeContent = $composeContent -replace "(\d+):80", "$Port`:80"
    $newComposeContent | Set-Content "docker-compose.yml"
    
    # Update environment variables
    $newComposeContent = $newComposeContent -replace "WORDPRESS_HOME=.*", "WORDPRESS_HOME=http://localhost:$Port/"
    $newComposeContent = $newComposeContent -replace "WORDPRESS_SITEURL=.*", "WORDPRESS_SITEURL=http://localhost:$Port/"
    $newComposeContent | Set-Content "docker-compose.yml"
    
    # Update wp-config.php
    $configContent = Get-Content "wp_data/wp-config.php" -Raw
    $newConfigContent = $configContent -replace "WP_HOME.*localhost:\d+", "WP_HOME', getenv_docker('WORDPRESS_HOME', 'http://localhost:$Port/'))"
    $newConfigContent = $newConfigContent -replace "WP_SITEURL.*localhost:\d+", "WP_SITEURL', getenv_docker('WORDPRESS_SITEURL', 'http://localhost:$Port/'))"
    $newConfigContent | Set-Content "wp_data/wp-config.php"
    
    Write-Host "✓ Port configuration updated!" -ForegroundColor Green
    Write-Host "Please restart containers: docker-compose down && docker-compose up -d" -ForegroundColor Yellow
}

# Main logic
switch ($Action.ToLower()) {
    "status" {
        Show-Status
    }
    "update" {
        Update-URL -Url $NewUrl
    }
    "port" {
        Set-Port -Port $Port
    }
    default {
        Write-Host "Usage:" -ForegroundColor Yellow
        Write-Host "  .\url_manager.ps1 status                    # Show current status" -ForegroundColor White
        Write-Host "  .\url_manager.ps1 update -NewUrl 'http://example.com'  # Update URL" -ForegroundColor White
        Write-Host "  .\url_manager.ps1 port -Port 8080          # Change port" -ForegroundColor White
    }
}
