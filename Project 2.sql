CREATE DATABASE AfritechDB;

CREATE TABLE stagingdata (
    CustomerID INT,
    CustomerName VARCHAR(100),
    Region VARCHAR(100),
    Age SMALLINT,
    Income DECIMAL(10,2),
    CustomerType VARCHAR(20),
    TransactionYear INT,
    TransactionDate DATE,
    ProductPurchased VARCHAR(50),
    PurchaseAmount DECIMAL(10,2),
    ProductRecalled BOOLEAN,
    Competitor_x VARCHAR(100),
    InteractionDate DATE,
    Platform VARCHAR(50),
    PostType VARCHAR(50),
    EngagementLikes INT,
    EngagementShares INT,
    EngagementComments INT,
    UserFollowers INT,
    InfluencerScore DECIMAL(10,2),
    BrandMention BOOLEAN,
    CompetitorMention BOOLEAN,
    Sentiment VARCHAR(20),
    CrisisEventTime DATE,
    FirstResponseTime DATE,
    ResolutionStatus BOOLEAN,
    NPSResponse INT
);


-- CUSTOMER TABLE
CREATE TABLE customers (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(255),
    Region VARCHAR(255),
    Age INT,
   	Income DECIMAL(10,2),
    CustomerType VARCHAR(50)
);

-- TRANSACTIONS TABLE
CREATE TABLE transactions (
    TransactionID SERIAL PRIMARY KEY,
    CustomerID INT NOT NULL,
    TransactionYear INT,
    TransactionDate DATE,
    ProductPurchased VARCHAR(50),
    PurchaseAmount DECIMAL(10,2),
    ProductRecalled BOOLEAN,
    Competitor_x VARCHAR(100),
    FOREIGN KEY (CustomerID) REFERENCES customers(CustomerID)
);

-- SOCIAL MEDIA INTERACTIONS TABLE
CREATE TABLE Social_Media (
    SocialMediaID SERIAL PRIMARY KEY,
    CustomerID INT NOT NULL,
    InteractionDate DATE,
    Platform VARCHAR(50),
    PostType VARCHAR(50),
    EngagementLikes INT,
    EngagementShares INT,
    EngagementComments INT,
    UserFollowers INT,
    InfluencerScore DECIMAL(10,2),
    BrandMention BOOLEAN,
    CompetitorMention BOOLEAN,
    Sentiment VARCHAR(20),
    Competitor_x VARCHAR(100),
    CrisisEventTime DATE,
    FirstResponseTime DATE,
    ResolutionStatus BOOLEAN,
    NPSResponse INT,
    FOREIGN KEY (CustomerID) REFERENCES customers(CustomerID)
);


-- Load customers
INSERT INTO customers(CustomerID, CustomerName, Region, Age, Income, CustomerType)
SELECT DISTINCT CustomerID, CustomerName, Region, Age, Income, CustomerType
FROM StagingData;

-- Load transactions
INSERT INTO transactions(CustomerID, TransactionYear, TransactionDate, ProductPurchased, PurchaseAmount, ProductRecalled, Competitor_x)
SELECT CustomerID, TransactionYear, TransactionDate, ProductPurchased, PurchaseAmount, ProductRecalled, Competitor_x
FROM StagingData
WHERE TransactionDate IS NOT NULL;

-- Load social media
INSERT INTO social_media(CustomerID, InteractionDate, Platform, PostType, EngagementLikes, EngagementShares, EngagementComments,
                         UserFollowers, InfluencerScore, BrandMention, CompetitorMention, Sentiment, Competitor_x,
                         CrisisEventTime, FirstResponseTime, ResolutionStatus, NPSResponse)
SELECT CustomerID, InteractionDate, Platform, PostType, EngagementLikes, EngagementShares, EngagementComments,
       UserFollowers, InfluencerScore, BrandMention, CompetitorMention, Sentiment, Competitor_x,
       CrisisEventTime, FirstResponseTime, ResolutionStatus, NPSResponse
FROM StagingData
WHERE InteractionDate IS NOT NULL;


---DROP TABLE IF EXISTS transactions;

