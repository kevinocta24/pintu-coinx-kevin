with first_trade_category as (
    select
        user_id
        ,category first_token_category
        ,date(trade_created_time) first_trade_date
        ,row_number() over(partition by user_id order by trade_created_time) rn
    from `datamart.fact_transactions_trades` t
    left join `datamart.dim_tokens` dt ON t.token_id = dt.token_id
)

,user_cohort as (
    select
        user_id,
        first_token_category,
        date_trunc(first_trade_date, month)first_trade_month
    from first_trade_category
    where rn = 1 -- get the first trade
)

,user_cohort_month0 as (
    select
        first_token_category
        ,first_trade_month
        ,count(distinct user_id) total_user
    from user_cohort
    group by 1,2
)

,monthly_activity as (
    select
        user_id,
        date_trunc(date(trade_created_time), month) activity_month
    from `datamart.fact_transactions_trades` t1
    group by 1, 2
)

,raw_cohort as (
    select
        c.first_trade_month
        ,c.first_token_category
        ,date_diff(a.activity_month, c.first_trade_month, month) months_since_first_trade
        ,count(distinct c.user_id) as retained_users
    from user_cohort c
    join monthly_activity a on c.user_id = a.user_id
    where a.activity_month >= c.first_trade_month
    group by 1, 2, 3
)

select
    r.*
    ,u.total_user total_cohort_users
    ,cast(retained_users as decimal) / cast(total_user as decimal) retention_rate
from raw_cohort r
left join user_cohort_month0 u on r.first_trade_month = u.first_trade_month and r.first_token_category = u.first_token_category
-- ORDER BY 2, 1, 3;