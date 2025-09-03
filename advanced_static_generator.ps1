# 高级静态网站生成脚本
# 自动发现所有页面并生成完整的静态网站

Write-Host "高级静态网站生成器" -ForegroundColor Green
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
$tempDir = "/tmp/static_gen"

# 创建目录
Write-Host "创建目录..." -ForegroundColor Cyan
docker-compose exec wordpress mkdir -p $outputDir
docker-compose exec wordpress mkdir -p $tempDir
docker-compose exec wordpress rm -rf "$outputDir/*"

# 从数据库获取所有页面和文章
Write-Host "从数据库获取页面列表..." -ForegroundColor Cyan
$pagesQuery = "SELECT post_name, post_type FROM wp_posts WHERE post_status = 'publish' AND post_type IN ('page', 'post') ORDER BY post_type, post_name;"
$pages = docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e $pagesQuery

# 解析页面列表
$pageList = @()
$lines = $pages -split "`n"
foreach ($line in $lines) {
    if ($line -match "^\|(.+)\|(.+)\|$") {
        $postName = $matches[1].Trim()
        $postType = $matches[2].Trim()
        if ($postName -and $postName -ne "post_name" -and $postName -ne "post_type") {
            if ($postType -eq "page") {
                $pageList += "/$postName/"
            } else {
                $pageList += "/$postName/"
            }
        }
    }
}

# 添加主页
$pageList += "/"

Write-Host "发现 $($pageList.Count) 个页面" -ForegroundColor Yellow

# 抓取每个页面
$successCount = 0
$failCount = 0

foreach ($page in $pageList) {
    $url = $siteUrl + $page
    $filename = if ($page -eq "/") { "index.html" } else { $page.Trim('/') + ".html" }
    
    Write-Host "抓取: $url" -ForegroundColor Yellow
    
    # 使用curl抓取页面
    $result = docker-compose exec wordpress curl -s -w "%{http_code}" -o "$outputDir/$filename" "$url"
    
    if ($result -eq "200") {
        Write-Host "  ✓ 成功 ($filename)" -ForegroundColor Green
        $successCount++
    } else {
        Write-Host "  ✗ 失败 (HTTP $result)" -ForegroundColor Red
        $failCount++
        # 删除失败的文件
        docker-compose exec wordpress rm -f "$outputDir/$filename"
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

# 创建目录结构
Write-Host "创建目录结构..." -ForegroundColor Cyan
foreach ($page in $pageList) {
    if ($page -ne "/") {
        $dirName = $page.Trim('/')
        docker-compose exec wordpress mkdir -p "$outputDir/$dirName"
        docker-compose exec wordpress mv "$outputDir/$dirName.html" "$outputDir/$dirName/index.html" 2>/dev/null || true
    }
}

# 设置权限
Write-Host "设置权限..." -ForegroundColor Cyan
docker-compose exec wordpress chown -R www-data:www-data $outputDir
docker-compose exec wordpress chmod -R 755 $outputDir

# 清理临时文件
docker-compose exec wordpress rm -rf $tempDir

# 显示结果
Write-Host "`n静态网站生成完成！" -ForegroundColor Green
Write-Host "成功: $successCount 个页面" -ForegroundColor Green
Write-Host "失败: $failCount 个页面" -ForegroundColor Red
Write-Host "输出目录: $outputDir" -ForegroundColor Yellow
Write-Host "`n访问方式:" -ForegroundColor Yellow
Write-Host "  - http://localhost:9898/static_site/" -ForegroundColor Cyan
Write-Host "  - 或复制整个 $outputDir 目录到您想要的位置" -ForegroundColor Cyan
