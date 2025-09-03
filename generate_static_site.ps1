# WordPress静态网站生成脚本 (PowerShell版本)
# 使用wget抓取整个网站并保存为静态文件

Write-Host "开始生成WordPress静态网站..." -ForegroundColor Green

# 设置变量
$siteUrl = "http://localhost:9898"
$outputDir = "/var/www/html/static_site"
$tempDir = "/tmp/static_generation"

# 检查Docker容器是否运行
$containers = docker-compose ps
if (-not ($containers -match "Up")) {
    Write-Host "错误: Docker容器未运行，请先启动容器" -ForegroundColor Red
    exit 1
}

Write-Host "创建输出目录: $outputDir" -ForegroundColor Cyan
docker-compose exec wordpress mkdir -p $outputDir
docker-compose exec wordpress mkdir -p $tempDir

# 清理之前的文件
Write-Host "清理之前的文件..." -ForegroundColor Yellow
docker-compose exec wordpress rm -rf "$outputDir/*"

# 使用wget抓取网站
Write-Host "开始抓取网站: $siteUrl" -ForegroundColor Cyan
$wgetCommand = @"
wget \
    --recursive \
    --no-clobber \
    --page-requisites \
    --html-extension \
    --convert-links \
    --restrict-file-names=windows \
    --domains localhost \
    --no-parent \
    --wait=1 \
    --random-wait \
    --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
    --reject="*.xml,*.txt,*.log" \
    --exclude-directories="/wp-admin,/wp-includes,/wp-content/uploads" \
    $siteUrl
"@

docker-compose exec wordpress bash -c "cd $tempDir && $wgetCommand"

# 移动文件到输出目录
Write-Host "移动文件到输出目录..." -ForegroundColor Cyan
docker-compose exec wordpress bash -c "mv $tempDir/localhost:9898/* $outputDir/ 2>/dev/null || true"

# 复制WordPress静态资源
Write-Host "复制WordPress静态资源..." -ForegroundColor Cyan
docker-compose exec wordpress bash -c "cp -r /var/www/html/wp-content/uploads $outputDir/wp-content/ 2>/dev/null || true"
docker-compose exec wordpress bash -c "cp -r /var/www/html/wp-content/themes $outputDir/wp-content/ 2>/dev/null || true"
docker-compose exec wordpress bash -c "cp -r /var/www/html/wp-content/plugins $outputDir/wp-content/ 2>/dev/null || true"

# 修复链接
Write-Host "修复内部链接..." -ForegroundColor Cyan
docker-compose exec wordpress bash -c "find $outputDir -name '*.html' -type f -exec sed -i 's|http://localhost:9898/||g' {} \;"
docker-compose exec wordpress bash -c "find $outputDir -name '*.html' -type f -exec sed -i 's|https://localhost:9898/||g' {} \;"

# 设置权限
Write-Host "设置文件权限..." -ForegroundColor Cyan
docker-compose exec wordpress chown -R www-data:www-data $outputDir
docker-compose exec wordpress chmod -R 755 $outputDir

# 清理临时文件
Write-Host "清理临时文件..." -ForegroundColor Yellow
docker-compose exec wordpress rm -rf $tempDir

Write-Host "静态网站生成完成！" -ForegroundColor Green
Write-Host "输出目录: $outputDir" -ForegroundColor Yellow
Write-Host "您可以通过 http://localhost:9898/static_site/ 访问静态网站" -ForegroundColor Yellow
