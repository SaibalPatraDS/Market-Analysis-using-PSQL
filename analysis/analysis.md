# Marketing Data Analysis 

## Overview of the Dataset

The dataset used in this marketing analysis project is a comprehensive collection of user interactions and marketing campaign data. It is stored in a PostgreSQL database and comprises multiple tables, including 'marketing.ca,' which is the primary table of interest. Here are some key characteristics of the dataset:

1. **Data Diversity**: The dataset covers a wide range of variables, including user demographics (such as age groups), marketing channel information, campaign variants, conversion status, language preferences, and subscription details.

2. **Temporal Aspect**: It spans over a period of time, with timestamps for each interaction, allowing for time-based analysis, trend identification, and cohort analysis.

3. **Conversion Tracking**: It includes a crucial metric for marketing analysis—conversion. Users are marked as 'converted' or 'not converted,' providing insights into the effectiveness of marketing strategies.

4. **Multilingual Support**: Language preferences are recorded, enabling the assessment of the impact of content displayed in a user's preferred language on conversion rates.

5. **Cancellation Data**: Information about user cancellations and retention status is available, facilitating churn analysis and user retention rate calculations.

6. **Marketing Channels**: Data about various marketing channels through which users were exposed to campaigns is included, aiding in channel effectiveness assessment.

This rich and diverse dataset serves as the foundation for conducting in-depth marketing analysis, allowing for the exploration of conversion patterns, user behaviors, and the impact of different factors on marketing campaign performance.


## Analysis 

###  1. Conversion Rate Analysis: 
     Question: What is the overall conversion rate for the marketing campaign based on the data provided?

     
