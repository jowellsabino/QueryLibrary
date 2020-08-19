/* Tasks Purge Fallback Rules*/
select *
from tl_purge_criteria
where tl_purge_description = 'GENERIC*'
go
 