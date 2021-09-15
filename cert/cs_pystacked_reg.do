clear all
 
if ("`c(username)'"=="kahrens") {
	adopath + "/Users/kahrens/MyProjects/pystacked"
}

*******************************************************************************
*** try other estimators											 		***
*******************************************************************************

insheet using https://web.stanford.edu/~hastie/ElemStatLearn/datasets/prostate.data,  tab

local m1 lassocv gradboost nnet
local m2 lassocv rf nnet
local m3 lassoic gradboost nnet
local m4 ridgecv gradboost nnet
local m5 elasticcv gradboost nnet
local m6 elasticcv gradboost svm
local m7 elasticcv gradboost linsvm

foreach m in "`m1'" "`m2'" "`m3'" "`m4'" "`m5'" "`m6'" "`m7'" {
	di "`m'"
	pystacked lpsa lcavol lweight age lbph svi lcp gleason pgg45, ///
						 type(regress) pyseed(243) ///
						 methods(`m')	
}

*******************************************************************************
*** check that predicted value = weighted avg of transform variables 		***
*******************************************************************************

insheet using https://web.stanford.edu/~hastie/ElemStatLearn/datasets/prostate.data,  tab

set seed 124345

pystacked lpsa lcavol lweight age lbph svi lcp gleason pgg45, ///
						 type(regress) pyseed(243) 
						 
predict double yhat, xb
list yhat if _n < 10

predict double t, transform  

mat W = e(weights)
gen myhat = t0*el(W,1,1)+t1*el(W,2,1)+t2*el(W,3,1)

assert reldif(yhat,myhat)<0.0001


*******************************************************************************
*** check for error message when data in memory changed				 		***
*******************************************************************************

clear
insheet using https://web.stanford.edu/~hastie/ElemStatLearn/datasets/prostate.data,  tab

set seed 124345

pystacked lpsa lcavol lweight age lbph svi lcp gleason pgg45, ///
						 type(regress) pyseed(243) 
						 
replace lcavol = 2 * lcavol

cap predict double yhat, xb
assert _rc != 0

