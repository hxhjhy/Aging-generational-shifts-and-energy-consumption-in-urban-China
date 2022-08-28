
clear
set more off
global log "$figures"
global output "$figures"
*capture log close _all


log using "${log}populating aging.log",replace
use $cuhs_data.dta, clear


*define cohort
gen birthyr = year - h_age
keep if h_age <= 80 & h_age >= 30
gen cohort5 = birthyr 
recode cohort5 (1920/1924=1) (1925/1929=2) (1930/1934=3)(1935/1939=4) (1940/1944=5) (1945/1949=6) (1950/1954=7) (1955/1959=8) (1960/1964=9) (1965/1969=10)(1970/1974=11)(1975/1979=12)(1980/1984=13)(1985/1990=14)

tab h_cohort5,m
tab h_age,m
tab year,m
drop if cohort5 > 14


*Data for Figure 1
preserve
collapse q_ele h_age,by(year h_cohort5)
forvalues i=1/14{
lowess q_total h_age if h_cohort5 == `i', gen(q_ele`i') nograph
lowess q_ele  h_age if h_cohort5 == `i', gen(q_ele`i') nograph
lowess q_gas  h_age if h_cohort5 == `i', gen(q_ele`i') nograph
lowess q_coal h_age if h_cohort5 == `i', gen(q_ele`i') nograph
}
restore


*Data for Figure 2

global factor "q_coal q_gas q_ele h_inc h_education h_area h_size h_job hdd cdd"
global var "h_inc h_education h_area h_size h_job hdd cdd"
global energy_type "h_inc h_education h_area h_size h_job hdd cdd"

collapse $factor, by(h_cohort5 year)

gen lncoal = ln(q_coal)
gen lngas = ln(q_gas)
gen lnele = ln(q_ele)
gen lninc = ln(h_inc)
gen lnhdd = ln(hdd)
gen lncdd = ln(cdd)

foreach k of global energy_type{

apcd lnele $var, age(h_age) period(year)

mat B = e(b)
mat SE = e(V)

// data for cohort effects
frame create new 
frame change new
set obs 14
gen h_cohort = _n
global ic= 1
gen coheff = 0 
gen cohef_lci = 0
gen cohef_uci = 0

cap program drop doit
program def doit
        while $ic <= 14 {
        replace coheff= B[1,$ic + 15] if h_cohort ==$ic
		replace cohef_uci = B[1,$ic + 15] + invttail(e(df),0.025)*sqrt(SE[$ic + 15, $ic + 15]) if h_cohort ==$ic
		replace cohef_lci = B[1,$ic + 15] - invttail(e(df),0.025)*sqrt(SE[$ic + 15 , $ic + 15]) if h_cohort ==$ic
        global ic=$ic+1
        }
end
doit
save apcd_`k'_cohortff.dta, replace

// data for age effects

frame change default
frame drop new
frame create new 
frame change new

set obs 11
gen h_age = _n*5+20
gen agef_uci = 0 
gen agef_lci = 0 
gen ageff = 0 
global ic= 1
cap program drop doit
program def doit
        while $ic <= 11 {
        replace ageff = B[1,$ic] if h_age ==$ic*5+20
		replace agef_uci = B[1,$ic] + invttail(e(df),0.025)*sqrt(SE[$ic, $ic]) if h_age ==$ic*5+20
		replace agef_lci = B[1,$ic] - invttail(e(df),0.025)*sqrt(SE[$ic, $ic]) if h_age ==$ic*5+20
        global ic=$ic+1
        }
end
doit
save apcd_`k'_aggff.dta, replace
}
restore


















