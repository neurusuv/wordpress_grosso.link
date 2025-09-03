# WordPress 缓存清理脚本
# 使用方法: .\cleanup_cache.ps1

Write-Host "WordPress 缓存清理工具" -ForegroundColor Green
Write-Host "=====================" -ForegroundColor Green

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

# 执行清理
Write-Host "正在清理缓存..." -ForegroundColor Cyan
docker-compose exec -T db mysql -u wordpress -pwordpress wordpress < cleanup_cache.sql

# 显示清理后的状态
Write-Host "清理后的状态:" -ForegroundColor Yellow
$afterCount = docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "SELECT COUNT(*) as count FROM wp_options;" | Select-String "\d+" | ForEach-Object { $_.Line.Trim() }
Write-Host "wp_options 条目数量: $afterCount" -ForegroundColor Cyan

$cleaned = [int]$beforeCount - [int]$afterCount
Write-Host "清理了 $cleaned 个条目" -ForegroundColor Green

Write-Host "清理完成！" -ForegroundColor Green
