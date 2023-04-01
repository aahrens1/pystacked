*! pystacked v0.7.1
*! last edited: 1april2023
*! authors: aa/ms

program _pyparse 
	syntax [anything] , ///
						type(string) Methods(string) ///
						[ sklearn1(real 1) sklearn2(real 0) sklearn3(real 0) PRINTopt debug *]

	if ("`methods'"!="") {

		local mcount : word count `methods'
		if `mcount'>1 {
			di as err "only one method allowed"
			error 198
		}

		if substr("`type'",1,3)=="reg" {
			local type reg
		}
		else {
			local type class
		}

		if "`printopt'"!="" {
			di as text ""
			di as text "Machine learner: `methods'"
			di as text ""
		}

		** v 1.1.2 becomes 101.2
		local sklearn_ver = `sklearn1'*100+`sklearn2'+`sklearn3'/10
		local options `options' sklearn_ver(`sklearn_ver') `printopt'

		if "`type'"=="reg" {
			if "`methods'"=="ols" {
				parse_LinearRegression , `options'
			}
			else if "`methods'"=="lassoic" {
				parse_LassoIC , `options' 
			}
			else if "`methods'"=="lassocv" {
				parse_ElasticCV , `options' l1_ratio(1) 
			}
			else if "`methods'"=="ridgecv" {
				parse_ElasticCV , `options' l1_ratio(0) 
			}
			else if "`methods'"=="elasticcv" {
				parse_ElasticCV , `options' 
			}
			else if "`methods'"=="svm" {
				parse_SVR , `options' 
			}
			else if "`methods'"=="gradboost" {
				parse_gradboostReg , `options' 
			}
			else if "`methods'"=="rf" {
				parse_rfReg , `options'
			}
			else if "`methods'"=="linsvm" {
				parse_LinearSVR , `options'
			}
			else if "`methods'"=="nnet" {
				parse_MLPReg , `options' 
			}
			else if "`methods'"=="xgb" {
				parse_XGB , `options' 
			}
			else {
				di as err "type(`type') with method(`methods') unknown"
				exit 198
			}
			local optstr `r(optstr)'
		}
		else if "`type'"=="class" {
			if "`methods'"=="logit" {
				parse_Logit , `options'   
			}
			else if "`methods'"=="lassocv" {
				parse_LassoLogitCV , `options' penalty(l1) solver(saga)
			}
			else if "`methods'"=="lassoic" {
				di as err "warning: lassoic not supported with type(class)."
				exit 198
			}
			else if "`methods'"=="elasticcv" {
				parse_LassoLogitCV , `options' penalty(elasticnet) solver(saga) 
			}
			else if "`methods'"=="ridgecv" {
				parse_LassoLogitCV , `options' penalty(l2)
			}
			else if "`methods'"=="svm" {
				parse_SVC , `options'
			}
			else if "`methods'"=="gradboost" {
				parse_gradboostClass , `options'
			}
			else if "`methods'"=="rf" {
				parse_rfClass , `options'
			}
			else if "`methods'"=="linsvm" {
				*parse_LinearSVC , `options'
				di as err "warning: linsvm not supported with type(class)."
				exit 198
			}
			else if "`methods'"=="nnet" {
				parse_MLPClass , `options'
			} 
			else if "`methods'"=="xgb" {
				parse_XGB , `options' 
			}
			else {
				di as err "type(`type') with method(`methods') unknown"
				exit 198
			}
			local optstr `r(optstr)'
		}
	}
	else {
		return_nothing
	}
	if "`debug'"!="" _printopt_tool `optstr'
end

program define parse_LinearRegression, rclass
	syntax [anything],  sklearn_ver(real) ///
					[ ///
					NOCONStant ///
					NORMalize ///
					POSitive ///
					PRINTopt /// 
					]

	if "`printopt'"!="" {
		di _skip(1) in smcl "{ul on}Stata syntax:{ul off}"
		di _skip(1) in smcl "{cmdab:nocons:tant} {cmdab:pos:itive}"
	}

	local optstr 

	** intercept
	if "`noconstant'"!="" {
		local optstr `optstr' 'fit_intercept':False,
	}
	else {
		local optstr `optstr' 'fit_intercept':True,
	}
	** normalize (discontinued from sklearn 1.2)
	if ("`normalize'"!="") {
		local optstr `optstr' 'normalize':True,
	}
	** positive
	if "`positive'"!="" {
		local optstr `optstr' 'positive':True,
	}
	else {
		local optstr `optstr' 'positive':False,
	}
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	if "`printopt'"!="" _print_tool `optstr'
	return local optstr `optstr'
end 

/* class sklearn.linear_model.LogisticRegression()[source]¶ */
program define parse_Logit, rclass
	syntax [anything],  sklearn_ver(real) ///
					[ ///
					NOCONStant /// 
					penalty(string) ///
					PRINTopt /// 
					]

	if "`printopt'"!="" {
		di _skip(1) in smcl "{ul on}Stata syntax:{ul off}"
		di _skip(1) in smcl "{cmdab:nocons:tant} {opt penalty(string)}"
	}

	local optstr 
	
	** intercept
	if "`noconstant'"!="" {
		local optstr `optstr' 'fit_intercept':False,
	}
	else {
		local optstr `optstr' 'fit_intercept':True,
	}
	** penalty
	if "`penalty'"=="none" | "`penalty'"=="None" {
		local penalty
	}
	if "`penalty'"!="" {
		local optstr `optstr' 'penalty':'`penalty'',
	}
	else if `sklearn_ver'<120 {
		local optstr `optstr' 'penalty':'none',
	} 
	else {
		local optstr `optstr' 'penalty':None,
	}
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	if "`printopt'"!="" _print_tool `optstr'
	return local optstr `optstr'
end 

/*
 class sklearn.linear_model.LogisticRegressionCV()[source]¶
  */
program define parse_LassoLogitCV, rclass
	syntax [anything],  sklearn_ver(real) ///
					[ ///
					l1_ratios(numlist) ///
					Cs(integer 10) ///
					NOCONStant /// 
					///cv(integer 5) ///
					penalty(string) ///
					solver(string) ///
					tol(real 1e-4) ///
					max_iter(integer 100) ///
					n_jobs(integer 0) ///
					NORefit ///
					intercept_scaling(real 1) ///
					random_state(integer -1) ///
					PRINTopt ///
					]

	if "`printopt'"!="" {
		di _skip(1) in smcl "{ul on}Stata syntax:{ul off}"
		di _skip(1) in smcl "{opt c:s(integer)} {opt nocons:tant} " _c
		di _skip(1) in smcl "{opt penalty(string)} {opt solver(string)} " _c
		di _skip(1) in smcl "{opt tol(real)} " _c
		di _skip(1) in smcl "{opt max_iter(integer)} {opt n_jobs(integer)} " 
		di _skip(1) in smcl "{opt nor:efit}" _c
		di _skip(1) in smcl "{opt intercept_scaling(real)} " _c
		di _skip(1) in smcl "{opt random_state(integer)}"
	}

	local optstr 
	
	if `cs'>0 {
		local optstr `optstr' 'Cs':`cs',
	}
	else {
		local optstr `optstr' 'Cs':10,
	}
	** intercept
	if "`noconstant'"!="" {
		local optstr `optstr' 'fit_intercept':False,
	}
	else {
		local optstr `optstr' 'fit_intercept':True,
	}
	** cv 
	*if `cv'>2 {
	*	local optstr `optstr' 'cv':`cv',
	*}
	** penalty
	if "`penalty'"=="l1"|"`penalty'"=="elasticnet"|"`penalty'"=="l2" {
		local optstr `optstr' 'penalty':'`penalty'',
	}
	else {
		local optstr `optstr' 'penalty':'l2',
	}
	** solver
	if "`solver'"=="newton-cg"|"`solver'"=="lbfgs"|"`solver'"=="liblinear"|"`solver'"=="sag"|"`solver'"=="saga" {
		local optstr `optstr' 'solver':'`solver'',
	}
	else {
		local optstr `optstr' 'solver':'newton-cg',
	}
	** tolerance
	if `tol'>=0 {
		local optstr `optstr' 'tol':`tol',
	}
	** max iterations
	if (`max_iter'>0) {
		local optstr `optstr' 'max_iter':`max_iter',
	}
	** n jobs
	if `n_jobs'!=0 {
		local optstr `optstr' 'n_jobs':`n_jobs',
	}
	else {
		local optstr `optstr' 'n_jobs':None,
	}
	** refit
	if "`norefit'"!="" {
		local optstr `optstr' 'refit':False,
	}
	else {
		local optstr `optstr' 'refit':True,
	}
	** intercept scaling
	local optstr `optstr' 'intercept_scaling':`intercept_scaling',
	** random state
	if `random_state'>=0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':rng,
	}
	** l1 ratios
	if "`penalty'"=="elasticnet" {
		if "`l1_ratios'"=="" local l1_ratios 0 .5 1
		local l1_ratios_list
		foreach i of numlist `l1_ratios' {
			local l1_ratios_list `l1_ratios_list'`i',
		}
		local optstr `optstr' 'l1_ratios':(`l1_ratios_list'),
	}
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	if "`printopt'"!="" _print_tool `optstr'
	return local optstr `optstr'
