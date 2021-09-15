program define pystacked, eclass
version 16.0

	tokenize "`0'", parse(",")
	local beforecomma `1'
	macro shift
	local restargs `*'
	tokenize `beforecomma', parse("|")
	local mainargs `1'
	local 0 "`mainargs' `restargs'"
	local doublebarsyntax = ("`2'"=="|")*("`3'"=="|")

	syntax varlist(min=2 fv) [if] [in] [aweight fweight], ///
				[ ///
					type(string) /// classification or regression
					finalest(string) ///
					njobs(int 1) ///
					folds(int 5) ///
					///
					///
					pyseed(integer 0) ///
					printopt ///
					NOSAVEPred ///
					NOSAVETransform ///
					///
					voting ///
					///
					VOTEType(string) ///
					VOTEWeights(numlist >0) ///
					debug ///
					Methods(string) ///
					cmdopt1(string asis) ///
					cmdopt2(string asis) ///
					cmdopt3(string asis) ///
					cmdopt4(string asis) ///
					cmdopt5(string asis) ///
					cmdopt6(string asis) ///
					cmdopt7(string asis) ///
					cmdopt8(string asis) ///
					cmdopt9(string asis) ///
					cmdopt10(string asis) ///
					pipe1(string asis) ///
					pipe2(string asis) ///
					pipe3(string asis) ///
					pipe4(string asis) ///
					pipe5(string asis) ///
					pipe6(string asis) ///
					pipe7(string asis) ///
					pipe8(string asis) ///
					pipe9(string asis) ///
					pipe10(string asis) ///
					///
					showpywarnings ///
				]

	** set data signature for pystacked_p;
	* need to do this before temp vars are created
	if ("`debug'"=="") local dqui qui
	`dqui' datasignature clear 
	`dqui'  datasignature set
	`dqui' datasignature report

	if "`type'"=="" local type reg
	if substr("`type'",1,3)=="reg" {
		local type reg
	}
	if substr("`type'",1,5)=="class" {
		local type class
	}

	* defaults
	if "`finalest'"=="" {
		local finalest nnls
	}
	if "`finalest'"!="nnls"&"`finalest'"!="ridge" {
		di as err "finalest(`finalest') not allowed"
		error 198
	}

	if "`votetype'"!=""&"`type'"=="reg" {
		di as err "votetype not allowed with type(reg). ignored."
	}
	
	if "`votetype'"=="" {
		local votetype hard
	}
	else if "`votetype'"!="hard"&"`votetype'"!="soft" {
		di as error "votetype(`votetype') not allowed"
		error 198
	}

	if (`doublebarsyntax'==0)&("`methods'"=="") {
		local methods lassoic rf gradboost
	}
	if (`doublebarsyntax'==0)&("`methods'"!="") {
		local mcount : word count `methods'
		if `mcount'>10 {
			di as err "more than 10 methods specified, but only up to 10 supported using this syntax"
			di as err "use e.g. 'pystacked y x* || m(rf) || m(lassocv) || ...' to specify as many base learners as you want"
		}
	}


	******** parse options using _pyparse.ado ********************************* 

	if `doublebarsyntax' {
		syntax_parse `beforecomma' , type(`type')
		local allmethods `r(allmethods)'
		local allpyopt `r(allpyopt)'
		local mcount = `r(mcount)'
		local allpipe (
		forvalues i = 1(1)`mcount' {
			local opt`i' `r(opt`i')'
			local method`i' `r(method`i')'
			local pyopt`i' `r(pyopt`i')'
			local pipe`i' `r(pipe`i')'
			local allpipe `allpipe' '`pipe`i''', 
		}
		local allpipe `allpipe')
	} 
	else {
		local allmethods `methods'
		local allpipe (
		forvalues i = 1(1)10 {
			local method : word `i' of `allmethods'
			if "`method'"!="" {
				local mcount = `i'
				_pyparse , `cmdopt`i'' type(`type') method(`method') 
				if `i'==1 {
					local allpyopt [`r(optstr)'
				}
				else {
					local allpyopt `allpyopt' , `r(optstr)'
				}
				local opt`i' `cmdopt`i'' 
				local method`i' `method'
				local pyopt`i' `r(optstr)'
				if "`pipe`i''"=="" local pipe`i' passthrough
				local allpipe `allpipe' '`pipe`i''', 
			}			
		}
		local allpyopt `allpyopt']
		local allpipe `allpipe')
	}

	******** parsing end ****************************************************** 

	marksample touse
	markout `touse' `varlist'
	qui count if `touse'
	local N		= r(N)

	* Deal with factor and time-series vars
	// first expand and unabbreviate
	fvexpand `varlist' if `touse'
	local varlist `r(varlist)'
	// now create a varlist with temps etc. that can be passed to Python
	fvrevar `varlist' if `touse'
	local varlist_t `r(varlist)'

	* Pass varlist into varlists called yvar and xvars
	gettoken yvar xvars : varlist
	gettoken yvar_t xvars_t : varlist_t

	ereturn clear

	python: run_stacked(	///
					"`type'",	///
					"`finalest'", ///
					"`allmethods'", ///
					"`yvar_t'", ///
					"`xvars_t'",	///
					"`training_var'", ///
					///
					"`allpyopt'", ///
					"`allpipe'", ///
					///  
					"`touse'", ///
					`pyseed', ///
					"`nosavepred'", ///
					"`nosavetransform'", ///
					"`voting'" , ///
					"`votetype'", ///
					"`voteweights'", ///
					`njobs' , ///
					`folds', ///
					"`nostandardscaler'", ///
					"`showpywarnings'" ///
					)

	ereturn local cmd				pystacked
	ereturn local predict			pystacked_p
	ereturn local depvar			`yvar'

	forvalues i = 1(1)`mcount' {
		ereturn local opt`i' `opt`i'' 
		ereturn local method`i' `method`i''
		ereturn local pyopt`i' `pyopt`i''	
		ereturn local pipe`i' `pipe`i''		
	}
	ereturn scalar mcount = `mcount'

	tempname weights_mat
	mat `weights_mat'=e(weights)
	di as text "{hline 17}{c TT}{hline 21}"
	di as text "  Method" _c
	di as text _col(18) "{c |}      Weight"
	di as text "{hline 17}{c +}{hline 21}"
	local j = 1
	local base_est `e(base_est)'
	foreach b of local base_est {
		di as text "  `b'" _c
		di as text _col(18) "{c |}" _c
		di as res %15.7f el(`weights_mat',`j',1)
		local j = `j'+1
	}

end

program define syntax_parse, rclass

	syntax [anything] , type(string)

	// save y x and if/in	
	tokenize `anything', parse("|")
	local mainargs `1'
	
	// save method-specific parts
	local mcount = 0
	local j = 1
	while "``j''"!="" {
		local mcount = `mcount'+1
		local j = `j'+3
		local part`mcount' ``j''
	}
	local mcount = `mcount'-1
	
	// parse each part 
	local allmethods
	forvalues i=1(1)`mcount' {
		local 0 ", `part`i''"
		syntax , [Method(string asis) OPTions(string asis) PIPEline(string asis)]
		local allmethods `allmethods' `method'
		return local method`i' `method'
		return local opt`i' `options'
		if "`pipeline'"=="" local pipeline passthrough
		_pyparse , `options' type(`type') method(`method') 
		return local pyopt`i' `r(optstr)'
		return local pipe`i' `pipeline'
		if `i'==1 {
			local allpyopt [`r(optstr)'
		}
		else {
			local allpyopt `allpyopt' , `r(optstr)'
		}
	}
	local allpyopt `allpyopt']

	return local allmethods `allmethods'
	return scalar mcount = `mcount' 
	return local mainargs `mainargs'
	return local restargs `restargs'
	return local allpyopt `allpyopt'
	
end

*===============================================================================
* Python helper function
*===============================================================================

version 16.0
python:

#-------------------------------------------------------------------------------
# Import required packages and attempt to install w/ Pip if that fails
#-------------------------------------------------------------------------------

# Import required Python modules
import sfi
from sklearn.pipeline import make_pipeline,Pipeline
from sklearn.neural_network import MLPRegressor,MLPClassifier
from sklearn.preprocessing import StandardScaler,PolynomialFeatures
from sklearn.impute import SimpleImputer,KNNImputer
from sklearn.linear_model import LassoLarsIC,LassoCV,LogisticRegression,LogisticRegressionCV,LinearRegression
from sklearn.linear_model import RidgeCV,ElasticNetCV
from sklearn.ensemble import StackingRegressor,StackingClassifier
from sklearn.ensemble import VotingRegressor,VotingClassifier
from sklearn.ensemble import RandomForestRegressor,RandomForestClassifier
from sklearn.ensemble import GradientBoostingRegressor,GradientBoostingClassifier
from sklearn.svm import LinearSVR,LinearSVC,SVC,SVR
import numpy as np
import scipy 
import sys
import sklearn

# To pass objects to Stata
import __main__

#if version.parse(sklearn.__version__)<version.parse("0.24.0"):
#	sfi.SFIToolkit.stata("di as err pystacked requires sklearn 0.24.0 or higher")
#	sfi.SFIToolkit.error()	

print('The scikit-learn version is {}.'.format(sklearn.__version__))
print('The numpy version is {}.'.format(np.__version__))
print('The scipy version is {}.'.format(scipy.__version__))
print('The Python version is {}.'.format(sys.version))



#-------------------------------------------------------------------------------
# Define Python function: run_stacked
#-------------------------------------------------------------------------------

class LinearRegressionClassifier(LinearRegression):
    _estimator_type="classifier"

    def predict_proba(self, X):
    	return self._decision_function(X)

def build_pipeline(pipes):
	ll = []
	pipes = pipes.split()
	for p in range(len(pipes)):
		if pipes[p]=="stdscaler":
			ll.append(('stdscaler',StandardScaler()))
		elif pipes[p]=="minmaxscaler":
			ll.append(('minmaxscaler',MinMaxScaler()))
		elif pipes[p]=="medianimputer":
			ll.append(('medianimputer',SimpleImputer(strategy='median')))
		elif pipes[p]=="knnimputer":
			ll.append(('knnimputer',KNNImputer()))
		elif pipes[p]=="poly2":
			ll.append(('poly2',PolynomialFeatures(degree=2)))
		elif pipes[p]=="poly3":
			ll.append(('poly3',PolynomialFeatures(degree=3)))
	return ll

def run_stacked(type,finalest,methods,yvar,xvars,training,allopt,allpipe,
	touse,seed,nosavepred,nosavetransform,
	voting,votetype,voteweights,njobs,nfolds,nostandardscaler,showpywarnings):

	# Set random seed
	if seed>0:
		np.random.seed(seed)
		
	if nostandardscaler=="":
		stdscaler = StandardScaler()
	else: 
		stdscaler = 'passthrough'

	if showpywarnings=="":
		import warnings
		warnings.filterwarnings('ignore') 
		
	##############################################################
	### load data  											   ###
	##############################################################	

	# Load into Pandas data frame
	y = np.array(sfi.Data.get(yvar,selectvar=touse))
	x = np.array(sfi.Data.get(xvars,selectvar=touse))
	x_0 = np.array(sfi.Data.get(xvars))

	##############################################################
	### prepare fit											   ###
	##############################################################

	methods = methods.split()
	allopt = eval(allopt)
	allpipe = eval(allpipe)

	est_list = []
	for m in range(len(methods)):
		if type=="reg":
			if methods[m]=="lassoic":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m])
				newmethod.append(('lassolarsic',LassoLarsIC(**opt)))
			if methods[m]=="lassocv":
				opt =allopt[m]
				newmethod= build_pipeline(allpipe[m])
				newmethod.append(('lassocv',ElasticNetCV(**opt)))
			if methods[m]=="ridgecv":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m])
				newmethod.append(('lassocv',ElasticNetCV(**opt)))
			if methods[m]=="elasticcv":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m])
				newmethod.append(('lassocv',ElasticNetCV(**opt)))
			if methods[m]=="rf":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m])
				newmethod.append(('rf',RandomForestRegressor(**opt)))
			if methods[m]=="gradboost":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m])
				newmethod.append(('gbr',GradientBoostingRegressor(**opt)))
			if methods[m]=="svm":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m])
				newmethod.append(('svm', SVR(**opt)))
			if methods[m]=="linsvm":	
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m])
				newmethod.append(('linsvm',LinearSVR(**opt)))
			if methods[m]=="nnet":	
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m])
				newmethod.append(('mlp',MLPRegressor(**opt)))
		elif type=="class":
			if methods[m]=="lassoic":
				sfi.SFIToolkit.stata("di as err lassoic not supported with type(class)")
				sfi.SFIToolkit.error()
			if methods[m]=="lassocv":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m])
				newmethod.append(('lassocv',LogisticRegressionCV(**opt)))
			if methods[m]=="ridgecv":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m])
				newmethod.append(('lassocv',LogisticRegressionCV(**opt)))
			if methods[m]=="elasticcv":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m])
				newmethod.append(('lassocv',LogisticRegressionCV(**opt)))
			if methods[m]=="rf":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m])
				newmethod.append(('rf',RandomForestClassifier(**opt)))
			if methods[m]=="gradboost":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m])
				newmethod.append(('gradboost',GradientBoostingClassifier(**opt)))
			if methods[m]=="svm":	
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m])
				newmethod.append(('svm',SVC(**opt)))
			if methods[m]=="linsvm":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m])
				newmethod.append(('linsvm',LinearSVC(**opt)))
			if methods[m]=="nnet":	
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m])
				newmethod.append(('mlp',MLPClassifier(**opt)))
		else: 
			sfi.SFIToolkit.stata("di as err method not known")
			sfi.SFIToolkit.error()
		est_list.append((methods[m],Pipeline(newmethod)))

	if finalest == "logit": 
		fin_est=LogisticRegression()
	else: 
		fin_est = LinearRegressionClassifier(fit_intercept=False,positive=True)
	if finalest=="ridge":
		fin_est = RidgeCV()
	else:
		fin_est = LinearRegression(fit_intercept=False,positive=True)

	if voting=="" and type=="reg":
		model = StackingRegressor(
					   estimators=est_list,
					   final_estimator=fin_est,
					   n_jobs=njobs,
					   cv=nfolds
				)
	elif voting=="" and type=="class":
		model = StackingClassifier(
					   estimators=est_list,
					   final_estimator=fin_est,
					   n_jobs=njobs,
					   cv=nfolds
				)
	elif voting!="" and type=="reg":
		model = VotingRegressor(
					   estimators=est_list,
					   n_jobs=njobs
				)
	elif voting!="" and type=="class":
		model = VotingClassifier(
					   estimators=est_list,
					   n_jobs=njobs, 
					   voting=votetype
				)


	##############################################################
	### fitting; save predictions in __main__				   ###
	##############################################################

	# Train model on training data
	if type=="class":
		y=y!=0
	model = model.fit(x,y)

	# for NNLS: standardize coefficients to sum to one
	if finalest == "nnls":
		model.final_estimator_.coef_ = model.final_estimator_.coef_ / model.final_estimator_.coef_.sum()

	w = model.final_estimator_.coef_
	if len(w.shape)==1:
		sfi.Matrix.store("e(weights)",w)
	else:
		sfi.Matrix.store("e(weights)",w[0])
	sfi.Macro.setGlobal("e(base_est)"," ".join(methods))  

	__main__.type = type

	if nosavepred=="" or nosavetransform=="":
		# Track NaNs
		x0_hasnan = np.isnan(x_0).any(axis=1)
		# Set any NaNs to zeros so that model.predict(.) won't crash
		x_0 = np.nan_to_num(x_0)

	if nosavepred == "" or nosavetransform == "":
		__main__.model_object = model
		__main__.model_xvars = xvars
		__main__.model_methods = methods

	if nosavepred == "":
		if type=="class" and finalest=="nnls":
			pred = model.predict_proba(x_0)>0.5
		else:
			pred = model.predict(x_0)
		# Set any predictions that should be missing to missing (NaN)
		if type=="class":
			pred = pred.astype(np.float32)
		pred[x0_hasnan] = np.nan
		__main__.predict = pred

	if nosavepred == "" and type =="class":
		pred_proba = model.predict_proba(x_0)
		# Set any predictions that should be missing to missing (NaN)
		pred[x0_hasnan] = np.nan
		__main__.predict_proba = pred_proba

	if nosavetransform == "":
		transf = model.transform(x_0)
		# Set any predictions that should be missing to missing (NaN)
		transf[x0_hasnan] = np.nan
		__main__.transform = transf
end