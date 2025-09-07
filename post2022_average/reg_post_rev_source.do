* load revenue file here

local flow_type REVENUE_real

rename `flow_type' Y

* classify LGU types
gen byte LGU = .
replace LGU = 1 if PT==0 & GT==0                 // Regions
replace LGU = 2 if PT==1                         // Land counties
replace LGU = 3 if PT==2                         // City counties
replace LGU = 4 if GT!=0 & PT==0                 // Municipalities

* organize the component names
gen comp = lower(COMPONENT)
replace comp = subinstr(comp, " ", "_", .)
replace comp = subinstr(comp, "-", "_", .)
replace comp = subinstr(comp, "/", "_", .)
drop COMPONENT
drop if comp == ""

egen id = group(WK PK GK), label

* add/remove 'comp' depending on need
* no comp = calculating total
* comp = need to choose a category below (uncomment)
collapse (sum) Y, by(YEAR QUARTER id LGU)

*collapse (sum) Y, by(YEAR QUARTER id LGU comp)
*keep if inlist(comp, "own_revenue")
* options: "pit","cit","grants","subsidies","own_revenue","eu_grants"

replace Y = Y / 1e6

* time index
gen tq = yq(YEAR, QUARTER)
format tq %tq

* post-2022 dummy
gen byte post = tq >= yq(2022,1)

* declare panel
xtset id tq

gen double lnY = ln(Y)

* count obs
tab LGU if lnY != .

xtreg lnY c.post#i.LGU, fe cluster(id)