end 

/*
class sklearn.linear_model.ElasticNetCV(*, l1_ratio=0.5, eps=0.001, 
n_alphas=100, alphas=None, fit_intercept=True, normalize=False, 
precompute='auto', max_iter=1000, tol=0.0001, cv=None, 
copy_X=True, verbose=0, n_jobs=None, positive=False, 
random_state=None, selection='cyclic')
*/
program define parse_ElasticCV, rclass
	syntax [anything],  sklearn_ver(real) ///
					[ ///
					l1_ratio(real .5) ///
					eps(real 1e-3) ///
					n_alphas(integer 100) ///	
					alphas(numlist >0) ///			
					NOCONStant ///
					NORMalize ///
					max_iter(integer 1000) ///
					tol(real 1e-4) ///
					///cv(integer 5) ///
					n_jobs(integer 0) ///
					POSitive ///
					random_state(integer -1) ///
					selection(string) ///
					PRINTopt ///
					]

	if "`printopt'"!="" {
		di _skip(1) in smcl "{ul on}Stata syntax:{ul off}"
		di _skip(1) in smcl "{opt alphas(numlist >0)} " _c
		di _skip(1) in smcl "{opt l1_ratio(real .5)} " _c
		di _skip(1) in smcl "{opt eps(real)} " _c
		di _skip(1) in smcl "{opt n_alphas(integer)} " _c
		di _skip(1) in smcl "{opt nocons:tant} " _c
		di _skip(1) in smcl "{opt max_iter(integer)} " _c
		di _skip(1) in smcl "{opt tol(real)} " 
		di _skip(1) in smcl "{opt n_jobs(integer)} " _c
		di _skip(1) in smcl "{opt pos:itive} " _c
		di _skip(1) in smcl "{opt selection(string)} " _c
		di _skip(1) in smcl "{opt random_state(integer)} "
	}

	local optstr 

	** alphas
	if ("`alphas'"==""&`l1_ratio'>0) {
		local optstr `optstr' 'alphas':None,
	}
	else if ("`alphas'"==""&`l1_ratio'==0) {
		local optstr `optstr' 'alphas':[0,1,10],
	}
	else {
		local allist 
		foreach i of numlist `alphas' {
			local allist `allist'`i',
		}
		local optstr `optstr' 'alphas':[`allist'],
	}
	** l1 ratios
	if `l1_ratio'>=0 & `l1_ratio'<= 1 {
		local optstr `optstr' 'l1_ratio':`l1_ratio',
	}
	** eps
	if (`eps'>0) {
		local optstr `optstr' 'eps':`eps',
	} 
	** n alphas
	if (`n_alphas'>0) {
		local optstr `optstr' 'n_alphas':`n_alphas',
	} 
	** intercept
	if "`noconstant'"!="" {
		local optstr `optstr' 'fit_intercept':False,
	}
	else {
		local optstr `optstr' 'fit_intercept':True,
	}
	** normalize (discontinues from sklearn 1.2)
	if ("`normalize'"!="") {
		local optstr `optstr' 'normalize':True,
	}
	** max iterations
	if (`max_iter'>0) {
		local optstr `optstr' 'max_iter':`max_iter',
	}
	** tolerance
	if `tol'>=0 {
		local optstr `optstr' 'tol':`tol',
	}
	** cv
	*if `cv'>2 {
	*	local optstr `optstr' 'cv':`cv',
	*}
	*else {
	*	local optstr `optstr' 'cv':5,
	*}
	** n jobs
	if `n_jobs'!=0 {
		local optstr `optstr' 'n_jobs':`n_jobs',
	}
	else {
		local optstr `optstr' 'n_jobs':None,
	}
	** positive
	if "`positive'"!="" {
		local optstr `optstr' 'positive':True,
	}
	else {
		local optstr `optstr' 'positive':False,
	}
	** 
	if "`selection'"=="cyclic"|"`selection'"=="random" {
		local optstr `optstr' 'selection':'`selection'',
	} 
	else {
		local optstr `optstr' 'selection':'cyclic',
	}
	** random state
	if `random_state'>=0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':rng,
	}
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	if "`printopt'"!="" _print_tool `optstr'
	return local optstr `optstr'
end 

/*
 class sklearn.linear_model.LassoLarsIC() 
 */
program define parse_LassoIC, rclass
	syntax [anything],  sklearn_ver(real) ///
					[criterion(string) ///
					NOCONStant ///
					max_iter(integer 500) ///
					eps(real -1) ///
					PRINTopt ///
					positive ]

	if "`printopt'"!="" {
		di _skip(1) in smcl "{ul on}Stata syntax:{ul off}"
		di _skip(1) in smcl "{opt criterion(string)} " _c
		di _skip(1) in smcl "{opt nocons:tant} " _c
		di _skip(1) in smcl "{opt max_iter(integer)} " _c
		di _skip(1) in smcl "{opt eps(real)} " _c
		di _skip(1) in smcl "{opt positive} "
	}

	local optstr 
	
	** criterion
	if "`criterion'"=="bic" {
		local optstr `optstr' 'criterion':'bic', 
	}
	else {
		local optstr `optstr' 'criterion':'aic', 
	}
	** intercept
	if "`noconstant'"!="" {
		local optstr `optstr' 'fit_intercept':False,
	}
	else {
		local optstr `optstr' 'fit_intercept':True,
	}
	** max iterations
	if (`max_iter'>0) {
		local optstr `optstr' 'max_iter':`max_iter',
	}
	** eps
	if (`eps'>0) {
		local optstr `optstr' 'eps':`eps',
	} 
	** positive
	if "`positive'"!="" {
		local optstr `optstr' 'positive':True,
	}
	else {
		local optstr `optstr' 'positive':False,
	}
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	if "`printopt'"!="" _print_tool `optstr'
	return local optstr `optstr'
end 

** sklearn.ensemble.RandomForestRegressor
/*
 class sklearn.ensemble.RandomForestRegressor()[source]¶
 */
