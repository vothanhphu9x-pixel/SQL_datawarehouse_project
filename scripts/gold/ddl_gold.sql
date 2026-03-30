/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;

create view gold.dim_customer as
select 
    row_number() over(order by cst_id) as customer_key,
    cst_id as customer_id,
    cst_key as customer_number,
    cst_Firstname as first_name,
    cst_lastname as last_name,
    cst_material_status as marital_status,
    case    
        when cst_gndr != 'n/a' then cst_gndr
        else coalesce(eca.gen, 'n/a')
    end as gender,                     -- CRM is the master for gender
    eca.bdate as brith_day,
    ela.cntry as country,
    cst_create_date as create_date
from silver.crm_cust_info cui 
left join silver.erp_cust_az12 eca
    on cui.cst_key = eca.cid
left join silver.erp_loc_a101 ela 
    on cui.cst_key = ela.cid;


-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;

create view gold.dim_product as
select 
    row_number() over(order by prd_start_dt, prd_key) as product_key,
    prd_id as product_id,
    prd_key as product_number,
    prd_nm as product_name,
    cat_id as category_id,
    epc.cat as category,
    epc.subcat as subcategory,
    epc.maintenance,
    prd_cost as cost,
    prd_line as line ,
    cast(prd_start_dt as date) as start_date
from silver.crm_prd_info cpi 
left join silver.erp_px_cat_g1v2 epc 
    on cpi.cat_id = epc.id
where cpi.prd_end_dt is null;


-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;

create view gold.fact_sales as
select 
    sls_ord_num as order_number,
    pr.product_key ,                -- change column
    cu.customer_key,                -- change column
    sls_order_dt as order_date,
    sls_ship_dt as shipping_date,
    sls_due_dt_at as due_date,
    sls_sales as sales_amount,
    sls_quantity as quantity,
    sls_price as price
from silver.crm_sales_details sd 
left join gold.dim_product pr 
    on  sd.sls_prd_key = pr.product_number
left join gold.dim_customer cu 
    on sd.sls_cust_id = cu.customer_id;