---DROP TABLE IF EXISTS social_media;

---DROP TABLE IF EXISTS customers;

---DROP TABLE IF EXISTS stagingdata;

SELECT*
FROM social_media
LIMIT 5;

DROP TABLE stagingdata;

--- DATA VALIDATION CHECKS 

SELECT COUNT(*)
FROM customers;

SELECT COUNT(*)
FROM transactions;

SELECT COUNT(*)
FROM social_media;

---Check for NULLs in Critical Columns

-- Customers
SELECT COUNT(*) 
FROM customers 
WHERE CustomerID IS NULL OR CustomerName IS NULL;

-- Transactions
SELECT COUNT(*) 
FROM transactions 
WHERE CustomerID IS NULL OR TransactionDate IS NULL OR PurchaseAmount IS NULL;

-- Social Media
SELECT COUNT(*) 
FROM social_media 
WHERE CustomerID IS NULL OR InteractionDate IS NULL OR Sentiment IS NULL;

SELECT*
FROM transactions;

SELECT* 
FROM social_media 
WHERE crisiseventtime IS NULL;

SELECT*
FROM transactions 
WHERE competitor_x IS NULL;


--- Check for Orphaned Foreign Keys
-- Transactions with non-matching CustomerID
SELECT DISTINCT t.CustomerID 
FROM transactions t
LEFT JOIN customers c ON t.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL;

-- Social media with non-matching CustomerID
SELECT DISTINCT s.CustomerID 
FROM social_media s
LEFT JOIN customers c ON s.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL;

---Duplicate Checks
-- Duplicate Customers
SELECT CustomerID, COUNT(*) 
FROM customers 
GROUP BY CustomerID 
HAVING COUNT(*) > 1;

-- Duplicate Transactions (by all fields)
SELECT CustomerID, TransactionDate, ProductPurchased, COUNT(*)
FROM transactions
GROUP BY CustomerID, TransactionDate, ProductPurchased
HAVING COUNT(*) > 1;

---Inspecting the duplicate Transactions

SELECT *
FROM transactions
WHERE (CustomerID, TransactionDate, ProductPurchased) IN (
    SELECT CustomerID, TransactionDate, ProductPurchased
    FROM transactions
    GROUP BY CustomerID, TransactionDate, ProductPurchased
    HAVING COUNT(*) > 1
)
ORDER BY CustomerID, TransactionDate, ProductPurchased;

--- DATA EXPLORATORY ANALYSIS

---Customer & Sales Insights
--- CUSTOMER DEMOGRAPHICS ANALYSIS

SELECT*
FROM customers;

---Customers by Region
SELECT Region, COUNT(*) AS Total_Customers
FROM customers
GROUP BY Region
ORDER BY Total_Customers ASC;

--Customer by Region and Type
--Shows how many new, returning, or VIP customers exist in each region.
--Helps identify market strength and loyalty distribution across locations.
SELECT
  Region,
  CustomerType,
  COUNT(DISTINCT CustomerID) AS Total_Customers
FROM customers
GROUP BY Region, CustomerType
ORDER BY Region, Total_Customers DESC;

--Customer Count by Type
--Gives a summary of customer composition by type (New, Returning, VIP).
--Useful for targeting loyalty programs and marketing segmentation.
SELECT
  CustomerType,
  COUNT(*) AS Total_Customers
FROM customers
GROUP BY CustomerType
ORDER BY Total_Customers DESC;

---Customer Count by Region
---Displays how many customers exist in each region.
--Prioritize regions with the highest customer base for targeted campaigns.

SELECT
  Region,
  COUNT(*) AS Total_Customers
FROM customers
GROUP BY Region
ORDER BY Total_Customers DESC;

---Customer Count by Age Range
--Counts the number of customers in each age bracket.
--Helps us understand which age groups dominate the customer base for demographic targeting.

