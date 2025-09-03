#!/bin/bash

# WordPress静态网站生成脚本
# 使用wget抓取整个网站并保存为静态文件

echo "开始生成WordPress静态网站..."

# 设置变量
SITE_URL="http://localhost:9898"
OUTPUT_DIR="/var/www/html/static_site"
TEMP_DIR="/tmp/static_generation"

# 创建输出目录
echo "创建输出目录: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_DIR"

# 清理之前的文件
echo "清理之前的文件..."
rm -rf "$OUTPUT_DIR"/*

# 使用wget抓取网站
echo "开始抓取网站: $SITE_URL"
cd "$TEMP_DIR"

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
    "$SITE_URL"

# 移动文件到输出目录
echo "移动文件到输出目录..."
mv localhost:9898/* "$OUTPUT_DIR/" 2>/dev/null || true

# 复制WordPress静态资源
echo "复制WordPress静态资源..."
cp -r /var/www/html/wp-content/uploads "$OUTPUT_DIR/wp-content/" 2>/dev/null || true
cp -r /var/www/html/wp-content/themes "$OUTPUT_DIR/wp-content/" 2>/dev/null || true
cp -r /var/www/html/wp-content/plugins "$OUTPUT_DIR/wp-content/" 2>/dev/null || true

# 修复链接
echo "修复内部链接..."
find "$OUTPUT_DIR" -name "*.html" -type f -exec sed -i 's|http://localhost:9898/||g' {} \;
find "$OUTPUT_DIR" -name "*.html" -type f -exec sed -i 's|https://localhost:9898/||g' {} \;

# 创建index.html重定向
echo "创建index.html..."
cat > "$OUTPUT_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>静态网站</title>
    <meta http-equiv="refresh" content="0; url=./index.html">
</head>
<body>
    <p>正在跳转到主页...</p>
</body>
</html>
EOF

# 设置权限
echo "设置文件权限..."
chown -R www-data:www-data "$OUTPUT_DIR"
chmod -R 755 "$OUTPUT_DIR"

# 清理临时文件
echo "清理临时文件..."
rm -rf "$TEMP_DIR"

echo "静态网站生成完成！"
echo "输出目录: $OUTPUT_DIR"
echo "您可以通过 http://localhost:9898/static_site/ 访问静态网站"
