* load revenue / expenditure file here

local flow_type REVENUE_real

collapse (sum) `flow_type', by(YEAR QUARTER COMPONENT)

replace `flow_type' = `flow_type' / 1e9

rename `flow_type' Y

gen comp = lower(COMPONENT)
replace comp = subinstr(comp, " ", "_", .)
replace comp = subinstr(comp, "-", "_", .)
replace comp = subinstr(comp, "/", "_", .)

drop COMPONENT

drop if comp == ""

reshape wide Y, i(YEAR QUARTER) j(comp) string

gen str4 yearq = string(YEAR) + "Q" + string(QUARTER)

order yearq YEAR QUARTER Y*
encode yearq, gen(yearq_id)
sort YEAR QUARTER

collapse (sum) Ypit Ycit Ygrants Yeu_grants Ysubsidies Yown_revenue, by(YEAR)

   
* === Stacked bar char - aggregate over each year === 

label define yearqlab 1 "19Q1" 2 "19Q2" 3 "19Q3" 4 "19Q4" ///
    5 "20Q1" 6 "20Q2" 7 "20Q3" 8 "20Q4" ///
    9 "21Q1" 10 "21Q2" 11 "21Q3" 12 "21Q4" ///
    13 "22Q1" 14 "22Q2" 15 "22Q3" 16 "22Q4" ///
    17 "23Q1" 18 "23Q2" 19 "23Q3" 20 "23Q4" ///
    21 "24Q1" 22 "24Q2" 23 "24Q3" 24 "24Q4"
label values yearq_id yearqlab

graph bar Ypit Ycit Ygrants Yeu_grants Ysubsidies Yown_revenue, ///
    stack ///
    over(YEAR, label(angle(0))) ///
    ytitle("Revenue components (bn PLN)") ///
    ylabel(, nogrid) ///
    bar(1, color(navy)) ///
    bar(2, color(gs8)) ///
    bar(3, color(red)) ///
    bar(4, color(green)) ///
    bar(5, color(orange)) ///
    bar(6, color(black)) ///
    legend(order(1 "PIT" 2 "CIT" 3 "Targeted grants" 4 "EU grants" 5 "Subsidies" 6 "Own revenue") ///
           rows(2) position(6))
