-- 重置Simply Static状态
UPDATE wp_options SET option_value = REPLACE(option_value, 's:18:"archive_start_time";s:19:"2025-09-03 05:57:05";', 's:18:"archive_start_time";N;') WHERE option_name = 'simply-static';
