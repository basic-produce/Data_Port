--This attempt to clean data for more usable purpose 
--Data source:	https://www.kaggle.com/tmthyjames/nashville-housing-data

USE [Porfolio project]
GO

SELECT * FROM
dbo.NashvilesHousing

--Standardize SaleDate (Date Format)
SELECT SaleDate , CONVERT(date,SaleDate) New_date
FROM dbo.NashvilesHousing

ALTER TABLE NashvilesHousing
ALTER COLUMN SaleDate date;

--Populate PropertyAddress
select *,PropertyAddress
from dbo.NashvilesHousing
where PropertyAddress is NULL

SELECT NasA.UniqueID, NasA.ParcelID, NasA.LandUse,NasA.PropertyAddress,NasB.UniqueID, NasB.ParcelID, NasB.LandUse, NasB.PropertyAddress
FROM dbo.NashvilesHousing NasA
JOIN dbo.NashvilesHousing NasB
	on NasA.ParcelID=NasB.ParcelID
	and NasA.[UniqueID ]<>NasB.[UniqueID ]
WHERE NasA.PropertyAddress IS NULL
----- testing(
select ParcelID, LandUse, PropertyAddress from NashvilesHousing
where PropertyAddress like  '410  ROSEHILL CT, GOODLETTSVILLE'

select ParcelID, LandUse, PropertyAddress from NashvilesHousing
where PropertyAddress is not null
-----)
update NasA
set PropertyAddress = ISNULL(NasA.PropertyAddress,NasB.PropertyAddress)
FROM dbo.NashvilesHousing NasA
JOIN dbo.NashvilesHousing NasB
	on NasA.ParcelID=NasB.ParcelID
	and NasA.[UniqueID ]<>NasB.[UniqueID ]
WHERE NasA.PropertyAddress IS NULL

--Breaking out address into Individual Columns (Adress, City)
SELECT PropertyAddress FROM dbo.NashvilesHousing

create VIEW SplitAdress
AS (
select substring(PropertyAddress,1, CHARINDEX(',', PropertyAddress)-1) AS Street,
substring (PropertyAddress,CHARINDEX(',', PropertyAddress)+1,len(PropertyAddress)) AS City
from dbo.NashvilesHousing
)
SELECT * FROM SplitAdress
DROP VIEW IF EXISTS SplitAdress

-----testing(
select PropertyAddress from dbo.NashvilesHousing
select substring(PropertyAddress,CHARINDEX(' ', PropertyAddress)+1, CHARINDEX(',', PropertyAddress))
from dbo.NashvilesHousing

select CHARINDEX(',', PropertyAddress)
from dbo.NashvilesHousing
-----)
alter table dbo.NashvilesHousing 
add Street nvarchar(225)

alter table dbo.NashvilesHousing 
add City nvarchar(225)

update dbo.NashvilesHousing
set Street = substring(PropertyAddress,1, CHARINDEX(',', PropertyAddress)-1)
update dbo.NashvilesHousing
set City = substring (PropertyAddress,CHARINDEX(',', PropertyAddress)+1,len(PropertyAddress))

select * from dbo.NashvilesHousing

--Breaking out Owneraddress into Individual Columns (Adress, City, State)
select OwnerAddress from dbo.NashvilesHousing

select PARSENAME(Replace(OwnerAddress,',','.'),3), 
PARSENAME(Replace(OwnerAddress,',','.'),2),
PARSENAME(Replace(OwnerAddress,',','.'),1)
from dbo.NashvilesHousing

alter table dbo.NashvilesHousing 
add OwnerStreet nvarchar(225)

alter table dbo.NashvilesHousing 
add OwnerCity nvarchar(225)

alter table dbo.NashvilesHousing 
add OwnerState nvarchar(225)


update dbo.NashvilesHousing
set OwnerStreet = PARSENAME(Replace(OwnerAddress,',','.'),3)
update dbo.NashvilesHousing
set OwnerCity = PARSENAME(Replace(OwnerAddress,',','.'),2)
update dbo.NashvilesHousing
set OwnerState = PARSENAME(Replace(OwnerAddress,',','.'),1)

--Change Y and N to Yes and No in 'SoldAsVacant'
-----testing(
select distinct(SoldAsVacant), count(SoldAsVacant) as counting
from dbo.NashvilesHousing
group by SoldAsVacant
order by 2
-----)
select SoldAsVacant, 
	case when SoldAsVacant='Yeses' then 'Yes'
		 when SoldAsVacant='Noo' then 'No'
		 else SoldAsVacant
		 end
from dbo.NashvilesHousing
a
update dbo.NashvilesHousing
set SoldAsVacant = case when SoldAsVacant='Yeses' then 'Yes'
		 when SoldAsVacant='Noo' then 'No'
		 else SoldAsVacant
		 end
select SoldAsVacant from dbo.NashvilesHousing

--Remove duplicate 
SELECT * FROM NashvilesHousing
---create tempt table
WITH RowNumDupplicate as (
select *, --UniqueID, ParcelID, PropertyAddress, OwnerName, OwnerAddress
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress
				order by ParcelID
				) row_num
from NashvilesHousing
---order by ParcelID
)
---Doublecheck
select * from RowNumDupplicate
where row_num >1
Order by PropertyAddress
---Delete
delete 
from RowNumDupplicate
where row_num >1


