* load expenses file here

local flow_type EXPENSE_real

rename `flow_type' Y

* classify LGU types
gen byte LGU = .
replace LGU = 1 if PT==0 & GT==0                 // Regions
replace LGU = 2 if PT==1                         // Land counties
replace LGU = 3 if PT==2                         // City counties
replace LGU = 4 if GT!=0 & PT==0                 // Municipalities

* to carry out on just one LGU type, uncomment
*keep if LGU == 1

* organize category names
gen cat = lower(CATEGORY)
replace cat = subinstr(cat, " ", "_", .)
replace cat = subinstr(cat, "-", "_", .)
replace cat = subinstr(cat, "/", "_", .)
drop CATEGORY
drop if cat == ""


egen id = group(WK PK GK), label

collapse (sum) Y, by(YEAR QUARTER id LGU cat)

replace Y = Y / 1e6

* time index + post dummy
gen tq = yq(YEAR, QUARTER)
format tq %tq
gen byte post_t = tq >= yq(2022,1)

* Log outcome
gen double lnY = ln(Y)


/******************************************************************
* Per-category FE (lnY on post), collect results, and tornado plot
******************************************************************/

* -------- SETTINGS ----------
* 0 = plot raw log coefficients; 1 = plot percent change 100*(exp(b)-1)
local as_percent 1

levelsof cat, local(cats)

* Where to save results/figure
*local outdir "/."
*cap mkdir "`outdir'"
*local outdta "`outdir'/expenses_post_by_cat.dta"


* -------- COLLECT RESULTS ----------
tempfile results
capture postutil clear
postfile H str80 catname double b se ci_lo ci_hi N using `results', replace

foreach c of local cats {
	// sometimes there're so few observations of certain categories that you need to exclude them
	*if "`c'" == "municipal_economy_&_environment" continue
	
    preserve
	display "`c'"
        keep if cat == "`c'"
        quietly xtreg lnY post, fe vce(cluster id)

        * if 'post' is estimable, post results
        capture scalar b_ = _b[post]
        if (_rc==0) {
            scalar se_ = _se[post]
            scalar df_ = e(df_r)
            scalar tcrit_ = invttail(df_, 0.025)
            scalar lo_ = b_ - tcrit_*se_
            scalar hi_ = b_ + tcrit_*se_
            post H ("`c'") (b_) (se_) (lo_) (hi_) (e(N))
        }
    restore
}
postclose H

use `results', clear
order catname b se ci_lo ci_hi N

* -------- TRANSFORM (optional) ----------
* Create plotting variables (either log-points or percent)
gen double b_plot  = b
gen double lo_plot = ci_lo
gen double hi_plot = ci_hi
if `as_percent' {
    replace b_plot  = (exp(b)     - 1)
    replace lo_plot = (exp(ci_lo) - 1)
    replace hi_plot = (exp(ci_hi) - 1)
}

* -------- SORT & BAR LIMITS ----------
gsort -b_plot

* Tag top 3 and bottom 3
gen keepflag = 0
replace keepflag = 1 in 1/3                 // top 3
replace keepflag = 1 in -3/l                // bottom 3

* Keep only those
*keep if keepflag == 1

gsort -b_plot
gen order = _n

* bar endpoints (so negatives go left from 0; positives go right)
gen double bar_lo = cond(b_plot<0, b_plot, 0)
gen double bar_hi = cond(b_plot<0, 0,      b_plot)

replace catname = "Administration"             if catname=="administration"
replace catname = "Agriculture & hunting"      if catname=="agriculture_&_hunting"
replace catname = "Botanical & nature"         if catname=="botanical_zoological_gardens_&_nature"
replace catname = "Culture & heritage"         if catname=="culture_&_heritage"
replace catname = "Debt service"               if catname=="debt_service"
replace catname = "Youth development"          if catname=="education_&_childcare"
replace catname = "Education"                  if catname=="education_(general)"
replace catname = "Energy & utilities"         if catname=="energy_supply"
replace catname = "Family"                     if catname=="family"
replace catname = "Fishery"          	       if catname=="fishing_and_fishery"
replace catname = "Forestry"                   if catname=="forestry"
replace catname = "Health"                     if catname=="health_protection"
replace catname = "Higher education"           if catname=="higher_education"
replace catname = "Hotels & restaurants"       if catname=="hotels_and_restaurants"
replace catname = "Housing"                    if catname=="housing"
replace catname = "Manufacturing"              if catname=="industry"
replace catname = "IT"                         if catname=="it"
replace catname = "Judiciary"                  if catname=="judiciary"
replace catname = "Mining"                     if catname=="mining"
replace catname = "Municipal economy & environ."       if catname=="municipal_economy_&_environment"
replace catname = "Defense"           	       if catname=="national_defense"
replace catname = "Other social policy"        if catname=="other_social_policy"
replace catname = "Safety & fire"              if catname=="safety_&_fire"
replace catname = "Service activities"         if catname=="service_activities"
replace catname = "Settlements"                if catname=="settlements"
replace catname = "Social assistance"          if catname=="social_assistance"
replace catname = "Social insurance"           if catname=="social_insurance"
replace catname = "Sports"                     if catname=="sports"
replace catname = "Supreme authorities"        if catname=="supreme_authorities"
replace catname = "Tax revenues"               if catname=="tax_revenues_&_collection"
replace catname = "Tourism"                    if catname=="tourism"
replace catname = "Trade"                      if catname=="trade"
replace catname = "Transport & communications" if catname=="transport_&_comm."


* y-labels list
local ylbls
quietly forvalues i = 1/`=_N' {
    local nm = catname[`i']
    local ylbls `ylbls' `i' "`nm'"
}


* -------- PLOT (tornado with CI at bar end) ----------
local bw 0.65   // try 0.55–0.80 for more/less spacing

twoway ///
    (rbar bar_lo bar_hi order, horizontal fc(teal) lc(none) barwidth(`bw')) ///
    (rcap lo_plot hi_plot order, horizontal lc(gs4) lw(medthick)), ///
    yscale(reverse) ///
    ytitle("") /// 
    ylab(`ylbls', angle(0) labsize(medium) nogrid) ///
    xline(0, lpattern(solid) lcolor(gs8)) ///
    xlabel(, labsize(small) nogrid) ///
    legend(off) ///
    ysize(12) xsize(10) scale(0.6)
    //title("Post-2022 effect by spending category", size(medlarge)) ///
    //subtitle("lnY on post, FE; clustered by id", size(small))
    //note("Bars show effect size; whiskers = 95% CI. " ///
   //      + cond(`as_percent',"Values in % (100·(e^{β}-1)).","Values in log points (β)."), size(small)) ///
