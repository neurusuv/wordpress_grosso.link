# Simply Static 修复脚本
# 解决Simply Static卡住的问题

Write-Host "Simply Static 修复工具" -ForegroundColor Green
Write-Host "=====================" -ForegroundColor Green

# 检查Docker容器是否运行
$containers = docker-compose ps
if (-not ($containers -match "Up")) {
    Write-Host "错误: Docker容器未运行，请先启动容器" -ForegroundColor Red
    exit 1
}

Write-Host "正在修复Simply Static..." -ForegroundColor Cyan

# 1. 重置Simply Static状态
Write-Host "1. 重置Simply Static状态..." -ForegroundColor Yellow
docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e "UPDATE wp_options SET option_value = '' WHERE option_name = 'simply-static' AND option_value LIKE '%archive_start_time%';"

# 2. 清理临时文件
Write-Host "2. 清理临时文件..." -ForegroundColor Yellow
docker-compose exec wordpress rm -rf /var/www/html/wp-content/uploads/simply-static/temp-files/*

# 3. 清理调试日志
Write-Host "3. 清理调试日志..." -ForegroundColor Yellow
docker-compose exec wordpress rm -f /var/www/html/wp-content/uploads/simply-static/*-debug.txt

# 4. 重置Simply Static配置
Write-Host "4. 重置Simply Static配置..." -ForegroundColor Yellow
$resetConfig = @"
UPDATE wp_options SET option_value = 'a:3:{s:7:"_locale";s:4:"user";s:14:"encryption_key";s:32:"ecc60f0c0622520df5bd8ac935f8376d";s:7:"version";s:7:"3.4.4.1";}' WHERE option_name = 'simply-static';
"@

docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e $resetConfig

# 5. 设置正确的配置
Write-Host "5. 设置正确的配置..." -ForegroundColor Yellow
$config = @"
UPDATE wp_options SET option_value = 'a:117:{s:7:"_locale";s:4:"user";s:14:"encryption_key";s:32:"ecc60f0c0622520df5bd8ac935f8376d";s:18:"destination_scheme";s:8:"https://";s:16:"destination_host";s:0:"";s:14:"temp_files_dir";s:0:"";s:15:"additional_urls";s:0:"";s:16:"additional_files";s:0:"";s:15:"urls_to_exclude";s:0:"";s:15:"delivery_method";s:5:"local";s:9:"local_dir";s:27:"/var/www/html/public_static";s:13:"relative_path";s:0:"";s:20:"destination_url_type";s:8:"relative";s:14:"debugging_mode";s:1:"1";s:11:"server_cron";s:0:"";s:17:"whitelist_plugins";s:0:"";s:24:"http_basic_auth_username";s:0:"";s:24:"http_basic_auth_password";s:0:"";s:10:"origin_url";s:0:"";s:17:"force_replace_url";s:1:"1";s:29:"clear_directory_before_export";s:0:"";s:11:"iframe_urls";s:0:"";s:17:"iframe_custom_css";s:0:"";s:11:"tiiny_email";s:19:"swisschao@gmail.com";s:15:"tiiny_subdomain";s:0:"";s:19:"tiiny_domain_suffix";s:10:"tiiny.site";s:14:"tiiny_password";s:0:"";s:11:"cdn_api_key";s:0:"";s:16:"cdn_storage_host";s:20:"storage.bunnycdn.com";s:14:"cdn_access_key";s:0:"";s:13:"cdn_pull_zone";s:0:"";s:16:"cdn_storage_zone";s:0:"";s:13:"cdn_directory";s:0:"";s:19:"github_account_type";s:8:"personal";s:11:"github_user";s:0:"";s:12:"github_email";s:0:"";s:28:"github_personal_access_token";s:0:"";s:17:"github_repository";s:0:"";s:28:"github_repository_visibility";s:6:"public";s:13:"github_branch";s:4:"main";s:18:"github_webhook_url";s:0:"";s:18:"github_folder_path";s:0:"";s:24:"github_throttle_requests";s:0:"";s:15:"aws_auth_method";s:11:"aws-iam-key";s:10:"aws_region";s:9:"us-east-2";s:14:"aws_access_key";s:0:"";s:17:"aws_access_secret";s:0:"";s:10:"aws_bucket";s:0:"";s:16:"aws_subdirectory";s:0:"";s:19:"aws_distribution_id";s:0:"";s:15:"aws_webhook_url";s:0:"";s:9:"aws_empty";s:0:"";s:13:"s3_access_key";s:0:"";s:11:"s3_base_url";s:0:"";s:16:"s3_access_secret";s:0:"";s:9:"s3_bucket";s:0:"";s:15:"s3_subdirectory";s:0:"";s:8:"fix_cors";s:20:"allowed_http_origins";s:10:"static_url";s:0:"";s:9:"use_forms";s:0:"";s:12:"use_comments";s:0:"";s:16:"comment_redirect";s:0:"";s:10:"use_search";s:0:"";s:11:"search_type";s:4:"fuse";s:18:"search_index_title";s:5:"title";s:20:"search_index_content";s:4:"body";s:20:"search_index_excerpt";s:14:".entry-content";s:17:"search_excludable";s:0:"";s:15:"search_metadata";s:0:"";s:13:"fuse_selector";s:13:".search-field";s:14:"fuse_threshold";s:3:"0.1";s:14:"algolia_app_id";s:0:"";s:21:"algolia_admin_api_key";s:0:"";s:22:"algolia_search_api_key";s:0:"";s:13:"algolia_index";s:13:"simply_static";s:16:"algolia_selector";s:13:".search-field";s:10:"use_minify";s:0:"";s:11:"minify_html";s:0:"";s:10:"minify_css";s:0:"";s:17:"minify_inline_css";s:0:"";s:9:"minify_js";s:0:"";s:16:"minify_inline_js";s:0:"";s:12:"generate_404";s:0:"";s:9:"add_feeds";s:0:"";s:12:"add_rest_api";s:0:"";s:11:"smart_crawl";s:1:"1";s:17:"wp_content_folder";s:0:"";s:18:"wp_includes_folder";s:0:"";s:17:"wp_uploads_folder";s:0:"";s:17:"wp_plugins_folder";s:0:"";s:16:"wp_themes_folder";s:0:"";s:16:"theme_style_name";s:5:"style";s:10:"author_url";s:0:"";s:13:"hide_comments";s:0:"";s:12:"hide_version";s:0:"";s:14:"hide_generator";s:0:"";s:13:"hide_prefetch";s:0:"";s:8:"hide_rsd";s:0:"";s:11:"hide_emotes";s:0:"";s:14:"disable_xmlrpc";s:0:"";s:13:"disable_embed";s:0:"";s:16:"disable_db_debug";s:0:"";s:20:"disable_wlw_manifest";s:0:"";s:9:"sftp_host";s:0:"";s:9:"sftp_user";s:0:"";s:9:"sftp_pass";s:0:"";s:11:"sftp_folder";s:0:"";s:9:"sftp_port";s:2:"22";s:23:"archive_status_messages";s:0:"";s:12:"pages_status";s:0:"";s:12:"archive_name";s:0:"";s:18:"archive_start_time";s:0:"";s:16:"archive_end_time";s:0:"";s:7:"version";s:7:"3.4.4.1";s:12:"integrations";a:0:{}s:8:"crawlers";a:11:{i:0;s:6:"author";i:1;s:4:"home";i:2;s:10:"pagination";i:3;s:13:"plugin_assets";i:4;s:9:"post_type";i:5;s:7:"sitemap";i:6;s:8:"taxonomy";i:7;s:12:"theme_assets";i:8;s:7:"uploads";i:9;s:12:"vendor_files";i:10;s:11:"wp_includes";}s:13:"generate_type";s:6:"export";s:10:"post_types";a:2:{i:0;s:4:"post";i:1;s:4:"page";}}' WHERE option_name = 'simply-static';
"@

docker-compose exec -T db mysql -u wordpress -pwordpress wordpress -e $config

Write-Host "修复完成！" -ForegroundColor Green
Write-Host "现在可以重新尝试生成静态文件了" -ForegroundColor Green