program define parse_rfReg, rclass
	syntax [anything] , ///
					 sklearn_ver(real) ///
					[ ///
					n_estimators(integer 100) ///
					criterion(string) ///
					max_depth(integer -1) ///  
					min_samples_split(real 2) ///
					min_samples_leaf(real 1) /// 
					min_weight_fraction_leaf(real 0) ///
					max_features(string) ///
					max_leaf_nodes(integer -1) ///
					min_impurity_decrease(real 0) ///
					bootstrap(string)  ///
					oob_score  ///
					n_jobs(integer 0) ///
					random_state(integer -1) ///
					warm_start ///
					ccp_alpha(real 0) ///
					max_samples(real -1) ///  
					PRINTopt ///
					]

	if "`printopt'"!="" {
		di _skip(1) in smcl "{ul on}Stata syntax:{ul off}"
		di _skip(1) in smcl "{opt n_estimators(integer 100)} " _c
		di _skip(1) in smcl "{opt criterion(string)} " _c
		di _skip(1) in smcl "{opt max_depth(integer -1)} " _c
		di _skip(1) in smcl "{opt min_samples_split(real 2)} " _c
		di _skip(1) in smcl "{opt min_samples_leaf(real 1)} "  
		di _skip(1) in smcl "{opt min_weight_fraction_leaf(real 0)} " _c
		di _skip(1) in smcl "{opt max_features(string)} " _c
		di _skip(1) in smcl "{opt max_leaf_nodes(integer -1)} " _c
		di _skip(1) in smcl "{opt min_impurity_decrease(real 0)} " _c
		di _skip(1) in smcl "{opt bootstrap(string)} " 
		di _skip(1) in smcl "{opt oob_score} " _c
		di _skip(1) in smcl "{opt n_jobs(integer 0)} " _c
		di _skip(1) in smcl "{opt random_state(integer -1)} " _c
		di _skip(1) in smcl "{opt warm_start} " _c
		di _skip(1) in smcl "{opt ccp_alpha(real 0)} " _c
		di _skip(1) in smcl "{opt max_samples(real -1)} " 
	}

	local optstr 

	** number of trees in the forest
	if `n_estimators'>0 {
		local optstr `optstr' 'n_estimators':`n_estimators',
	}
	** criterion
	if strpos("mae mse squared_error absolute_error poisson","`criterion'")!=0 & "`criterion'"!="" {
		local optstr `optstr' 'criterion':'`criterion'',		
	}
	else if "`criterion'"=="" & `sklearn_ver'<100 {
		// use default
		local optstr `optstr' 'criterion':'mse',	
	}
	else if "`criterion'"=="" & `sklearn_ver'>=100 {
		// use default
		local optstr `optstr' 'criterion':'squared_error',	
	}
	else {
		di as err "criterion(`criterion') not allowed"
		error 197
	}
	** max depth
	if `max_depth'>0 {
		local optstr `optstr' 'max_depth':`max_depth',
	} 
	else {
		local optstr `optstr' 'max_depth':None,
	}
	** min sample split
	if `min_samples_split'>0 {
		local optstr `optstr' 'min_samples_split':`min_samples_split',
	}
	** min samples leaf
	if `min_samples_leaf'>0 {
		local optstr `optstr' 'min_samples_leaf':`min_samples_leaf',
	}
	** min weight fraction leaf
	if `min_weight_fraction_leaf'>=0 {
		local optstr `optstr' 'min_weight_fraction_leaf':`min_weight_fraction_leaf',
	}
	** max features
	if "`max_features'"=="auto"|"`max_features'"=="sqrt"|"`max_features'"=="log2" {
		local optstr `optstr' 'max_features':'`max_features'',
	} 
	else if "`max_features'"=="" {
		if (`sklearn_ver'>=101) {
			local optstr `optstr' 'max_features':1.0,
		}
		else {
			local optstr `optstr' 'max_features':'auto',
		}
	} 
	else {
		local optstr `optstr' 'max_features':`max_features',
	}
	** max leaf nodes
	if `max_leaf_nodes'>0 {
		local optstr `optstr' 'max_leaf_nodes':`max_leaf_nodes',
	}	
	else {
		local optstr `optstr' 'max_leaf_nodes':None,
	}
	** min impurity decrease
	if `min_impurity_decrease'>=0 {
		local optstr `optstr' 'min_impurity_decrease':`min_impurity_decrease',
	}
	** bootstrap
	if "`bootstrap'"!="" {
		local optstr `optstr' 'bootstrap':`bootstrap',
	}
	else {
		local optstr `optstr' 'bootstrap':True,
	}
	** oob score
	if "`oob_score'"!="" {
		local optstr `optstr' 'oob_score':True,
	}
	else {
		local optstr `optstr' 'oob_score':False,
	}
	** n jobs
	if `n_jobs'!=0 {
		local optstr `optstr' 'n_jobs':`n_jobs',
	}
	else {
		local optstr `optstr' 'n_jobs':None,
	}
	** random state
	if `random_state'>=0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':rng,
	}
	** warm start 
	if "`warm_start'"!="" {
		local optstr `optstr' 'warm_start':True,
	}
	else {
		local optstr `optstr' 'warm_start':False,
	}
	** ccp alpha
	if `ccp_alpha'>=0 {
		local optstr `optstr' 'ccp_alpha':`ccp_alpha',
	}
	** max samples
	if `max_samples'>=0 {
		local optstr `optstr' 'max_samples':`max_samples',
	}
	else {
		local optstr `optstr' 'max_samples':None,
	}
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	if "`printopt'"!="" _print_tool `optstr'
	return local optstr `optstr'
end 

** sklearn.ensemble.RandomForestClassifier
/*
 class sklearn.ensemble.RandomForestClassifier()[source]¶
 */
program define parse_rfClass, rclass
	syntax [anything] , ///
					 sklearn_ver(real) ///
					[ ///
					n_estimators(integer 100) ///
					criterion(string) ///
					max_depth(integer -1) ///  
					min_samples_split(real 2) /// only int supported
					min_samples_leaf(real 1) /// 
					min_weight_fraction_leaf(real 0) ///
					max_features(string) ///
					max_leaf_nodes(integer -1) ///
					min_impurity_decrease(real 0) ///
					bootstrap(string)  ///
					///class_weight(string) ///
					oob_score  ///
					n_jobs(integer 0) ///
					random_state(integer -1) ///
					warm_start ///
					ccp_alpha(real 0) ///
					max_samples(integer -1) /// only int supported
					PRINTopt ///
					]

	if "`printopt'"!="" {
		di _skip(1) in smcl "{ul on}Stata syntax:{ul off}"
		di _skip(1) in smcl "{opt n_estimators(integer 100)} " _c 
		di _skip(1) in smcl "{opt criterion(string)} " _c 
		di _skip(1) in smcl "{opt max_depth(integer -1)} " _c 
		di _skip(1) in smcl "{opt min_samples_split(real 2)} "
		di _skip(1) in smcl "{opt min_samples_leaf(real 1)} "   _c 
		di _skip(1) in smcl "{opt min_weight_fraction_leaf(real 0)} " _c 
		di _skip(1) in smcl "{opt max_features(string)} " _c 
		di _skip(1) in smcl "{opt max_leaf_nodes(integer -1)} " 
		di _skip(1) in smcl "{opt min_impurity_decrease(real 0)} " _c 
		di _skip(1) in smcl "{opt bootstrap(string)} "  _c 
		di _skip(1) in smcl "{opt oob_score} " _c 
		di _skip(1) in smcl "{opt n_jobs(integer 0)} "    
		di _skip(1) in smcl "{opt random_state(integer -1)} " _c 
		di _skip(1) in smcl "{opt warm_start} " _c 
		di _skip(1) in smcl "{opt ccp_alpha(real 0)} "  _c 
		di _skip(1) in smcl "{opt max_samples(integer -1)}"
	}

	local optstr 

	** number of trees in the forest
	if `n_estimators'>0 {
		local optstr `optstr' 'n_estimators':`n_estimators',
	}
	** criterion
	if "`criterion'"=="gini"|"`criterion'"=="entropy" {
		local optstr `optstr' 'criterion':'`criterion'',		
	}
	else if "`criterion'"=="" {
		local optstr `optstr' 'criterion':'gini',	
	}
	else {
		di as err "criterion(`criterion') not allowed"
		error 197
	}
	** max depth
	if `max_depth'>0 {
		local optstr `optstr' 'max_depth':`max_depth',
	} 
	else {
		local optstr `optstr' 'max_depth':None,
	}
	** min sample split
	if `min_samples_split'>0 {
		local optstr `optstr' 'min_samples_split':`min_samples_split',
	}
	** min samples leaf
	if `min_samples_leaf'>0 {
		local optstr `optstr' 'min_samples_leaf':`min_samples_leaf',
	}
	** min weight fraction leaf
	if `min_weight_fraction_leaf'>=0 {
		local optstr `optstr' 'min_weight_fraction_leaf':`min_weight_fraction_leaf',
	}
	** max features
	if "`max_features'"=="auto"|"`max_features'"=="sqrt"|"`max_features'"=="log2" {
		local optstr `optstr' 'max_features':'`max_features'',
	} 
	else if "`max_features'"=="" {
		if (`sklearn_ver'>=101) {
			local optstr `optstr' 'max_features':1.0,
		}
		else {
			local optstr `optstr' 'max_features':'auto',
		}
	}
	else {
		local optstr `optstr' 'max_features':`max_features',
	}
	** max leaf nodes
	if `max_leaf_nodes'>0 {
		local optstr `optstr' 'max_leaf_nodes':`max_leaf_nodes',
	}	
	else {
		local optstr `optstr' 'max_leaf_nodes':None,
	}
	** min impurity decrease
	if `min_impurity_decrease'>=0 {
		local optstr `optstr' 'min_impurity_decrease':`min_impurity_decrease',
	}
	** bootstrap
	if "`bootstrap'"!="" {
		local optstr `optstr' 'bootstrap':`bootstrap',
	}
	else {
		local optstr `optstr' 'bootstrap':True,
	}
	** oob score
	if "`oob_score'"!="" {
		local optstr `optstr' 'oob_score':True,
	}
	else {
		local optstr `optstr' 'oob_score':False,
	}
	** n jobs
	if `n_jobs'!=0 {
		local optstr `optstr' 'n_jobs':`n_jobs',
	}
	else {
		local optstr `optstr' 'n_jobs':None,
	}
	** random state
	if `random_state'>=0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':rng,
	}
	** warm start 
	if "`warm_start'"!="" {
		local optstr `optstr' 'warm_start':True,
	}
	else {
		local optstr `optstr' 'warm_start':False,
	}
	** class_weight
	//if "`class_weight'"=="balanced"|"`class_weight'"=="balanced_subsample" {
	//	local optstr `optstr' 'class_weight':'`class_weight'',
	//}
	//else {
	//	local optstr `optstr' 'class_weight':None,
	//}
	** ccp alpha
	if `ccp_alpha'>=0 {
		local optstr `optstr' 'ccp_alpha':`ccp_alpha',
	}
	** max samples
	if `max_samples'>0 {
		local optstr `optstr' 'max_samples':`max_samples',
	}
	else {
		local optstr `optstr' 'max_samples':None,
	}
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	if "`printopt'"!="" _print_tool `optstr'
	return local optstr `optstr'
end 

** sklearn.ensemble.GradientBoostingRegressor
/* class sklearn.ensemble.GradientBoostingRegressor()
*/
program define parse_gradboostReg, rclass
	syntax [anything] , ///
					 sklearn_ver(real) ///
					[ ///
					loss(string) ///
					criterion(string) ///
					learning_rate(real 0.1) ///
					n_estimators(integer 100) ///
					subsample(real 1) ///
					min_samples_split(real 2) /// only int supported
					min_samples_leaf(real 1) /// only int supported
					min_weight_fraction_leaf(real 0) ///
					max_depth(integer 3) ///  
					min_impurity_decrease(real 0) ///
					init(string) ///
					random_state(integer -1) ///
					max_features(string) ///
					alpha(real 0.9) ///
					max_leaf_nodes(integer -1) ///
					warm_start ///
					validation_fraction(real 0.1) ///
					n_iter_no_change(integer -1) ///
					tol(real 1e-4) ///
					ccp_alpha(real 0) ///
					PRINTopt ///
					]

	if "`printopt'"!="" {
		di _skip(1) in smcl "{ul on}Stata syntax:{ul off}"
		di _skip(1) in smcl "{opt loss(string)} " _c
		di _skip(1) in smcl "{opt criterion(string)} " _c
		di _skip(1) in smcl "{opt learning_rate(real 0.1)} " _c
		di _skip(1) in smcl "{opt n_estimators(integer 100)} " _c
		di _skip(1) in smcl "{opt subsample(real 1)} "  
		di _skip(1) in smcl "{opt min_samples_split(real 2)} " _c
		di _skip(1) in smcl "{opt min_samples_leaf(real 1)} " _c
		di _skip(1) in smcl "{opt min_weight_fraction_leaf(real 0)} " _c
		di _skip(1) in smcl "{opt max_depth(integer 3)} "  
		di _skip(1) in smcl "{opt min_impurity_decrease(real 0)} " _c 
		di _skip(1) in smcl "{opt init(string)} " _c
		di _skip(1) in smcl "{opt random_state(integer -1)} " _c
		di _skip(1) in smcl "{opt max_features(string)} " _c
		di _skip(1) in smcl "{opt alpha(real 0.9)} "
		di _skip(1) in smcl "{opt max_leaf_nodes(integer -1)} "   _c
		di _skip(1) in smcl "{opt warm_start} " _c
		di _skip(1) in smcl "{opt validation_fraction(real 0.1)} " _c
		di _skip(1) in smcl "{opt n_iter_no_change(integer -1)} " 
		di _skip(1) in smcl "{opt tol(real 1e-4)} " _c
		di _skip(1) in smcl "{opt ccp_alpha(real 0)} " 
	}

	local optstr 

	** loss
	if strpos("absolute_error squared_error ls lad huber quantile","`loss'")!=0 & "`loss'"!="" {
		local optstr `optstr' 'loss':'`loss'',
	} 
	else if "`loss'"=="" & `sklearn_ver'<100 {
		local optstr `optstr' 'loss':'ls',
	}
	else if "`loss'"=="" & `sklearn_ver'>=100 {
		local optstr `optstr' 'loss':'squared_error',
	}
	else {
		di as err "loss(`loss') not supported"
		error 197
	}
	** learning rate
	if `learning_rate'>=0 {
		local optstr `optstr' 'learning_rate':`learning_rate',
	}
	** number of trees in the forest
	if `n_estimators'>0 {
		local optstr `optstr' 'n_estimators':`n_estimators',
	}
	** subsample
	if `subsample'>=0 {
		local optstr `optstr' 'subsample':`subsample',
	}
	** criterion
	if strpos("friedman_mse squared_error mse mae","`criterion'")!=0 & "`criterion'"!="" {
		local optstr `optstr' 'criterion':'`criterion'',		
	}
	else if "`criterion'"=="" {
		// use default
		local optstr `optstr' 'criterion':'friedman_mse',	
	}
	else {
		di as err "criterion(`criterion') not allowed"
		error 197
	}
	** min sample split
	if `min_samples_split'>0 {
		local optstr `optstr' 'min_samples_split':`min_samples_split',
	}
	** min samples leaf
	if `min_samples_leaf'>0 {
		local optstr `optstr' 'min_samples_leaf':`min_samples_leaf',
	}
	** min weight fraction leaf
	if `min_weight_fraction_leaf'>=0 {
		local optstr `optstr' 'min_weight_fraction_leaf':`min_weight_fraction_leaf',
	}
	** max depth
	if `max_depth'>0 {
		local optstr `optstr' 'max_depth':`max_depth',
	} 
	** min impurity decrease
	if `min_impurity_decrease'>=0 {
		local optstr `optstr' 'min_impurity_decrease':`min_impurity_decrease',
	}
	** init
	if "`init'"=="zero" {
		local optstr `optstr' 'init':'zero',
	}
	else {
		local optstr `optstr' 'init':None,
	}
	** random state
	if `random_state'>=0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':rng,
	}
	** max features
	if "`max_features'"=="auto"|"`max_features'"=="sqrt"|"`max_features'"=="log2" {
		local optstr `optstr' 'max_features':'`max_features'',
	} 
	else if "`max_features'"=="" {
		local optstr `optstr' 'max_features':None,
	}
	else {
		local optstr `optstr' 'max_features':`max_features',
	}
	** alpha
	if `alpha'>=0 {
		local optstr `optstr' 'alpha':`alpha',
	}
	** max leaf nodes
	if `max_leaf_nodes'>0 {
		local optstr `optstr' 'max_leaf_nodes':`max_leaf_nodes',
	}	
	else {
		local optstr `optstr' 'max_leaf_nodes':None,
	}
	** warm start 
	if "`warm_start'"!="" {
		local optstr `optstr' 'warm_start':True,
	}
	else {
		local optstr `optstr' 'warm_start':False,
	}
	** validation fraction
	if `validation_fraction'>=0 {
		local optstr `optstr' 'validation_fraction':`validation_fraction',
	}
	** n iter no change
	if `n_iter_no_change'>=0 {
		local optstr `optstr' 'n_iter_no_change':`n_iter_no_change',
	} 
	else {
		local optstr `optstr' 'n_iter_no_change':None,
	}
	** tolerance
	if `tol'>=0 {
		local optstr `optstr' 'tol':`tol',
	}
	** ccp alpha
	if `ccp_alpha'>=0 {
		local optstr `optstr' 'ccp_alpha':`ccp_alpha',
	}
	** return
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	if "`printopt'"!="" _print_tool `optstr'
	return local optstr `optstr'