SELECT 
  CASE 
    WHEN Age BETWEEN 15 AND 24 THEN '15–24'
    WHEN Age BETWEEN 25 AND 34 THEN '25–34'
    WHEN Age BETWEEN 35 AND 44 THEN '35–44'
    WHEN Age BETWEEN 45 AND 54 THEN '45–54'
    WHEN Age BETWEEN 55 AND 64 THEN '55–64'
    WHEN Age BETWEEN 65 AND 75 THEN '65–75'
    ELSE '76+' 
  END AS Age_Range,
  COUNT(*) AS Customer_Count
FROM customers
GROUP BY Age_Range
ORDER BY Age_Range;

--Income Stats by Customer Type
--Provides income range (average, min, max) by customer type.
--Helps identify high-value segments like VIPs or returning customers with high income.

SELECT 
    CustomerType, 
    COUNT(*) AS Total_Customers,
    ROUND(AVG(Income), 2) AS Avg_Income,
    ROUND(MIN(Income), 2) AS Min_Income,
    ROUND(MAX(Income), 2) AS Max_Income
FROM customers
GROUP BY CustomerType
ORDER BY Avg_Income DESC;

---Average Income by Age Range
--Calculates average income per age bracket.
--Helps in crafting age-targeted campaigns based on income trends.
SELECT 
  CASE 
    WHEN Age BETWEEN 15 AND 24 THEN '15–24'
    WHEN Age BETWEEN 25 AND 34 THEN '25–34'
    WHEN Age BETWEEN 35 AND 44 THEN '35–44'
    WHEN Age BETWEEN 45 AND 54 THEN '45–54'
    WHEN Age BETWEEN 55 AND 64 THEN '55–64'
    WHEN Age BETWEEN 65 AND 75 THEN '65–75'
    ELSE '76+' 
  END AS Age_Range,
  ROUND(AVG(Income), 2) AS Avg_Income
FROM customers
GROUP BY Age_Range
ORDER BY Age_Range;


--- Customer Type Distribution by Region
--Shows how customer types are distributed in each region — helps design region-specific campaigns.
SELECT
  Region,
  CustomerType,
  COUNT(*) AS Total_Customers
FROM customers
GROUP BY Region, CustomerType
ORDER BY Region, CustomerType;

---SALES & TRANSACTION INSIGHTS

--Total Revenue by Year - Helps us understand how sales have changed over time.
SELECT TransactionYear, 
       SUM(PurchaseAmount) AS Total_Revenue
FROM transactions
GROUP BY TransactionYear
ORDER BY TransactionYear;

---Top 5 Products by Revenue - Helps us see which products drive the most revenue.
SELECT ProductPurchased, 
       COUNT(*) AS Units_Sold,
       SUM(PurchaseAmount) AS Revenue
FROM transactions
GROUP BY ProductPurchased
ORDER BY Revenue DESC
LIMIT 5;

---Revenue by Region - Identifying high-performing regions.
SELECT c.Region, 
       SUM(t.PurchaseAmount) AS Total_Revenue
FROM transactions t
JOIN customers c ON t.CustomerID = c.CustomerID
GROUP BY c.Region
ORDER BY Total_Revenue DESC;

---Average Spend by Customer Type - Determining which customer segments spend more per transaction.
SELECT c.CustomerType, 
       AVG(t.PurchaseAmount) AS Avg_Spend
FROM transactions t
JOIN customers c ON t.CustomerID = c.CustomerID
GROUP BY c.CustomerType
ORDER BY Avg_Spend DESC;

---Product Recall Impact - Identifying which products have been recalled most.
SELECT ProductPurchased, 
       COUNT(*) AS Total_Transactions,
       SUM(CASE WHEN ProductRecalled = TRUE THEN 1 ELSE 0 END) AS Recall_Count
FROM transactions
GROUP BY ProductPurchased
ORDER BY Recall_Count DESC;

---Competitor Mention Influence - Spotting competitors impacting the company's sales.
SELECT Competitor_x, 
       COUNT(*) AS Mentions, 
       SUM(PurchaseAmount) AS Revenue_Lost
FROM transactions
WHERE Competitor_x IS NOT NULL
GROUP BY Competitor_x
ORDER BY Revenue_Lost DESC;

