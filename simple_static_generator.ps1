# 简单静态网站生成脚本
# 手动抓取主要页面并保存为静态文件

Write-Host "简单静态网站生成器" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green

# 检查Docker容器是否运行
$containers = docker-compose ps
if (-not ($containers -match "Up")) {
    Write-Host "错误: Docker容器未运行，请先启动容器" -ForegroundColor Red
    exit 1
}

# 设置变量
$siteUrl = "http://localhost:9898"
$outputDir = "/var/www/html/static_site"

# 创建输出目录
Write-Host "创建输出目录..." -ForegroundColor Cyan
docker-compose exec wordpress mkdir -p $outputDir
docker-compose exec wordpress rm -rf "$outputDir/*"

# 要抓取的页面列表
$pages = @(
    "/",
    "/about-us/",
    "/gl901/",
    "/linear-hall-sensor/",
    "/tmr-magnetic-sensors/",
    "/tmr-magnetic-sensors-2/",
    "/tmr-magnetic-switch/"
)

# 抓取每个页面
foreach ($page in $pages) {
    $url = $siteUrl + $page
    $filename = if ($page -eq "/") { "index.html" } else { $page.Trim('/') + ".html" }
    
    Write-Host "抓取页面: $url -> $filename" -ForegroundColor Yellow
    
    # 使用curl抓取页面
    docker-compose exec wordpress curl -s -o "$outputDir/$filename" "$url"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ 成功" -ForegroundColor Green
    } else {
        Write-Host "  ✗ 失败" -ForegroundColor Red
    }
}

# 复制静态资源
Write-Host "复制静态资源..." -ForegroundColor Cyan
docker-compose exec wordpress bash -c "cp -r /var/www/html/wp-content/uploads $outputDir/wp-content/ 2>/dev/null || true"
docker-compose exec wordpress bash -c "cp -r /var/www/html/wp-content/themes $outputDir/wp-content/ 2>/dev/null || true"

# 修复HTML文件中的链接
Write-Host "修复链接..." -ForegroundColor Cyan
docker-compose exec wordpress bash -c "find $outputDir -name '*.html' -type f -exec sed -i 's|http://localhost:9898/||g' {} \;"
docker-compose exec wordpress bash -c "find $outputDir -name '*.html' -type f -exec sed -i 's|https://localhost:9898/||g' {} \;"

# 设置权限
Write-Host "设置权限..." -ForegroundColor Cyan
docker-compose exec wordpress chown -R www-data:www-data $outputDir
docker-compose exec wordpress chmod -R 755 $outputDir

Write-Host "静态网站生成完成！" -ForegroundColor Green
Write-Host "输出目录: $outputDir" -ForegroundColor Yellow
Write-Host "您可以通过以下方式访问静态网站:" -ForegroundColor Yellow
Write-Host "  - http://localhost:9898/static_site/" -ForegroundColor Cyan
Write-Host "  - 或者直接复制 $outputDir 目录到您想要的位置" -ForegroundColor Cyan
