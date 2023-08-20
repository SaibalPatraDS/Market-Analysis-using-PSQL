/* Marketing Data Analysis */

SELECT *
FROM marketing.ca
LIMIT 100;

SELECT DISTINCT EXTRACT(YEAR FROM date_served) AS year
FROM marketing.ca;

SELECT DISTINCT variant
FROM marketing.ca;

/*
1. Conversion Rate Analysis:
Question: What is the overall conversion rate for the marketing campaign based on the data provided?

2. Marketing Channel Effectiveness:
Question: Which marketing channels in the dataset have the highest and lowest conversion rates?

3. A/B Testing:
Question: Based on the data, did the "personalization" variant have a higher conversion rate than the "non-personalization" variant?

4. Retention Analysis:
Question: Can we determine the retention rate based on the provided data? 
          How does it vary by subscribing channel and language preferred?
		  
5. Churn Analysis:
Question: Are there any patterns in user cancellations (churn) based on age group or language preference from the data provided?

6. Time Series Analysis:
Question: How has the conversion rate changed over time based on the data, if at all?

7. Language Preference Impact:
Question: Is there evidence in the data that displaying content in a user's preferred language impacts conversion rates positively?

8. Funnel Analysis:
Question: Can we identify where users drop off in the conversion funnel based on the data?

9. Calculate Average Time to Cancel:
Question: What is the average time it takes for users to cancel their subscription after subscribing?

10. Calculate Cumulative Conversions:
Question: Create a cumulative sum of conversions over time to visualize how they accumulate.
*/



/* Solution */

/*
1. Conversion Rate Analysis:
Question: What is the overall conversion rate for the marketing campaign based on the data provided?
*/

SELECT ROUND(converted_customers::NUMERIC/total_customers::NUMERIC * 100.0, 2) || ' %' AS conversion_rate
FROM (
	SELECT COUNT(*) AS total_customers,
		   SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END) AS converted_customers
	FROM marketing.ca) x;



/* Bonus */

SELECT EXTRACT(DAY FROM date_served) AS day,
       EXTRACT(YEAR FROM date_served) AS year,
       SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END) AS converted_customers,
	   COUNT(*) AS customers,
	   ROUND(100 * SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END)::NUMERIC/COUNT(*), 2) AS conversion_rate
FROM marketing.ca
WHERE date_served IS NOT NULL
GROUP BY year,day
ORDER BY day;



/*
2. Marketing Channel Effectiveness:
Question: Which marketing channels in the dataset have the highest and lowest conversion rates?
*/
WITH marketing_channels_rate AS (
	SELECT marketing_channel,
		   SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END) AS converted_customer,
		   COUNT(*) AS total_customers
	FROM marketing.ca
	WHERE marketing_channel IS NOT NULL
	GROUP BY marketing_channel),
conversion_rate AS(
	SELECT marketing_channel,
		   ROUND(100.0 * converted_customer/total_customers , 2) AS conversion_rate
	FROM marketing_channels_rate
	ORDER BY conversion_rate DESC)
	
SELECT marketing_channel AS highest_marketing_channel
FROM conversion_rate
WHERE conversion_rate = (SELECT MAX(conversion_rate)
								    FROM conversion_rate)
UNION 

SELECT marketing_channel AS minimalist_marketing_channel
FROM conversion_rate
WHERE conversion_rate = (SELECT MIN(conversion_rate)
								    FROM conversion_rate);



/*
3. A/B Testing:
Question: Based on the data, did the "personalization" variant have a higher conversion rate 
          than the "non-personalization" variant?
*/

SELECT variant AS ads_technique,
       ROUND(100.0 * converted_customers/total_customers, 2) AS conversion_rate
FROM (
	SELECT variant,
		   COUNT(*) AS total_customers,
		   SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END) AS converted_customers
	FROM marketing.ca
	GROUP BY variant) x
ORDER BY conversion_rate DESC;




/*
4. Retention Analysis:
Question: Can we determine the retention rate based on the provided data? 
          How does it vary by subscribing channel and language preferred?
*/

--- Retention based on subscribing channel

SELECT subscribing_channel,
       ROUND(100.0 * retention/total_customer, 2) AS retention_rate
FROM (
	SELECT subscribing_channel,
		   COUNT(is_retained) AS total_customer,
		   SUM(CASE WHEN is_retained = 'TRUE' THEN 1 ELSE 0 END) AS retention
	FROM marketing.ca
	WHERE subscribing_channel IS NOT NULL
	GROUP BY subscribing_channel) x
ORDER BY retention_rate DESC;



--- Retention based on language preferred

SELECT language,
       ROUND(100.0 * retention/total_customers, 2) AS retention_rate
FROM (
	SELECT language_preferred AS language,
	--        SUM(CASE WHEN language_preferred = language_displayed THEN 1 ELSE 0 END) AS language_variation,
		   COUNT(language_preferred) AS total_customers,
		   SUM(CASE WHEN is_retained = 'TRUE' THEN 1 ELSE 0 END) retention 
	FROM marketing.ca
	GROUP BY language_preferred) x
ORDER BY retention_rate DESC;

-- IS language_displayed even matters?

SELECT -- language_displayed,
--        language_preferred,
--        language_displayed = language_preferred as result,
       is_retained,
	   COUNT(is_retained) as retention
FROM marketing.ca
WHERE language_displayed = language_preferred IS false AND is_retained IS NOT NULL
GROUP BY is_retained;


--- Retention based on language displayed
SELECT language,
       ROUND(100.0 * retention/total_customers, 2) AS retention_rate
