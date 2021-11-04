DECLARE @FinancialYearId INT = 99,
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
        @Sort NVARCHAR(MAX) = N'',
        @FromInputNumber VARCHAR(MAX) = NULL;

IF (@PageSize IS NULL)
    SET @PageSize = [Core].[MaxInt]();
IF (@Page IS NULL)
    SET @Page = 1;

SELECT [Item] = CAST([StringSplit].[Value] AS INT)
INTO [#FromInputNumber]
FROM [Core].[StringSplit](@FromInputNumber, ',');

DECLARE @RegionHID HIERARCHYID;
SELECT @RegionHID = [Regions].[HId]
FROM [InventoryBasics].[Regions]
WHERE [Regions].[Id] = @RegionId;

    WITH [Records]
    AS (SELECT [Invoices].[Number],[InputSheetHeaders].[FinancialYearId],
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
               'SAL' [Type]
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
        SELECT [Invoices].[Number],[InputSheetHeaders].[FinancialYearId],
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
               'RTN'
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

        --WHERE [InputSheetHeaders].[FinancialYearId] = @FinancialYearId
              --AND (
              --        @FromDate IS NULL
              --        OR [Invoices].[Date] >= @FromDate
              --    )
              --AND (
              --        @ToDate IS NULL
              --        OR [Invoices].[Date] <= @ToDate
              --    )
              --AND (
              --        @FromNumber IS NULL
              --        OR [Invoices].[Number] >= @FromNumber
              --    )
              --AND (
              --        @ToNumber IS NULL
              --        OR [Invoices].[Number] <= @ToNumber
              --    )
              --AND
              ----htrn add
              --(
              --    @FromInputNumber IS NULL
              --    OR [FromInputNumber].[Item] IS NOT NULL
              --)
			  )


SELECT * FROM  Records
DROP TABLE [#FromInputNumber];