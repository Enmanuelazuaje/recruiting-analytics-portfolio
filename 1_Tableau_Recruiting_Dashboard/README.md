# Tableau Dashboard — Sales, Vacancies & Marketing Performance

Interactive executive dashboard on **Tableau Public** for a remote staffing agency:
placements, monthly recurring revenue, recruiter leaderboard and marketing funnel
economics, with global date and department filters.

> **Live dashboard:** _link coming — published on Tableau Public_

## Views

- **KPI banner** — total placements, new MRR, fill rate %, avg time-to-fill
- **Monthly revenue trend** — MRR from filled vacancies over time
- **Vacancies by status** — Open / Filled / Cancelled per month
- **Time-to-fill by role** — where the bottlenecks are (sorted, colored by department)
- **Recruiter leaderboard** — revenue per recruiter, fill rate in tooltip
- **Cost per lead by channel** — paid channels benchmarked weekly
- **Marketing funnel** — leads → qualified → meetings → deals per channel

## Model

Three sources: `vacancies.csv` related to `recruiters.csv` on `recruiter_id`;
`marketing_leads.csv` as an independent source sharing the date axis.

Key calculated fields:

```
Time to Fill (days) = DATEDIFF('day', [Opened Date], [Filled Date])
Fill Rate           = SUM(IF [Status]='Filled' THEN 1 ELSE 0 END) / COUNT([Vacancy Id])
Cost per Lead       = SUM([Ad Spend Usd]) / SUM([Leads])
Lead → Deal %       = SUM([Deals Closed]) / SUM([Leads])
```
