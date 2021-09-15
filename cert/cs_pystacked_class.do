clear all
 
if ("`c(username)'"=="kahrens") {
	adopath + "/Users/kahrens/MyProjects/ddml"
	adopath + "/Users/kahrens/MyProjects/pylearn2"
	cd "/Users/kahrens/Dropbox (PP)/ddml"
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

*******************************************************************************
*** try predict with xb for classification 									***
*******************************************************************************
	
predict ybin , xb

*******************************************************************************
*** try other estimators											 		***
*******************************************************************************

pystacked v58 v1-v57, type(class) pyseed(123) ///
						 methods(lassocv rf gradboost svm)
						 
