# WordPress URL更新脚本 (PowerShell版本)
# 使用方法: .\update_urls.ps1 [新URL] [旧URL]
# 例如: .\update_urls.ps1 "http://localhost:9898" "http://10.10.10.112"

param(
    [string]$NewUrl = "http://localhost:9898",
    [string]$OldUrl = "http://10.10.10.112"
)

Write-Host "正在更新WordPress URL..." -ForegroundColor Green
Write-Host "从: $OldUrl" -ForegroundColor Yellow
Write-Host "到: $NewUrl" -ForegroundColor Yellow

# 检查Docker容器是否运行
$containers = docker-compose ps
if (-not ($containers -match "Up")) {
    Write-Host "错误: Docker容器未运行，请先启动容器" -ForegroundColor Red
    exit 1
}

# 更新wp_options表中的URL
Write-Host "1. 更新wp_options表中的URL..." -ForegroundColor Cyan
$sql1 = @"
UPDATE wp_options SET option_value = REPLACE(option_value, '$OldUrl', '$NewUrl') WHERE option_value LIKE '%$OldUrl%';
UPDATE wp_options SET option_value = REPLACE(option_value, '$OldUrl/', '$NewUrl/') WHERE option_value LIKE '%$OldUrl/%';
"@

docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e $sql1

# 更新wp_posts表中的内容
Write-Host "2. 更新wp_posts表中的内容..." -ForegroundColor Cyan
$sql2 = @"
UPDATE wp_posts SET post_content = REPLACE(post_content, '$OldUrl', '$NewUrl') WHERE post_content LIKE '%$OldUrl%';
UPDATE wp_posts SET post_content = REPLACE(post_content, '$OldUrl/', '$NewUrl/') WHERE post_content LIKE '%$OldUrl/%';
UPDATE wp_posts SET post_excerpt = REPLACE(post_excerpt, '$OldUrl', '$NewUrl') WHERE post_excerpt LIKE '%$OldUrl%';
UPDATE wp_posts SET post_excerpt = REPLACE(post_excerpt, '$OldUrl/', '$NewUrl/') WHERE post_excerpt LIKE '%$OldUrl/%';
"@

docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e $sql2

# 更新wp_postmeta表中的元数据
Write-Host "3. 更新wp_postmeta表中的元数据..." -ForegroundColor Cyan
$sql3 = @"
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, '$OldUrl', '$NewUrl') WHERE meta_value LIKE '%$OldUrl%';
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, '$OldUrl/', '$NewUrl/') WHERE meta_value LIKE '%$OldUrl/%';
"@

docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e $sql3

# 更新wp_comments表中的评论内容
Write-Host "4. 更新wp_comments表中的评论内容..." -ForegroundColor Cyan
$sql4 = @"
UPDATE wp_comments SET comment_content = REPLACE(comment_content, '$OldUrl', '$NewUrl') WHERE comment_content LIKE '%$OldUrl%';
UPDATE wp_comments SET comment_content = REPLACE(comment_content, '$OldUrl/', '$NewUrl/') WHERE comment_content LIKE '%$OldUrl/%';
UPDATE wp_comments SET comment_author_url = REPLACE(comment_author_url, '$OldUrl', '$NewUrl') WHERE comment_author_url LIKE '%$OldUrl%';
UPDATE wp_comments SET comment_author_url = REPLACE(comment_author_url, '$OldUrl/', '$NewUrl/') WHERE comment_author_url LIKE '%$OldUrl/%';
"@

docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e $sql4

# 更新wp_usermeta表中的用户元数据
Write-Host "5. 更新wp_usermeta表中的用户元数据..." -ForegroundColor Cyan
$sql5 = @"
UPDATE wp_usermeta SET meta_value = REPLACE(meta_value, '$OldUrl', '$NewUrl') WHERE meta_value LIKE '%$OldUrl%';
UPDATE wp_usermeta SET meta_value = REPLACE(meta_value, '$OldUrl/', '$NewUrl/') WHERE meta_value LIKE '%$OldUrl/%';
"@

docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e $sql5

# 清理缓存
Write-Host "6. 清理WordPress缓存..." -ForegroundColor Cyan
$sql6 = @"
DELETE FROM wp_options WHERE option_name LIKE '_transient_%';
DELETE FROM wp_options WHERE option_name LIKE '_site_transient_%';
"@

docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e $sql6

Write-Host "URL更新完成！" -ForegroundColor Green
Write-Host "请访问 $NewUrl 查看更新后的网站" -ForegroundColor Green