---Average Revenue per Customer by Region- This helps us identify regions not just with high revenue, 
--but where individual customers are most valuable. 
 SELECT c.Region, 
       COUNT(DISTINCT c.CustomerID) AS Customers,
       SUM(t.PurchaseAmount) AS Total_Revenue,
       ROUND(SUM(t.PurchaseAmount)/COUNT(DISTINCT c.CustomerID), 2) AS Avg_Revenue_Per_Customer
FROM transactions t
JOIN customers c ON t.CustomerID = c.CustomerID
GROUP BY c.Region
ORDER BY Avg_Revenue_Per_Customer DESC;

---Product Recall Rate (% of Transactions) - Shows severity of recall relative to product volume.
SELECT ProductPurchased,
       COUNT(*) AS Total_Transactions,
       SUM(CASE WHEN ProductRecalled = TRUE THEN 1 ELSE 0 END) AS Recall_Count,
       ROUND(SUM(CASE WHEN ProductRecalled = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Recall_Percentage
FROM transactions
GROUP BY ProductPurchased
ORDER BY Recall_Percentage DESC;

---SOCIAL MEDIA ENGAGEMENT & SENTIMENT ANALYSIS

---Sentiment Distribution -Helps us understand the volume of positive, neutral, and negative posts.
SELECT Sentiment, COUNT(*) AS Post_Count
FROM social_media
GROUP BY Sentiment
ORDER BY Post_Count DESC;


---Average Engagement by Sentiment - Determining which sentiment type drives higher user interaction.
SELECT Sentiment,
       ROUND(AVG(EngagementLikes), 2) AS Avg_Likes,
       ROUND(AVG(EngagementShares), 2) AS Avg_Shares,
       ROUND(AVG(EngagementComments), 2) AS Avg_Comments
FROM social_media
GROUP BY Sentiment
ORDER BY Sentiment;

---Platform-wise Post Volume - Identifying the platforms that are most active and useful for targeting PR and support teams.
SELECT Platform, COUNT(*) AS Total_Posts
FROM social_media
GROUP BY Platform
ORDER BY Total_Posts DESC;


---Influencer Activity and Reach - Measures potential influencer impact on brand perception.
SELECT 
  COUNT(*) AS Total_Posts,
  ROUND(AVG(UserFollowers), 2) AS Avg_Followers,
  ROUND(AVG(InfluencerScore), 2) AS Avg_Influencer_Score
FROM social_media
WHERE InfluencerScore >= 70;


Brand vs. Competitor Mentions -Useful for benchmarking brand visibility vs. competitors.
SELECT 
  COUNT(*) FILTER (WHERE BrandMention = TRUE) AS Brand_Mentions,
  COUNT(*) FILTER (WHERE CompetitorMention = TRUE) AS Competitor_Mentions
FROM social_media;


---Top 3 Mentioned Competitors
SELECT Competitor_x, COUNT(*) AS Mentions
FROM social_media
WHERE Competitor_x IS NOT NULL
GROUP BY Competitor_x
ORDER BY Mentions DESC
LIMIT 3;

---COMPLIANTS & CRISIS MANAGNMENT
---Monthly Crisis Trend - This reveals when crises spike over time.

SELECT DATE_TRUNC('month', CrisisEventTime) AS Month,
       COUNT(*) AS Crises
FROM social_media
WHERE CrisisEventTime IS NOT NULL
GROUP BY Month
ORDER BY Month;

---Resolution Status - This tracks how many issues were resolved.

SELECT ResolutionStatus, COUNT(*) AS Total_Incidents
FROM social_media
GROUP BY ResolutionStatus;

---Avg Crisis Response Time (in days) - Key KPI for support efficiency.

SELECT ROUND(AVG(FirstResponseTime::date - CrisisEventTime::date), 2) AS Avg_Response_Days
FROM social_media
WHERE CrisisEventTime IS NOT NULL AND FirstResponseTime IS NOT NULL;

---Customer Loyalty (NPS)
---NPS Response Distribution - This evaluates overall satisfaction and loyalty.

SELECT NPSResponse, COUNT(*) AS Count
FROM social_media
GROUP BY NPSResponse
ORDER BY NPSResponse;



