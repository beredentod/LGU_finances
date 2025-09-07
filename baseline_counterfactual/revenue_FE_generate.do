* load revenue file

local expense_type REVENUE_real

rename `expense_type' Y

gen comp = lower(COMPONENT)
replace comp = subinstr(comp, " ", "_", .)
replace comp = subinstr(comp, "-", "_", .)
replace comp = subinstr(comp, "/", "_", .)
drop COMPONENT
drop if comp == ""

egen id = group(WK PK GK), label

collapse (sum) Y, by(YEAR QUARTER comp id)
replace Y = Y / 1e6

* time index
gen tq = yq(YEAR, QUARTER)
format tq %tq
sort tq
egen yearq_id = group(tq)   // linear time trend

* Ensure target vars exist
cap drop yhat resid
gen double yhat  = .
gen double resid = .

* Get groups
levelsof comp, local(COMPS)
levelsof id,    local(IDS)

foreach g of local COMPS {
    foreach i of local IDS {
        quietly count if comp == "`g'" & id == `i' & YEAR <= 2021
        if (r(N) >= 6) {
            regress Y i.QUARTER c.yearq_id ///
                if comp == "`g'" & id == `i' & YEAR <= 2021
            tempvar ytmp
            predict double `ytmp' if comp == "`g'" & id == `i', xb
            replace yhat = `ytmp' if comp == "`g'" & id == `i'
            drop `ytmp'
        }
    }
}

replace resid = Y - yhat
