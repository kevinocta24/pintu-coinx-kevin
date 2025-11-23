create or replace table datamart.dim_date as
select
  date_field AS date_key,
from
  unnest(generate_date_array('2024-01-01', '2024-06-26', interval 1 day)) AS date_field
order by
  date_key;