/* 
Author: Ken Norris

Date: August 2018

Last Update: August 2018

Description: Convert Excel workbook sheets into dataset of expected lifetime 
			 charts from 1992 - 2014.

*/
			 
clear
global dropbox `"C:/Users/`c(username)'/Dropbox/VSL2018/data/CDC"'

import excel "$dropbox/CDC_ExpectedLife.xlsx", sheet("`i'") firstrow clear
gen year = 1992
rename Age age
save "mainfile", replace

*Format includes age for 1992- 1995 waves*
forvalues i = 1993/1996{
	import excel "$dropbox/CDC_ExpectedLife.xlsx", sheet("`i'") firstrow clear
	gen year = `i'
	rename Age age
	append using "mainfile"
	save "mainfile", replace
}

*Format only lists years in descending order for 1996 onwards, create age variable*
forvalues i = 1997/2005{
	import excel "$dropbox/CDC_ExpectedLife.xlsx", sheet("`i'") firstrow clear
	gen year = `i'
	
	*Taking first year of that age var
	split Age, parse("-") generate(age)
	rename age1 age
	
	destring age, replace ignore("+")
	drop age2 Age
	append using "mainfile"
	save "mainfile", replace
}

forvalues i = 2006/2014{
	import excel "$dropbox/CDC_ExpectedLife.xlsx", sheet("`i'") firstrow clear
	gen year = `i'
	
	*Taking first year of that age var
	split Age, parse("-") generate(age)
	rename age1 age
	
	destring age, replace ignore("+")
	drop age2 Age
	append using "mainfile"
	save "mainfile", replace
}

*drop N O AllotherFemale

rename*, lower

order year age

drop if age ==.

/*format:


Year      Age       Gender               Race      LE
 
where Year corresponds to the year of the life table (1992 through 2016), 
age corresponds to the first column in the table, gender will be a binary 
variable (that we will use for matching later), race will be a variable 
that is coded for ALL, WHITE, BLACK, NON-WHITE OTHER, and LE is years of life 
expectancy corresponding to the data in the table.


*/

local les allbothsexes allmale allfemale whitebothsexes whitemale whitefemale ///
		  blackbothsexes blackmale blackfemale  ///
		  hispanicbothsexes hispanicmale hispanicfemale ///
		  nonhispanicwhitebothsexes nonhispanicwhitemale nonhispanicwhitefemale ///
		  nonhispanicblackbothsexes nonhispanicblackmale nonhispanicblackfemale

drop allother*
		  
local i = 1		  
foreach l of varlist `les' {
	replace `l' = round(`l')
	rename `l' LE`i'
	local i = `i' + 1
}

*Replicate loop above to get similar tail to match up to recodes below
local proportion proportion*

local j = 1		  
foreach p of varlist `proportion' {
	rename `p' prop`j'
	local j = `j' + 1
}


*Give it a reshape then use recode and generate to create gender and race vars
reshape long LE prop, i(year age) j(seq)

recode seq (1 4 7 10 13 16 = 2) (2 5 8 11 14 17 = 0) (3 6 9 12 15 18 = 1), gen(gender)
recode seq (1/3 = 0) (4/6 = 1) (7/9 = 2) (10/12 = 5) (13/15 = 6) (16/18 = 7), gen(race)

drop seq


label define genderlab 0 "Male" 1 "Female" 2 "Both sexes" 

label define racelab   0 "All" 1 "White" 2 "Black" 5 "Hispanic" ///
					   6 "Non-Hispanic White" 7 "Non-Hispanic Black"
					   

label values gender genderlab
label values race racelab

save "$dropbox/life_expectancy.dta", replace
