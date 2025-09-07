* load expenses file

local expense_type EXPENSE_real

rename `expense_type' Y

* organize group names
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

collapse (sum) Y, by(YEAR QUARTER gr_id id)
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
levelsof gr_id, local(GROUPS)
levelsof id,    local(IDS)

foreach g of local GROUPS {
    foreach i of local IDS {
        quietly count if gr_id == "`g'" & id == `i' & YEAR <= 2021
        if (r(N) >= 6) {
            regress Y i.QUARTER c.yearq_id ///
                if gr_id == "`g'" & id == `i' & YEAR <= 2021
            tempvar ytmp
            predict double `ytmp' if gr_id == "`g'" & id == `i', xb
            replace yhat = `ytmp' if gr_id == "`g'" & id == `i'
            drop `ytmp'
        }
    }
}

replace resid = Y - yhat
