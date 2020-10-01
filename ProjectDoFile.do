clear all
set more off

cd "/Users/leamorical/Desktop/14.33/"
 
*load referendum data to join to original data
*referendum data source: www.ncsl.org/research/elections-and-campaigns/ballot-measures-database.aspx
import delimited "Referendum.csv"
save referendum
gen hasref = 1 if numref >= 1
replace hasref = 0 if numref < 1
rename ïstate state
save referendum, replace

*creating bargraph of contentious/close
label variable closevote "Referendum that was within 5% of 50% approval"
label variable contentious "Contentious Referendum"
label define CONTF 0 "no contentious referendum" 1 "at least one contentious referendum"
label values contentious CONTF
label define CLOSEF 0 "not a close vote" 1 "at least one close vote"
label values closevote CLOSEF
graph bar (count), over (closevote) over (contentious) scale(*.5) title("Frequency of Close Referendum Votes by Contention of Referendum") ytitle("Number of States")
graph export contention.png
(file /Users/leamorical/Desktop/14.33/contention.png written in PNG format)

*creating bargraph of having referendums
label variable hasref "State has Referendum on 2016 Ballot"
label define hasREF 0 "no 2016 state referendum" 1 "at least one state referendum"
label values hasref hasREF
graph bar (count), over (hasref) scale(*.5) title("Frequency of State Referendums in 2016 Election") ytitle("Number of States")
graph export stateref.png

clear

*join new data onto county voting data
import delimited "Voting.csv"
save voting
joinby state using referendum.dta 

*focus on important cols
drop prcpmm mintempc maxtempc prcpmm1015 mintempc1015 maxtempc1015 freezing fips statefips
drop votedphysical voteduocava votedabsentee votedprovisional votedearly votedearlyvotecenter votedbymail votedother votedotherexplanation allowsameday sharesameday earlyvoting numpollworkers difficulttoobtainpollworkers

*converting voter to numeric, dropping counties without data on voters
drop if voted == "NA"
destring voted, replace

*define turnout as voted / population over 18, form of voting does not matter
drop turnout
rename turnout2 turnout
destring turnout, replace
drop if turnout > 1

*cleaning/destringing data
gen closepres = 1 if closeelection == "TRUE"
replace closepres = 0 if closeelection == "FALSE"
gen closesen = 1 if closesenate == "TRUE"
replace closesen = 0 if closesenate == "FALSE"
destring closepres, replace
destring closesen, replace
keep if closesen == 0 | closesen == 1

*list of demographic vars for convenience
local listvars "medianincome medianage eductillhs educsomecollege educcollegeup sharewhite shareblack shareasian shareotherrace sharehispanic"
di "`listvars'"

*labeling variables
label var closepres "State Vote for President within 5% Margin"
label var closesen  "State Vote for Senator within 5% Margin"
label var medianincome "County median income (thousands of dollars)"
label var medianage "County median age"
label var eductillhs "County share of population with high school education or below"
label var educsomecollege "County share of population with some college education but did not complete a 4-year degree"
label var educcollegeup "County share of population with college education or higher"
label var sharewhite "County share of whites"
label var shareblack "County share of Blacks"
label var shareasian "County share of Asians"
label var shareotherrace "County share of other races"
label var sharehispanic "County share of Hispanics"
label var turnout "Percent of Eligible Voters who Voted in 2016 General Election"

*motivating factor regression table
est clear
eststo: quietly regress turnout contentious if closesen == 0 & closepres == 0, r
eststo: quietly regress turnout closevote contentious if closesen == 0 & closepres == 0, r
eststo: quietly regress turnout closevote contentious `listvars' if closesen == 0 & closepres == 0, r 

*export regression 1
esttab est1 est2 est3 using 1433Regressions.doc, label main(b) aux(se) rtf onecell stats(N r2, label("Observations (N)" "R-Squared")) title("Table 1: Regressions of Referendums on Voter Turnout in Counties with Clear Senate and Presidential Winners") note("Note: Robust standard errors in parentheses; dependent variable: Voter Turnout")

*additional factor regression table
eststo: quietly regress turnout contentious if closesen == 1 | closepres == 1, r
eststo: quietly regress turnout closevote contentious if closesen == 1 | closepres == 1, r
eststo: quietly regress turnout closevote contentious `listvars' if closesen == 1 | closepres == 1, r

*export regression 2
esttab est1 est2 est3 using 1433Regressions2.doc, label main(b) aux(se) rtf onecell stats(N r2, label("Observations (N)" "R-Squared")) title("Table 2: Regressions of Referendums on Voter Turnout in Counties with Close Senate or Presidential Races") note("Note: Robust standard errors in parentheses; dependent variable: Voter Turnout")

