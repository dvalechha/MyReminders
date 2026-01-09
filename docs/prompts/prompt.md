# Role: Flutter Logic Fix

**Task:**
Sync the Bar Chart data with the Total Summary.

**Issue:**
The chart visualizes a value of ~$200 for "Jan", but the "Total Monthly Spend" variable is $1082.70.

**Action:**
Update the `BarChartGroupData` generation for the current month.
Ensure the `toY` value of the rod uses the `totalMonthlySpend` variable (or the sum of all active subscriptions) so the bar height visually reflects the total shown in the header.