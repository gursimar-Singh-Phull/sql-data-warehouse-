/*
=====================================================================================
DDL Script: Create silver Tables
=====================================================================================
Script Purpose:
This script creates tables in the 'silver' schema, dropping existing tables
if Ehey already exist.
read this script to re-define the DDL structure of 'silver' Tables
=====================================================================================
*/
create or alter procedure silver.load_silver  as
begin
    /* =========================================================
       1.  CRM Customer Info
       ========================================================= */
    TRUNCATE TABLE silver.crm_cust_info;
    PRINT '>> Inserting Data Into silver.crm_cust_info';

    INSERT INTO silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        [cst_material_status],
        cst_gndr,
        cst_create_date
    )
    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname),
        TRIM(cst_lastname),
        CASE
            WHEN UPPER(TRIM([cst_material_status])) = 'S' THEN 'Single'
            WHEN UPPER(TRIM([cst_material_status])) = 'M' THEN 'Married'
            ELSE 'n/a'
        END,
        CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
            ELSE 'n/a'
        END,
        cst_create_date
    FROM bronzee.crm_cust_info;

    /* =========================================================
       2.  CRM Product Info
       ========================================================= */
    TRUNCATE TABLE silver.crm_prd_info;
    PRINT '>> Inserting Data Into silver.crm_prd_info';

        INSERT INTO [silver].[crm_prd_info]
        (
            [prd_id],
            [cat_id],
            prd_key,
            [prd_nm],
            [prd_cost],
            [prd_line],
            [prd_start_dt],
            [prd_end_dt]
        )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
            SUBSTRING(prd_key, 7, LEN(prd_key))        AS prd_key,
            prd_nm,
            ISNULL(prd_cost, 0)                         AS prd_cost,
            CASE 
                 WHEN UPPER(LTRIM(RTRIM(prd_line))) = 'M' THEN 'Mountain'
                 WHEN UPPER(LTRIM(RTRIM(prd_line))) = 'R' THEN 'Road'
                 WHEN UPPER(LTRIM(RTRIM(prd_line))) = 'S' THEN 'Other Sales'
                 WHEN UPPER(LTRIM(RTRIM(prd_line))) = 'T' THEN 'Touring'
                 ELSE 'Unknown'
            END                                         AS prd_line,
            CAST(prd_start_dt AS date)                  AS prd_start_dt,
            DATEADD(
                DAY,
                -1,
                LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)
            )                                           AS prd_end_dt
        FROM bronzee.crm_prd_info;

 

    /* =========================================================
       3.  CRM Sales Detail
       ========================================================= */
    TRUNCATE TABLE silver.crm_sales_detail;
    PRINT '>> Inserting Data Into silver.crm_sales_detail';

    insert into silver.crm_sales_detail( 
    sls_ord_num,sls_prd_key,sls_cust_id,sls_order_dt,sls_ship_dt,sls_due_dt,sls_sales,sls_quantity,sls_price) 
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,

        -- Keep valid date or NULL
        CASE
            WHEN sls_order_dt IS NULL THEN NULL
            ELSE CONVERT(date, sls_order_dt)
        END AS sls_order_dt,

        CASE
            WHEN sls_ship_dt IS NULL THEN NULL
            ELSE CONVERT(date, sls_ship_dt)
        END AS sls_ship_dt,

        CASE
            WHEN sls_due_dt IS NULL THEN NULL
            ELSE CONVERT(date, sls_due_dt)
        END AS sls_due_dt,

        -- Always return a number (0 if bad or NULL)
        ISNULL(
            CASE
                WHEN sls_sales <= 0
                     OR sls_quantity IS NULL
                     OR sls_price IS NULL
                     OR ABS(sls_sales) <> ABS(sls_quantity) * ABS(sls_price)
                THEN ABS(ISNULL(sls_quantity,0)) * ABS(ISNULL(sls_price,0))
                ELSE sls_sales
            END,
            0
        ) AS sls_sales,

        -- Replace NULL or <=0 quantity with 0
        ISNULL(
            CASE
                WHEN sls_quantity <= 0 THEN 0
                ELSE sls_quantity
            END,
            0
        ) AS sls_quantity,

        -- Replace NULL or <=0 price with 0
        ISNULL(
            CASE
                WHEN sls_price <= 0 THEN 0
                ELSE sls_price
            END,
            0
        ) AS sls_price
    FROM bronzee.crm_sales_detail

    /* =========================================================
       4.  ERP Customer AZ12
       ========================================================= */
    TRUNCATE TABLE silver.erp_cust_az12;
    PRINT '>> Inserting Data Into silver.erp_cust_az12';

    INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
    SELECT  
        CASE 
            WHEN TRIM(UPPER(cid)) LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
            ELSE cid 
        END AS cid,
        CASE 
            WHEN bdate > GETDATE() THEN NULL
            ELSE bdate 
        END AS bdate,
        CASE 
            WHEN UPPER(LTRIM(RTRIM(gen))) IN ('F', 'FEMALE') THEN 'Female'
            WHEN UPPER(LTRIM(RTRIM(gen))) IN ('M', 'MALE')   THEN 'Male'
            ELSE 'n/a'
        END AS gen
    FROM bronzee.erp_cust_az12;


    /* =========================================================
       5.  ERP Location A101
       ========================================================= */
    TRUNCATE TABLE silver.erp_loc_A101;
    PRINT '>> Inserting Data Into silver.erp_loc_A101';

    insert into silver.erp_loc_A101(cid,cntry)
    select replace(cid,'-','')as cid,
    CASE WHEN TRIM(UPPER(cntry)) IN ('US','USA') THEN 'United States' 
    WHEN TRIM(UPPER(cntry)) = 'DE' THEN 'Germany' 
    WHEN cntry IS NULL OR TRIM(cntry) = '' THEN 'not available' 
    ELSE TRIM(cntry) END AS cntry 
    from bronzee.erp_loc_A101 where replace(cid,'-','') in (select cst_key from silver.crm_cust_info)


    /* =========================================================
       6.  ERP Product Category G1V2
       ========================================================= */
    TRUNCATE TABLE silver.erp_PX_CAT_G1V2;
    PRINT '>> Inserting Data Into silver.erp_PX_CAT_G1V2';

    INSERT INTO silver.erp_PX_CAT_G1V2 (
         id,
        [CAT],[SUBCAT],
        [MAINTENANCE]
    )
    SELECT
       id,
        TRIM([CAT]),TRIM([SUBCAT]),
        TRIM([MAINTENANCE])
    FROM bronzee.erp_PX_CAT_G1V2;
end
