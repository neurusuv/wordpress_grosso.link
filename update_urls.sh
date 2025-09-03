#!/bin/bash

# WordPress URL更新脚本
# 使用方法: ./update_urls.sh [新URL] [旧URL]
# 例如: ./update_urls.sh "http://localhost:9898" "http://10.10.10.112"

# 设置默认值
NEW_URL=${1:-"http://localhost:9898"}
OLD_URL=${2:-"http://10.10.10.112"}

echo "正在更新WordPress URL..."
echo "从: $OLD_URL"
echo "到: $NEW_URL"

# 检查Docker容器是否运行
if ! docker-compose ps | grep -q "Up"; then
    echo "错误: Docker容器未运行，请先启动容器"
    exit 1
fi

# 更新wp_options表中的URL
echo "1. 更新wp_options表中的URL..."
docker-compose exec -T db mysql -u wordpress -pwordpress wordpress << EOF
UPDATE wp_options SET option_value = REPLACE(option_value, '$OLD_URL', '$NEW_URL') WHERE option_value LIKE '%$OLD_URL%';
UPDATE wp_options SET option_value = REPLACE(option_value, '$OLD_URL/', '$NEW_URL/') WHERE option_value LIKE '%$OLD_URL/%';
EOF

# 更新wp_posts表中的内容
echo "2. 更新wp_posts表中的内容..."
docker-compose exec -T db mysql -u wordpress -pwordpress wordpress << EOF
UPDATE wp_posts SET post_content = REPLACE(post_content, '$OLD_URL', '$NEW_URL') WHERE post_content LIKE '%$OLD_URL%';
UPDATE wp_posts SET post_content = REPLACE(post_content, '$OLD_URL/', '$NEW_URL/') WHERE post_content LIKE '%$OLD_URL/%';
UPDATE wp_posts SET post_excerpt = REPLACE(post_excerpt, '$OLD_URL', '$NEW_URL') WHERE post_excerpt LIKE '%$OLD_URL%';
UPDATE wp_posts SET post_excerpt = REPLACE(post_excerpt, '$OLD_URL/', '$NEW_URL/') WHERE post_excerpt LIKE '%$OLD_URL/%';
EOF

# 更新wp_postmeta表中的元数据
echo "3. 更新wp_postmeta表中的元数据..."
docker-compose exec -T db mysql -u wordpress -pwordpress wordpress << EOF
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, '$OLD_URL', '$NEW_URL') WHERE meta_value LIKE '%$OLD_URL%';
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, '$OLD_URL/', '$NEW_URL/') WHERE meta_value LIKE '%$OLD_URL/%';
EOF

# 更新wp_comments表中的评论内容
echo "4. 更新wp_comments表中的评论内容..."
docker-compose exec -T db mysql -u wordpress -pwordpress wordpress << EOF
UPDATE wp_comments SET comment_content = REPLACE(comment_content, '$OLD_URL', '$NEW_URL') WHERE comment_content LIKE '%$OLD_URL%';
UPDATE wp_comments SET comment_content = REPLACE(comment_content, '$OLD_URL/', '$NEW_URL/') WHERE comment_content LIKE '%$OLD_URL/%';
UPDATE wp_comments SET comment_author_url = REPLACE(comment_author_url, '$OLD_URL', '$NEW_URL') WHERE comment_author_url LIKE '%$OLD_URL%';
UPDATE wp_comments SET comment_author_url = REPLACE(comment_author_url, '$OLD_URL/', '$NEW_URL/') WHERE comment_author_url LIKE '%$OLD_URL/%';
EOF

# 更新wp_usermeta表中的用户元数据
echo "5. 更新wp_usermeta表中的用户元数据..."
docker-compose exec -T db mysql -u wordpress -pwordpress wordpress << EOF
UPDATE wp_usermeta SET meta_value = REPLACE(meta_value, '$OLD_URL', '$NEW_URL') WHERE meta_value LIKE '%$OLD_URL%';
UPDATE wp_usermeta SET meta_value = REPLACE(meta_value, '$OLD_URL/', '$NEW_URL/') WHERE meta_value LIKE '%$OLD_URL/%';
EOF

# 清理缓存
echo "6. 清理WordPress缓存..."
docker-compose exec -T db mysql -u wordpress -pwordpress wordpress << EOF
DELETE FROM wp_options WHERE option_name LIKE '_transient_%';
DELETE FROM wp_options WHERE option_name LIKE '_site_transient_%';
EOF

echo "URL更新完成！"
echo "请访问 $NEW_URL 查看更新后的网站"
