/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/


-- check table crm_cust_info
-- check null & duplicated for PK
select 
    cst_id,
    count (*)
from silver.crm_cust_info
group by cst_id
having count(*) > 1 or cst_id is null

-- check for unwanted spaces
select *
from silver.crm_cust_info
where cst_Firstname != trim(cst_Firstname) or cst_lastname != trim(cst_lastname)


-- table crm_prd_info
select 
    prd_id,
    count (*)
from silver.crm_prd_info
group by prd_id
having count(*) > 1 or prd_id is null

-- check for unwanted spaces
select *
from silver.crm_prd_info
where prd_key != trim(prd_key) or prd_nm != trim(prd_nm) or prd_line != trim(prd_line)

-- check logic business
select *
from silver.crm_prd_info
where prd_cost < 0 or prd_cost is null

select distinct prd_line from silver.crm_prd_info

select *
from silver.crm_prd_info
where prd_end_dt < prd_start_dt



  
-- table crm_sales_info
-- check null & unwanted spaces
select *
from silver.crm_sales_details
where sls_ord_num is null or sls_ord_num != trim(sls_ord_num)

-- check for foreign key
select *
from silver.crm_sales_details
where sls_prd_key not in (select prd_key from silver.crm_prd_info)

select *
from silver.crm_sales_details
where sls_cust_id not in (select cst_id from silver.crm_cust_info)

-- check datatype
select 
    nullif(sls_order_dt,0) as sls_order_dt
from silver.crm_sales_details
where sls_order_dt <= 0 or len(sls_order_dt) != 8
    or sls_order_dt > 20500101
    or sls_order_dt < 19000101

select 
    nullif(sls_ship_dt,0) as sls_ship_dt
from silver.crm_sales_details
where sls_ship_dt <= 0 or len(sls_ship_dt) != 8
    or sls_ship_dt > 20500101
    or sls_ship_dt < 19000101

select 
    nullif(sls_due_dt_at,0) as sls_due_dt_at
from silver.crm_sales_details
where sls_due_dt_at <= 0 or len(sls_due_dt_at) != 8
    or sls_due_dt_at > 20500101
    or sls_due_dt_at < 19000101

-- check logic business
select *
from silver.crm_sales_details
where sls_order_dt > sls_ship_dt or sls_ship_dt > sls_due_dt_at

SELECT DISTINCT
    sls_sales, 
    sls_quantity, 
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales Is NULL OR sls_quantity IS NULL OR sls_price IS NULL 
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
order by sls_sales, sls_quantity, sls_price



-- table erp_cust_az12
--check foreign key
select *
from silver.erp_cust_az12
where cid not in (select cst_key from silver.crm_cust_info)

--check unwanted spaces
select gen,
    len(gen) as h
from silver.erp_cust_az12
group by gen


-- check logic business
select distinct
    bdate
from silver.erp_cust_az12
where bdate > GETDATE()



-- table erp_loc_a101
-- check mapping key
select *
from silver.erp_loc_a101
where cid not in (select cst_key from silver.crm_cust_info)

--check unwanted spaces
select distinct cntry
from silver.erp_loc_a101
group by cntry



-- table erp_px_cat_g1v2
-- check mapping key
select *
from silver.erp_px_cat_g1v2
where id not in (select cat_id from silver.crm_prd_info)

-- check unwanted spaces
select *
from silver.erp_px_cat_g1v2
where cat != trim(cat) or subcat != trim(subcat) or id != trim(id)

-- check logic
select distinct cat
from silver.erp_px_cat_g1v2

select distinct subcat
from silver.erp_px_cat_g1v2

select distinct maintenance
from silver.erp_px_cat_g1v2
