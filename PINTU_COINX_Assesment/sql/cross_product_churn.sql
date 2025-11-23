with all_activity as (
  select
    user_id
    ,trade_created_time activity_time
    ,'Trade' activity
  from datamart.fact_transactions_trades
  
  union all
  select
    sender_id user_id
    ,transfer_created_time activity_time
    ,'P2P Transfer' activity
  from datamart.fact_transactions_p2p_transfers

  union all
  select
    receiver_id user_id
    ,transfer_created_time activity_time
    ,'P2P Transfer' activity
  from datamart.fact_transactions_p2p_transfers
)

,ranked_all_activity as (
  select
    *
    ,row_number() over(partition by user_id order by activity_time asc) rnk
  from all_activity
)

,first_activity_per_user as (
  select
    user_id
    ,activity_time first_activity_time
    ,activity first_activity
  from ranked_all_activity
  where rnk = 1
)

,first_trade as (
  select
    user_id
    ,min(trade_created_time) first_trade_time
    ,max(trade_created_time) last_trade_time
  from datamart.fact_transactions_trades
  group by 1
)

select
  count (if(first_activity='P2P Transfer',fa.user_id,null)) count_first_p2p_transfer_user
  ,count (if(first_activity='P2P Transfer' and first_trade_time is not null,fa.user_id,null)) count_first_p2p_transfer_and_do_trade
  ,avg(date_diff(date(ft.first_trade_time), date(fa.first_activity_time), DAY)) average_time_to_convert_in_day
from first_activity_per_user fa
left join first_trade ft on fa.user_id = ft.user_id
where first_activity = 'P2P Transfer'