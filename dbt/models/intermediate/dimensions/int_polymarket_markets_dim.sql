{{ config(materialized='table') }}

with raw_data as (
    select
        market_slug,
        market_title,
        market_url,
        -- Extraemos los elementos de texto del array anidado
        array(
            select element 
            from unnest(categories.list)
        ) as categories_array,
        data_extracted_at
    from {{ ref('stg_polymarket_markets') }}
),

latest_records as (
    select
        *,
        row_number() over (
            partition by market_slug 
            order by data_extracted_at desc
        ) as rn
    from raw_data
)

select
    market_slug,
    market_title,
    market_url,
    categories_array as categories,
    data_extracted_at
from latest_records
where rn = 1