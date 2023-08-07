
which pystacked 
python: import sklearn
python: sklearn.__version__

global xvars crim-lstat

*******************************************************************************
*** check that it works without default methods						 		***
*******************************************************************************

clear all
use https://statalasso.github.io/dta/cal_housing.dta, clear
set seed 42
pystacked medh longi-medi 


*******************************************************************************
*** check that printing the coefficients works						 		***
*******************************************************************************

clear all
use https://statalasso.github.io/dta/cal_housing.dta, clear
set seed 42

foreach meth in lassocv elasticcv ridgecv rf gradboost {
	pystacked medh longi-medi , m(ols `meth') showc
}


*******************************************************************************
*** check that printing the options works							 		***
*******************************************************************************

clear all
use https://statalasso.github.io/dta/cal_housing.dta, clear
set seed 42

foreach meth in lassocv elasticcv ridgecv rf gradboost {
	pystacked medh longi-medi , m(ols `meth') printopt
}


*******************************************************************************
*** check against SJ paper 											 		***
*******************************************************************************

clear all
use https://statalasso.github.io/dta/cal_housing.dta, clear
set seed 42
gen train=runiform()
replace train=train<.75
replace medh = medh/10e3 
label var medh 
set seed 42
pystacked medh longi-medi if train,                        ///
    type(regress)                                          ///
    methods(ols lassocv lassocv rf gradboost)              ///
    pipe3(poly2) cmdopt5(learning_rate(0.01)               ///
    n_estimators(1000))

mat W = e(weights)
assert reldif(0,el(W,1,1))<0.005
assert reldif(0,el(W,2,1))<0.005
assert reldif(0,el(W,3,1))<0.005
assert reldif(0.8382714,el(W,4,1))<0.005
assert reldif(0.1617286,el(W,5,1))<0.005


*******************************************************************************
*** foldvar															 		***
*******************************************************************************

insheet using "/Users/kahrens/Dropbox (PP)/ddml/Data/housing.csv", ///
	clear comma

gen fid = 1 + (_n>250)
	
pystacked medv $xvars, method(ols rf) foldvar(fid)
predict yb , basexb cvalid

reg medv $xvars if _n<=250
predict ols1 if _n>250
reg medv $xvars if _n>250
predict ols2 if _n<=250
gen ols_crossfit = ols1 if _n>250
replace ols_crossfit = ols2 if _n<=250

assert reldif(ols_crossfit , yb1)<10e-6


*******************************************************************************
*** pystacked with one predictor									 		***
*******************************************************************************

sysuse auto , clear
pystacked price mpg, type(reg) m(ols)
predict double xhat1

reg price mpg
predict double xhat2 

assert reldif(xhat1,xhat2)<10e-6


*******************************************************************************
*** check stdscaler default with regularized linear learners		 		***
*******************************************************************************

insheet using "/Users/kahrens/Dropbox (PP)/ddml/Data/housing.csv", ///
	clear comma

pystacked medv $xvars, method(gradboost lassocv)   
di "`e(pipe2)'"
assert "`e(pipe2)'"=="stdscaler"

pystacked medv $xvars, method(gradboost lassocv) pipe2(nostdscaler)
di "`e(pipe2)'"
assert "`e(pipe2)'"=="passthrough"
	
pystacked medv $xvars || m(gradboost) || m(lassocv)   
di "`e(pipe2)'"
assert "`e(pipe2)'"=="stdscaler"

pystacked medv $xvars || m(gradboost) || m(lassocv) pipe(nostdscaler)
di "`e(pipe2)'"
assert "`e(pipe2)'"=="passthrough"


*******************************************************************************
*** xvar option 													 		***
*******************************************************************************

insheet using "/Users/kahrens/Dropbox (PP)/ddml/Data/housing.csv", ///
	clear comma
	
global xuse c.(crim lstat)##c.(crim lstat)
global xall c.(crim-lstat)##c.(crim-lstat)

set seed 789
pystacked medv $xuse, method(gradboost lassocv)   
predict double xb
 
set seed 789
pystacked medv $xall, method(gradboost lassocv) xvars1($xuse) xvars2($xuse) 
predict double xb2

set seed 789
pystacked medv $xall || method(gradboost) xvars($xuse) || m(lassocv) xvars($xuse),  
predict double xb3

set seed 789
pystacked medv crim, method(gradboost lassocv) xvars1($xuse) xvars2($xuse)  
predict double xb4

** this should be different
set seed 789
pystacked medv crim, method(gradboost lassocv) xvars1(crim lstat) xvars2(crim lstat)   
predict double xb5

assert reldif(xb,xb2)<1e-5
assert reldif(xb,xb3)<1e-5
assert reldif(xb,xb4)<1e-5
assert xb!=xb5


*******************************************************************************
*** xvar vs pipeline												 		***
*******************************************************************************

insheet using "/Users/kahrens/Dropbox (PP)/ddml/Data/housing.csv", ///
	clear comma
	
set seed 789
pystacked medv crim-lstat, method(gradboost lassocv) xvars2(c.(crim-lstat)##c.(crim-lstat))  
predict double xb1

set seed 789
pystacked medv crim-lstat, method(gradboost lassocv) pipe2(poly2) 
predict double xb2

assert reldif(xb1,xb2)<1e-4


*******************************************************************************
*** voting															 		***
*******************************************************************************

clear
insheet using https://web.stanford.edu/~hastie/ElemStatLearn/datasets/prostate.data, tab clear

global xvars lcavol-pgg

set seed 124345

pystacked lpsa $xvars, ///
						 type(regress) pyseed(243) ///
						 methods(ols lassoic rf) ///
						 pipe1(poly2) pipe2(poly2) /// 
						 voting voteweights(.5 .1)

// should cause error
cap pystacked lpsa $xvars, ///
						 type(regress) pyseed(243) ///
						 methods(ols lassoic rf) ///
						 pipe1(poly2) pipe2(poly2) /// 
						 voting voteweights(.5 .9)	
assert _rc == 198						 
					
*******************************************************************************
*** check pipeline													 		***
*******************************************************************************

clear
insheet using https://web.stanford.edu/~hastie/ElemStatLearn/datasets/prostate.data,  tab clear
global xvars lcavol-pgg


pystacked lpsa $xvars, ///
						 type(regress) pyseed(243) ///
						 methods(ols lassoic rf ) ///
						 pipe1(poly2) pipe2(poly2 nostdscaler) pipe3(poly2)  
ereturn list
predict a, basexb

 
pystacked lpsa c.($xvars)##c.($xvars), ///
						 type(regress) pyseed(243) ///
						 methods(ols lassoic  rf ) pipe2(nostdscaler)
ereturn list
predict b, basexb
list lpsa a* b* if _n <= 10

assert reldif(a1,b1)<1e-5
assert reldif(a2,b2)<1e-5

*******************************************************************************
*** check that xvar() subsetting works								 		***
*******************************************************************************


insheet using https://statalasso.github.io/dta/housing.csv, clear

set seed 789
pystacked medv crim lstat, method(gradboost lassocv) pyseed(-1)
predict double xb

set seed 789
pystacked medv crim-lstat, method(gradboost lassocv) xvars1(crim lstat) xvars2(crim lstat) pyseed(-1)
predict double xb2

set seed 789
pystacked medv crim-lstat || method(gradboost) xvars(crim lstat) || m(lassocv) xvars(crim lstat), pyseed(-1)
predict double xb3
list xb* if _n<5
assert reldif(xb,xb2)<10e-9
assert reldif(xb,xb3)<10e-9


*** with factor variables

insheet using https://statalasso.github.io/dta/housing.csv, clear

set seed 789
pystacked medv i.rad##c.crim, method(gradboost lassocv) pyseed(-1)
predict double xb

set seed 789
pystacked medv i.rad##c.(crim-lstat), method(gradboost lassocv) xvars1(i.rad##c.crim) xvars2(i.rad##c.crim) pyseed(-1)
predict double xb2

set seed 789
pystacked medv i.rad##c.(crim-lstat) || method(gradboost) xvars(i.rad##c.crim) || m(lassocv) xvars(i.rad##c.crim), pyseed(-1)
predict double xb3
list xb* if _n<5
assert reldif(xb,xb2)<10e-9
assert reldif(xb,xb3)<10e-9


*******************************************************************************
*** try various combinations of estimators							 		***
*******************************************************************************

insheet using https://web.stanford.edu/~hastie/ElemStatLearn/datasets/prostate.data,  tab clear

local m1 ols lassocv gradboost nnet
local m2 ols lassocv rf nnet
local m3 ols lassoic gradboost nnet
local m4 ols ridgecv gradboost nnet
local m5 ols elasticcv gradboost nnet
local m6 ols elasticcv gradboost svm
local m7 ols elasticcv gradboost linsvm

foreach m in "`m1'" "`m2'" "`m3'" "`m4'" "`m5'" "`m6'" "`m7'" {
	di "`m'"
	pystacked lpsa lcavol lweight age lbph svi lcp gleason pgg45, ///
						 type(regress) pyseed(243) ///
						 methods(`m') /// 
						 njobs(4) ///
						 pipe2(poly2) pipe1(poly2)
	pystacked lpsa lcavol lweight age lbph svi lcp gleason pgg45, ///
						 type(regress) pyseed(243) ///
						 methods(`m') /// 
						 njobs(4) ///
						 pipe2(poly2) pipe1(poly2) finalest(singlebest)
}

*******************************************************************************
*** check that predicted value = weighted avg of transform variables 		***
*******************************************************************************

insheet using https://web.stanford.edu/~hastie/ElemStatLearn/datasets/prostate.data,  tab clear

set seed 124345

pystacked lpsa lcavol lweight age lbph svi lcp gleason pgg45, ///
						 type(regress) pyseed(243) 
						 
predict double yhat, xb
list yhat if _n < 10

predict double t, basexb

mat W = e(weights)
gen myhat = t1*el(W,1,1)+t2*el(W,2,1)+t3*el(W,3,1)

assert reldif(yhat,myhat)<0.0001


*******************************************************************************
*** check for error message when data in memory changed				 		***
*******************************************************************************

clear
insheet using https://web.stanford.edu/~hastie/ElemStatLearn/datasets/prostate.data,  tab clear

set seed 124345

pystacked lpsa lcavol lweight age lbph svi lcp gleason pgg45, ///
						 type(regress) pyseed(243) 
						 
replace lcavol = 2 * lcavol

cap predict double yhat, xb
assert _rc != 0

*******************************************************************************
*** check table option												 		***
*******************************************************************************

clear
insheet using https://web.stanford.edu/~hastie/ElemStatLearn/datasets/prostate.data,  tab clear
global xvars lcavol-pgg

set seed 124345

// holdout sample 1
cap drop h1
gen h1 = _n>60
// holdout sample 2
cap drop h2
gen h2 = _n>40

// postestimation syntax

// full sample
pystacked lpsa $xvars, ///
						 type(regress) pyseed(243) ///
						 methods(ols lassocv rf) ///
						 pipe1(poly2) pipe2(poly2)
pystacked, table

// with holdout sample
pystacked lpsa $xvars if _n<50, ///
						 type(regress) pyseed(243) ///
						 methods(ols lassocv rf) ///
						 pipe1(poly2) pipe2(poly2)
// default holdout - all available obs
pystacked, table holdout
// specified holdout sample
pystacked, table holdout(h1)
// holdout sample overlaps with estimation sample
cap noi pystacked, table holdout(h2)
assert _rc != 0

// as pystacked option
pystacked lpsa $xvars if _n<50, ///
						 type(regress) pyseed(243) ///
						 methods(ols lassocv rf) ///
						 pipe1(poly2) pipe2(poly2) ///
						 table holdout

// syntax 2
pystacked lpsa $xvars || method(ols) || method(lassocv) || method(rf) ||  if _n<50, ///
						 type(regress) pyseed(243) ///
						 methods(ols lassoic rf)
pystacked, table holdout(h1)

*******************************************************************************
*** check graph option												 		***
*******************************************************************************

clear
insheet using https://web.stanford.edu/~hastie/ElemStatLearn/datasets/prostate.data,  tab clear
global xvars lcavol-pgg

set seed 124345

// holdout sample 1
cap drop h1
gen h1 = _n>60
// holdout sample 2
cap drop h2
gen h2 = _n>40

// postestimation syntax

// full sample
pystacked lpsa $xvars, ///
						 type(regress) pyseed(243) ///
						 methods(ols lassocv rf) ///
						 pipe1(poly2) pipe2(poly2)
// in-sample predictions
pystacked, graph

// with holdout sample
pystacked lpsa $xvars if _n<50, ///
						 type(regress) pyseed(243) ///
						 methods(ols lassocv rf) ///
						 pipe1(poly2) pipe2(poly2)
// in-sample predictions
pystacked, graph
// default holdout - all available obs
pystacked, graph holdout
// specified holdout sample
pystacked, graph holdout(h1)
// graphing options - combined graph
pystacked, graph(subtitle("subtitle goes here")) holdout
// graphing options - learner graphs
pystacked, lgraph(ytitle("ytitle goes here")) holdout

// as pystacked option
pystacked lpsa $xvars if _n<50, ///
						 type(regress) pyseed(243) ///
						 methods(ols lassocv rf) ///
						 pipe1(poly2) pipe2(poly2) ///
						 graph holdout

// syntax 2
pystacked lpsa $xvars || method(ols) || method(lassocv) || method(rf) || if _n<50 , ///
						 type(regress) pyseed(243) ///
						 methods(ols lassoic rf)
pystacked, graph holdout
 