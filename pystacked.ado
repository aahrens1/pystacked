*! pystacked v0.1 (first release)
*! last edited: 25oct2021
*! authors: aa/ms

// parent program
program define pystacked, eclass sortpreserve
	version 16.0

	// no replay - must estimate
	if ~replay() {
		_pystacked `0'
	}
	
	// display results
	tempname weights_mat
	mat `weights_mat'=e(weights)
	local base_est `e(base_est)'
	local nlearners	= e(mcount)

	di as text "{hline 17}{c TT}{hline 21}"
	di as text "  Method" _c
	di as text _col(18) "{c |}      Weight"
	di as text "{hline 17}{c +}{hline 21}"

	forvalues j=1/`nlearners' {
		local b : word `j' of `base_est'
		di as text "  `b'" _c
		di as text _col(18) "{c |}" _c
		di as res %15.7f el(`weights_mat',`j',1)
	}

	// parse and check for graph/table options
	syntax [anything]  [if] [in] [aweight fweight] , 	///
				[										///
					GRAPH1								/// vanilla option, abbreviates to "graph"
					graph(string)						/// for passing options to graph combine
					lgraph(string)						/// for passing options to the graphs of the learners
					table								/// 
					HOLDOUT1							/// vanilla option, abbreviates to "holdout"
					holdout(varname)					///
					*									///
				]
	
	// graph/table block
	if "`graph'`graph1'`table'" ~= "" {
		pystacked_graph_table,							///
			`holdout1' holdout(`holdout')				///
			`graph1'									///
			goptions(`graph') lgoptions(`lgraph')		///
			`table'
	}
	
	// print table
	if "`table'" ~= "" {
		tempname m w
		mat `m' = r(m)
		
		di
		di as text "MSPE: In-Sample and Out-of-Sample"
		di as text "{hline 17}{c TT}{hline 35}"
		di as text "  Method" _c
		di as text _col(18) "{c |} Weight   In-Sample   Out-of-Sample"
		di as text "{hline 17}{c +}{hline 35}"
		
		di as text "  STACKING" _c
		di as text _col(18) "{c |}" _c
		di as text "    .  " _c
		di as res  _col(30) %7.3f el(`m',1,1) _col(44) %7.3f el(`m',1,2)
		
		forvalues j=1/`nlearners' {
			local b : word `j' of `base_est'
			di as text "  `b'" _c
			di as text _col(18) "{c |}" _c
			di as res _col(20) %5.3f el(`weights_mat',`j',1) _c
			di as res _col(30) %7.3f el(`m',`j',1) _col(44) %7.3f el(`m',`j',2)
		}

		// add to estimation macros
		ereturn mat mspe = `m'
	}
	
		
end

// graph and/or table
program define pystacked_graph_table, rclass
	version 16.0
	syntax ,							///
				[						///
					HOLDOUT1			/// vanilla option, abbreviates to "holdout"
					holdout(varname)	///
					graph				///
					goptions(string)	///
					lgoptions(string)	///
					table				/// 
				]
		
	if "`holdout'`holdout1'"=="" {
		local title In-sample Predictions
		tempvar touse
		qui gen `touse' = e(sample)
	}
	else {
		local title Out-of-sample Predictions
		// holdout variable provided, or default = not-in-sample?
		if "`holdout'"=="" {
			// default
			tempvar touse
			qui gen `touse' = 1-e(sample)
			// check number of OOS obs
			qui count if `touse'
			if r(N)==0 {
				di as err "error - no observations in holdout sample"
				exit 198
			}
			di
			di as text "Number of holdout observations:" as res %5.0f r(N)
		}
		else {
			// check that holdout variable doesn't overlap with e(sample)
			qui count if e(sample) & `holdout' > 0
			if r(N) > 0 {
				di as err "error - holdout and estimation samples overlap"
				exit 198
			}
			local touse `holdout'
		}
	}

	local nlearners	= e(mcount)
	local learners	`e(base_est)'
	local y			`e(depvar)'
	// weights
	tempname weights
	mat `weights'	= e(weights)

	tempvar stacking_p stacking_r
	predict double `stacking_p'
	label var `stacking_p' "Prediction: Stacking Regressor"
	qui gen double `stacking_r' = `y' - `stacking_p'
	// not ideal, will need to drop by hand later
	qui predict double `stacking_p', transform
	forvalues i=1/`nlearners' {
		local lname : word `i' of `learners'
		label var `stacking_p'`i' "Prediction: `lname'"
		tempvar stacking_r`i'
		qui gen double `stacking_r`i'' = `y' - `stacking_p'`i'
	}

	if "`graph'"~="" {
		twoway (scatter `stacking_p' `y') (line `y' `y') if `touse'		///
			,															///
			legend(off)													///
			title("STACKING")											///
			`lgoptions'													///
			nodraw														///
			name(`g0', replace)
		local glist `g0'
		forvalues i=1/`nlearners' {
			tempname g`i'
			local lname : word `i' of `learners'
			local w : di %5.3f el(`weights',`i',1)
			twoway (scatter `stacking_p'`i' `y') (line `y' `y') if `touse'	///
				,															///
				legend(off)													///
				title("Learner: `lname'")									///
				`lgoptions'													///
				subtitle("weight = `w'")									///
				nodraw														///
				name(`g`i'', replace)
			local glist `glist' `g`i''
		}
	
		graph combine `glist'										///
						,											///
						title("`title'")							///
						`goptions'
	}
	
	if "`table'"~="" {
		
		// save in matrix
		tempname m m_in m_out
		
		// column for in-sample MSPE
		qui sum `stacking_r' if e(sample)
		mat `m_in' = r(sd) * sqrt( (r(N)-1)/r(N) )
		forvalues i=1/`nlearners' {
			qui sum `stacking_r`i'' if e(sample)
			mat `m_in' = `m_in' \ (r(sd) * sqrt( (r(N)-1)/r(N) ))
		}
		
		// column for OOS MSPE
		if "`holdout'`holdout1'"~="" {
			// touse is the holdout indicator
			qui sum `stacking_r' if `touse'
			mat `m_out' = r(sd) * sqrt( (r(N)-1)/r(N) )
			forvalues i=1/`nlearners' {
				qui sum `stacking_r`i'' if `touse'
				mat `m_out' = `m_out' \ (r(sd) * sqrt( (r(N)-1)/r(N) ))
			}
		}
		else {
			mat `m_out' = J(`nlearners'+1,1,.)
		}
		
		mat `m' = `m_in' , `m_out'
		mat colnames `m' = MSPE_in MSPE_out
		mat rownames `m' = STACKING `learners'
		
		return matrix m = `m'

	}
	
end

// main program
program define _pystacked, eclass
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
					njobs(int 0) ///
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
					backend(string) ///
					///
					/// options for graphing; ignore here
					GRAPH1								/// vanilla option, abbreviates to "graph"
					graph(string)						/// for passing options to graph combine
					lgraph(string)						/// for passing options to the graphs of the learners
					table								/// 
					HOLDOUT1							/// vanilla option, abbreviates to "holdout"
					holdout(varname)					///
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
	else if substr("`type'",1,5)=="class" {
		local type class
	}
	else {
		di as err "type(`type') not recognized"
		exit 198
	}

	* defaults
	if "`finalest'"=="" {
		local finalest nnls
	}

	if "`votetype'"!=""&"`type'"=="reg" {
		di as err "votetype not allowed with type(reg). ignored."
	}
	
	if "`backend'"=="" {
		if "`c(os)'"=="Windows" {
			local backend threading
		}
		else {
			local backend loky
		}
	}
	if "`backend'"!="loky"&"`backend'"!="multiprocessing"&"`backend'"!="threading" {
		di as err "backend not supported"
		exit 198
	}

	if "`votetype'"=="" {
		local votetype hard
	}
	else if "`votetype'"!="hard"&"`votetype'"!="soft" {
		di as error "votetype(`votetype') not allowed"
		error 198
	}

	if (`doublebarsyntax'==0)&("`methods'"=="") {
		if ("`type'"=="reg") {
			local methods ols lassoic gradboost
		}
		else {
			local methods logit lassocv gradboost
		}
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

	// no longer needed
	// ereturn clear
	// create esample variable for posting (disappears from memory after posting)
	tempvar esample
	qui gen byte `esample' = `touse'
	ereturn post, depname(`yvar') esample(`esample') obs(`N')

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
					"`showpywarnings'", ///
					"`backend'" ///
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

end

program define syntax_parse, rclass

	syntax [anything(everything)] , type(string)

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

### Import required Python modules
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
import __main__

### Define required Python functions/classes

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
			ll.append(('poly2',PolynomialFeatures(degree=2,include_bias=False)))
		elif pipes[p]=="poly3":
			ll.append(('poly3',PolynomialFeatures(degree=3,include_bias=False)))
		elif pipes[p]=="interact":
			ll.append(('interact',PolynomialFeatures(include_bias=False,interaction_only=True)))
	return ll

def run_stacked(type,finalest,methods,yvar,xvars,training,allopt,allpipe,
	touse,seed,nosavepred,nosavetransform,
	voting,votetype,voteweights,njobs,nfolds,nostandardscaler,showpywarnings,parbackend):
	
	if int(format(sklearn.__version__).split(".")[1])<24 and int(format(sklearn.__version__).split(".")[0])<1:
		sfi.SFIToolkit.stata('di as err "pystacked requires sklearn 0.24.0 or higher. Please update sklearn."')
		sfi.SFIToolkit.stata('di as err "See instructions on https://scikit-learn.org/stable/install.html, and in the help file."')
		sfi.SFIToolkit.error(198)

	# Set random seed
	if seed>0:
		#np.random.seed(seed)
		rng=np.random.RandomState(seed)
	else: 
		rng=None

	if nostandardscaler=="":
		stdscaler = StandardScaler()
	else: 
		stdscaler = 'passthrough'

	if showpywarnings=="":
		import warnings
		warnings.filterwarnings('ignore') 

	if njobs==0: 
		nj = None 
	else: 
		nj = njobs
		
	##############################################################
	### load data  											   ###
	##############################################################	

	# Load into Pandas data frame
	y = np.array(sfi.Data.get(yvar,selectvar=touse))
	x = np.array(sfi.Data.get(xvars,selectvar=touse))
	# If missings are present, need to specify they are NaNs.
	x_0 = np.array(sfi.Data.get(xvars,missingval=np.nan))

	##############################################################
	### prepare fit											   ###
	##############################################################

	methods = methods.split()
	allopt = eval(allopt)
	allpipe = eval(allpipe)

	est_list = []
	for m in range(len(methods)):
		if type=="reg":
			if methods[m]=="ols":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m])
				newmethod.append(('ols',LinearRegression(**opt)))
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
			if methods[m]=="logit":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m])
				newmethod.append(('lassocv',LogisticRegression(**opt)))
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
			sfi.SFIToolkit.stata('di as err "method not known"') 
			#"
			sfi.SFIToolkit.error()
		est_list.append((methods[m]+str(m),Pipeline(newmethod)))

	if finalest == "nnls" and type == "class": 
		fin_est = LinearRegressionClassifier(fit_intercept=False,positive=True)
	elif finalest == "ridge" and type == "class": 
		fin_est = LogisticRegression()
	elif finalest == "nnls" and type == "reg": 
		fin_est = LinearRegression(fit_intercept=False,positive=True)
	elif finalest == "ridge" and type == "reg": 
		fin_est = RidgeCV()
	elif finalest == "ols" and type == "class": 
		fin_est = LinearRegressionClassifier()	
	elif finalest == "ols" and type == "reg": 
		fin_est = LinearRegression()	
	else:
		sfi.SFIToolkit.stata('di as err "final estimator not supported with type()"')
		#"
		sfi.SFIToolkit.error(198)

	# if single base learner, use voting with weight = 1
	if len(methods)==1:
		voting="voting"
		voteweights=""
		sfi.SFIToolkit.stata('di as text "Single base learner: no stacking done."')
		#"

	if voting=="" and type=="reg":
		model = StackingRegressor(
					   estimators=est_list,
					   final_estimator=fin_est,
					   n_jobs=nj,
					   cv=nfolds
				)
	elif voting=="" and type=="class":
		model = StackingClassifier(
					   estimators=est_list,
					   final_estimator=fin_est,
					   n_jobs=nj,
					   cv=nfolds
				)
	elif voting!="":
		if voteweights!="":
			vweights = voteweights.split(" ")
			if len(vweights)!=len(methods)-1:
				sfi.SFIToolkit.stata('di as err "numlist in voteweights should be number of base learners - 1"')
				#"
				sfi.SFIToolkit.error(198)				
			vweights = [float(i) for i in vweights]
			vw_sum = sum(vweights)
			if vw_sum>1:
				sfi.SFIToolkit.stata('di as err "sum of voting weights larger than 1."')
				#"
				sfi.SFIToolkit.error(198)
			vweights.append(1-vw_sum)
		else: 
			vweights=None
		if type=="reg":
			model = VotingRegressor(
						   estimators=est_list,
						   n_jobs=nj,
						   weights=vweights
					)
		else: 
			model = VotingClassifier(
						   estimators=est_list,
						   n_jobs=nj, 
						   voting=votetype,
						   weights=vweights
					)

	##############################################################
	### fitting; save predictions in __main__				   ###
	##############################################################

	# Train model on training data
	if type=="class":
		y=y!=0
	with sklearn.utils.parallel_backend(parbackend):
		model = model.fit(x,y)

	# for NNLS: standardize coefficients to sum to one
	if voting=="":
		if finalest == "nnls":
			model.final_estimator_.coef_ = model.final_estimator_.coef_ / model.final_estimator_.coef_.sum()
		w = model.final_estimator_.coef_
		if len(w.shape)==1:
			sfi.Matrix.store("e(weights)",w)
		else:
			sfi.Matrix.store("e(weights)",w[0])
	elif vweights!=None: 
		w = np.array(vweights)
		sfi.Matrix.store("e(weights)",w)
	else:
		w = np.array([1/len(methods)]*len(methods))
		sfi.Matrix.store("e(weights)",w)
		
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

	# save versions of Python and packages
	sfi.Macro.setGlobal("e(sklearn_ver)",format(sklearn.__version__))
	sfi.Macro.setGlobal("e(numpy_ver)",format(np.__version__))
	sfi.Macro.setGlobal("e(scipy_ver)",format(scipy.__version__))
	sfi.Macro.setGlobal("e(python_ver)",format(sys.version))

end