end 

** sklearn.ensemble.GradientClassifier
/*  class sklearn.ensemble.GradientBoostingClassifier() */
program define parse_gradboostClass, rclass
	syntax [anything] , ///
					 sklearn_ver(real) ///
					[ ///
					loss(string) ///
					learning_rate(real 0.1) ///
					n_estimators(integer 100) ///
					subsample(real 1) ///
					criterion(string) ///
					min_samples_split(real 2) /// only int supported
					min_samples_leaf(real 1) /// only int supported
					min_weight_fraction_leaf(real 0) ///
					max_depth(integer 3) ///  
					min_impurity_decrease(real 0) ///
					init(string) ///
					random_state(integer -1) ///
					max_features(string) ///
					max_leaf_nodes(integer -1) ///
					warm_start ///
					validation_fraction(real 0.1) ///
					n_iter_no_change(integer -1) ///
					tol(real 1e-4) ///
					ccp_alpha(real 0) ///
					PRINTopt ///
					]

	if "`printopt'"!="" {
		di _skip(1) in smcl "{ul on}Stata syntax:{ul off}"
		di _skip(1) in smcl "{opt loss(string)} " _c
		di _skip(1) in smcl "{opt learning_rate(real 0.1)} " _c
		di _skip(1) in smcl "{opt n_estimators(integer 100)} " _c
		di _skip(1) in smcl "{opt subsample(real 1)} " _c
		di _skip(1) in smcl "{opt criterion(string)} "  
		di _skip(1) in smcl "{opt min_samples_split(real 2)} " _c
		di _skip(1) in smcl "{opt min_samples_leaf(real 1)} " _c
		di _skip(1) in smcl "{opt min_weight_fraction_leaf(real 0)} " _c
		di _skip(1) in smcl "{opt max_depth(integer 3)} " 
		di _skip(1) in smcl "{opt min_impurity_decrease(real 0)} " _c 
		di _skip(1) in smcl "{opt init(string)} " _c
		di _skip(1) in smcl "{opt random_state(integer -1)} " _c
		di _skip(1) in smcl "{opt max_features(string)} " _c
		di _skip(1) in smcl "{opt max_leaf_nodes(integer -1)} "
		di _skip(1) in smcl "{opt warm_start} "  _c
		di _skip(1) in smcl "{opt validation_fraction(real 0.1)} " _c
		di _skip(1) in smcl "{opt n_iter_no_change(integer -1)} " _c
		di _skip(1) in smcl "{opt tol(real 1e-4)} " _c
		di _skip(1) in smcl "{opt ccp_alpha(real 0)} "
	}

	local optstr 

	** loss
	if "`loss'"=="deviance"|"`loss'"=="exponential"|"`loss'"=="log_loss" {
		local optstr `optstr' 'loss':'`loss'',
	} 
	else if "`loss'"=="" {
		if (`sklearn_ver'<110) {
			local optstr `optstr' 'loss':'deviance',
		}
		else {
			local optstr `optstr' 'loss':'log_loss',
		}
	}
	else {
		di as err "loss(`loss') not supported"
		error 197
	}
	** learning rate
	if `learning_rate'>=0 {
		local optstr `optstr' 'learning_rate':`learning_rate',
	}
	** number of trees in the forest
	if `n_estimators'>0 {
		local optstr `optstr' 'n_estimators':`n_estimators',
	}
	** criterion
	if strpos("friedman_mse squared_error mse mae","`criterion'")!=0 & "`criterion'"!="" {
		local optstr `optstr' 'criterion':'`criterion'',		
	}
	else if "`criterion'"=="" {
		// use default
		local optstr `optstr' 'criterion':'friedman_mse',	
	}
	else {
		di as err "criterion(`criterion') not allowed"
		error 197
	}
	** subsample
	if `subsample'>=0 {
		local optstr `optstr' 'subsample':`subsample',
	}
	** min sample split
	if `min_samples_split'>0 {
		local optstr `optstr' 'min_samples_split':`min_samples_split',
	}
	** min samples leaf
	if `min_samples_leaf'>0 {
		local optstr `optstr' 'min_samples_leaf':`min_samples_leaf',
	}
	** min weight fraction leaf
	if `min_weight_fraction_leaf'>=0 {
		local optstr `optstr' 'min_weight_fraction_leaf':`min_weight_fraction_leaf',
	}
	** max depth
	if `max_depth'>0 {
		local optstr `optstr' 'max_depth':`max_depth',
	} 
	** min impurity decrease
	if `min_impurity_decrease'>=0 {
		local optstr `optstr' 'min_impurity_decrease':`min_impurity_decrease',
	}
	** init
	if "`init'"=="zero" {
		local optstr `optstr' 'init':'zero',
	}
	else {
		local optstr `optstr' 'init':None,
	}
	** random state
	if `random_state'>=0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':rng,
	}
	** max features
	if "`max_features'"=="auto"|"`max_features'"=="sqrt"|"`max_features'"=="log2" {
		local optstr `optstr' 'max_features':'`max_features'',
	} 
	else if "`max_features'"=="" {
		local optstr `optstr' 'max_features':None,
	}
	else {
		local optstr `optstr' 'max_features':`max_features',
	}
	** max leaf nodes
	if `max_leaf_nodes'>0 {
		local optstr `optstr' 'max_leaf_nodes':`max_leaf_nodes',
	}	
	else {
		local optstr `optstr' 'max_leaf_nodes':None,
	}
	** warm start 
	if "`warm_start'"!="" {
		local optstr `optstr' 'warm_start':True,
	}
	else {
		local optstr `optstr' 'warm_start':False,
	}
	** validation fraction
	if `validation_fraction'>=0 {
		local optstr `optstr' 'validation_fraction':`validation_fraction',
	}
	** n iter no change
	if `n_iter_no_change'>=0 {
		local optstr `optstr' 'n_iter_no_change':`n_iter_no_change',
	} 
	else {
		local optstr `optstr' 'n_iter_no_change':None,
	}
	** tolerance
	if `tol'>=0 {
		local optstr `optstr' 'tol':`tol',
	}
	** ccp alpha
	if `ccp_alpha'>=0 {
		local optstr `optstr' 'ccp_alpha':`ccp_alpha',
	}
	** return
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	if "`printopt'"!="" _print_tool `optstr'
	return local optstr `optstr'
