create or replace table `datamart.dim_tokens` as 
select
  token_id
  ,token_name
  ,category
from  `raw_config.raw_tokens`
where token_id is not null