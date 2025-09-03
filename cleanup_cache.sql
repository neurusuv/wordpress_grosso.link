-- WordPress wp_options 表清理SQL脚本
-- 清理过期的缓存和临时数据

-- 1. 清理过期的临时缓存
DELETE FROM wp_options WHERE option_name LIKE '_transient_timeout_%' AND option_value < UNIX_TIMESTAMP();

-- 2. 清理过期的站点临时缓存
DELETE FROM wp_options WHERE option_name LIKE '_site_transient_timeout_%' AND option_value < UNIX_TIMESTAMP();

-- 3. 清理一些特定的大缓存
DELETE FROM wp_options WHERE option_name = '_site_transient_available_translations';
DELETE FROM wp_options WHERE option_name = '_site_transient_poptags_40cd750bba9870f18aada2478b24840a';
DELETE FROM wp_options WHERE option_name = '_site_transient_wp_theme_files_patterns-93f4f3a30109443b1f1ec1699edabcdc';

-- 4. 清理WP-Optimize插件缓存
DELETE FROM wp_options WHERE option_name LIKE 'wpo_%';

-- 5. 清理其他临时数据
DELETE FROM wp_options WHERE option_name LIKE '_transient_doing_cron';
DELETE FROM wp_options WHERE option_name LIKE '_transient_timeout_doing_cron';

-- 显示清理后的统计
SELECT COUNT(*) as total_options FROM wp_options;
SELECT option_name, LENGTH(option_value) as size FROM wp_options ORDER BY LENGTH(option_value) DESC LIMIT 10;