end 

/*
 class sklearn.svm.SVR()[source]¶
 */
program define parse_SVR, rclass
	syntax [anything] , ///
					 sklearn_ver(real) ///
					[ ///
					KERnel(string) ///
					degree(integer 3) ///
					GAMma(string) ///
					coef0(real 0) ///
					tol(real 1e-3) ///
					C(real 1) ///
					epsilon(real 0.1) ///
					SHRinking(string) ///
					cache_size(real 200) ///
					max_iter(integer -1) ///
					PRINTopt ///
					]

	if "`printopt'"!="" {
		di _skip(1) in smcl "{ul on}Stata syntax:{ul off}"
		di _skip(1) in smcl "{opt ker:nel(string)} " _c
		di _skip(1) in smcl "{opt degree(integer 3)} " _c
		di _skip(1) in smcl "{opt gam:ma(string)} " _c
		di _skip(1) in smcl "{opt coef0(real 0)} " _c
		di _skip(1) in smcl "{opt tol(real 1e-3)} " _c
		di _skip(1) in smcl "{opt c(real 1)} "  
		di _skip(1) in smcl "{opt epsilon(real 0.1)} " _c
		di _skip(1) in smcl "{opt shr:inking(string)} " _c
		di _skip(1) in smcl "{opt cache_size(real 200)} " _c
		di _skip(1) in smcl "{opt max_iter(integer -1)}"
	}

	local optstr 

	** kernel
	if "`kernel'"=="linear"|"`kernel'"=="poly"|"`kernel'"=="rbf"|"`kernel'"=="sigmoid"|"`kernel'"=="precomputed" {
		local optstr `optstr' 'kernel':'`kernel'',
	}
	else {
		local optstr `optstr' 'kernel':'rbf',
	}
	** degree
	if `degree'>=1 {
		local optstr `optstr' 'degree':`degree',
	}
	** gamma
	if "`gamma'"=="scale"|"`gamma'"=="auto" {
		local optstr `optstr' 'gamma':'`gamma'',
	}
	else {
		local optstr `optstr' 'gamma':'scale',
	}
	** coef0
	if `coef0'>0 {
		local optstr `optstr' 'coef0':`coef0',
	}
	** tol 
	if `tol'>=0 {
		local optstr `optstr' 'tol':`tol',
	}
	** C 
	if `c'>=0 {
		local optstr `optstr' 'C':`c',
	}
	** epsilon
	if `epsilon'>=0 {
		local optstr `optstr' 'epsilon':`epsilon',
	}
	** max iter
	if `max_iter'==-1|`max_iter'>0 {
		local optstr `optstr' 'max_iter':`max_iter',
	}
	** shrinking
	if "`shrinking'"!="" {
		local optstr `optstr' 'shrinking':`shrinking',
	}
	else {
		local optstr `optstr' 'shrinking':True,
	}
	** cache size
	if `cache_size'>0 {
		local optstr `optstr' 'cache_size':`cache_size',
	}
	** max iter
	if `max_iter'>=-1 {
		local optstr `optstr' 'max_iter':`max_iter',
	}
	** return
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	if "`printopt'"!="" _print_tool `optstr'
	return local optstr `optstr'
end

/*
 class sklearn.svm.LinearSVR()[source]
 */
program define parse_LinearSVR, rclass
	syntax [anything] , ///
					 sklearn_ver(real) ///
					[ ///
					epsilon(real 0) /// OK
					tol(real 1e-4) /// OK  
					C(real 1) /// OK  
					loss(string) /// OK
					NOCONStant /// fit_intercept OK
					intercept_scaling(real 1) /// OK
					dual(string) /// dual OK
					random_state(integer -1) /// OK
					max_iter(integer 1000) /// OK
					PRINTopt ///
					]

	if "`printopt'"!="" {
		di _skip(1) in smcl "{ul on}Stata syntax:{ul off}"
		di _skip(1) in smcl "{opt epsilon(real 0)} " _c
		di _skip(1) in smcl "{opt tol(real 1e-4)} " _c 
		di _skip(1) in smcl "{opt c(real 1)} " _c
		di _skip(1) in smcl "{opt loss(string)} " _c
		di _skip(1) in smcl "{opt nocons:tant} " 
		di _skip(1) in smcl "{opt intercept_scaling(real 1)} " _c
		di _skip(1) in smcl "{opt dual(string)} " _c
		di _skip(1) in smcl "{opt random_state(integer -1)} " _c
		di _skip(1) in smcl "{opt max_iter(integer 1000)} "
	}

	local optstr 

	** epsilon
	if `epsilon'>=0 {
		local optstr `optstr' 'epsilon':`epsilon',
	}
	** tol 
	if `tol'>=0 {
		local optstr `optstr' 'tol':`tol',
	}
	** C 
	if `c'>=0 {
		local optstr `optstr' 'C':`c',
	}
	** loss
	if "`loss'"=="epsilon_insensitive"|"`loss'"=="squared_epsilon_insensitive" {
		local optstr `optstr' 'loss':'`loss'',
	}
	else {
		local optstr `optstr' 'loss':'epsilon_insensitive',
	}
	** intercept 
	if "`noconstant'"!="" {
		local optstr `optstr' 'fit_intercept':False,
	}
	else {
		local optstr `optstr' 'fit_intercept':True,
	}
	** intercept scaling
	local optstr `optstr' 'intercept_scaling':`intercept_scaling',
	** dual/primal 
	if "`dual'"!="" {
		local optstr `optstr' 'dual':`dual',
	}
	else {
		local optstr `optstr' 'dual':True,
	}
	** random state
	if `random_state'>=0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':rng,
	}
	** max iter
	if `max_iter'>0 {
		local optstr `optstr' 'max_iter':`max_iter',
	}
	** return
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	if "`printopt'"!="" _print_tool `optstr'
	return local optstr `optstr'
