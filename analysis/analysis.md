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











