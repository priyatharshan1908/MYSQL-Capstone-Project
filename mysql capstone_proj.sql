select *  from customer_churn;

### DATA CLEANING  -------------------------------------------------------------------------------------------------------------------------------

-- calculate rounded mean values using user-defined variables

SET @WarehouseToHome_avg = (SELECT round(AVG(WarehouseToHome)) FROM customer_churn);
SELECT @WarehouseToHome_avg;
 
set @HourSpendOnApp_avg = (select round(avg(HourSpendOnApp)) from customer_churn);
select @HourSpendOnApp_avg;

set @OrderAmountHikeFromlastYear_avg = (select round(avg(OrderAmountHikeFromlastYear)) from customer_churn); 
select @OrderAmountHikeFromlastYear_avg;

set @DaySinceLastOrder_avg = (select round(avg(DaySinceLastOrder)) from customer_churn);
select @DaySinceLastOrder_avg;

-- disable safe updates

set sql_safe_updates = 0;

-- impute_values of mean values

update customer_churn
set WarehouseToHome = @WarehouseToHome_avg
where WarehouseToHome is null;
select WarehouseToHome from customer_churn;

update customer_churn
set HourSpendOnApp = @HourSpendOnApp_avg 
where HourSpendOnApp is null;
select HourSpendOnApp from customer_churn;

update customer_churn
set OrderAmountHikeFromlastYear = @OrderAmountHikeFromlastYear_avg
where OrderAmountHikeFromlastYear is null;
select OrderAmountHikeFromlastYear from customer_churn;

update customer_churn
set DaySinceLastOrder = @DaySinceLastOrder_avg
where DaySinceLastOrder is null;
select DaySinceLastOrder from customer_churn;


-- mode method Tenure,CouponUsed,OrderCount

set @Tenure_mode =(select Tenure from customer_churn group by Tenure order by count(*)desc limit 1);

update customer_churn
set Tenure = @Tenure_mode
where Tenure  is null;
select Tenure from customer_churn;

set @CouponUsed_mode =(select CouponUsed from customer_churn group by CouponUsed order by count(*)desc limit 1);

update customer_churn
set CouponUsed = @CouponUsed_mode
where CouponUsed  is null;
select CouponUsed from customer_churn;

set @OrderCount_mode =(select OrderCount from customer_churn group by OrderCount order by count(*)desc limit 1);

update customer_churn
set OrderCount = @CouponUsed_mode
where OrderCount  is null;
select OrderCount from customer_churn;

-- outliers

delete from customer_churn
where  WarehouseToHome >100;

update customer_churn
set PreferredLoginDevice = if(PreferredLoginDevice = 'Phone','Mobile Phone',PreferredLoginDevice);
select PreferredLoginDevice from customer_churn;

update customer_churn
set PreferedOrderCat = if(PreferedOrderCat ='Mobile','Mobile Phone',PreferedOrderCat);
select PreferedOrderCat from customer_churn;

-- standartise
update customer_churn
set PreferredPaymentMode = case
when PreferredPaymentMode = 'COD' then 'Cash on Delivery'
when PreferredPaymentMode = 'CC' then 'Credit Card'
else PreferredPaymentMode
end;

### DATA TRANSFORMATION ----------------------------------------------------------------------------------------------------------------------------

-- coloumn renaming

ALTER TABLE customer_churn
RENAME COLUMN PreferedOrderCat TO PreferredOrderCat,
RENAME COLUMN HourSpendOnApp TO HoursSpendOnApp;

-- creating new coloumns 

ALTER TABLE  customer_churn
ADD COLUMN Complaintreceived enum ("yes","no"),
ADD COLUMN Churnstatus enum ("churned","active");

set sql_safe_updates =0;

UPDATE customer_churn
SET ComplaintReceived = CASE 
    WHEN Complain = 1 THEN 'Yes'
    ELSE 'No'
END;

UPDATE customer_churn
SET ChurnStatus = CASE 
    WHEN Churn = 1 THEN 'Churned'
    ELSE 'Active'
END;

select * from customer_churn;

-- column droping--
 
ALTER TABLE customer_churn
DROP column complain,
DROP column churn;


### DATA EXPLORATION & analysis ----------------------------------------------------------------------------------------------------------------

 -- 1 
select Churnstatus,count(*) as Churnstatus_acti_inact_count from customer_churn 
group by Churnstatus;

-- 2 
select floor(avg (tenure)),Churnstatus  from customer_churn where Churnstatus = "churned";

-- 3 
select sum(cashbackamount),churnstatus from customer_churn
where Churnstatus = "churned"
group by churnstatus;

-- 4 
select Complaintreceived,concat(round(count(*) * 100 /
(select count(*) from customer_churn where Churnstatus = "churned"),2),'%') as complaint_perc
from customer_churn
where Complaintreceived = 'yes' and churnstatus = "churned"
group by Complaintreceived;

-- 5 
select gender,count(Complaintreceived) from customer_churn 
where Complaintreceived = 'yes'
group by gender;

-- 6
select CityTier,count(*) as churned_cust from customer_churn where PreferredOrderCat = "Laptop & Accessory" and Churnstatus = "churned"
group by citytier
order by churned_cust desc
limit 1;