end

/*
 class sklearn.svm.SVC()[source]¶
 */
program define parse_SVC, rclass
	syntax [anything] , ///
					 sklearn_ver(real) ///
					[ ///
					C(real 1) ///
					KERnel(string) ///
					degree(integer 3) ///
					GAMma(string) ///
					coef0(real 0) ///
					probability(string) ///
					tol(real 1e-3) ///
					epsilon(real 0.1) ///
					SHRinking(string) ///
					cache_size(real 200) ///
					max_iter(integer -1) ///
					decision_function_shape(string) ///
					break_ties ///
					random_state(integer -1) ///
					PRINTopt ///
					]

	if "`printopt'"!="" {
		di _skip(1) in smcl "{ul on}Stata syntax:{ul off}"
		di _skip(1) in smcl "{opt c(real 1)} " _c
		di _skip(1) in smcl "{opt ker:nel(string)} " _c
		di _skip(1) in smcl "{opt degree(integer 3)} " _c
		di _skip(1) in smcl "{opt gam:ma(string)} "  _c
		di _skip(1) in smcl "{opt coef0(real 0)} "  _c
		di _skip(1) in smcl "{opt probability(string)} "  
		di _skip(1) in smcl "{opt tol(real 1e-3)} " _c
		di _skip(1) in smcl "{opt epsilon(real 0.1)} " _c
		di _skip(1) in smcl "{opt shr:inking(string)} " _c
		di _skip(1) in smcl "{opt cache_size(real 200)} " _c
		di _skip(1) in smcl "{opt max_iter(integer -1)} " 
		di _skip(1) in smcl "{opt decision_function_shape(string)} " _c
		di _skip(1) in smcl "{opt break_ties} " _c
		di _skip(1) in smcl "{opt random_state(integer -1)}"
	}

	local optstr 

	** C 
	if `c'>=0 {
		local optstr `optstr' 'C':`c',
	}
	** kernel
	if "`kernel'"=="linear"|"`kernel'"=="poly"|"`kernel'"=="rbf"|"`kernel'"=="sigmoid"|"`kernel'"=="precomputed" {
		local optstr `optstr' 'kernel':'`kernel'',
	}
	else {
		local optstr `optstr' 'kernel':'rbf',
	}
	** degree
	if `degree'>=1 {
		local optstr `optstr' 'degree':`degree',
	}
	** gamma
	if "`gamma'"=="scale"|"`gamma'"=="auto" {
		local optstr `optstr' 'gamma':'`gamma'',
	}
	else {
		local optstr `optstr' 'gamma':'scale',
	}
	** coef0
	if `coef0'>=0 {
		local optstr `optstr' 'coef0':`coef0',
	}
	** shrinking
	if "`shrinking'"!="" {
		local optstr `optstr' 'shrinking':`shrinking',
	}
	else {
		local optstr `optstr' 'shrinking':True,
	}
	** probability estimates
	if "`probability'"!="" {
		local optstr `optstr' 'probability':`probability',
	}
	else {
		local optstr `optstr' 'probability':True,
	}
	** tol 
	if `tol'>=0 {
		local optstr `optstr' 'tol':`tol',
	}
	** cache size
	if `cache_size'>0 {
		local optstr `optstr' 'cache_size':`cache_size',
	}
	** max iter
	if `max_iter'>=-1 {
		local optstr `optstr' 'max_iter':`max_iter',
	}
	** decision function shape
	if "`decision_function_shape'"=="ovo"|"`decision_function_shape'"=="ovr" {
		local optstr `optstr' 'decision_function_shape':'`decision_function_shape'',
	}
	else if "`decision_function_shape'"=="" {
		local optstr `optstr' 'decision_function_shape':'ovr',
	}
	** break ties
	if "`break_ties'"!="" {
		local optstr `optstr' 'break_ties':'`break_ties'',
	}
	** random state
	if `random_state'>=0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':rng,
	}
	** return
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	if "`printopt'"!="" _print_tool `optstr'
	return local optstr `optstr'
end

/*
class sklearn.svm.LinearSVC()
*/
program define parse_LinearSVC, rclass
	syntax [anything] , ///
					 sklearn_ver(real) ///
					[ ///
					penalty(string) ///
					loss(string) ///
					primal /// dual
					tol(real 1e-4) ///
					C(real 1) ///
					NOCONStant /// fit_intercept
					intercept_scaling(real 1) ///
					random_state(integer -1) ///
					max_iter(integer 1000) ///
					PRINTopt ///
					]

	if "`printopt'"!="" {
		di _skip(1) in smcl "{ul on}Stata syntax:{ul off}"
		di _skip(1) in smcl "{opt penalty(string)} " _c
		di _skip(1) in smcl "{opt loss(string)} " _c
		di _skip(1) in smcl "{opt primal} " _c
		di _skip(1) in smcl "{opt tol(real 1e-4)} " _c
		di _skip(1) in smcl "{opt c(real 1)} " _c
		di _skip(1) in smcl "{opt nocons:tant} "  
		di _skip(1) in smcl "{opt intercept_scaling(real 1)} " _c
		di _skip(1) in smcl "{opt random_state(integer -1)} " _c
		di _skip(1) in smcl "{opt max_iter(integer 1000)}"
	}

	local optstr
	** penalty
	if "`penalty'"=="l1"|"`penalty'"=="l2" {
		local optstr `optstr' 'penalty':'`penalty'',
	}
	else {
		local optstr `optstr' 'penalty':'l2',
	} 
	** loss
	if "`loss'"=="hinge"|"`loss'"=="squared_hinge" {
		local optstr `optstr' 'loss':`loss',
	}
	else {
		local optstr `optstr' 'loss':'squared_hinge',
	}
	** dual/primal 
	if "`primal'"!="" {
		local optstr `optstr' 'dual':False,
	}
	else {
		local optstr `optstr' 'dual':True,
	}
	** tol 
	if `tol'>=0 {
		local optstr `optstr' 'tol':`tol',
	}
	** C 
	if `c'>=0 {
		local optstr `optstr' 'C':`c',
	}
	** intercept 
	if "`noconstant'"!="" {
		local optstr `optstr' 'fit_intercept':False,
	}
	else {
		local optstr `optstr' 'fit_intercept':True,
	}
	** random state
	if `random_state'>=0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':rng,
	}
	** max iter
	if `max_iter'>0 {
		local optstr `optstr' 'max_iter':`max_iter',
	}
	** return
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	if "`printopt'"!="" _print_tool `optstr'
	return local optstr `optstr'
end

/*
 class sklearn.neural_network.MLPRegressor()[source]
 */
