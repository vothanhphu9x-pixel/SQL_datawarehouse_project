/*
======================================
DDL Script: Create Bronze Tables
======================================
Script Purpose:|
  This script creates tables in the 'bronze' schema, dropping existing tables 
  if they already exist.
  Run this script to re-define the DDL structure of 'bronze' Tables
*/




IF OBJECT_ID ('bronze.crm_cust_info', 'U') is not null
	DROP TABLE bronze.crm_cust_info;
CREATE TABLE bronze.crm_cust_info (
	cst_id INT, 
	cst_key NVARCHAR (50),
	cst_Firstname NVARCHAR(50),
	cst_lastname NVARCHAR (50),
	cst_material_status NVARCHAR (50),
	cst_gndr NVARCHAR(50) ,
	cst_create_date date
);

IF OBJECT_ID ('bronze.crm_sales_details', 'U') is not null
	DROP TABLE bronze.crm_sales_details;
CREATE TABLE bronze.crm_sales_details ( 
	sls_ord_num NVARCHAR (50),
	sls_prd_key NVARCHAR (50),
	sls_cust_id INT,
	sls_order_dt INT,
	sls_ship_dt INT,
	sls_due_dt_at INT, 
	sls_sales INT, 
	sls_quantity INT, 
	sls_price INT
);

IF OBJECT_ID ('bronze.crm_prd_info', 'U') is not null
	DROP TABLE bronze.crm_prd_info;
CREATE TABLE bronze.crm_prd_info (
	prd_id INT,
	prd_key NVARCHAR(50),
	prd_nm NVARCHAR(50),
	prd_cost INT ,
	prd_line NVARCHAR (50),
	prd_start_dt DATETIME,
	prd_end_dt DATETIME
);

IF OBJECT_ID ('bronze.erp_loc_a101', 'U') is not null
	DROP TABLE bronze.erp_loc_a101;
CREATE TABLE bronze. erp_loc_a101 ( 
	cid NVARCHAR(50), 
	cntry NVARCHAR( 50)
);

IF OBJECT_ID ('bronze.erp_cust_az12', 'U') is not null
	DROP TABLE bronze.erp_cust_az12;
CREATE TABLE bronze. erp_cust_az12 ( 
	cid NVARCHAR (50),
	bdate DATE, 
	gen NVARCHAR ( 50)
);

IF OBJECT_ID ('bronze.erp_px_cat_g1v2', 'U') is not null
	DROP TABLE bronze.erp_px_cat_g1v2;
CREATE TABLE bronze.erp_px_cat_g1v2 (
	id NVARCHAR ( 50),
	cat NVARCHAR (50),
	subcat NVARCHAR ( 50),
	maintenance NVARCHAR ( 50)
);


-- load dataset into Bronze
create or alter procedure bronze.load_data as
begin
  DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	begin try
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
