WITH sellout as(
  SELECT 
    'sellout' label, 
    country, 
    sku, 
    channel, 
    sum(real_sale) so_fc_unit, 
    sum(revenue) so_fc_rev, 
    sum(gmv) so_fc_gmv, 
    month 
  FROM 
    forecast_sale_monthly_project 
  WHERE 
    channel NOT IN ('Local') 
    AND fc_type = 'demand' 
    AND sku is not NULL 
  GROUP BY 
    label, 
    country, 
    sku, 
    month, 
    channel
), 
fc_7 as (
  select 
    sku, 
    'base_case' as label, 
    country, 
    month_etd month, 
    'AVC DI' channel, 
    sum(revenue) revenue, 
    sum(qty) qty 
  FROM 
    temp_SCO_DI_US 
  GROUP BY 
    sku, 
    label, 
    country, 
    month, 
    channel 
  union all 
  select 
    sku, 
    'base_case' label, 
    country, 
    DATE_FORMAT(etd, '%Y-%m-01') month, 
    'AVC DI' channel, 
    sum(final_revenue) revenue, 
    sum(final_qty) qty 
  FROM 
    temp_SCO_DI_Inter 
  GROUP BY 
    sku, 
    label, 
    country, 
    month, 
    channel
), 
actual as(
  SELECT 
    'actual' label, 
    country, 
    sku, 
    channel, 
    DATE_FORMAT(ac.date, '%Y-%m-01') month, 
    sum(shipped_unit) real_sale, 
    sum(shipped_revenue) revenue 
  FROM 
    sell_in_historical_daily ac 
  WHERE 
    ac.channel NOT IN ('Local') 
    AND date >= curdate() - INTERVAL (
      dayofmonth(
        curdate()
      ) -1
    ) DAY - INTERVAL 18 MONTH 
    AND shipped_unit > 0 
  GROUP BY 
    label, 
    sku, 
    country, 
    month, 
    channel 
  UNION ALL 
  SELECT 
    'actual_fz' label, 
    country, 
    sku, 
    channel, 
    DATE_FORMAT(etd, '%Y-%m-01') month, 
    sum(qty) real_sale, 
    sum(revenue) revenue 
  FROM 
    Temp_PO_DI_frozen_fc_7 
  WHERE 
    month(etd) >= 7 
  GROUP BY 
    label, 
    sku, 
    country, 
    month, 
    channel 
  ORDER BY 
    month
), 
act_22 as(
  SELECT 
    'actual_22' label, 
    country, 
    sku, 
    channel, 
    DATE_FORMAT(date, '%2023-%m-01') month, 
    sum(shipped_unit) qty_22, 
    sum(shipped_revenue) rev_22 
  FROM 
    sell_in_historical_daily 
  WHERE 
    channel NOT IN ('Local') 
    AND shipped_unit > 0 
    AND year(date) = 2022 
  GROUP BY 
    label, 
    sku, 
    country, 
    month, 
    channel 
  ORDER BY 
    month
), 
label_type AS (
  WITH ship AS (
    SELECT 
      log_date shipped_date, 
      sku, 
      country, 
      channel, 
      row_number() over (
        PARTITION BY sku 
        ORDER BY 
          log_date ASC
      ) rn 
    FROM 
      public_main.sale_performance_by_channel 
    WHERE 
      country = 'USA' 
      AND channel NOT IN ('Local', 'AVC GAP') 
      AND label_currency = 'USD' 
      AND log_date >= '2022-01-01'
  ) 
  SELECT 
    'base_case' as label, 
    ship.*, 
    CASE WHEN DATE_ADD(shipped_date, INTERVAL 6 MONTH) > CURDATE() THEN 'NPD' WHEN DATE_ADD(shipped_date, INTERVAL 6 MONTH) <= CURDATE() 
    AND DATE_ADD(shipped_date, INTERVAL 12 MONTH) >= CURDATE() THEN 'NPD' WHEN DATE_ADD(shipped_date, INTERVAL 12 MONTH) < CURDATE() THEN 'Existing' END as label_product_type 
  FROM 
    ship 
  WHERE 
    rn = 1 
  UNION ALL 
  SELECT 
    'best_case' as label, 
    ship.*, 
    CASE WHEN DATE_ADD(shipped_date, INTERVAL 6 MONTH) > CURDATE() THEN 'NPD' WHEN DATE_ADD(shipped_date, INTERVAL 6 MONTH) <= CURDATE() 
    AND DATE_ADD(shipped_date, INTERVAL 12 MONTH) >= CURDATE() THEN 'NPD' WHEN DATE_ADD(shipped_date, INTERVAL 12 MONTH) < CURDATE() THEN 'Existing' END as label_product_type 
  FROM 
    ship 
  WHERE 
    rn = 1
), 
list_sku AS (
  WITH sku AS (
    SELECT 
      sku, 
      label, 
      country, 
      month, 
      channel 
    FROM 
      forecast_cashflow 
    UNION ALL 
    SELECT 
      sku, 
      label, 
      country, 
      month, 
      channel 
    FROM 
      fc_7 
    GROUP BY 
      sku, 
      label, 
      country, 
      month, 
      channel 
    UNION ALL 
    SELECT 
      sku, 
      'actual' label, 
      country, 
      DATE_FORMAT(date, '%Y-%m-01') month, 
      channel 
    FROM 
      sell_in_historical_daily 
    WHERE 
      channel NOT IN ('Local') 
      AND date >= curdate() - INTERVAL (
        dayofmonth(
          curdate()
        ) -1
      ) DAY - INTERVAL 18 MONTH 
      AND shipped_unit > 0 
    GROUP BY 
      sku, 
      label, 
      country, 
      month, 
      channel 
    UNION ALL 
    SELECT 
      sku, 
      'actual_fz' label, 
      country, 
      DATE_FORMAT(etd, '%Y-%m-01') month, 
      channel 
    FROM 
      Temp_PO_DI_frozen_fc_7 
    where 
      month(etd) >= 7 
    GROUP BY 
      label, 
      sku, 
      country, 
      month, 
      channel 
    UNION ALL 
    SELECT 
      sku, 
      'sellout' label, 
      country, 
      month, 
      channel 
    FROM 
      forecast_sale_monthly_project 
    WHERE 
      channel NOT IN ('Local') 
      AND sku is not NULL 
    GROUP BY 
      label, 
      country, 
      sku, 
      month, 
      channel 
    UNION ALL 
    SELECT 
      sku, 
      'actual_22' label, 
      country, 
      DATE_FORMAT(date, '%2023-%m-01') month, 
      channel 
    FROM 
      sell_in_historical_daily 
    WHERE 
      channel NOT IN ('Local') 
      AND shipped_unit > 0 
      AND year(date) = 2022 
    GROUP BY 
      label, 
      sku, 
      country, 
      month, 
      channel 
    ORDER BY 
      month
  ) 
  SELECT 
    sku, 
    label, 
    country, 
    month, 
    channel 
  FROM 
    sku 
  GROUP BY 
    sku, 
    label, 
    country, 
    month, 
    channel ```
ORDER BY
  month
)

``` 
  SELECT 
    ls.*, 
    CASE WHEN ls.channel like 'AVC' THEN 'AVC' WHEN ls.channel like 'AVC DI%' THEN 'AVC DI' WHEN ls.channel like 'AVC WH%' THEN 'AVC WH' WHEN ls.channel like 'AVC DS%' THEN 'AVC DS' WHEN ls.channel = 'FBA' THEN 'ASC FBA' WHEN ls.channel = 'FBM' THEN 'ASC FBM' WHEN ls.channel like 'Wayfair' THEN 'WF DS' WHEN ls.channel like 'WF' THEN 'WF DS' ELSE ls.channel END AS channel_2, 
    cate.category, 
    COALESCE(
      cate.subcategory, gp.group_product
    ) subcategory, 
    CASE WHEN COALESCE(cate.sales_team, gp.sales_team) = 'Sales Sports & Outdoor' THEN 'Sporting Goods' WHEN COALESCE(cate.sales_team, gp.sales_team) = 'Sales Furniture & International' THEN 'Furniture' ELSE COALESCE(cate.sales_team, gp.sales_team) END AS sales_team_2, 
    CASE WHEN ls.channel like '%DI%' THEN 'DI' ELSE 'Non DI' END AS channel_3, 
    cate.sales_team, 
    cate.product_name, 
    cate.life_cycle, 
    lt.label_product_type, 
    CASE when LENGTH(ls.sku)> 4 THEN 'Idea Code' ELSE 'Normal SKU' END AS sku_type, 
    f11_22.real_sale qty_f11_22, 
    f11_22.revenue rev_f11_22, 
    f12_22.real_sale qty_f12_22, 
    f12_22.revenue rev_f12_22, 
    f1_23.real_sale qty_f1_23, 
    f1_23.revenue rev_f1_23, 
    f2_23.real_sale qty_f2_23, 
    f2_23.revenue rev_f2_23, 
    f3_23.real_sale qty_f3_23, 
    f3_23.revenue rev_f3_23, 
    f4_23.real_sale qty_f4_23, 
    f4_23.revenue rev_f4_23, 
    f5_23.real_sale qty_f5_23, 
    f5_23.revenue rev_f5_23, 
    f6_23.real_sale qty_f6_23, 
    f6_23.revenue rev_f6_23, 
    f7_23.qty qty_f7_23_DI, 
    f7_23.revenue rev_f7_23_DI, 
    a.real_sale qty_act, 
    a.revenue rev_act, 
    so.so_fc_unit, 
    so.so_fc_rev, 
    so.so_fc_gmv, 
    a22.qty_22, 
    a22.rev_22 
  FROM 
    list_sku ls 
    LEFT JOIN (
      SELECT 
        sku, 
        label, 
        country, 
        month, 
        channel, 
        real_sale, 
        revenue 
      FROM 
        forecast_cashflow 
      WHERE 
        log_date = '2022-11-01' 
        and month > '2022-11-01' 
      GROUP BY 
        sku, 
        label, 
        country, 
        month, 
        channel
    ) f11_22 USING (
      sku, label, country, month, channel
    ) 
    LEFT JOIN (
      SELECT 
        sku, 
        label, 
        country, 
        month, 
        channel, 
        real_sale, 
        revenue 
      FROM 
        forecast_cashflow 
      WHERE 
        log_date = '2022-12-01' 
        and month > '2022-12-01' 
      GROUP BY 
        sku, 
        label, 
        country, 
        month, 
        channel
    ) f12_22 USING (
      sku, label, country, month, channel
    ) 
    LEFT JOIN (
      SELECT 
        sku, 
        label, 
        country, 
        month, 
        channel, 
        real_sale, 
        revenue 
      FROM 
        forecast_cashflow 
      WHERE 
        log_date = '2023-01-01' 
        and month > '2023-01-01' 
      GROUP BY 
        sku, 
        label, 
        country, 
        month, 
        channel
    ) f1_23 USING (
      sku, label, country, month, channel
    ) 
    LEFT JOIN (
      SELECT 
        sku, 
        label, 
        country, 
        month, 
        channel, 
        real_sale, 
        revenue 
      FROM 
        forecast_cashflow 
      WHERE 
        log_date = '2023-02-01' 
        and month > '2023-02-01' 
      GROUP BY 
        sku, 
        label, 
        country, 
        month, 
        channel
    ) f2_23 USING (
      sku, label, country, month, channel
    ) 
    LEFT JOIN (
      SELECT 
        sku, 
        channel, 
        label, 
        country, 
        month, 
        real_sale, 
        revenue 
      FROM 
        forecast_cashflow 
      where 
        log_date = '2023-03-01' 
        and month > '2023-03-01' 
      GROUP BY 
        sku, 
        channel, 
        country, 
        month, 
        channel
    ) f3_23 USING (
      sku, label, country, month, channel
    ) 
    LEFT JOIN (
      SELECT 
        sku, 
        channel, 
        label, 
        country, 
        month, 
        real_sale, 
        revenue 
      FROM 
        forecast_cashflow 
      where 
        log_date = '2023-04-01' 
        and month(month) != 11 
      GROUP BY 
        sku, 
        label, 
        country, 
        month, 
        channel
    ) f4_23 USING (
      sku, label, country, month, channel
    ) 
    LEFT JOIN (
      SELECT 
        sku, 
        label, 
        country, 
        month, 
        channel, 
        real_sale, 
        revenue 
      FROM 
        forecast_cashflow 
      where 
        log_date = '2023-05-01' 
      GROUP BY 
        sku, 
        label, 
        country, 
        month, 
        channel
    ) f5_23 USING (
      sku, label, country, month, channel
    ) 
    LEFT JOIN (
      SELECT 
        sku, 
        label, 
        country, 
        month, 
        channel, 
        real_sale, 
        revenue 
      FROM 
        forecast_cashflow 
      WHERE 
        log_date = '2023-06-01' 
      GROUP BY 
        sku, 
        label, 
        country, 
        month, 
        channel
    ) f6_23 USING (
      sku, label, country, month, channel
    ) 
    LEFT JOIN fc_7 f7_23 USING (
      sku, label, country, month, channel
    ) 
    LEFT JOIN actual a USING (
      sku, label, country, month, channel
    ) 
    LEFT JOIN sellout so USING (
      sku, label, country, month, channel
    ) 
    LEFT JOIN act_22 a22 USING (
      sku, label, country, month, channel
    ) 
    LEFT JOIN (
      SELECT 
        sku 
      from 
        dim_product 
      group by 
        sku
    ) asi USING (sku) 
    LEFT JOIN (
      SELECT 
        sku, 
        group_product, 
        sales_team 
      from 
        forecast_sale_monthly_project 
      GROUP BY 
        sku, 
        group_product
    ) gp USING (sku) 
    LEFT JOIN (
      SELECT 
        sku, 
        product_name, 
        category, 
        subcategory, 
        root_category, 
        team, 
        life_cycle, 
        CASE WHEN root_category = 'Packaging' THEN root_category WHEN team = 'YDL' THEN 'Deployment Lab' WHEN team = 'HMD' THEN 'HMD' WHEN root_category = 'Furniture' THEN root_category WHEN team = 'YSL' 
        AND root_category = 'Sporting Goods' THEN 'Sporting Goods' ELSE root_category END AS sales_team 
      FROM 
        sc_main.dim_product dp
    ) cate USING (sku) 
    LEFT JOIN label_type lt USING (label, sku, country, channel) 
  GROUP BY 
    asi.sku, 
    ls.sku, 
    ls.label, 
    ls.country, 
    ls.month, 
    ls.channel 
  ORDER BY 
    month