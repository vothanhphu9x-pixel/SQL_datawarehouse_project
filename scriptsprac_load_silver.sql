/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/


CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------';

		-- Loading silver.crm_cust_info
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT '>> Inserting Data Into: silver.crm_cust_info';
        insert into silver.crm_cust_info (
            cst_id , 
            cst_key ,
            cst_Firstname ,
            cst_lastname ,
            cst_material_status ,
            cst_gndr ,
            cst_create_date 
        )
        select 
            cst_id,
            cst_key,
            trim(cst_Firstname) as cst_Firstname,
            trim(cst_lastname) as cst_lastname,
            case
                when upper(cst_material_status) = 'M' then 'Married'
                when upper(cst_material_status) = 'S' then 'Single'
                else 'n/a'
            end as cst_material_status,
            case
                when upper(cst_gndr) = 'M' then 'Male'
                when upper(cst_gndr) = 'F' then 'Female'
                else 'n/a'
            end as cst_gndr,
            cst_create_date
        from (
            select *,
                row_number() over(partition by cst_id order by cst_create_date desc) as r
            from bronze.crm_cust_info) t
        where r = 1 and cst_id is not null;
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		-- Loading silver.crm_prd_info
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT '>> Inserting Data Into: silver.crm_prd_info';
        insert into silver.crm_prd_info (
            prd_id ,
            cat_id ,
            prd_key ,
            prd_nm ,
            prd_cost  ,
            prd_line ,
            prd_start_dt ,
            prd_end_dt 
        )
        select 
            prd_id,
            replace(substring(prd_key,1,5), '-','_') as cat_id,
            substring(prd_key,7,len(prd_key)) as prd_key,
            prd_nm,
            isnull(prd_cost,0) as prd_cost,
            case upper(prd_line)
                when 'M' then 'Mountain'
                when 'R' then 'Road'
                when 'S' then 'Other Sales'
                when 'T' then 'Touring'
            else 'n/a'
            end as prd_line,
            cast(prd_start_dt as date) as prd_start_dt,
            cast(lead(prd_start_dt) over(partition by prd_key order by prd_start_dt) - 1 as date) as prd_end_dt
        from bronze.crm_prd_info;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- Loading crm_sales_details
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT '>> Inserting Data Into: silver.crm_sales_details';
        insert into silver.crm_sales_details (
            sls_ord_num ,
            sls_prd_key ,
            sls_cust_id ,
            sls_order_dt ,
            sls_ship_dt ,
            sls_due_dt_at , 
            sls_sales , 
            sls_quantity , 
            sls_price
        )
        select
            sls_ord_num,
            sls_prd_key ,
            sls_cust_id ,
            case
                when sls_order_dt = 0 or len(sls_order_dt) != 8 then null
                else cast(CAST(sls_order_dt as varchar) as date)
            end as sls_order_dt,
            case
                when sls_ship_dt = 0 or len(sls_ship_dt) != 8 then null
                else cast(CAST(sls_ship_dt as varchar) as date)
            end as sls_ship_dt,
            case
                when sls_due_dt_at = 0 or len(sls_due_dt_at) != 8 then null
                else cast(CAST(sls_due_dt_at as varchar) as date)
            end as sls_due_dt_at,
            case   
                when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * abs(sls_price)
                    then sls_quantity * abs(sls_price)
                else sls_sales
            end as sls_sales,
                sls_quantity,
            case    
                when sls_price is null or sls_price <= 0
                    then sls_sales / sls_quantity
                else sls_price
            end as sls_price
        from bronze.crm_sales_details
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- Loading erp_cust_az12
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12;
		PRINT '>> Inserting Data Into: silver.erp_cust_az12';
        insert into silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        select
            case
                when cid like 'NAS%' then substring(cid, 4, len(cid))
                else cid
            end as cid,
            case    
                when bdate > GETDATE() then null
                else bdate
            end as bdate,
            CASE 
                WHEN UPPER(trim(REPLACE(REPLACE(TRIM(gen), CHAR(13), ''), CHAR(10), ''))) IN ('M', 'MALE') THEN 'Male'
                WHEN UPPER(trim(REPLACE(REPLACE(TRIM(gen), CHAR(13), ''), CHAR(10), ''))) IN ('F', 'FEMALE') THEN 'Female'
                ELSE 'n/a'
            END AS gen
        from bronze.erp_cust_az12
	    SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		PRINT '------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------';

        -- Loading erp_loc_a101
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT '>> Inserting Data Into: silver.erp_loc_a101';
        insert into silver.erp_loc_a101 (
            cid, 
            cntry
        )
        select
            replace(cid,'-','') as cid,
            case 
                when REPLACE(REPLACE(TRIM(cntry), CHAR(13), ''), CHAR(10), '') = 'DE' THEN 'Germany'
                when REPLACE(REPLACE(TRIM(cntry), CHAR(13), ''), CHAR(10), '') in ('US', 'USA') then 'United States'
                when REPLACE(REPLACE(TRIM(cntry), CHAR(13), ''), CHAR(10), '') = '' then 'n/a'
                else REPLACE(REPLACE(TRIM(cntry), CHAR(13), ''), CHAR(10), '')
            end as cntry
        from bronze.erp_loc_a101
	    SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
		
		-- Loading erp_px_cat_g1v2
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
        insert into silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance
        )
        select
            id,
            cat,
            subcat,
            REPLACE(REPLACE(TRIM(maintenance), CHAR(13), ''), CHAR(10), '') as maintenance
        from bronze.erp_px_cat_g1v2
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		SET @batch_end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='
		
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END
