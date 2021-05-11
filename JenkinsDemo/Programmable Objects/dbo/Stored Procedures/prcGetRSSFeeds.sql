IF OBJECT_ID('[dbo].[prcGetRSSFeeds]') IS NOT NULL
	DROP PROCEDURE [dbo].[prcGetRSSFeeds];

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[prcGetRSSFeeds]
AS
SET NOCOUNT ON
    SELECT  RSSFeedID,
            FeedName,
            Checked
    FROM    dbo.RSSFeeds

	-- v4
GO
