/*
Cleaning Housing Data using SQL Queries
*/

--General query to check if everything is good in the table
SELECT *
  FROM PortfolioProject.dbo.NashvilleHousing;

--Standardizing (changing) date format by removing time from SaleDate column
--First step is to alter the table
ALTER TABLE NashvilleHousing
  ADD SaleDateFixed Date;

--Second step is to update the table
UPDATE NashvilleHousing
   SET SaleDateFixed = CONVERT(Date, SaleDate);

--Third step is to query the table to see if the column was successfully changed/standardized
SELECT SaleDateFixed, CONVERT(Date, SaleDate)
  FROM PortfolioProject.dbo.NashvilleHousing;


--Populating property address data. Note:ParcelID is linked to PropertyAddress, so Null PropertyAddress cells have the address somwhere else with the same ParcelID.
--First Step is to update the table to fill out all the PropertyAddress cells that are NULL
UPDATE a
   SET PropertyAddress = ISNUll(a.PropertyAddress, b.PropertyAddress)
  FROM PortfolioProject.dbo.NashvilleHousing a
  JOIN PortfolioProject.dbo.NashvilleHousing b
       ON a.ParcelID = b.ParcelID
	   AND a.[UniqueID ] <> b.[UniqueID ]
 WHERE a.PropertyAddress IS NULL;

--Second step is to query the table and see if all NULL cells are fixed
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNUll(a.PropertyAddress, b.PropertyAddress)
  FROM PortfolioProject.dbo.NashvilleHousing a
  JOIN PortfolioProject.dbo.NashvilleHousing b
       ON a.ParcelID = b.ParcelID
	   AND a.[UniqueID ] <> b.[UniqueID ]
 WHERE a.PropertyAddress IS NULL;


--Breaking out property address into individual columns (Address, City)
--First, I add two new columns in the table to host the Propery Address and City name separately
ALTER TABLE NashvilleHousing
  ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
   SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1); --the -1 means comme will be excluded from address

ALTER TABLE NashvilleHousing
  ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
   SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)); --the +1 means that comma before city name will be excluded

--Second, I query to see if the columns have been updated successfully
SELECT *
  FROM PortfolioProject.dbo.NashvilleHousing;


--Breaking out owner address into individual columns (Address, City, State)
--First, I add three new columns in the table to host the Owner Address, City, and State name separately 
ALTER TABLE NashvilleHousing
  ADD OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
   SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3);

ALTER TABLE NashvilleHousing
  ADD OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleHousing
   SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2);

ALTER TABLE NashvilleHousing
  ADD OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
   SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1);

--Second, I query to see if the columns have been updated successfully
SELECT *
  FROM PortfolioProject.dbo.NashvilleHousing;


--Changing Y and N to Yes and No in "Sold as Vacant" field
--First, I check how many Yes, No, Y, and N are there in the table
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
  FROM PortfolioProject.dbo.NashvilleHousing
 GROUP BY SoldAsVacant
 ORDER BY 2;

--Second, I update the table changing Y and N to full form and leaving complete Yes/No as it is. Then I doublecheck count to make sure the update went through.
UPDATE NashvilleHousing
   SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
  FROM PortfolioProject.dbo.NashvilleHousing;


--Removing duplicates. Standard practices is to never delete actual raw data but set up a temp table to remove duplicates. However, I will delete duplicates from the original raw data in this example.
--Creating a table where row_num shows 1 or 2, 2 is for a duplicate record
WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
  FROM PortfolioProject.dbo.NashvilleHousing
)
--Delete duplicates from the table
DELETE 
  FROM RowNumCTE
 WHERE row_num > 1;

--Query to see if the deletion worked. Run it with the CTE query above, table should show up empty.
SELECT * 
  FROM RowNumCTE
 WHERE row_num > 1
 ORDER BY PropertyAddress;


--Deleting unused columns
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;
