ALTER PROCEDURE [Distribution].[Report_Sale]
    @FinancialYearId INT,
    @CustomerId INT = NULL,
    @ProductId INT = NULL,
    @OrgSupplierId INT = NULL,
    @SupplierId INT = NULL,
    @RegionId INT = NULL,
    @TagId INT = NULL,
    @MarketerId INT = NULL,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL,
    @FromNumber INT = NULL,
    @ToNumber INT = NULL,
    @GroupbyCustomer BIT = NULL,
    @GroupbyProduct BIT = NULL,
    @GroupbyOrgSupplier BIT = NULL,
    @GroupbySupplier BIT = NULL,
    @GroupbyRegion BIT = NULL,
    @GroupbyMarketer BIT = NULL,
    @GroupbyInvoiceNumber BIT = NULL,
    @GroupbyMonth BIT = NULL,
    @DrugId INT = NULL,
    @DrugFormId INT = NULL,
    @PartyAccountGroupId INT = NULL,
    @Page INT = 1,
    @PageSize INT = 10,
    @Asc BIT = 0,
    @Sort NVARCHAR(MAX) = '',
    @FromInputNumber VARCHAR(MAX) NULL = NULL,
    @GroupbyPartyAccount BIT = NULL
WITH RECOMPILE
AS
BEGIN

    IF (@PageSize IS NULL)
        SET @PageSize = [Core].[MaxInt] ();
    IF (@Page IS NULL)
        SET @Page = 1;

    SELECT [Item] = CAST([StringSplit].[Value] AS INT)
    INTO [#FromInputNumber]
    FROM [Core].[StringSplit] (@FromInputNumber, ',');

    DECLARE @RegionHID HIERARCHYID;
    SELECT @RegionHID = [Regions].[HId]
    FROM [InventoryBasics].[Regions]
    WHERE [Regions].[Id] = @RegionId;

    WITH [Records]
    AS (SELECT [Invoices].[Number],
               [Invoices].[Date],
               [Invoices].[CustomerId],
               [Invoices].[MarketerId],
               [PartyAccounts].[RegionId],
               [InvoiceDetails].[ProductId],
               [InvoiceDetails].[Id] [DetailId],
               [InputSheetDetails].[OrgSupplier],
               [InputSheetDetails].[BatchNumber],
               [InputSheetDetails].[ExpireDate],
               CASE
                   WHEN [InvoiceDetails].[RelatedInvoiceDetaileId] IS NULL THEN
                        CAST([SheetDetailRelations].[Quantity] AS BIGINT)
                   ELSE 0
               END [SaleQuantity],
               CASE
                   WHEN [InvoiceDetails].[RelatedInvoiceDetaileId] IS NULL THEN
                        CAST([InvoiceDetails].[SalePrice] * [SheetDetailRelations].[Quantity] AS BIGINT)
                   ELSE 0
               END [SalePrice],
               CASE
                   WHEN [InvoiceDetails].[RelatedInvoiceDetaileId] IS NOT NULL THEN
                        CAST([SheetDetailRelations].[Quantity] AS BIGINT)
                   ELSE 0
               END [OfferQuantity],
               CASE
                   WHEN [InvoiceDetails].[RelatedInvoiceDetaileId] IS NOT NULL THEN
                        CAST([InvoiceDetails].[SalePrice] * [SheetDetailRelations].[Quantity] AS BIGINT)
                   ELSE 0
               END [OfferPrice],
               CAST([InputSheetDetails].[FullCost] * [SheetDetailRelations].[Quantity] AS BIGINT) [FullCost],
               'SAL' [Type],
               InputSheetHeaders.PartyAccountId
        FROM [Distribution].[Invoices]
            INNER JOIN [Distribution].[InvoiceDetails] ON [InvoiceDetails].[HeaderId] = [Invoices].[Id]
            INNER JOIN [Inventory].[SheetDetailRelations] ON [SheetDetailRelations].[OutputSheetDetailId] = [InvoiceDetails].[OutputSheetDetailId]
            INNER JOIN [Inventory].[InputSheetDetails] ON [InputSheetDetails].[Id] = [SheetDetailRelations].[InputSheetDetailId]
            INNER JOIN [Inventory].[InputSheetHeaders] ON [InputSheetHeaders].[Id] = [InputSheetDetails].[HeaderId]
            INNER JOIN [InventoryBasics].[PartyAccounts] ON [PartyAccounts].[Id] = [Invoices].[CustomerId]
            LEFT JOIN [#FromInputNumber] [FromInputNumber] ON [FromInputNumber].[Item] = [Inventory].[InputSheetHeaders].[Number]
        WHERE [Invoices].[FinancialYearId] = @FinancialYearId
              AND (
                      @FromDate IS NULL
                      OR [Invoices].[Date] >= @FromDate
                  )
              AND (
                      @ToDate IS NULL
                      OR [Invoices].[Date] <= @ToDate
                  )
              AND (
                      @FromNumber IS NULL
                      OR [Invoices].[Number] >= @FromNumber
                  )
              AND (
                      @ToNumber IS NULL
                      OR [Invoices].[Number] <= @ToNumber
                  )
              AND (
                      @FromInputNumber IS NULL
                      OR [FromInputNumber].[Item] IS NOT NULL
                  )
              AND (
                      @PartyAccountGroupId IS NULL
                      OR [PartyAccounts].[PartyAccountGroupId] = @PartyAccountGroupId
                  )
        UNION ALL
        SELECT [Invoices].[Number],
               [Invoices].[Date],
               [Invoices].[CustomerId],
               [Invoices].[MarketerId],
               [PartyAccounts].[RegionId],
               [InputSheetDetails].[ProductId],
               [InputSheetDetails].[Id] [DetailId],
               [InputSheetDetails].[OrgSupplier],
               [InputSheetDetails].[BatchNumber],
               [InputSheetDetails].[ExpireDate],
               CASE
                   WHEN [InvoiceDetails].[RelatedInvoiceDetaileId] IS NULL THEN
                        CAST([InputSheetDetails].[Quantity] AS BIGINT)
                   ELSE 0
               END [SaleQuantity],
               CASE
                   WHEN [InvoiceDetails].[RelatedInvoiceDetaileId] IS NULL THEN
                        CAST([InvoiceDetails].[SalePrice] * [InputSheetDetails].[Quantity] AS BIGINT)
                   ELSE 0
               END [SalePrice],
               CASE
                   WHEN [InvoiceDetails].[RelatedInvoiceDetaileId] IS NOT NULL THEN
                        CAST([InputSheetDetails].[Quantity] AS BIGINT)
                   ELSE 0
               END [OfferQuantity],
               CASE
                   WHEN [InvoiceDetails].[RelatedInvoiceDetaileId] IS NOT NULL THEN
                        CAST([InvoiceDetails].[SalePrice] * [InputSheetDetails].[Quantity] AS BIGINT)
                   ELSE 0
               END [OfferPrice],
               CAST([InputSheetDetails].[FullCost] * [InputSheetDetails].[Quantity] AS BIGINT) [FullCost],
               'RTN',
               InputSheetHeaders.PartyAccountId
        FROM [Inventory].[InputSheetHeaders]
            INNER JOIN [Inventory].[InputSheetDetails] ON [InputSheetDetails].[HeaderId] = [InputSheetHeaders].[Id]
            INNER JOIN [Inventory].[SheetTypes] ON [SheetTypes].[Id] = [InputSheetHeaders].[TypeId]
                                                   AND [SheetTypes].[Name] = 'ReturnOutputSheet'
            INNER JOIN [Distribution].[InvoiceDetails] ON [InvoiceDetails].[OutputSheetDetailId] = [InputSheetDetails].[OutputSheetDetailId]
            INNER JOIN [Distribution].[Invoices] ON [Invoices].[Id] = [InvoiceDetails].[HeaderId]
            INNER JOIN [InventoryBasics].[PartyAccounts] ON [PartyAccounts].[Id] = [Invoices].[CustomerId]
            --htrn add
            INNER JOIN [Inventory].[SheetDetailRelations] ON [SheetDetailRelations].[OutputSheetDetailId] = [InvoiceDetails].[OutputSheetDetailId]
            INNER JOIN [Inventory].[InputSheetDetails] [SourceInputSheetDetails] ON [SourceInputSheetDetails].[Id] = [SheetDetailRelations].[InputSheetDetailId]
            INNER JOIN [Inventory].[InputSheetHeaders] [SourceInputSheetHeaders] ON [SourceInputSheetHeaders].[Id] = [InputSheetDetails].[HeaderId]
            LEFT JOIN [#FromInputNumber] [FromInputNumber] ON [FromInputNumber].[Item] = [SourceInputSheetHeaders].[Number]
        --htrn add end

        WHERE [InputSheetHeaders].[FinancialYearId] = @FinancialYearId
              AND (
                      @FromDate IS NULL
                      OR [Invoices].[Date] >= @FromDate
                  )
              AND (
                      @ToDate IS NULL
                      OR [Invoices].[Date] <= @ToDate
                  )
              AND (
                      @FromNumber IS NULL
                      OR [Invoices].[Number] >= @FromNumber
                  )
              AND (
                      @ToNumber IS NULL
                      OR [Invoices].[Number] <= @ToNumber
                  )
              AND
              --htrn add
              (
                  @FromInputNumber IS NULL
                  OR [FromInputNumber].[Item] IS NOT NULL
              )),
         [GroupedRecords]
    AS (SELECT CASE
                   WHEN @GroupbyCustomer = 1 THEN [Records].[CustomerId]
               END [CustomerId],
               CASE
                   WHEN @GroupbyProduct = 1 THEN [Records].[ProductId]
               END [ProductId],
               CASE
                   WHEN @GroupbyOrgSupplier = 1 THEN [Records].[OrgSupplier]
               END [OrgSupplierId],
               CASE
                   WHEN @GroupbySupplier = 1 THEN [Products].[SupplierId]
               END [SupplierId],
               CASE
                   WHEN @GroupbyRegion = 1 THEN [Records].[RegionId]
               END [RegionId],
               CASE
                   WHEN @GroupbyMarketer = 1 THEN [Records].[MarketerId]
               END [MarketerId],
               CASE
                   WHEN @GroupbyInvoiceNumber = 1 THEN [Records].[Number]
               END [InvoiceNumber],
               CASE
                   WHEN @GroupbyMonth = 1 THEN [DimDate].[PersianMonthNumberOfYear]
               END [PersianMonth],
               CASE
                   WHEN @GroupbyMonth = 1 THEN [DimDate].[PersianMonthName]
               END [PersianMonthName],
               --jn add
               CASE
                   WHEN @GroupbyPartyAccount = 1 THEN [Records].[PartyAccountId]
               END [PartyAccountId],
               --jn end
               --htn add
               --
               COUNT (DISTINCT [Records].[DetailId]) [InvoiceRowCount],
               COUNT (DISTINCT [Records].[Number]) [InvoiceCount],
               COUNT (DISTINCT [Records].[CustomerId]) [CustomerCount],
               COUNT (DISTINCT [Records].[ProductId]) [ProductCount],
               --htn end
               SUM (   CASE
                           WHEN [Records].[Type] = 'SAL' THEN [Records].[SaleQuantity]
                           ELSE 0
                       END
                   ) [SaleQuantity],
               SUM (   CASE
                           WHEN [Records].[Type] = 'RTN' THEN [Records].[SaleQuantity]
                           ELSE 0
                       END
                   ) [SaleReturnQuantity],
               SUM (   CASE
                           WHEN [Records].[Type] = 'SAL' THEN [Records].[OfferQuantity]
                           ELSE 0
                       END
                   ) [OfferQuantity],
               SUM (   CASE
                           WHEN [Records].[Type] = 'RTN' THEN [Records].[OfferQuantity]
                           ELSE 0
                       END
                   ) [OfferReturnQuantity],
               SUM (   CASE
                           WHEN [Records].[Type] = 'SAL' THEN [Records].[SalePrice]
                           ELSE 0
                       END
                   ) [SalePrice],
               SUM (   CASE
                           WHEN [Records].[Type] = 'RTN' THEN [Records].[SalePrice]
                           ELSE 0
                       END
                   ) [SaleReturnPrice],
               SUM (   CASE
                           WHEN [Records].[Type] = 'SAL' THEN [Records].[OfferPrice]
                           ELSE 0
                       END
                   ) [OfferPrice],
               SUM (   CASE
                           WHEN [Records].[Type] = 'RTN' THEN [Records].[OfferPrice]
                           ELSE 0
                       END
                   ) [OfferReturnPrice],
               SUM (   CASE
                           WHEN [Records].[Type] = 'SAL' THEN [Records].[FullCost]
                           ELSE 0
                       END
                   ) [FullCost],
               SUM (   CASE
                           WHEN [Records].[Type] = 'RTN' THEN [Records].[FullCost]
                           ELSE 0
                       END
                   ) [ReturnFullCost]
        FROM [Records]
            INNER JOIN [InventoryBasics].[Products] ON [Products].[Id] = [Records].[ProductId]
            INNER JOIN [Core].[Dates] [DimDate] ON [DimDate].[Date] = [Records].[Date]
            LEFT JOIN [InventoryBasics].[Regions] ON [Regions].[Id] = [Records].[RegionId]
            LEFT JOIN (
                          SELECT [ProductTags].[ProductId]
                          FROM [InventoryBasics].[ProductTags]
                          WHERE [ProductTags].[TagId] = @TagId
                          GROUP BY [ProductTags].[ProductId]
                      ) [Tags] ON [Tags].[ProductId] = [Products].[Id]
        WHERE (
                  @TagId IS NULL
                  OR [Tags].[ProductId] IS NOT NULL
              )
              AND (
                      @CustomerId IS NULL
                      OR [Records].[CustomerId] = @CustomerId
                  )
              AND (
                      @ProductId IS NULL
                      OR [Records].[ProductId] = @ProductId
                  )
              AND (
                      @DrugId IS NULL
                      OR [Products].[DrugId] = @DrugId
                  )
              AND (
                      @DrugFormId IS NULL
                      OR [Products].[DrugFormId] = @DrugFormId
                  )
              AND (
                      @OrgSupplierId IS NULL
                      OR [Records].[OrgSupplier] = @OrgSupplierId
                  )
              AND (
                      @SupplierId IS NULL
                      OR [Products].[SupplierId] = @SupplierId
                  )
              AND (
                      @RegionHID IS NULL
                      OR [Regions].[HId].[IsDescendantOf] (@RegionHID) = 1
                  )
              AND (
                      @MarketerId IS NULL
                      OR [Records].[MarketerId] = @MarketerId
                  )
        GROUP BY CASE
                     WHEN @GroupbyCustomer = 1 THEN [Records].[CustomerId]
                 END,
                 CASE
                     WHEN @GroupbyProduct = 1 THEN [Records].[ProductId]
                 END,
                 CASE
                     WHEN @GroupbyOrgSupplier = 1 THEN [Records].[OrgSupplier]
                 END,
                 CASE
                     WHEN @GroupbySupplier = 1 THEN [Products].[SupplierId]
                 END,
                 CASE
                     WHEN @GroupbyRegion = 1 THEN [Records].[RegionId]
                 END,
                 CASE
                     WHEN @GroupbyMarketer = 1 THEN [Records].[MarketerId]
                 END,
                 CASE
                     WHEN @GroupbyInvoiceNumber = 1 THEN [Records].[Number]
                 END,
                 CASE
                     WHEN @GroupbyMonth = 1 THEN [DimDate].[PersianMonthNumberOfYear]
                 END,
                 CASE
                     WHEN @GroupbyMonth = 1 THEN [DimDate].[PersianMonthName]
                 END,
                 CASE
                     WHEN @GroupbyPartyAccount = 1 THEN [Records].[PartyAccountId]
                 END),
         [Prepared]
    AS (SELECT [GroupedRecords].[CustomerId],
               --htn add
               [GroupedRecords].[InvoiceCount],
               [GroupedRecords].[InvoiceRowCount],
               [GroupedRecords].[CustomerCount],
               [GroupedRecords].[ProductCount],
               --htn end
               [GroupedRecords].[ProductId],
               [GroupedRecords].[OrgSupplierId],
               [GroupedRecords].[SupplierId],
               [GroupedRecords].[RegionId],
               [GroupedRecords].[MarketerId],
               [GroupedRecords].[InvoiceNumber],
               [GroupedRecords].[PersianMonth],
               [GroupedRecords].[PersianMonthName],
               [GroupedRecords].[SaleQuantity],
               [GroupedRecords].[SaleReturnQuantity],
               [GroupedRecords].[OfferQuantity],
               [GroupedRecords].[OfferReturnQuantity],
               [GroupedRecords].[SalePrice],
               [GroupedRecords].[SaleReturnPrice],
               [GroupedRecords].[OfferPrice],
               [GroupedRecords].[OfferReturnPrice],
               [GroupedRecords].[FullCost],
               [GroupedRecords].[ReturnFullCost],
               ([GroupedRecords].[SalePrice] - [GroupedRecords].[SaleReturnPrice])
               - ([GroupedRecords].[FullCost] - [GroupedRecords].[ReturnFullCost]) [Profit]
        FROM [GroupedRecords]),
         [TempCount]
    AS (SELECT COUNT (*) AS [MaxRows]
        FROM [Prepared]),
         [TempTotalSum]
    AS (SELECT SUM ([Prepared].[SaleQuantity]) [SumSaleQuantity],
               SUM ([Prepared].[SaleReturnQuantity]) [SumSaleReturnQuantity],
               SUM ([Prepared].[OfferQuantity]) [SumOfferQuantity],
               SUM ([Prepared].[OfferReturnQuantity]) [SumOfferReturnQuantity],
               SUM ([Prepared].[SalePrice]) [SumSalePrice],
               SUM ([Prepared].[SaleReturnPrice]) [SumSaleReturnPrice],
               SUM ([Prepared].[OfferPrice]) [SumOfferPrice],
               SUM ([Prepared].[OfferReturnPrice]) [SumOfferReturnPrice],
               SUM ([Prepared].[FullCost]) [SumFullCost],
               SUM ([Prepared].[ReturnFullCost]) [SumReturnFullCost],
               SUM ([Prepared].[Profit]) [SumProfit],
               SUM ([Prepared].[InvoiceCount]) [SumInvoiceCount],
               SUM ([Prepared].[InvoiceRowCount]) [SumInvoiceRowCount]
        FROM [Prepared])
    SELECT
        --htn add    
        [Prepared].[InvoiceCount],
        [Prepared].[InvoiceRowCount],
        [Prepared].[CustomerCount],
        [Prepared].[ProductCount],
        --htn end
        [Core].[GetFullTitle] ([PartyAccounts].[Code], [PartyAccounts].[Title]) [Customer],
        [Core].[GetFullTitle] ([Products].[Code], [Products].[Title]) [Product],
        [Core].[GetFullTitle] ([OrgSuppliers].[Code], [OrgSuppliers].[Title]) [OrgSupplier],
        [Core].[GetFullTitle] ([Suppliers].[Code], [Suppliers].[Title]) [Supplier],
        [Region_CTE].[Path] [Region],
        [Core].[GetFullTitle] ([Marketers].[Code], [Marketers].[Title]) [Marketer],
        [Prepared].[InvoiceNumber],
        [Prepared].[PersianMonthName] [PersianMonth],
        [Prepared].[SaleQuantity],
        [Prepared].[SaleReturnQuantity],
        [Prepared].[OfferQuantity],
        [Prepared].[OfferReturnQuantity],
        [Prepared].[SalePrice],
        [Prepared].[SaleReturnPrice],
        [Prepared].[OfferPrice],
        [Prepared].[OfferReturnPrice],
        [Prepared].[FullCost],
        [Prepared].[ReturnFullCost],
        [Prepared].[Profit],
        [TempCount].*,
        [TempTotalSum].*
    FROM [TempCount],
         [TempTotalSum],
         [Prepared]
        LEFT JOIN [InventoryBasics].[PartyAccounts] ON [Prepared].[CustomerId] = [PartyAccounts].[Id]
        LEFT JOIN [InventoryBasics].[Products] ON [Prepared].[ProductId] = [Products].[Id]
        LEFT JOIN [InventoryBasics].[PartyAccounts] [OrgSuppliers] ON [Prepared].[OrgSupplierId] = [OrgSuppliers].[Id]
        LEFT JOIN [InventoryBasics].[Suppliers] ON [Suppliers].[Id] = [Prepared].[SupplierId]
        LEFT JOIN [InventoryBasics].[Region_CTE] () ON [Region_CTE].[Id] = [Prepared].[RegionId]
        LEFT JOIN [InventoryBasics].[PartyAccounts] [Marketers] ON [Marketers].[Id] = [Prepared].[MarketerId]
    ORDER BY CASE
                 WHEN @Sort = 'SaleQuantity'
                      AND @Asc = 1 THEN [Prepared].[SaleQuantity]
             END ASC,
             CASE
                 WHEN @Sort = 'SaleQuantity'
                      AND @Asc = 0 THEN [Prepared].[SaleQuantity]
             END DESC,
             CASE
                 WHEN @Sort = 'SaleReturnQuantity'
                      AND @Asc = 1 THEN [Prepared].[SaleReturnQuantity]
             END ASC,
             CASE
                 WHEN @Sort = 'SaleReturnQuantity'
                      AND @Asc = 0 THEN [Prepared].[SaleReturnQuantity]
             END DESC,
             CASE
                 WHEN @Sort = 'OfferQuantity'
                      AND @Asc = 1 THEN [Prepared].[OfferQuantity]
             END ASC,
             CASE
                 WHEN @Sort = 'OfferQuantity'
                      AND @Asc = 0 THEN [Prepared].[OfferQuantity]
             END DESC,
             CASE
                 WHEN @Sort = 'OfferReturnQuantity'
                      AND @Asc = 1 THEN [Prepared].[OfferReturnQuantity]
             END ASC,
             CASE
                 WHEN @Sort = 'OfferReturnQuantity'
                      AND @Asc = 0 THEN [Prepared].[OfferReturnQuantity]
             END DESC,
             CASE
                 WHEN @Sort = 'SalePrice'
                      AND @Asc = 1 THEN [Prepared].[SalePrice]
             END ASC,
             CASE
                 WHEN @Sort = 'SalePrice'
                      AND @Asc = 0 THEN [Prepared].[SalePrice]
             END DESC,
             CASE
                 WHEN @Sort = 'SaleReturnPrice'
                      AND @Asc = 1 THEN [Prepared].[SaleReturnPrice]
             END ASC,
             CASE
                 WHEN @Sort = 'SaleReturnPrice'
                      AND @Asc = 0 THEN [Prepared].[SaleReturnPrice]
             END DESC,
             CASE
                 WHEN @Sort = 'OfferPrice'
                      AND @Asc = 1 THEN [Prepared].[OfferPrice]
             END ASC,
             CASE
                 WHEN @Sort = 'OfferPrice'
                      AND @Asc = 0 THEN [Prepared].[OfferPrice]
             END DESC,
             CASE
                 WHEN @Sort = 'OfferReturnPrice'
                      AND @Asc = 1 THEN [Prepared].[OfferReturnPrice]
             END ASC,
             CASE
                 WHEN @Sort = 'OfferReturnPrice'
                      AND @Asc = 0 THEN [Prepared].[OfferReturnPrice]
             END DESC,
             CASE
                 WHEN @Sort = 'FullCost'
                      AND @Asc = 1 THEN [Prepared].[FullCost]
             END ASC,
             CASE
                 WHEN @Sort = 'FullCost'
                      AND @Asc = 0 THEN [Prepared].[FullCost]
             END DESC,
             CASE
                 WHEN @Sort = 'ReturnFullCost'
                      AND @Asc = 1 THEN [Prepared].[ReturnFullCost]
             END ASC,
             CASE
                 WHEN @Sort = 'ReturnFullCost'
                      AND @Asc = 0 THEN [Prepared].[ReturnFullCost]
             END DESC,
             CASE
                 WHEN @Sort = 'Profit'
                      AND @Asc = 1 THEN [Prepared].[Profit]
             END ASC,
             CASE
                 WHEN @Sort = 'Profit'
                      AND @Asc = 0 THEN [Prepared].[Profit]
             END DESC,
             CASE
                 WHEN @Sort = 'Customer'
                      AND @Asc = 1 THEN [Prepared].[CustomerId]
             END ASC,
             CASE
                 WHEN @Sort = 'Customer'
                      AND @Asc = 0 THEN [Prepared].[CustomerId]
             END DESC,
             CASE
                 WHEN @Sort = 'Product'
                      AND @Asc = 1 THEN [Prepared].[ProductId]
             END ASC,
             CASE
                 WHEN @Sort = 'Product'
                      AND @Asc = 0 THEN [Prepared].[ProductId]
             END DESC,
             CASE
                 WHEN @Sort = 'OrgSupplier'
                      AND @Asc = 1 THEN [Prepared].[OrgSupplierId]
             END ASC,
             CASE
                 WHEN @Sort = 'OrgSupplier'
                      AND @Asc = 0 THEN [Prepared].[OrgSupplierId]
             END DESC,
             CASE
                 WHEN @Sort = 'Supplier'
                      AND @Asc = 1 THEN [Prepared].[SupplierId]
             END ASC,
             CASE
                 WHEN @Sort = 'Supplier'
                      AND @Asc = 0 THEN [Prepared].[SupplierId]
             END DESC,
             CASE
                 WHEN @Sort = 'Region'
                      AND @Asc = 1 THEN [Prepared].[RegionId]
             END ASC,
             CASE
                 WHEN @Sort = 'Region'
                      AND @Asc = 0 THEN [Prepared].[RegionId]
             END DESC,
             CASE
                 WHEN @Sort = 'Marketer'
                      AND @Asc = 1 THEN [Prepared].[MarketerId]
             END ASC,
             CASE
                 WHEN @Sort = 'Marketer'
                      AND @Asc = 0 THEN [Prepared].[MarketerId]
             END DESC,
             CASE
                 WHEN @Sort = 'PersianMonth'
                      AND @Asc = 1 THEN [Prepared].[PersianMonth]
             END ASC,
             CASE
                 WHEN @Sort = 'PersianMonth'
                      AND @Asc = 0 THEN [Prepared].[PersianMonth]
             END DESC,
             CASE
                 WHEN @Sort = 'InvoiceNumber'
                      AND @Asc = 1 THEN [Prepared].[InvoiceNumber]
             END ASC,
             CASE
                 WHEN @Sort = 'InvoiceNumber'
                      AND @Asc = 0 THEN [Prepared].[InvoiceNumber]
             END DESC,
             CASE
                 WHEN @Sort = 'InvoiceCount'
                      AND @Asc = 1 THEN [Prepared].[InvoiceCount]
             END ASC,
             CASE
                 WHEN @Sort = 'InvoiceCount'
                      AND @Asc = 0 THEN [Prepared].[InvoiceCount]
             END DESC,
             CASE
                 WHEN @Sort = 'CustomerCount'
                      AND @Asc = 1 THEN [Prepared].[CustomerCount]
             END ASC,
             CASE
                 WHEN @Sort = 'CustomerCount'
                      AND @Asc = 0 THEN [Prepared].[CustomerCount]
             END DESC,
             CASE
                 WHEN @Sort = 'ProductCount'
                      AND @Asc = 1 THEN [Prepared].[ProductCount]
             END ASC,
             CASE
                 WHEN @Sort = 'ProductCount'
                      AND @Asc = 0 THEN [Prepared].[ProductCount]
             END DESC,
             CASE
                 WHEN @Sort = 'InvoiceRowCount'
                      AND @Asc = 1 THEN [Prepared].[InvoiceRowCount]
             END ASC,
             CASE
                 WHEN @Sort = 'InvoiceRowCount'
                      AND @Asc = 0 THEN [Prepared].[InvoiceRowCount]
             END DESC,
             [Prepared].[CustomerId],
             [Prepared].[ProductId],
             [Prepared].[OrgSupplierId],
             [Prepared].[SupplierId],
             [Prepared].[RegionId],
             [Prepared].[MarketerId],
             [Prepared].[PersianMonth],
             [Prepared].[InvoiceNumber] OFFSET (@Page - 1) * @PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;

END;
GO