program define parse_MLPReg, rclass
	syntax [anything] , ///
						 sklearn_ver(real) ///
						[ ///
						hidden_layer_sizes(numlist >0 integer) ///
						activation(string) ///
						solver(string) ///
						alpha(real -1) ///
						batch_size(integer -1) ///
						learning_rate(string) ///
						learning_rate_init(real -1) ///
						power_t(real -1) ///
						max_iter(integer -1) ///
						shuffle(string) ///
						random_state(integer -1) ///
						tol(real -1) ///
						verbose ///
						warm_start ///
						momentum(real -1) ///
						NONESTerovs_momentum ///
						early_stopping ///
						validation_fraction(real -1) ///
						beta_1(real -1) ///
						beta_2(real -1) ///
						epsilon(real -1) ///
						n_iter_no_change(integer -1) ///
						max_fun(integer -1) ///
						PRINTopt ///
					]

	if "`printopt'"!="" {
		di _skip(1) in smcl "{ul on}Stata syntax:{ul off}"
		di _skip(1) in smcl "{opt hidden_layer_sizes(numlist >0 integer)} " _c
		di _skip(1) in smcl "{opt activation(string)} " _c
		di _skip(1) in smcl "{opt solver(string)} " _c
		di _skip(1) in smcl "{opt alpha(real -1)} " _c
		di _skip(1) in smcl "{opt batch_size(integer -1)} " 
		di _skip(1) in smcl "{opt learning_rate(string)} " _c
		di _skip(1) in smcl "{opt learning_rate_init(real -1)} " _c
		di _skip(1) in smcl "{opt power_t(real -1)} " _c
		di _skip(1) in smcl "{opt max_iter(integer -1)} " _c
		di _skip(1) in smcl "{opt shuffle(string)} "  
		di _skip(1) in smcl "{opt random_state(integer -1)} " _c
		di _skip(1) in smcl "{opt tol(real -1)} " _c
		di _skip(1) in smcl "{opt verbose} " _c
		di _skip(1) in smcl "{opt warm_start} " _c
		di _skip(1) in smcl "{opt momentum(real -1)} "  
		di _skip(1) in smcl "{opt nonest:erovs_momentum} " _c
		di _skip(1) in smcl "{opt early_stopping} " _c
		di _skip(1) in smcl "{opt validation_fraction(real -1)} " _c
		di _skip(1) in smcl "{opt beta_1(real -1)} " _c
		di _skip(1) in smcl "{opt beta_2(real -1)} "  
		di _skip(1) in smcl "{opt epsilon(real -1)} " _c
		di _skip(1) in smcl "{opt n_iter_no_change(integer -1)} " _c
		di _skip(1) in smcl "{opt max_fun(integer -1)}" 
	}

	local optstr
	*** hidden layer sizes
	if "`hidden_layer_sizes'"!="" {
		local hidden_layer_sizes_all
		foreach i of numlist `hidden_layer_sizes' {
			local hidden_layer_sizes_all `hidden_layer_sizes_all'`i',
		}
	} 
	else {
		local hidden_layer_sizes_all 100,
	}
	local optstr `optstr' 'hidden_layer_sizes':(`hidden_layer_sizes_all'),
	*** activation
	if "`activation'"=="identity"|"`activation'"=="logistic"|"`activation'"=="tanh"|"`activation'"=="relu" {
		local optstr `optstr' 'activation':'`activation'',
	} 
	else {
		local optstr `optstr' 'activation':'relu',
	}
	*** solver
	if "`solver'"=="lbfgs"|"`solver'"=="sgd"|"`solver'"=="adam" {
		local optstr `optstr' 'solver':'`solver'',
	} 
	else {
		local optstr `optstr' 'solver':'adam',
	}
	*** solver
	if `alpha'>0 {
		local optstr `optstr' 'alpha':`alpha',
	} 
	else {
		local optstr `optstr' 'alpha':0.0001,
	}
	*** batch size
	if `batch_size'>0 {
		local optstr `optstr' 'batch_size':`batch_size',
	} 
	else {
		local optstr `optstr' 'batch_size':'auto',
	}
	*** learning rate
	if "`learning_rate'"=="constant"|"`learning_rate'"=="invscaling"|"`learning_rate'"=="adaptive" {
		local optstr `optstr' 'learning_rate':'`learning_rate'',
	} 
	else {
		local optstr `optstr' 'learning_rate':'constant',
	}
	*** learning rate init
	if `learning_rate_init'>0 {
		local optstr `optstr' 'learning_rate_init':`learning_rate_init',
	} 
	else {
		local optstr `optstr' 'learning_rate_init':0.001,
	}
	*** power t
	if `power_t'>0 {
		local optstr `optstr' 'power_t':`power_t',
	}
	else {
		local optstr `optstr' 'power_t':0.5,
	}
	*** max iter
	if `max_iter'>0 {
		local optstr `optstr' 'max_iter':`max_iter',
	}
	else {
		local optstr `optstr' 'max_iter':200,
	}
	*** shuffle
	if "`shuffle'"!="" {
		local optstr `optstr' 'shuffle':`shuffle',
	}
	else {
		local optstr `optstr' 'shuffle':True,
	}
	** random state
	if `random_state'>=0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':rng,
	}
	** tol 
	if `tol'>=0 {
		local optstr `optstr' 'tol':`tol',
	}
	else {
		local optstr `optstr' 'tol':1e-4,
	}
	** verbose
	if "`verbose'"!="" {
		local optstr `optstr' 'verbose':True,		
	}
	else {
		local optstr `optstr' 'verbose':False,		
	}
	** warm start
	if "`warm_start'"!="" {
		local optstr `optstr' 'warm_start':True,		
	}
	else {
		local optstr `optstr' 'warm_start':False,		
	}
	** momentum
	if `momentum'>0 {
		local optstr `optstr' 'momentum':`momentum',		
	}
	else {
		local optstr `optstr' 'momentum':0.9,		
	}
	** nesterovs
	if "`nonesterovs_momentum'"!="" {
		local optstr `optstr' 'nesterovs_momentum':False,		
	}
	else {
		local optstr `optstr' 'nesterovs_momentum':True,		
	}
	** early stopping
	if "`early_stopping'"!="" {
		local optstr `optstr' 'early_stopping':True,		
	}
	else {
		local optstr `optstr' 'early_stopping':False,		
	}
	** validation fraction
	if `validation_fraction'>0 {
		local optstr `optstr' 'validation_fraction':`validation_fraction',				
	}
	else {
		local optstr `optstr' 'validation_fraction':.1,					
	}
	** beta 1
	if `beta_1'>0 {
		local optstr `optstr' 'beta_1':`beta_1',						
	}
	else {
		local optstr `optstr' 'beta_1':0.9,								
	}
	** beta 2
	if `beta_2'>0 {
		local optstr `optstr' 'beta_2':`beta_2',						
	}
	else {
		local optstr `optstr' 'beta_2':0.999,								
	}
	** epsilon
	if `epsilon'>0 {
		local optstr `optstr' 'epsilon':`epsilon',						
	}
	else {
		local optstr `optstr' 'epsilon':1e-8,								
	}
	** n_iter_no_change
	if `n_iter_no_change'>0 {
		local optstr `optstr' 'n_iter_no_change':`n_iter_no_change',						
	}
	else {
		local optstr `optstr' 'n_iter_no_change':10,						
	}
	** max fun
	if `max_fun'>0 {
		local optstr `optstr' 'max_fun':`max_fun',						
	}
	else {
		local optstr `optstr' 'max_fun':15000,						
	}	
	** return
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	if "`printopt'"!="" _print_tool `optstr'
	return local optstr `optstr'
end

/*
 class sklearn.neural_network.MLPClassifier()[source]¶
 */
program define parse_MLPClass, rclass
	syntax [anything] , ///
						 sklearn_ver(real) ///
						[ ///
						hidden_layer_sizes(numlist >0 integer) ///
						activation(string) ///
						solver(string) ///
						alpha(real -1) ///
						batch_size(integer -1) ///
						learning_rate(string) ///
						learning_rate_init(real -1) ///
						power_t(real -1) ///
						max_iter(integer -1) ///
						shuffle(string) ///
						random_state(integer -1) ///
						tol(real -1) ///
						verbose ///
						warm_start ///
						momentum(real -1) ///
						NONESTerovs_momentum ///
						early_stopping ///
						validation_fraction(real -1) ///
						beta_1(real -1) ///
						beta_2(real -1) ///
						epsilon(real -1) ///
						n_iter_no_change(integer -1) ///
						max_fun(integer -1) ///
						PRINTopt ///
					]

	if "`printopt'"!="" {
		di _skip(1) in smcl "{ul on}Stata syntax:{ul off}"
		di _skip(1) in smcl "{opt hidden_layer_sizes(numlist >0 integer)} " _c
		di _skip(1) in smcl "{opt activation(string)} " _c
		di _skip(1) in smcl "{opt solver(string)} " _c
		di _skip(1) in smcl "{opt alpha(real -1)} " _c
		di _skip(1) in smcl "{opt batch_size(integer -1)} "  
		di _skip(1) in smcl "{opt learning_rate(string)} " _c
		di _skip(1) in smcl "{opt learning_rate_init(real -1)} " _c
		di _skip(1) in smcl "{opt power_t(real -1)} " _c
		di _skip(1) in smcl "{opt max_iter(integer -1)} " _c
		di _skip(1) in smcl "{opt shuffle(string)} " 
		di _skip(1) in smcl "{opt random_state(integer -1)} " _c
		di _skip(1) in smcl "{opt tol(real -1)} " _c
		di _skip(1) in smcl "{opt verbose} " _c
		di _skip(1) in smcl "{opt warm_start} " _c
		di _skip(1) in smcl "{opt momentum(real -1)} "  
		di _skip(1) in smcl "{opt nonest:erovs_momentum} " _c
		di _skip(1) in smcl "{opt early_stopping} " _c
		di _skip(1) in smcl "{opt validation_fraction(real -1)} " _c
		di _skip(1) in smcl "{opt beta_1(real -1)} " _c
		di _skip(1) in smcl "{opt beta_2(real -1)} "  
		di _skip(1) in smcl "{opt epsilon(real -1)} " _c
		di _skip(1) in smcl "{opt n_iter_no_change(integer -1)} " _c
		di _skip(1) in smcl "{opt max_fun(integer -1)} " 
	}

	local optstr
	*** hidden layer sizes
	if "`hidden_layer_sizes'"!="" {
		local hidden_layer_sizes_all
		foreach i of numlist `hidden_layer_sizes' {
			local hidden_layer_sizes_all `hidden_layer_sizes_all'`i',
		}
	} 
	else {
		local hidden_layer_sizes_all 100,
	}
	local optstr `optstr' 'hidden_layer_sizes':(`hidden_layer_sizes_all'),
	*** activation
	if "`activation'"=="identity"|"`activation'"=="logistic"|"`activation'"=="tanh"|"`activation'"=="relu" {
		local optstr `optstr' 'activation':'`activation'',
	} 
	else {
		local optstr `optstr' 'activation':'relu',
	}
	*** solver
	if "`solver'"=="lbfgs"|"`solver'"=="sgd"|"`solver'"=="adam" {
		local optstr `optstr' 'solver':'`solver'',
	} 
	else {
		local optstr `optstr' 'solver':'adam',
	}
	*** solver
	if `alpha'>0 {
		local optstr `optstr' 'alpha':`alpha',
	} 
	else {
		local optstr `optstr' 'alpha':0.0001,
	}
	*** batch size
	if `batch_size'>0 {
		local optstr `optstr' 'batch_size':`batch_size',
	} 
	else {
		local optstr `optstr' 'batch_size':'auto',
	}
	*** learning rate
	if "`learning_rate'"=="constant"|"`learning_rate'"=="invscaling"|"`learning_rate'"=="adaptive" {
		local optstr `optstr' 'learning_rate':'`learning_rate'',
	} 
	else {
		local optstr `optstr' 'learning_rate':'constant',
	}
	*** learning rate init
	if `learning_rate_init'>0 {
		local optstr `optstr' 'learning_rate_init':`learning_rate_init',
	} 
	else {
		local optstr `optstr' 'learning_rate_init':0.001,
	}
	*** power t
	if `power_t'>0 {
		local optstr `optstr' 'power_t':`power_t',
	}
	else {
		local optstr `optstr' 'power_t':0.5,
	}
	*** max iter
	if `max_iter'>0 {
		local optstr `optstr' 'max_iter':`max_iter',
	}
	else {
		local optstr `optstr' 'max_iter':200,
	}
	*** shuffle
	if "`shuffle'"!="" {
		local optstr `optstr' 'shuffle':`shuffle',
	}
	else {
		local optstr `optstr' 'shuffle':True,
	}
	** random state
	if `random_state'>=0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':rng,
	}
	** tol 
	if `tol'>=0 {
		local optstr `optstr' 'tol':`tol',
	}
	else {
		local optstr `optstr' 'tol':1e-4,
	}
	** verbose
	if "`verbose'"!="" {
		local optstr `optstr' 'verbose':True,		
	}
	else {
		local optstr `optstr' 'verbose':False,		
	}
	** warm start
	if "`warm_start'"!="" {
		local optstr `optstr' 'warm_start':True,		
	}
	else {
		local optstr `optstr' 'warm_start':False,		
	}
	** momentum
	if `momentum'>0 {
		local optstr `optstr' 'momentum':`momentum',		
	}
	else {
		local optstr `optstr' 'momentum':0.9,		
	}
	** nesterovs
	if "`nonesterovs_momentum'"!="" {
		local optstr `optstr' 'nesterovs_momentum':False,		
	}
	else {
		local optstr `optstr' 'nesterovs_momentum':True,		
	}
	** early stopping
	if "`early_stopping'"!="" {
		local optstr `optstr' 'early_stopping':True,		
	}
	else {
		local optstr `optstr' 'early_stopping':False,		
	}
	** validation fraction
	if `validation_fraction'>0 {
		local optstr `optstr' 'validation_fraction':`validation_fraction',				
	}
	else {
		local optstr `optstr' 'validation_fraction':.1,					
	}
	** beta 1
	if `beta_1'>0 {
		local optstr `optstr' 'beta_1':`beta_1',						
	}
	else {
		local optstr `optstr' 'beta_1':0.9,								
	}
	** beta 2
	if `beta_2'>0 {
		local optstr `optstr' 'beta_2':`beta_2',						
	}
	else {
		local optstr `optstr' 'beta_2':0.999,								
	}
	** epsilon
	if `epsilon'>0 {
		local optstr `optstr' 'epsilon':`epsilon',						
	}
	else {
		local optstr `optstr' 'epsilon':1e-8,								
	}
	** n_iter_no_change
	if `n_iter_no_change'>0 {
		local optstr `optstr' 'n_iter_no_change':`n_iter_no_change',						
	}
	else {
		local optstr `optstr' 'n_iter_no_change':10,						
	}
	** max fun
	if `max_fun'>0 {
		local optstr `optstr' 'max_fun':`max_fun',						
	}
	else {
		local optstr `optstr' 'max_fun':15000,						
	}	
	** return
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	if "`printopt'"!="" _print_tool `optstr'
	return local optstr `optstr'
end

/*
 */
program define parse_XGB, rclass
	syntax [anything] , ///
						 sklearn_ver(real) ///
						[ /// 
						/// integer
						n_estimators(integer -1) ///
						max_depth(integer -1) ///
						max_leaves(integer -1) ///
						max_bin(integer -1) ///
						grow_policy(integer -1) ///
						verbosity(integer -1) ///
						n_jobs(integer -1) ///
						random_state(integer -1) ///
						max_cat_to_onehot(integer -1) ///  
						early_stopping_rounds(integer -1) ///
						num_parallel_tree(integer -1) ///
						///
						/// real
						learning_rate(real -1) ///
						gamma(real -1) ///
						min_child_weight(real -1) ///
						max_delta_step(real -1) ///
						subsample(real -1) ///
						colsample_bytree(real -1) ///
						colsample_bylevel(real -1) ///
						colsample_bynode(real -1) ///
						reg_alpha(real -1) ///  
						reg_lambda(real -1) ///
						scale_pos_weight(real -1) ///
						base_score(real -1) ///
						///
						/// string
						objective(string) ///
						booster(string) ///
						subsample_method(string) ///
 						tree_method(string) ///
						monotone_constraints(string) ///  
						importance_type(string) ///
						eval_metric(string) ///
						/// 
						/// numlist
						interaction_constraints1(numlist integer)  ///
						interaction_constraints2(numlist integer)  ///
						interaction_constraints3(numlist integer)  ///
					]
	local optstr
	*** integer
	foreach l in n_estimators max_depth max_leaves max_bin grow_policy verbosity n_jobs random_state max_cat_to_onehot early_stopping_rounds num_parallel_tree {
		if ``l''>0 {
			local optstr `optstr' '`l'':``l'',
		} 
	}
	*** real
	foreach l in learning_rate gamma min_child_weight max_delta_step subsample colsample_bytree colsample_bylevel colsample_bynode reg_alpha reg_lambda scale_pos_weight base_score {
		if ``l''>0 {
			local optstr `optstr' '`l'':``l'',
		} 
	}
	*** string
	foreach l in objective booster subsample_method tree_method monotone_constraints importance_type eval_metric { 
		if "``l''"!="" {
			local optstr `optstr' '`l'':'``l''',
		} 
	}
	*** interaction contrains
	if "`interaction_constraints1'"!="" | "`interaction_constraints2'"!="" | "`interaction_constraints3'"!="" {
		local constr [
		if "`interaction_constraints1'"!="" {
			local constr1 [
			foreach j of numlist `interaction_constraints1' {
				local i = `j'-1
				local constr1 `constr1'`i',	
			}
			local constr1 `constr1'],
		}
		if "`interaction_constraints2'"!="" {
			local constr2 [
			foreach j of numlist `interaction_constraints2' {
				local i = `j'-1
				local constr2 `constr2'`i',	
			}
			local constr2 `constr2'],
		}
		if "`interaction_constraints3'"!="" {
			local constr3 [
			foreach j of numlist `interaction_constraints3' {
				local i = `j'-1
				local constr3 `constr3'`i',	
			}
			local constr3 `constr3'],
		}
		local constr [`constr1'`constr2'`constr3']
		local optstr `optstr' 'interaction_constraints':'`constr'',
	}
	** return
	di "optstr {`optstr'}"
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	if "`printopt'"!="" _print_tool `optstr'
	return local optstr `optstr'
end

program _print_tool 
	di ""
    di _skip(1) in smcl "{ul:Specified options are translated to:} " 
	local str `0'
	local str = subinstr("`str'","':","(",.)
	local str = subinstr("`str'",",'",") ",.)
	local str = subinstr("`str'","'","",.)
	local str = subinstr("`str'","{","",.)
	local str = subinstr("`str'","}",")",.)
	local str = subinstr("`str'","[","",.)
	local str = subinstr("`str'","]","",.)
	local str = subinstr("`str'",","," ",.)
	local str = subinstr("`str'"," ))",")",.)
	local str = subinstr("`str'","((","(",.)
	tokenize "`str'", parse(")")
	local j = 1
	local i = 1
	while ("``j''"!="") {
		if mod(`i',6)==0 {
			di _skip(1) as text "``j'') "
		}
		else {
			di _skip(1) as text "``j'') " _c
		}
		local i = `i'+1
		local j = `j'+2
	}
	di ""
end