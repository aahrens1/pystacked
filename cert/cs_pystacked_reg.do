clear all
 
 /*
net install pystacked, ///
		from(https://raw.githubusercontent.com/aahrens1/pystacked/main) replace
which pystacked 
*/
adopath + "/Users/kahrens/MyProjects/pystacked"
which pystacked

*******************************************************************************
*** check pipeline													 		***
*******************************************************************************

clear
insheet using https://web.stanford.edu/~hastie/ElemStatLearn/datasets/prostate.data,  tab clear

set seed 124345

global xvars lcavol lweight age lbph svi lcp gleason pgg45

pystacked lpsa $xvars, ///
						 type(regress) pyseed(243) ///
						 methods(ols lassoic rf) ///
						 pipe1(poly2) pipe2(poly2) 
predict a, transf
			 
pystacked lpsa c.($xvars)##c.($xvars), ///
						 type(regress) pyseed(243) ///
						 methods(ols lassoic )  					 
predict b, transf
list lpsa a* b*

assert a0==b0
assert a1==b1

*******************************************************************************
*** try various combinations of estimators							 		***
*******************************************************************************

insheet using https://web.stanford.edu/~hastie/ElemStatLearn/datasets/prostate.data,  tab clear

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
						 methods(`m') /// 
						 njobs(4) ///
						 pipe1(poly2)
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
