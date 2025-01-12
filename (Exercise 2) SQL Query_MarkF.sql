--syntax: Snowflake SQL

--What are the top 5 brands by receipts scanned for most recent month?
select
    brandName,
    count(*) as receipt_count
from
    receiptItems
left join
    brands
        on brands.brand_uuid = receiptItems.rewardsProductPartnerId
left join
    receipts
        using(receipt_uuid)
where
    trunc(dateScanned, 'month') = trunc(current_date(), 'month')
group by
    1
order by
    receipt_count desc
limit 5

--How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?
with
    receipt_count as (
        select
            brandName,
            case
                when trunc(dateScanned, 'month') = trunc(current_date(), 'month')
                    then 'current'
                else 'previous'
            end as month_type,
            count(*) as receipt_count
        from
            receiptItems
        left join
            brands
                on brands.brand_uuid = receiptItems.rewardsProductPartnerId
        left join
            receipts
                using(receipt_uuid)
        where
            trunc(dateScanned, 'month') >= trunc((current_date() - interval '1 month'), 'month')
        group by
            1, 2
    ),

    ranked_brands as (
        select
            brandName,
            month_type,
            receipt_count,
            rank() over (partitition by month_type order by receipt_count desc) as rank
        from
            receipt_count
    )

    select
        r1.brandName,
        r1.receipt_count as current_receipt_count,
        r2.receipt_count as previous_receipt_count,
        r1.rank as current_month_rank,
        r2.rank as prvious_month_rank
    from
        ranked_brands r1
    left join
        ranked_brands r2
            using(brandName)
    where
        r1.month_type = 'current'
        and r2.month_type = 'previous'
        and r1.rank <= 5
    order by 
        r1.rank

--When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
select
    rewardsReceiptStatus,
    avg(nvl(totalSpent, 0)) as average_spend
from
    receipts
where
    rewardsReceiptStatus in ('Accepted', 'Rejected')
group by
    1

--When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
select
    rewardsReceiptStatus,
    sum(nvl(purchasedItemCount)) as total_items_purchased
from
    receipts
where
    rewardsReceiptStatus in ('Accepted', 'Rejected')
group by
    1

--Which brand has the most spend among users who were created within the past 6 months?
select
    brandName,
    sum(nvl(totalSpent, 0)) as total_spend
from
    receiptItems
left join
    brands
        on brands.brand_uuid = receiptItems.rewardsProductPartnerId
left join
    receipts
        using(receipt_uuid)
left join
    users
        using(userID)
where
    users.Active = True
    and users.createdDate > current_date() - interval '6 month'
group by
    1
order by
    sum(nvl(totalSpent, 0)) desc
limit 1

--Which brand has the most transactions among users who were created within the past 6 months?
select
    brandName,
    count(*) as receipt_count
from
    receiptItems
left join
    brands
        on brands.brand_uuid = receiptItems.rewardsProductPartnerId
left join
    receipts
        using(receipt_uuid)
left join
    users
        using(userID)
where
    users.Active = True
    and users.createdDate > current_date() - interval '6 month'
group by
    1
order by
    count(*) desc
limit 1
