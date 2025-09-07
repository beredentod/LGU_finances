* load expenses file here

local flow_type EXPENSE_real

rename `flow_type' Y

* classify LGU types
gen byte LGU = .
replace LGU = 1 if PT==0 & GT==0                 // Regions
replace LGU = 2 if PT==1                         // Land counties
replace LGU = 3 if PT==2                         // City counties
replace LGU = 4 if GT!=0 & PT==0                 // Municipalities

* organize the group names
gen gr_id = lower(GROUP)
replace gr_id = subinstr(gr_id, " ", "_", .)
replace gr_id = subinstr(gr_id, "-", "_", .)
replace gr_id = subinstr(gr_id, "/", "_", .)
replace gr_id = "benefits"      if gr_id == "benefits_for_individuals"
replace gr_id = "fin_oblig"     if gr_id == "financial_obligations"
replace gr_id = "grants"        if gr_id == "grants_for_current_tasks"
replace gr_id = "statutory"     if gr_id == "statutory_tasks"
drop GROUP
drop if gr_id == ""

egen id = group(WK PK GK), label

* add/remove 'gr_id' depending on need
* no gr_id = calculating total
* gr_id = need to choose a category below (uncomment)
collapse (sum) Y, by(YEAR QUARTER id LGU)

*collapse (sum) Y, by(YEAR QUARTER id LGU gr_id)
*keep if inlist(gr_id, "salaries")
* options: "benefits", "fin_oblig", "grants", "investments", "salaries", "statutory"

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

