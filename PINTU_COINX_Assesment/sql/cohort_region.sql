with usercohort as  (
    select
        user_id
        ,region
        ,date_trunc(t1.signup_date, month) signup_month
    from `datamart.dim_users` t1
)

,user_cohort_month0 as (
    select
        region
        ,signup_month
        ,count(distinct user_id) total_user
    from usercohort
    group by 1,2
)
,monthly_activity AS (
    select
        t1.user_id,
        date_trunc(t1.trade_created_time, month) AS activity_month
    from `datamart.fact_transactions_trades` t1
    join `datamart.dim_date` t3 on date(t1.trade_created_time) = t3.date_key
    group by 1, 2
)

,raw_cohort as (
    select
        c.signup_month
        ,c.region
        ,date_diff(a.activity_month, c.signup_month, month) AS months_since_signup,
        count(distinct c.user_id) AS retained_users
    from usercohort c
    join monthly_activity a ON c.user_id = a.user_id
    where a.activity_month >= c.signup_month -- Hanya hitung retensi setelah signup
    group by 1, 2, 3
)

select
    c.*
    ,total_user total_cohort_users
    ,cast(retained_users as decimal) / cast(total_user as decimal) retention_rate
from raw_cohort c
left join user_cohort_month0 uc on c.signup_month = uc.signup_month and c.region = uc.region
order by 2, 1, 3;