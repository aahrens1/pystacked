cap cd "/Users/kahrens/MyProjects/pystacked/cert"

cap log close
log using "log_cs_pystacked_class.txt", text replace

clear all
 
net install pystacked, ///
		from(https://raw.githubusercontent.com/aahrens1/pystacked/main) replace
which pystacked 
python: import sklearn
python: sklearn.__version__


*******************************************************************************
*** try voting 														 		***
*******************************************************************************

insheet using https://archive.ics.uci.edu/ml/machine-learning-databases/spambase/spambase.data, clear comma
						
pystacked v58 v1-v57, type(class) pyseed(123) ///
							methods(lassocv rf nnet) /// 
							njobs(4) pipe1(poly2) ///
							voting voteweights(0.1 .4) ///
							votetype(soft)
			

*******************************************************************************
*** try other estimators											 		***
*******************************************************************************

insheet using https://archive.ics.uci.edu/ml/machine-learning-databases/spambase/spambase.data, clear comma

local m1 logit lassocv gradboost nnet
local m2 logit lassocv rf nnet
local m3 logit ridgecv gradboost nnet
local m4 logit elasticcv gradboost nnet
local m5 logit elasticcv gradboost svm
local m6 logit elasticcv gradboost linsvm

foreach m in "`m1'" "`m2'" "`m3'" "`m4'" "`m5'" "`m6'" {
	di "`m'"
	pystacked v58 v1-v57, type(class) pyseed(123) ///
							methods(`m') /// 
							njobs(4)
}

*******************************************************************************
*** check that predicted value = weighted avg of transform variables 		***
*******************************************************************************
						 
insheet using https://archive.ics.uci.edu/ml/machine-learning-databases/spambase/spambase.data, clear comma

pystacked v58 v1-v57, type(class) pyseed(123)

predict double yhat, pr
list yhat if _n < 10

predict double t, transform  

mat W = e(weights)
gen myhat = t0*el(W,1,1)+t1*el(W,2,1)+t2*el(W,3,1)

assert reldif(yhat,myhat)<0.0001

log close
