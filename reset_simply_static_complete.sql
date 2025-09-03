-- 彻底重置Simply Static状态
-- 清除所有任务状态和配置

-- 1. 重置Simply Static配置为默认状态
UPDATE wp_options SET option_value = 'a:3:{s:7:"_locale";s:4:"user";s:14:"encryption_key";s:32:"403a8c07bf4733dfeaec309f929dadf5";s:7:"version";s:7:"3.4.4.1";}' WHERE option_name = 'simply-static';

-- 2. 删除所有Simply Static相关的临时数据
DELETE FROM wp_options WHERE option_name LIKE '%simply_static%' AND option_name != 'simply-static';

-- 3. 清理任何可能的任务队列
DELETE FROM wp_options WHERE option_name LIKE '%ss_%';
DELETE FROM wp_options WHERE option_name LIKE '%simply_static_%';
