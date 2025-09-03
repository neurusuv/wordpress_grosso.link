# 智能WordPress URL更新脚本
# 自动检测当前URL并更新到新URL
# 使用方法: .\smart_url_update.ps1 [新URL]

param(
    [Parameter(Mandatory=$true)]
    [string]$NewUrl
)

Write-Host "智能WordPress URL更新工具" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

# 检查Docker容器是否运行
$containers = docker-compose ps
if (-not ($containers -match "Up")) {
    Write-Host "错误: Docker容器未运行，请先启动容器" -ForegroundColor Red
    exit 1
}

# 获取当前URL
Write-Host "正在检测当前URL..." -ForegroundColor Yellow
$currentUrl = docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "SELECT option_value FROM wp_options WHERE option_name = 'home';" | Select-String "http" | ForEach-Object { $_.Line.Trim() }

if (-not $currentUrl) {
    Write-Host "错误: 无法获取当前URL" -ForegroundColor Red
    exit 1
}

Write-Host "当前URL: $currentUrl" -ForegroundColor Cyan
Write-Host "新URL: $NewUrl" -ForegroundColor Cyan

if ($currentUrl -eq $NewUrl) {
    Write-Host "URL相同，无需更新" -ForegroundColor Yellow
    exit 0
}

# 确认更新
$confirm = Read-Host "确认要更新URL吗？(y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "取消更新" -ForegroundColor Yellow
    exit 0
}

Write-Host "开始更新URL..." -ForegroundColor Green

# 更新所有相关表
$tables = @(
    @{Name="wp_options"; Description="Options Table"},
    @{Name="wp_posts"; Description="Posts Table"},
    @{Name="wp_postmeta"; Description="Post Meta Table"},
    @{Name="wp_comments"; Description="Comments Table"},
    @{Name="wp_usermeta"; Description="User Meta Table"}
)

foreach ($table in $tables) {
    Write-Host "更新 $($table.Description)..." -ForegroundColor Cyan
    
    if ($table.Name -eq "wp_options") {
        $sql = @"
UPDATE wp_options SET option_value = REPLACE(option_value, '$currentUrl', '$NewUrl') WHERE option_value LIKE '%$currentUrl%';
UPDATE wp_options SET option_value = REPLACE(option_value, '$currentUrl/', '$NewUrl/') WHERE option_value LIKE '%$currentUrl/%';
"@
    }
    elseif ($table.Name -eq "wp_posts") {
        $sql = @"
UPDATE wp_posts SET post_content = REPLACE(post_content, '$currentUrl', '$NewUrl') WHERE post_content LIKE '%$currentUrl%';
UPDATE wp_posts SET post_content = REPLACE(post_content, '$currentUrl/', '$NewUrl/') WHERE post_content LIKE '%$currentUrl/%';
UPDATE wp_posts SET post_excerpt = REPLACE(post_excerpt, '$currentUrl', '$NewUrl') WHERE post_excerpt LIKE '%$currentUrl%';
UPDATE wp_posts SET post_excerpt = REPLACE(post_excerpt, '$currentUrl/', '$NewUrl/') WHERE post_excerpt LIKE '%$currentUrl/%';
"@
    }
    elseif ($table.Name -eq "wp_postmeta") {
        $sql = @"
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, '$currentUrl', '$NewUrl') WHERE meta_value LIKE '%$currentUrl%';
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, '$currentUrl/', '$NewUrl/') WHERE meta_value LIKE '%$currentUrl/%';
"@
    }
    elseif ($table.Name -eq "wp_comments") {
        $sql = @"
UPDATE wp_comments SET comment_content = REPLACE(comment_content, '$currentUrl', '$NewUrl') WHERE comment_content LIKE '%$currentUrl%';
UPDATE wp_comments SET comment_content = REPLACE(comment_content, '$currentUrl/', '$NewUrl/') WHERE comment_content LIKE '%$currentUrl/%';
UPDATE wp_comments SET comment_author_url = REPLACE(comment_author_url, '$currentUrl', '$NewUrl') WHERE comment_author_url LIKE '%$currentUrl%';
UPDATE wp_comments SET comment_author_url = REPLACE(comment_author_url, '$currentUrl/', '$NewUrl/') WHERE comment_author_url LIKE '%$currentUrl/%';
"@
    }
    elseif ($table.Name -eq "wp_usermeta") {
        $sql = @"
UPDATE wp_usermeta SET meta_value = REPLACE(meta_value, '$currentUrl', '$NewUrl') WHERE meta_value LIKE '%$currentUrl%';
UPDATE wp_usermeta SET meta_value = REPLACE(meta_value, '$currentUrl/', '$NewUrl/') WHERE meta_value LIKE '%$currentUrl/%';
"@
    }
    
    try {
        docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e $sql
        Write-Host "✓ $($table.Description) 更新完成" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ $($table.Description) 更新失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 清理缓存
Write-Host "清理WordPress缓存..." -ForegroundColor Cyan
$cacheSql = @"
DELETE FROM wp_options WHERE option_name LIKE '_transient_%';
DELETE FROM wp_options WHERE option_name LIKE '_site_transient_%';
"@

try {
    docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e $cacheSql
    Write-Host "✓ 缓存清理完成" -ForegroundColor Green
}
catch {
    Write-Host "✗ 缓存清理失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 验证更新结果
Write-Host "验证更新结果..." -ForegroundColor Yellow
$newHomeUrl = docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "SELECT option_value FROM wp_options WHERE option_name = 'home';" | Select-String "http" | ForEach-Object { $_.Line.Trim() }
$newSiteUrl = docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "SELECT option_value FROM wp_options WHERE option_name = 'siteurl';" | Select-String "http" | ForEach-Object { $_.Line.Trim() }

Write-Host "更新后的home URL: $newHomeUrl" -ForegroundColor Green
Write-Host "更新后的siteurl: $newSiteUrl" -ForegroundColor Green

if ($newHomeUrl -eq $NewUrl -and $newSiteUrl -eq $NewUrl) {
    Write-Host "✓ URL更新成功！" -ForegroundColor Green
    Write-Host "请访问 $NewUrl 查看更新后的网站" -ForegroundColor Green
} else {
    Write-Host "⚠ 部分URL可能未完全更新，请检查" -ForegroundColor Yellow
}
