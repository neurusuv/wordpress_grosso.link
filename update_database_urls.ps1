# Simple WordPress URL Update Script
param(
    [string]$NewUrl = "http://localhost:9898"
)

Write-Host "Updating WordPress URLs to: $NewUrl" -ForegroundColor Green

# Get current URL
$currentUrl = docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "SELECT option_value FROM wp_options WHERE option_name = 'home';" | Select-String "http" | ForEach-Object { $_.Line.Trim() }

Write-Host "Current URL: $currentUrl" -ForegroundColor Yellow
Write-Host "New URL: $NewUrl" -ForegroundColor Yellow

if ($currentUrl -eq $NewUrl) {
    Write-Host "URLs are the same, no update needed" -ForegroundColor Yellow
    exit 0
}

# Update wp_options
Write-Host "Updating wp_options..." -ForegroundColor Cyan
docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "UPDATE wp_options SET option_value = REPLACE(option_value, '$currentUrl', '$NewUrl') WHERE option_value LIKE '%$currentUrl%';"

# Update wp_posts
Write-Host "Updating wp_posts..." -ForegroundColor Cyan
docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "UPDATE wp_posts SET post_content = REPLACE(post_content, '$currentUrl', '$NewUrl') WHERE post_content LIKE '%$currentUrl%';"

# Update wp_postmeta
Write-Host "Updating wp_postmeta..." -ForegroundColor Cyan
docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, '$currentUrl', '$NewUrl') WHERE meta_value LIKE '%$currentUrl%';"

# Update wp_comments
Write-Host "Updating wp_comments..." -ForegroundColor Cyan
docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "UPDATE wp_comments SET comment_content = REPLACE(comment_content, '$currentUrl', '$NewUrl') WHERE comment_content LIKE '%$currentUrl%';"

# Update wp_usermeta
Write-Host "Updating wp_usermeta..." -ForegroundColor Cyan
docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "UPDATE wp_usermeta SET meta_value = REPLACE(meta_value, '$currentUrl', '$NewUrl') WHERE meta_value LIKE '%$currentUrl%';"

# Clear cache
Write-Host "Clearing cache..." -ForegroundColor Cyan
docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "DELETE FROM wp_options WHERE option_name LIKE '_transient_%';"

Write-Host "URL update completed!" -ForegroundColor Green
