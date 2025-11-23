-- top 5 vs non top 5 daily trade volume

with top_5_user as ( -- Top  5 User based on Trading Volume
  select
    user_id
    ,sum(trade_value_usd) total_trade
  from `datamart.fact_transactions_trades`
  group by 1
  order by 2 desc
  limit 5
)

select
  date_trunc(date(trade_created_time),month) trade_date_month
  ,sum(
    case
    when t.user_id is not null then trade_value_usd
    else 0
  end ) total_trade_non_top_5
  ,sum(
    case
    when t.user_id is not null then 0
    else trade_value_usd
  end ) total_trade_non_top_5
from `datamart.fact_transactions_trades` f
left join top_5_user t on f.user_id = t.user_id
group by 1

order by 1