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
CREATE TABLE silver.crm_cust_info (
    cst_id           INT            ,
    cst_key          VARCHAR(50)    ,
    cst_firstname    VARCHAR(100)   ,
    cst_lastname     VARCHAR(100)   ,
    cst_marital_status VARCHAR(20)  ,
    cst_gndr         VARCHAR(10)    ,
    cst_create_date  DATETIME       ,
);
v
CREATE TABLE silver.crm_prd_info (
    prd_id       INT            ,
    prd_key      VARCHAR(50)    ,
    prd_name     VARCHAR(200)   ,
    prd_price    DECIMAL(18,2)  ,
    prd_category VARCHAR(100)   ,
);
CREATE TABLE silver.crm_sales_detail (
    sls_ord_num   INT             ,
    sls_prd_key   VARCHAR(50)     ,
    sls_cust_id   INT             ,
    sls_order_dt  DATE            ,
    sls_ship_dt   DATE            ,
    sls_due_dt    DATE            ,
    sls_sales     DECIMAL(18,2)   ,
    sls_quantity  INT             ,
    sls_price     DECIMAL(18,2)   ,
);
CREATE TABLE silver.erp_cust_az12 (
    cid       VARCHAR(50) ,
    bdate    datetime     ,
    gen   VARCHAR(50)     ,
 
);
CREATE TABLE silver.erp_loc_A101 (
    cid     VARCHAR(50)    ,
    cntry    VARCHAR(200)  ,
 
);
CREATE TABLE silver.erp_PX_CAT_G1V2 (
    id           INT            ,
    cat          VARCHAR(100)   ,
    subcat       VARCHAR(100)   ,
    maintenance  VARCHAR(100)   ,

);
