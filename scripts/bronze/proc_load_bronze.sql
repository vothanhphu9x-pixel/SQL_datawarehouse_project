/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/


create or alter procedure bronze.load_bronze as
begin
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	begin try
        set @batch_start_time = GETDATE();
		print '=================================';
		print 'loading bronze layer';
		print '=================================';
		
		print 'loading crm table';
		print '=================================';
		
        set @start_time = GETDATE()
		print 'insert data into: crm_cust_info';
		
		truncate table bronze.crm_cust_info;
		BULK INSERT bronze.crm_cust_info
		FROM '/data/source_crm/cust_info.csv'
		WITH (
		    FIRSTROW = 2,
		    FIELDTERMINATOR = ',',
		    TABLOCK
		);
        set @end_time = GETDATE()
        print '>> load duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR)

		set @start_time = GETDATE()
		print 'insert data into: crm_prd_info';
		truncate table bronze.crm_prd_info;
		BULK INSERT bronze.crm_prd_info
		FROM '/data/source_crm/prd_info.csv'
		WITH (
		    FIRSTROW = 2,
		    FIELDTERMINATOR = ',',
		    TABLOCK
		);
        set @end_time = GETDATE()
        print '>> load duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR)
		

		set @start_time = GETDATE()       
		print 'insert data into: crm_sales_details';
		truncate table bronze.crm_sales_details;
		BULK INSERT bronze.crm_sales_details
		FROM '/data/source_crm/sales_details.csv'
		WITH (
		    FIRSTROW = 2,
		    FIELDTERMINATOR = ',',
		    TABLOCK
		);
        set @end_time = GETDATE()
        print '>> load duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR)

		
		print '=================================';
		print 'loading erp table';
		print '=================================';
		
        set @start_time = GETDATE() 
		print 'insert data into: erp_loc_a101';
		truncate table bronze.erp_loc_a101;
		BULK INSERT bronze.erp_loc_a101
		FROM '/data/source_erp/loc_a101.csv'
		WITH (
		    FIRSTROW = 2,
		    FIELDTERMINATOR = ',',
		    TABLOCK
		);
        set @end_time = GETDATE()
        print '>> load duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR)

		
        set @start_time = GETDATE() 
		print 'insert data into: erp_cust_az12';
		truncate table bronze.erp_cust_az12;
		BULK INSERT bronze.erp_cust_az12
		FROM '/data/source_erp/cust_az12.csv'
		WITH (
		    FIRSTROW = 2,
		    FIELDTERMINATOR = ',',
		    TABLOCK
		);
        set @end_time = GETDATE()
        print '>> load duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR)


        set @start_time = GETDATE()		
		print 'insert data into: erp_px_cat_g1v2';
		truncate table bronze.erp_px_cat_g1v2;
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM '/data/source_erp/px_cat_g1v2.csv'
		WITH (
		    FIRSTROW = 2,
		    FIELDTERMINATOR = ',',
		    TABLOCK
		);
        set @end_time = GETDATE()
        print '>> load duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR)

        set @batch_end_time = GETDATE();
        print '>> total load duration:' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR)
	end try

	begin catch
		print 'error occured during loading bronze layer';
		print 'error message' + error_message();
        print 'error message' + CAST(error_number() as NVARCHAR);
        print 'error message' + CAST(error_state() as NVARCHAR);
	end catch

end;
