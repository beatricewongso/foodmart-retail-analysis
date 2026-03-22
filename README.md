# foodmart-retail-analysis
## Overview
Analysis of Foodmart retail dataset, which covers transaction across 13 stores operating in USA along with other fact tables such as customer, store, products. Throughout the project, Python was used to standardize and ensure consistency during data preparation, while SQL was used to extract insights covering financial performance, customer behavior, membership tiers, and store formats which was then visualized with PowerBI. 

## Project Structure
- gen_metric.sql
  - fin_metric.sql
  - vol_metrics.sql
  - geo_metric.sql
  - time_metrics.sql
    - time_bound.sql
  - cust_metric.sql
    - member_tier_segment.sql
    - member_tier_deep_dive.sql
  - product_metrics.sql
    - product_deep_dive.sql
  - store_type_segment.sql
    - store_type_deep_dive.sql


## Key Findings
### Financial Performance
- ~60% profit margin — well above the retail norm of 20–50%; the business keeps 60 cents of every dollar spent
- 247% average markup with margins holding steady across all months and store types — never discounting through slow periods

### Customer Behavior
- Customers return 3.68 times on average and buy 13 items per visit — habitual, purposeful shoppers
- 98% retention rate once a customer makes their first purchase — but 46% of registered members have never bought anything, making first-purchase conversion the biggest growth lever available

### Membership Tiers
- The tier system doesn't reflect actual customer value — the top customer by every metric holds a Bronze card
- Golden members are the most valuable individually but only 12% of the base; Silver is the worst performing tier across every metric and the smallest tier despite not being the highest
- Active rates and margins are nearly identical across all tiers — the program drives no differentiated behavior

### Store Types
- Supermarket generates 56% of total revenue and ranks first every single month
- Gourmet Supermarket more than doubles its revenue across the year — the format with the most growth momentum
- Small Grocery is flat all year but carries the highest profit margin — a stable, efficient convenience format
- Year-end surge is driven by Supermarket on volume and Gourmet on value

### Time-Based Performance
- Predictable annual cycle — slow start, mid-year dip (months 4–7), strong finish in months 11–12
- On a per day basis, weekends are only 7–8% busier per day than weekdays — well below the 30–50% premium typical in retail; the business runs on habitual weekday shoppers

### Product Performance
- 99.94% of products and 100% of brands sold at least one unit across the year
- Products that sell the most carry below-average margins; slow movers carry above-average margins — sourcing cost is the primary margin driver
- Two exceptions break this pattern: Special Wheat Puffs and Big Time Ice Cream (low fat & recyclable) — both high volume and above-average margin
- 56% recyclable and 35% low-fat in 1997, before these became mainstream retail priorities

### Red Flags
- Tier system not working; card levels don't reflect actual customer value
- Conversion problem:  46% of registered members have never purchased despite a 98% retention rate once they do
- 323 out of 365 active days: 42 days with zero transactions across all 13 stores 
- Geographic inconsistency — fact table includes Canada and Mexico but all transactions are USA only

#### Notes
- All data is from 1997 
- Revenue and cost figures are in USD
- This analysis covers USA stores only