FROM (
	SELECT language_displayed AS language,
	--        SUM(CASE WHEN language_preferred = language_displayed THEN 1 ELSE 0 END) AS language_variation,
		   COUNT(language_displayed) AS total_customers,
		   SUM(CASE WHEN is_retained = 'TRUE' THEN 1 ELSE 0 END) retention 
	FROM marketing.ca
	GROUP BY language_displayed) x
ORDER BY retention_rate DESC;



/*
Correlation between retention by language preferred and subscribing channel
*/

WITH subs_channel AS (
	SELECT subscribing_channel,
       ROUND(100.0 * retention/total_customer, 2) AS subscribing_retention_rate
	FROM (
		SELECT subscribing_channel,
			   COUNT(is_retained) AS total_customer,
			   SUM(CASE WHEN is_retained = 'TRUE' THEN 1 ELSE 0 END) AS retention
		FROM marketing.ca
		WHERE subscribing_channel IS NOT NULL
		GROUP BY subscribing_channel) x
	ORDER BY subscribing_retention_rate DESC
),
language_preference AS(
	SELECT language,
       ROUND(100.0 * retention/total_customers, 2) AS language_retention_rate
	FROM (
		SELECT language_preferred AS language,
		--        SUM(CASE WHEN language_preferred = language_displayed THEN 1 ELSE 0 END) AS language_variation,
			   COUNT(language_preferred) AS total_customers,
			   SUM(CASE WHEN is_retained = 'TRUE' THEN 1 ELSE 0 END) retention 
		FROM marketing.ca
		GROUP BY language_preferred) x
	ORDER BY language_retention_rate DESC
)

SELECT CORR(subscribing_retention_rate, language_retention_rate) AS correlation
FROM subs_channel,language_preference;




/*
5. Churn Analysis:
Question: Are there any patterns in user cancellations (churn) based on age group or 
          language preference from the data provided?
*/

WITH churn AS (
	SELECT age_group,
		   language_preferred,
		   ROUND(100.0 * churn/total_customer, 2) AS churn_rate,
		   DENSE_RANK() OVER(PARTITION BY age_group ORDER BY 100.0 * churn/total_customer DESC) AS drnk
	FROM (
		SELECT age_group,
			   language_preferred,
			   SUM(CASE WHEN date_canceled IS NOT NULL THEN 1 ELSE 0 END) AS churn,
			   COUNT(*) AS total_customer
		FROM marketing.ca
		GROUP BY age_group, language_preferred) x)

SELECT age_group,
       language_preferred,
	   churn_rate
FROM churn
WHERE drnk = 1;



/*
7. Language Preference Impact:
Question: Is there evidence in the data that displaying content in a user's preferred language 
          impacts conversion rates positively?
*/

-- SELECT language_displayed,
--        SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END) AS converted,
-- 	   COUNT(*) AS total_customer
-- FROM marketing.ca
-- GROUP BY language_displayed;



WITH impact AS(
	SELECT language_preferred,
		   language_displayed,	
		   SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END) AS converted,
		   COUNT(*) AS total_customer,
		   ROUND(100.0 * SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END)/COUNT(*), 2) AS conversion_rate
	FROM marketing.ca
	GROUP BY language_preferred, language_displayed)

SELECT 'preferred language' AS type,
       ROUND(AVG(conversion_rate), 2) AS avg_conversion_rate
FROM impact
WHERE language_preferred = language_displayed
UNION
SELECT 'displayed language' AS type,
       ROUND(AVG(conversion_rate), 2) AS avg_conversion_rate
FROM impact
WHERE language_preferred != language_displayed
ORDER BY avg_conversion_rate DESC;



/*
8. Funnel Analysis:
Question: Can we identify where users drop off in the conversion funnel based on the data?
*/


WITH funnel_steps AS(
	SELECT SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END) AS subscribed_users,
		   SUM(CASE WHEN is_retained = 'TRUE' THEN 1 ELSE 0 END) AS retained_users,
		   COUNT(*) AS total_users
	FROM marketing.ca
	WHERE marketing_channel IS NOT NULL OR converted IS NOT NULL AND is_retained IS NOT NULL)

SELECT 'Viewed Ad' AS steps,
       COUNT(*) AS users,
	   ROUND(100.0 * COUNT(*)/COUNT(user_id), 2) AS percentage 
FROM marketing.ca
WHERE marketing_channel IS NOT NULL

UNION ALL

SELECT 'Subscribed' AS steps,
       subscribed_users AS users,
	   ROUND(100.0 * subscribed_users/total_users, 2) AS percentage
FROM funnel_steps

UNION ALL

SELECT 'Retained' AS steps,
       retained_users AS users,
	   ROUND(100.0 * retained_users/total_users, 2) AS percentage
FROM funnel_steps;




/*
9. Calculate Average Time to Cancel:
Question: What is the average time it takes for users to cancel their subscription after subscribing?
*/


SELECT age_group, 
       ROUND(AVG(date_canceled - date_subscribed),0) AS days_before_cancelation
-- 	   AVG(AGE(date_canceled, date_subscribed)) AS col1
FROM marketing.ca
WHERE date_canceled >= date_subscribed
GROUP BY age_group
ORDER BY days_before_cancelation DESC;



/*
10. Calculate Cumulative Conversions:
Question: Create a cumulative sum of conversions over time to visualize how they accumulate.
*/

SELECT DISTINCT date_served,
       SUM(CASE WHEN converted = 'TRUE' THEN 1
		        ELSE 0
		  END) OVER(ORDER BY date_served)AS subcribers
FROM marketing.ca
WHERE date_served IS NOT NULL
ORDER BY date_served;
