# WordPress wp_options 表清理脚本
# 清理过期的缓存和临时数据

Write-Host "WordPress wp_options 表清理工具" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# 检查Docker容器是否运行
$containers = docker-compose ps
if (-not ($containers -match "Up")) {
    Write-Host "错误: Docker容器未运行，请先启动容器" -ForegroundColor Red
    exit 1
}

# 显示清理前的状态
Write-Host "清理前的状态:" -ForegroundColor Yellow
$beforeCount = docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "SELECT COUNT(*) as count FROM wp_options;" | Select-String "\d+" | ForEach-Object { $_.Line.Trim() }
Write-Host "wp_options 条目数量: $beforeCount" -ForegroundColor Cyan

# 清理过期的临时缓存
Write-Host "1. 清理过期的临时缓存..." -ForegroundColor Cyan
docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "DELETE FROM wp_options WHERE option_name LIKE '_transient_timeout_%' AND option_value < UNIX_TIMESTAMP();"

# 清理过期的站点临时缓存
Write-Host "2. 清理过期的站点临时缓存..." -ForegroundColor Cyan
docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "DELETE FROM wp_options WHERE option_name LIKE '_site_transient_timeout_%' AND option_value < UNIX_TIMESTAMP();"

# 清理对应的临时缓存数据
Write-Host "3. 清理对应的临时缓存数据..." -ForegroundColor Cyan
docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "DELETE FROM wp_options WHERE option_name LIKE '_transient_%' AND option_name NOT LIKE '_transient_timeout_%' AND option_name NOT IN (SELECT REPLACE(option_name, '_transient_timeout_', '_transient_') FROM wp_options WHERE option_name LIKE '_transient_timeout_%');"

docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "DELETE FROM wp_options WHERE option_name LIKE '_site_transient_%' AND option_name NOT LIKE '_site_transient_timeout_%' AND option_name NOT IN (SELECT REPLACE(option_name, '_site_transient_timeout_', '_site_transient_') FROM wp_options WHERE option_name LIKE '_site_transient_timeout_%');"

# 清理一些特定的大缓存
Write-Host "4. 清理特定的大缓存..." -ForegroundColor Cyan
$largeCaches = @(
    "_site_transient_available_translations",
    "_site_transient_poptags_40cd750bba9870f18aada2478b24840a",
    "_site_transient_wp_theme_files_patterns-93f4f3a30109443b1f1ec1699edabcdc"
)

foreach ($cache in $largeCaches) {
    docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "DELETE FROM wp_options WHERE option_name = '$cache';"
    Write-Host "  清理: $cache" -ForegroundColor Gray
}

# 清理WP-Optimize插件的缓存
Write-Host "5. 清理WP-Optimize插件缓存..." -ForegroundColor Cyan
docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "DELETE FROM wp_options WHERE option_name LIKE 'wpo_%';"

# 显示清理后的状态
Write-Host "清理后的状态:" -ForegroundColor Yellow
$afterCount = docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "SELECT COUNT(*) as count FROM wp_options;" | Select-String "\d+" | ForEach-Object { $_.Line.Trim() }
Write-Host "wp_options 条目数量: $afterCount" -ForegroundColor Cyan

$cleaned = [int]$beforeCount - [int]$afterCount
Write-Host "清理了 $cleaned 个条目" -ForegroundColor Green

# 显示剩余的大条目
Write-Host "剩余的大条目:" -ForegroundColor Yellow
docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "SELECT option_name, LENGTH(option_value) as size FROM wp_options ORDER BY LENGTH(option_value) DESC LIMIT 5;"

Write-Host "清理完成！" -ForegroundColor Green
Write-Host "建议定期运行此脚本来保持数据库优化" -ForegroundColor Yellow
