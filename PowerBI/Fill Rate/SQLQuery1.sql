select Material, Plant, Unrestricted, [Value Unrestricted] as Val_Unrestricted, [Transit and Transfer] as Trans, [Val# in Trans#/Tfr] as Val_Tras from dim_inventory
where [Storage Location] = '1100'

select [Order No] as Order_No, Item, [Order Date] as Order_date, [Order Method] as Order_method, [Customer Code] as Customer_code, Channel, Plant, [Product Code] as Material, [Order Qty] as Order_qty, Salesman, [Delivery Number] as Delivery_no 
from open_order

select [Sales document] as Sales_doc, [Sold-To Party] as Sold_to, Material, [Order Quantity (Item)] as Qty, Plant	 from sales_order


select * from shipment_track_22