```sql
SELECT ROUND(converted_customers::NUMERIC/total_customers::NUMERIC * 100.0, 2) || ' %' AS conversion_rate
FROM (
	SELECT COUNT(*) AS total_customers,
		   SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END) AS converted_customers
	FROM marketing.ca) x;
```
![image](https://github.com/SaibalPatraDS/Market-Analysis-using-PSQL/assets/102281722/efb44c84-303f-4bc9-aab1-55cf7e2e2c5a)


**More Insights**

```sql
SELECT EXTRACT(DAY FROM date_served) AS day,
       EXTRACT(YEAR FROM date_served) AS year,
       SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END) AS converted_customers,
	   COUNT(*) AS customers,
	   ROUND(100 * SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END)::NUMERIC/COUNT(*), 2) AS conversion_rate
FROM marketing.ca
WHERE date_served IS NOT NULL
GROUP BY year,day
ORDER BY day;
```

using the above quesry, we can observe the trend in conversion `year` wise as well as `day` wise. 

![query-1](https://github.com/SaibalPatraDS/Market-Analysis-using-PSQL/assets/102281722/6b442713-8284-4e46-97b2-7ac05718f0cf)

-----------------------------------------------------------------
---------------------------------------------------------

### 2. Marketing Channel Effectiveness:
    Question: Which marketing channels in the dataset have the highest and lowest conversion rates?

```sql
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
	ORDER BY conversion_rate DESC),
ranking AS(
	SELECT marketing_channel,
		   RANK() OVER(ORDER BY conversion_rate DESC) AS rnk
	FROM conversion_rate)

SELECT marketing_channel,
       CASE WHEN rnk = 1 THEN 'Highest Marketing Channel'
            WHEN rnk = 5 THEN 'Lowest Marketing Channel' END AS channel_types
FROM ranking
WHERE CASE WHEN rnk = 1 THEN 'Highest Marketing Channel'
            WHEN rnk = 5 THEN 'Lowest Marketing Channel' END IS NOT NULL;
```

This SQL query calculates and ranks marketing channels by conversion rate, then identifies the highest and fifth-highest performing channels, categorizing them accordingly as 'Highest Marketing Channel' and 'Lowest Marketing Channel' for further analysis.


![Screenshot 2023-08-20 125132](https://github.com/SaibalPatraDS/Market-Analysis-using-PSQL/assets/102281722/7362f632-340f-4d72-aeba-e7c79e4e991c)

-----------------------------------------------------------------
-----------------------------------------------------------------

### 3. A/B Testing:
    Question: Based on the data, did the "personalization" variant have a higher conversion rate 
          than the "non-personalization" variant?

```sql
SELECT variant AS ads_technique,
       ROUND(100.0 * converted_customers/total_customers, 2) AS conversion_rate
FROM (
	SELECT variant,
		   COUNT(*) AS total_customers,
		   SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END) AS converted_customers
	FROM marketing.ca
	GROUP BY variant) x
ORDER BY conversion_rate DESC;
```

This SQL query calculates the conversion rates for different advertising techniques (variants) by dividing the number of converted customers by the total number of customers in the dataset. It presents the results in descending order of conversion rates, providing insights into the effectiveness of each advertising variant.

![Screenshot 2023-08-20 125404](https://github.com/SaibalPatraDS/Market-Analysis-using-PSQL/assets/102281722/dcd343fe-cb29-4b41-9142-6c3880a93259)

-----------------------------------------------------------------
-----------------------------------------------------------------

### 4. Retention Analysis:
	Question: Can we determine the retention rate based on the provided data? 
          How does it vary by subscribing channel and language preferred?

```sql
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
```
This SQL code calculates the retention rates for different subscribing channels by dividing the number of retained customers by the total number of customers who subscribed through each channel. The results are presented in descending order of retention rates, providing insights into the effectiveness of each subscribing channel in retaining customers.


![query-4](https://github.com/SaibalPatraDS/Market-Analysis-using-PSQL/assets/102281722/9dba0945-8695-4aa4-b8fb-f8ef6ae3f378)

-----------------------------------------------------------------

```sql
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
```

This SQL query calculates the retention rates based on preferred language, comparing the language preferred by users with the language displayed. It computes the retention rate by dividing the number of retained customers by the total number of customers who preferred each language. The results are sorted in descending order of retention rates, providing insights into the impact of language preferences on customer retention.


![Screenshot 2023-08-20 130314](https://github.com/SaibalPatraDS/Market-Analysis-using-PSQL/assets/102281722/774aad14-626d-49bc-a976-31b046fc921f)

![query-4 2](https://github.com/SaibalPatraDS/Market-Analysis-using-PSQL/assets/102281722/7c043b02-bda5-4161-bf48-43d5d5ca0a12)

-----------------------------------------------------------------

```sql
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
```

This SQL query calculates the retention rates based on the language displayed to users. It compares the displayed language with user preferences, then computes the retention rate by dividing the number of retained customers by the total number of customers for each displayed language. The results are sorted in descending order of retention rates, providing insights into how displaying content in different languages impacts customer retention.

![Screenshot 2023-08-20 130212](https://github.com/SaibalPatraDS/Market-Analysis-using-PSQL/assets/102281722/fe292858-f63e-4a32-b7ed-aecc27258378)

![query-4 3](https://github.com/SaibalPatraDS/Market-Analysis-using-PSQL/assets/102281722/7a5c8cf4-1a75-4a13-96e9-dec844e1b70f)



**Conclusion** --> We can clearly observed `language preference` doesn't matter that much for this customers. There is huge jump in `conversion rate` when the marketing process doesn't market in preferred language. 


----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------


### 5. Churn Analysis:
	Question: Are there any patterns in user cancellations (churn) based on age group or 
          language preference from the data provided?

```sql
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
```

This SQL code calculates the churn rates for different age groups and preferred languages. It ranks these groups by churn rate using dense ranking within each age group. The final result selects the age group, preferred language, and churn rate for the top-ranking group with the highest churn rate within each age group. This query provides insights into which age group and language preference combination has the highest churn rate in the dataset.

![Screenshot 2023-08-20 131253](https://github.com/SaibalPatraDS/Market-Analysis-using-PSQL/assets/102281722/f80bb8a7-402f-494c-8c28-fd3bf689df98)


As per the result, we can comment that there is more cancellation done by people whose preferred language is `German`. 


----------------------------------------------------------------------------------------------------------------------------------



 -----> **taking `age-group` in consideration only**

```sql
WITH churn AS (
	SELECT age_group,
-- 		   language_preferred,
		   ROUND(100.0 * churn/total_customer, 2) AS churn_rate,
		   DENSE_RANK() OVER(ORDER BY 100.0 * churn/total_customer DESC) AS drnk
	FROM (
		SELECT age_group,
-- 			   language_preferred,
			   SUM(CASE WHEN date_canceled IS NOT NULL THEN 1 ELSE 0 END) AS churn,
			   COUNT(*) AS total_customer
		FROM marketing.ca
		GROUP BY age_group) x)

SELECT age_group,
--        language_preferred,
	   churn_rate
FROM churn
WHERE drnk = 1;
```

This SQL code calculates the churn rates for different age groups. It ranks these age groups by churn rate using dense ranking, considering all age groups collectively. The final result selects the age group with the highest churn rate, providing insights into which age group experiences the highest churn in the dataset. The `language_preferred` column appears to be commented out and not used in this specific query.

![image](https://github.com/SaibalPatraDS/Market-Analysis-using-PSQL/assets/102281722/195d2e78-3d7c-46e5-b7b9-af026edc8cad)

----------------------------------------------------------------------------------------------------------------------------------



-----> **Taking `preferred-language` into consideration only

```sql
WITH churn AS (
	SELECT --age_group,
		   language_preferred,
		   ROUND(100.0 * churn/total_customer, 2) AS churn_rate,
		   DENSE_RANK() OVER(ORDER BY 100.0 * churn/total_customer DESC) AS drnk
	FROM (
		SELECT --age_group,
			   language_preferred,
			   SUM(CASE WHEN date_canceled IS NOT NULL THEN 1 ELSE 0 END) AS churn,
			   COUNT(*) AS total_customer
		FROM marketing.ca
		GROUP BY language_preferred) x)

SELECT --age_group,
       language_preferred,
	   churn_rate
FROM churn
WHERE drnk = 1;
```

This SQL code calculates the churn rates for different language preferences. It ranks these language preferences by churn rate using dense ranking, considering all language preferences collectively. The final result selects the language preference with the highest churn rate, providing insights into which language preference has the highest churn rate in the dataset. The `age_group` column appears to be commented out and not used in this specific query.

![image](https://github.com/SaibalPatraDS/Market-Analysis-using-PSQL/assets/102281722/6f43ed66-83b6-4a66-bc2a-5107a6a2e321)

**Conclusion** - `German` preferred users are mostly cancelling the subscriptions.



----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------


### 7. Language Preference Impact:
      Question: Is there evidence in the data that displaying content in a user's preferred language 
                impacts conversion rates positively?


```sql
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
```

This SQL code calculates and compares the average conversion rates based on whether users preferred the displayed language ('preferred language') or encountered content in a different language ('displayed language'). It calculates the conversion rates for both scenarios, then presents the results in descending order of average conversion rates. This query helps evaluate the impact of matching user preferences with displayed content language on conversion rates, providing insights into the effectiveness of language personalization in marketing campaigns.


![image](https://github.com/SaibalPatraDS/Market-Analysis-using-PSQL/assets/102281722/e80ec9ed-fd7a-4390-9d92-0ca1e2f7b696)

**Conclusion** - No of subscribers **`increases`** when the ads are run in `preferred language` over random language.


----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------


### 8. Funnel Analysis:
       Question: Can we identify where users drop off in the conversion funnel based on the data?


```sql
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
```

This SQL code calculates and presents a marketing conversion funnel with three steps: 'Viewed Ad,' 'Subscribed,' and 'Retained.' It calculates the number of users at each step and the percentage of users who progress to the next step. The query first aggregates user data related to these steps, then calculates the percentage for each step. The results provide insights into user progression through the marketing funnel, helping assess the effectiveness of each conversion step in the user journey.

![image](https://github.com/SaibalPatraDS/Market-Analysis-using-PSQL/assets/102281722/151888ce-935f-4932-bd18-de743e540282)


----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------


### 9. Calculate Average Time to Cancel:
      Question: What is the average time it takes for users to cancel their subscription after subscribing?

```sql
SELECT age_group, 
       ROUND(AVG(date_canceled - date_subscribed),0) AS days_before_cancelation
-- 	   AVG(AGE(date_canceled, date_subscribed)) AS col1
FROM marketing.ca
WHERE date_canceled >= date_subscribed
GROUP BY age_group
ORDER BY days_before_cancelation DESC;
```


This SQL query calculates the average number of days it takes for users in different age groups to cancel their subscriptions after subscribing. It filters for cases where the cancellation date is greater than or equal to the subscription date, groups the data by age group, and then calculates the average number of days before cancellation. The results are presented in descending order of days before cancellation for each age group. This analysis provides insights into the subscription duration patterns among different age groups.



![query-9](https://github.com/SaibalPatraDS/Market-Analysis-using-PSQL/assets/102281722/450aa096-7ff7-4cde-bb0e-ae1a7c27c610)


----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------


### 10. Calculate Cumulative Conversions:
	Question: Create a cumulative sum of conversions over time to visualize how they accumulate.
  
```sql
SELECT DISTINCT date_served,
       SUM(CASE WHEN converted = 'TRUE' THEN 1
		        ELSE 0
		  END) OVER(ORDER BY date_served)AS subcribers
FROM marketing.ca
WHERE date_served IS NOT NULL
ORDER BY date_served;
```

This SQL query retrieves distinct dates when marketing campaigns were served (`date_served`) and calculates the cumulative number of subscribers (users who converted) over time. The `SUM` function with the `OVER` clause is used to calculate the cumulative sum of subscribers ordered by the `date_served`. The results provide a time series view of subscriber growth, showing how the number of subscribers increases over the specified period.


![query-10](https://github.com/SaibalPatraDS/Market-Analysis-using-PSQL/assets/102281722/0d4bb3ce-17b7-4e96-b713-5e84a26972d8)

**Conclusion** - The growth in the `subscribers` count can be clearly seen.