-- 7
select PreferredPaymentMode,count(*) as usage_count from customer_churn 
where churnstatus = "active"
group by PreferredPaymentMode 
order by usage_count desc
limit 1;


-- 8
select PreferredLoginDevice,count(*) as Device_count from customer_churn
where DaySinceLastOrder  >10
group by PreferredLoginDevice
order by Device_count desc
limit 2;

-- 9
select count(churnstatus) active_cust from customer_churn
where churnstatus = 'active' and HoursSpendOnApp > 3;

-- 10
select round(avg(CashbackAmount)) from customer_churn
where HoursSpendOnApp >=2;

-- 11
select PreferredOrderCat, max(HoursSpendOnApp) maxi_hours_on_cate from customer_churn
group by PreferredOrderCat
order by maxi_hours_on_cate desc;

-- 12
select avg(OrderAmountHikeFromlastYear),MaritalStatus from customer_churn
group by MaritalStatus;

-- 13
select MaritalStatus,PreferredOrderCat,sum(OrderAmountHikeFromlastYear) tot_ord from customer_churn
where MaritalStatus = 'single' and PreferredOrderCat = 'mobile phone';

-- 14
select round(avg(NumberOfDeviceRegistered)),PreferredPaymentMode from customer_churn
where PreferredPaymentMode = 'upi'; 

-- 15
select CityTier,count(CustomerID) as count_of_cus from customer_churn
group by CityTier
order by count_of_cus desc
limit 1;

-- 16
select MaritalStatus,max(NumberOfAddress) mari_sts_of_adr from customer_churn
group by MaritalStatus;

-- 17
select gender,max(couponused) from customer_churn
group by gender;

-- 18
select PreferredOrderCat,avg(SatisfactionScore) cat_satis_scr from customer_churn
group by PreferredOrderCat
order by cat_satis_scr desc;

-- 19
select count(ordercount),max(SatisfactionScore) from customer_churn
where PreferredPaymentMode = 'upi' 
group by PreferredPaymentMode;

-- 20
select sum(CustomerID) from customer_churn
where HoursSpendOnApp = 1 and DaySinceLastOrder >5;

-- 21
select avg(SatisfactionScore),Complaintreceived from customer_churn
where Complaintreceived = 'yes';

-- 22
select count(CustomerID) tot_cust,PreferredOrderCat from customer_churn
group by PreferredOrderCat;

-- 23
select avg(CashbackAmount),MaritalStatus from customer_churn
group by MaritalStatus;

-- 24
select avg(NumberOfDeviceRegistered) avg_device from customer_churn
where PreferredLoginDevice != 'mobile_phone';

-- 25
select PreferredOrderCat,count(*) as frequ from customer_churn
where CouponUsed >5
group by PreferredOrderCat 
order by frequ desc
limit 1; 

-- 26
select PreferredOrderCat,concat('5',round(avg(cashbackamount),2)) high_avg_cshbck_amt from customer_churn 
group by PreferredOrderCat
order by high_avg_cshbck_amt 
desc limit 3;

 -- 27
select PreferredPaymentMode, count(*) as freq_ord  from customer_churn
where tenure = 10 and ordercount > 500
group by PreferredPaymentMode;

-- 28
select
case 
when WarehouseToHome <=5 then 'very close distance'
when WarehouseToHome <=10 then 'close distance'
when WarehouseToHome <=15 then 'moderate distance'
else 'far distance'
end as distance_cat, churnstatus,count(*) from customer_churn
group by distance_cat, churnstatus;

-- 29
set @ordercountofcustomer = (select avg(ordercount) from customer_churn);
select MaritalStatus,count(ordercount) from customer_churn
where MaritalStatus = 'married' and citytier =1 and ordercount > @ordercountofcustomer;

-- 30
create table ecomm.customer_returns(
Return_id int primary key,
Customer_id int,
Return_date date,
Refund_amnt int
);
-- Insert the given data
Insert into ecomm.customer_returns (Return_id,Customer_id,Return_date,Refund_amnt) 
VALUES
(1001, 50022, '2023-01-01', 2130),
(1002, 50316, '2023-01-23', 2000),
(1003, 51099, '2023-02-14', 2290),
(1004, 52321, '2023-03-08', 2510),
(1005, 52928, '2023-03-20', 3000),
(1006, 53749, '2023-04-17', 1740),
(1007, 54206, '2023-04-21', 3250),
(1008, 54838, '2023-04-30', 1990);

SELECT cr.Return_id,cr.Customer_id,cr.Return_date,cr.Refund_amnt,cc.Tenure, 
cc.PreferredLoginDevice,cc.CityTier,cc.WarehouseToHome,cc.PreferredPaymentMode,
cc.Gender,cc.HourSpendOnApp,cc.NumberOfDeviceRegistered,cc.PreferedOrderCat,
cc.SatisfactionScore,cc.MaritalStatus,cc.NumberOfAddress,cc.OrderAmountHikeFromlastYear,
cc.CouponUsed,cc.OrderCount,cc.DaySinceLastOrder,cc.CashbackAmount 
from ecomm.customer_returns cr
join customer_churn cc 
on cr.Customer_ID = cc.CustomerID
where cc.Churn = 1 AND cc.Complain = 1;
