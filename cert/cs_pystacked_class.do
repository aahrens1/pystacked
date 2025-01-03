

which pystacked 
python: import sklearn
python: sklearn.__version__

tempfile testdata
set seed 765
global model v58 v1-v30
insheet using https://archive.ics.uci.edu/ml/machine-learning-databases/spambase/spambase.data, clear comma
sample 15
gen u = runiform()
gen train = u<0.5
gen train2 = u<.75
save `testdata'

*******************************************************************************
*** check that it works without default methods						 		***
*******************************************************************************

 insheet using ///
 https://archive.ics.uci.edu/ml/machine-learning-databases/spambase/spambase.data, ///
 clear comma
set seed 42
gen train=runiform()
replace train=train<.75
 pystacked v58 v1-v57 , type(class)

 
*******************************************************************************
*** check that printing the coefficients works						 		***
*******************************************************************************

 insheet using ///
 https://archive.ics.uci.edu/ml/machine-learning-databases/spambase/spambase.data, ///
 clear comma
set seed 42

foreach meth in lassocv elasticcv ridgecv rf gradboost {
	pystacked v58 v1-v57, type(class) m(logit `meth') showc
}


*******************************************************************************
*** check that printing the options works							 		***
*******************************************************************************

 insheet using ///
 https://archive.ics.uci.edu/ml/machine-learning-databases/spambase/spambase.data, ///
 clear comma

foreach meth in lassocv elasticcv ridgecv rf gradboost {
	pystacked v58 v1-v57, type(class) m(logit `meth') printopt
}

 
 
*******************************************************************************
*** from SJ paper 													 		***
*******************************************************************************

 insheet using ///
 https://archive.ics.uci.edu/ml/machine-learning-databases/spambase/spambase.data, ///
 clear comma
set seed 42
gen train=runiform()
replace train=train<.75
 
 pystacked v58 v1-v57                           || ///
    m(logit) pipe(poly2)                        || ///
    m(gradboost) opt(n_estimators(600))         || ///
    m(gradboost) opt(n_estimators(1000))        || ///
    m(nnet) opt(hidden_layer_sizes(5 5))        || ///
    m(nnet) opt(hidden_layer_sizes(5))          || ///
    if train, type(class) njobs(8) backend(threading) 
	
mat W = e(weights)
local sum = el(W,1,1)+el(W,2,1)+el(W,3,1)+el(W,4,1)+el(W,5,1)
assert reldif(`sum',1)<0.001


*******************************************************************************
*** foldvar															 		***
*******************************************************************************

use `testdata', clear

gen fid = 1 + (_n>345)
	
pystacked v58 v1 v2 v3, method(logit rf) foldvar(fid) type(class)
predict yb , basexb cvalid

logit v58 v1 v2 v3 if fid==1
predict log1 if fid ==2
logit v58 v1 v2 v3 if fid==2
predict log2 if fid==1
gen double log_crossfit = log1 if fid==2
replace log_crossfit = log2 if fid==1

assert reldif(log_crossfit , yb1)<10e-4



*******************************************************************************
*** check that predicted value = weighted avg of transform variables 		***
*******************************************************************************
						 
use `testdata', clear

pystacked $model, type(class) pyseed(123)

predict double yhat, pr
list yhat if _n < 10

predict double t, basexb

mat W = e(weights)
gen myhat = t1*el(W,1,1)+t2*el(W,2,1)+t3*el(W,3,1)

assert reldif(yhat,myhat)<0.0001

*******************************************************************************
*** only one predictor 														***
*******************************************************************************

use `testdata', clear

pystacked v58 v57, type(class) m(logit)
predict double xhat1

logit v58 v57
predict double xhat2 

assert reldif(xhat1,xhat2)<0.0001

*******************************************************************************
*** predicted values/classes										 		***
*******************************************************************************

cap drop yhat*

pystacked $model, type(class) methods(logit)
predict yhat , class
predict yhat2  
predict yhat3 , pr
assert yhat>0 if yhat3>0.5
assert yhat<1 if yhat3<0.5
assert yhat2>0 if yhat3>0.5
assert yhat2<1 if yhat3<0.5

*******************************************************************************
*** try voting 														 		***
*******************************************************************************

use `testdata', clear
			
pystacked $model, type(class) pyseed(123) ///
							methods(lassocv rf logit) /// 
							njobs(4) pipe1(poly2) ///
							voting voteweights(0.1 .4) ///
							votetype(soft)
mat W = e(weights)
assert reldif(0.1,el(W,1,1))<0.0001
assert reldif(0.4,el(W,2,1))<0.0001
assert reldif(0.5,el(W,3,1))<0.0001
 

*******************************************************************************
*** try other estimators											 		***
*******************************************************************************

use `testdata', clear

local m1 logit lassocv gradboost nnet
local m2 logit lassocv rf nnet
local m3 logit ridgecv gradboost nnet
local m4 logit elasticcv gradboost nnet
local m5 logit elasticcv gradboost svm

foreach m in "`m1'" "`m2'" "`m3'" "`m4'" "`m5'" "`m6'" {
	di "`m'"
	pystacked $model, type(class) pyseed(123) ///
							methods(`m') /// 
							njobs(4)
}


*******************************************************************************
*** check table option 														***
*******************************************************************************

use `testdata', clear

// holdout sample 1
cap drop h1
gen h1 = !train2

// full sample
pystacked $model, type(class) pyseed(123) methods(logit rf gradboost)
pystacked, table

// with holdout sample
pystacked $model if train, type(class) pyseed(123) methods(logit rf gradboost)
// default holdout - all available obs
pystacked, table holdout
// specified holdout sample
pystacked, table holdout(h1)

// as pystacked option
pystacked $model if train, type(class) pyseed(123) ///
	methods(logit rf gradboost) table holdout

// syntax 2
pystacked $model || method(logit) || method(rf) || method(gradboost) || if train, ///
	type(class) pyseed(123)
pystacked, table holdout


*******************************************************************************
*** check graph option 														***
*******************************************************************************

use `testdata', clear

// holdout sample 1
cap drop h1
gen h1 = !train2

// full sample
pystacked $model, type(class) pyseed(123) methods(logit rf gradboost)
pystacked, graph

// with holdout sample
pystacked $model if train, type(class) pyseed(123) methods(logit rf gradboost)
// default holdout - all available obs
pystacked, graph holdout
// specified holdout sample
pystacked, graph holdout(h1)
// histogram option
pystacked, graph hist holdout
// graphing options - combined graph
pystacked, graph(subtitle("subtitle goes here")) holdout
// graphing options - learner graphs
pystacked, lgraph(percent) hist holdout

// as pystacked option
pystacked $model if train, type(class) pyseed(123) ///
	methods(logit rf gradboost) graph holdout

// syntax 2
pystacked $model || method(logit) || method(rf) || method(gradboost) || if train, ///
	type(class) pyseed(123)
pystacked, graph holdout

