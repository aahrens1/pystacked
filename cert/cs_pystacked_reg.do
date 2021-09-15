clear all
 
if ("`c(username)'"=="kahrens") {
	adopath + "/Users/kahrens/MyProjects/ddml"
	adopath + "/Users/kahrens/MyProjects/pylearn2"
	cd "/Users/kahrens/Dropbox (PP)/ddml"
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

*******************************************************************************
*** try other estimators											 		***
*******************************************************************************

pystacked lpsa lcavol lweight age lbph svi lcp gleason pgg45, ///
						 type(regress) pyseed(243) ///
						 methods(lassocv lassoic rf gradboost svm)
						 
