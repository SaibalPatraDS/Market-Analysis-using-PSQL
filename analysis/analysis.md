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



















