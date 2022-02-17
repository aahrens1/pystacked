cap cd "/Users/kahrens/MyProjects/pystacked/cert"
cap cd "/Users/ecomes/Documents/GitHub/pystacked/cert"

cap log close
log using "log_cs_pystacked_class.txt", text replace

clear all

if "`c(username)'"=="kahrens" {
	adopath + "/Users/kahrens/MyProjects/pystacked"
}
else if "`c(username)'"=="ecomes" {
	adopath + "/Users/ecomes/Documents/GitHub/pystacked/cert"
}
else {
	net install pystacked, ///
		from(https://raw.githubusercontent.com/aahrens1/pystacked/main) replace
}
which pystacked 
python: import sklearn
python: sklearn.__version__

tempfile testdata
global model v58 v1-v30
insheet using https://archive.ics.uci.edu/ml/machine-learning-databases/spambase/spambase.data, clear comma
sample 50
gen u = runiform()
gen train = u<0.5
gen train2 = u<.75
save `testdata'

*******************************************************************************
*** try voting 														 		***
*******************************************************************************

use `testdata', clear
			
pystacked $model, type(class) pyseed(123) ///
							methods(lassocv rf logit) /// 
							njobs(4) pipe1(poly2) ///
							voting voteweights(0.1 .4) ///
							votetype(soft)
			

*******************************************************************************
*** try other estimators											 		***
*******************************************************************************

use `testdata', clear

local m1 logit lassocv gradboost nnet
local m2 logit lassocv rf nnet
local m3 logit ridgecv gradboost nnet
local m4 logit elasticcv gradboost nnet
local m5 logit elasticcv gradboost svm
local m6 logit elasticcv gradboost linsvm

foreach m in "`m1'" "`m2'" "`m3'" "`m4'" "`m5'" "`m6'" {
	di "`m'"
	pystacked $model, type(class) pyseed(123) ///
							methods(`m') /// 
							njobs(4)
}

*******************************************************************************
*** check that predicted value = weighted avg of transform variables 		***
*******************************************************************************
						 
use `testdata', clear

pystacked $model, type(class) pyseed(123)

predict double yhat, pr
list yhat if _n < 10

predict double t, transform  

mat W = e(weights)
gen myhat = t1*el(W,1,1)+t2*el(W,2,1)+t3*el(W,3,1)

assert reldif(yhat,myhat)<0.0001


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


log close
