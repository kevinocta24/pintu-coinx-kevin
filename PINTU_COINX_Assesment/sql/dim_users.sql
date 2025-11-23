create or replace table `datamart.dim_users` as 
select
  user_id
  ,region
  ,date(signup_date) signup_date
from  `raw_kyc.raw_users`
where user_id is not null