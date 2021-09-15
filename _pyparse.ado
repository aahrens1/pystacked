** pyparse v0.1
** for scikit-learn 0.24.0

program _pyparse 
	syntax [anything] , type(string) method(string) [ debug *]

	if ("`method'"!="") {

		if substr("`type'",1,3)=="reg" {
			local type reg
		}
		else {
			local type class
		}

		if "`type'"=="reg" {
			if "`method'"=="lassoic" {
				parse_LassoIC , `options'
			}
			else if "`method'"=="lassocv" {
				parse_ElasticCV , `options' l1_ratio(1)
			}
			else if "`method'"=="ridgecv" {
				parse_ElasticCV , `options' l1_ratio(0)
			}
			else if "`method'"=="elasticcv" {
				parse_ElasticCV , `options'
			}
			else if "`method'"=="svm" {
				parse_SVR , `options'
			}
			else if "`method'"=="gradboost" {
				parse_gradboostReg , `options'
			}
			else if "`method'"=="rf" {
				parse_rfReg , `options'
			}
			else if "`method'"=="linsvm" {
				parse_LinearSVR , `options'
			}
			else if "`method'"=="nnet" {
				parse_MLPReg , `options'
			}
			else {
				di as err "method(`method') unknown"
				exit 198
			}
			local optstr `r(optstr)'
		}
		else if "`type'"=="class" {
			if "`method'"=="lassocv" {
				parse_LassoLogitCV , `options' penalty(l1) solver(saga)
			}
			else if "`method'"=="lassoic" {
				di as err "warning: lassoic not supported with type(class); ignored."
				exit 198
			}
			else if "`method'"=="elasticcv" {
				parse_LassoLogitCV , `options' penalty(elasticnet) solver(saga)
			}
			else if "`method'"=="ridgecv" {
				parse_LassoLogitCV , `options'
			}
			else if "`method'"=="svm" {
				parse_SVC , `options'
			}
			else if "`method'"=="gradboost" {
				parse_gradboostClass , `options'
			}
			else if "`method'"=="rf" {
				parse_rfClass , `options'
			}
			else if "`method'"=="linsvm" {
				parse_LinearSVC , `options'
			}
			else if "`method'"=="nnet" {
				parse_MLPClass , `options'
			} 
			else {
				di as err "method(`method') unknown"
				exit 198
			}
			local optstr `r(optstr)'
		}
	}
	else {
		return_nothing
	}
	if "`debug'"!="" di "`optstr'"
end

//program return_nothing, rclass 
//	return local optstr {}
//end

/*
 class sklearn.linear_model.LogisticRegressionCV(*, Cs=10, 
 fit_intercept=True, cv=None, dual=False, penalty='l2', 
 scoring=None, solver='lbfgs', tol=0.0001, max_iter=100, 
 class_weight=None, n_jobs=None, verbose=0, refit=True, 
 intercept_scaling=1.0, multi_class='auto', random_state=None,
  l1_ratios=None)[source]¶
  */
program define parse_LassoLogitCV, rclass
	syntax [anything], [ ///
					l1_ratio(real -1) ///
					Cs(integer 10) ///
					NOCONStant /// 
					cv(integer 5) ///
					penalty(string) ///
					solver(string) ///
					tol(real 1e-4) ///
					max_iter(integer 100) ///
					n_jobs(integer 1) ///
					norefit ///
					intercept_scaling(real 1) ///
					random_state(integer -1) ///
					]
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
	if `cv'>2 {
		local optstr `optstr' 'cv':`cv',
	}
	** penalty
	if "`penalty'"=="l1"|"`penalty'"=="elasticnet" {
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
	if `n_jobs'>0 {
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
	if `random_state'>0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':None,
	}
	** l1 ratios
	if `l1_ratio'>=0 & `l1_ratio'<= 1 {
		local optstr `optstr' 'l1_ratios':`l1_ratio',
	}
	else {
		local optstr `optstr' 'l1_ratios':None,
	}
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
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
	syntax [anything], [ ///
					l1_ratio(real .5) ///
					eps(real 1e-3) ///
					n_alphas(integer 100) ///					
					NOCONStant ///
					NONormalize ///
					eps(real 1e-3) ///
					max_iter(integer 1000) ///
					tol(real 1e-4) ///
					cv(integer 5) ///
					n_jobs(integer 1) ///
					POSitive ///
					random_state(integer -1) ///
					selection(string) ///
					]
	local optstr 

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
	** normalize
	if ("`nonormalize'"!="") {
		local optstr `optstr' 'normalize':False,
	}
	else {
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
	if `cv'>2 {
		local optstr `optstr' 'cv':`cv',
	}
	else {
		local optstr `optstr' 'cv':5,
	}
	** n jobs
	if `n_jobs'>0 {
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
	if `random_state'>0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':None,
	}
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	return local optstr `optstr'
end 

/*
 class sklearn.linear_model.LassoLarsIC(criterion='aic', *, 
 fit_intercept=True, verbose=False, normalize=True, precompute='auto', 
 max_iter=500, eps=2.220446049250313e-16, copy_X=True, positive=False) 
 */
program define parse_LassoIC, rclass
	syntax [anything], [criterion(string) ///
					NOCONStant ///
					NONormalize ///
					max_iter(integer 500) ///
					eps(real -1) ///
					positive ]
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
	** normalize
	if ("`nonormalize'"!="") {
		local optstr `optstr' 'normalize':False,
	}
	else {
		local optstr `optstr' 'normalize':True,
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
	return local optstr `optstr'
end 

** sklearn.ensemble.RandomForestRegressor
/*
 class sklearn.ensemble.RandomForestRegressor(n_estimators=100, *, 
 criterion='mse', max_depth=None, min_samples_split=2, min_samples_leaf=1, 
 min_weight_fraction_leaf=0.0, max_features='auto', max_leaf_nodes=None, 
 min_impurity_decrease=0.0, min_impurity_split=None, bootstrap=True, 
 oob_score=False, n_jobs=None, random_state=None, verbose=0, warm_start=False, 
 ccp_alpha=0.0, max_samples=None)[source]¶
 */
program define parse_rfReg, rclass
	syntax [anything] , [ ///
					n_estimators(integer 100) ///
					criterion(string) ///
					max_depth(integer -1) ///  
					min_samples_split(integer 2) ///
					min_samples_leaf(integer 1) /// only integer supported
					min_weight_fraction_leaf(real 0) ///
					max_features(string) ///
					max_leaf_nodes(integer -1) ///
					min_impurity_decrease(real 0) ///
					NOBOOTStrap  ///
					oob_score  ///
					n_jobs(integer 1) ///
					random_state(integer -1) ///
					warm_start ///
					ccp_alpha(real 0) ///
					max_samples(integer -1) /// only integer supported
					]

	local optstr 

	** number of trees in the forest
	if `n_estimators'>0 {
		local optstr `optstr' 'n_estimators':`n_estimators',
	}
	** criterion
	if "`criterion'"=="mae"|"`criterion'"=="mse" {
		local optstr `optstr' 'criterion':'`criterion'',		
	}
	else if "`criterion'"=="" {
		// use default
		local optstr `optstr' 'criterion':'mse',	
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
	if `min_samples_split'>=1 {
		local optstr `optstr' 'min_samples_split':`min_samples_split',
	}
	** min samples leaf
	if `min_samples_leaf'>=1 {
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
		local optstr `optstr' 'max_features':'auto',
	} 
	else {
		di as err "max_features(`max_features') not allowed"
		exit 197
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
	if "`nobootstrap'"!="" {
		local optstr `optstr' 'bootstrap':False,
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
	if `n_jobs'>0 {
		local optstr `optstr' 'n_jobs':`n_jobs',
	}
	else {
		local optstr `optstr' 'n_jobs':None,
	}
	** random state
	if `random_state'>0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':None,
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
	if `max_samples'>=1 {
		local optstr `optstr' 'max_samples':`max_samples',
	}
	else {
		local optstr `optstr' 'max_samples':None,
	}
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	return local optstr `optstr'
end 

** sklearn.ensemble.RandomForestClassifier
/*
 class sklearn.ensemble.RandomForestClassifier(n_estimators=100, *, 
 criterion='gini', max_depth=None, min_samples_split=2,
  min_samples_leaf=1, min_weight_fraction_leaf=0.0, max_features='auto',
   max_leaf_nodes=None, min_impurity_decrease=0.0, min_impurity_split=None,
    bootstrap=True, oob_score=False, n_jobs=None, random_state=None,
     verbose=0, warm_start=False, class_weight=None, ccp_alpha=0.0,
      max_samples=None)[source]¶
 */
program define parse_rfClass, rclass
	syntax [anything] , [ ///
					n_estimators(integer 100) ///
					criterion(string) ///
					max_depth(integer -1) ///  
					min_samples_split(integer 2) /// only int supported
					min_samples_leaf(integer 1) /// only int supported
					min_weight_fraction_leaf(real 0) ///
					max_features(string) ///
					max_leaf_nodes(integer -1) ///
					min_impurity_decrease(real 0) ///
					NOBOOTStrap  ///
					///class_weight(string) ///
					oob_score  ///
					n_jobs(integer -1) ///
					random_state(integer -1) ///
					warm_start ///
					ccp_alpha(real 0) ///
					max_samples(integer -1) /// only int supported
					]

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
		local optstr `optstr' 'max_features':'auto',
	}
	else {
		di as err "max_features(`max_features') not allowed"
		error 197
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
	if "`nobootstrap'"!="" {
		local optstr `optstr' 'bootstrap':False,
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
	if `n_jobs'>0 {
		local optstr `optstr' 'n_jobs':`n_jobs',
	}
	else {
		local optstr `optstr' 'n_jobs':None,
	}	
	** random state
	if `random_state'>0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':None,
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
	return local optstr `optstr'
end 

** sklearn.ensemble.GradientBoostingRegressor
/* class sklearn.ensemble.GradientBoostingRegressor(*, loss='ls', 
    learning_rate=0.1, n_estimators=100, subsample=1.0, criterion='friedman_mse',
    min_samples_split=2, min_samples_leaf=1, min_weight_fraction_leaf=0.0, 
    max_depth=3, min_impurity_decrease=0.0, min_impurity_split=None, init=None,
    random_state=None, max_features=None, alpha=0.9, verbose=0, max_leaf_nodes=None, 
    warm_start=False, validation_fraction=0.1, n_iter_no_change=None, tol=0.0001, 
    ccp_alpha=0.0)
*/
program define parse_gradboostReg, rclass
	syntax [anything] , [ ///
					loss(string) ///
					learning_rate(real 0.1) ///
					n_estimators(integer 100) ///
					subsample(real 1) ///
					min_samples_split(integer 2) /// only int supported
					min_samples_leaf(integer 1) /// only int supported
					min_weight_fraction_leaf(real 0) ///
					max_depth(integer 3) ///  
					min_impurity_decrease(real 0) ///
					init(string) ///
					random_state(integer -1) ///
					///max_features(string) ///
					alpha(real 0.9) ///
					max_leaf_nodes(integer -1) ///
					warm_start ///
					validation_fraction(real 0.1) ///
					n_iter_no_change(integer -1) ///
					tol(real 1e-4) ///
					ccp_alpha(real 0) ///
					]

	local optstr 

	** loss
	if "`loss'"=="ls"|"`loss'"=="lad"|"`loss'"=="huber"|"`loss'"=="huber" {
		local optstr `optstr' 'loss':'`loss'',
	} 
	else if "`loss'"=="" {
		local optstr `optstr' 'loss':'ls',
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
	if `random_state'>0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':None,
	}
	** max features
	if "`max_features'"=="auto"|"`max_features'"=="sqrt"|"`max_features'"=="log2" {
		local optstr `optstr' 'max_features':'`max_features'',
	} 
	else if real("`max_features'")!=. {
		local optstr `optstr' 'max_features':`max_features',
	}
	else if "`max_features'"=="" {
		local optstr `optstr' 'max_features':None,
	}
	else {
		di as err "max_features(`max_features') not allowed"
		error 197
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
	return local optstr `optstr'
end 

** sklearn.ensemble.GradientClassifier
/*  class sklearn.ensemble.GradientBoostingClassifier(*, loss='deviance',
 	learning_rate=0.1, n_estimators=100, subsample=1.0, criterion='friedman_mse',
  	min_samples_split=2, min_samples_leaf=1, min_weight_fraction_leaf=0.0, 
  	max_depth=3, min_impurity_decrease=0.0, min_impurity_split=None, init=None,
   	random_state=None, max_features=None, verbose=0, max_leaf_nodes=None,
    warm_start=False, validation_fraction=0.1, n_iter_no_change=None, 
    tol=0.0001, ccp_alpha=0.0) */
program define parse_gradboostClass, rclass
	syntax [anything] , [ ///
					loss(string) ///
					learning_rate(real 0.1) ///
					n_estimators(integer 100) ///
					subsample(real 1) ///
					min_samples_split(integer 2) /// only int supported
					min_samples_leaf(integer 1) /// only int supported
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
					]
	local optstr 
	** loss
	if "`loss'"=="deviance"|"`loss'"=="exponential" {
		local optstr `optstr' 'loss':'`loss'',
	} 
	else if "`loss'"=="" {
		local optstr `optstr' 'loss':'deviance',
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
	if `random_state'>0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':None,
	}
	** max features
	if "`max_features'"=="auto"|"`max_features'"=="sqrt"|"`max_features'"=="log2" {
		local optstr `optstr' 'max_features':'`max_features'',
	} 
	else if real("`max_features'")!=. {
		local optstr `optstr' 'max_features':`max_features',
	}
	else if "`max_features'"=="" {
		local optstr `optstr' 'max_features':None,
	}
	else {
		di as err "max_features(`max_features') not allowed"
		error 197
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
	return local optstr `optstr'
end 

/*
 class sklearn.svm.SVR(*, kernel='rbf', degree=3, gamma='scale', coef0=0.0, 
 tol=0.001, C=1.0, epsilon=0.1, shrinking=True, cache_size=200, verbose=False,
 max_iter=- 1)[source]¶
 */
program define parse_SVR, rclass
	syntax [anything] , [ ///
					KERnel(string) ///
					degree(integer 3) ///
					GAMma(string) ///
					coef0(real 0) ///
					tol(real 1e-3) ///
					C(real 1) ///
					epsilon(real 0.1) ///
					NOSHRinking ///
					cache_size(real 200) ///
					max_iter(integer -1) ///
					]

	local optstr 

	** kernel
	if "`kernel'"=="linear"|"`kernel'"=="poly"|"`kernel'"=="rbf"|"`kernel'"=="sigmoid"|"`kernel'"=="precomputed" {
		local optstr `optstr' 'kernel':`kernel',
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
		local optstr `optstr' 'gamma':`gamma',
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
	if "`noshrinking'"!="" {
		local optstr `optstr' 'shrinking':False,
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
	return local optstr `optstr'
end

/*
 class sklearn.svm.LinearSVR(*, epsilon=0.0, tol=0.0001, C=1.0, 
 loss='epsilon_insensitive', fit_intercept=True, intercept_scaling=1.0, 
 dual=True, verbose=0, random_state=None, max_iter=1000)[source]
 */
program define parse_LinearSVR, rclass
	syntax [anything] , [ ///
					epsilon(real 0) /// OK
					tol(real 1e-4) /// OK  
					C(real 1) /// OK  
					loss(string) /// OK
					NOCONStant /// fit_intercept OK
					intercept_scaling(real 1) /// OK
					primal /// dual OK
					random_state(integer -1) /// OK
					max_iter(integer 1000) /// OK
					]

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
		local optstr `optstr' 'loss':`loss',
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
	if "`primal'"!="" {
		local optstr `optstr' 'dual':False,
	}
	else {
		local optstr `optstr' 'dual':True,
	}
	** random state
	if `random_state'>0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':None,
	}
	** max iter
	if `max_iter'>0 {
		local optstr `optstr' 'max_iter':`max_iter',
	}
	** return
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	return local optstr `optstr'
end

/*
 class sklearn.svm.SVC(*, C=1.0, kernel='rbf', degree=3, gamma='scale', 
 coef0=0.0, shrinking=True, probability=False, tol=0.001, cache_size=200,
  class_weight=None, verbose=False, max_iter=- 1, decision_function_shape='ovr',
   break_ties=False, random_state=None)[source]¶
 */
program define parse_SVC, rclass
	syntax [anything] , [ ///
					C(real 1) ///
					KERnel(string) ///
					degree(integer 3) ///
					GAMma(string) ///
					coef0(real 0) ///
					probability ///
					tol(real 1e-3) ///
					epsilon(real 0.1) ///
					NOSHRinking ///
					cache_size(real 200) ///
					max_iter(integer -1) ///
					decision_function_shape(string) ///
					break_ties ///
					random_state(integer -1) ///
					]

	local optstr 

	** C 
	if `c'>=0 {
		local optstr `optstr' 'C':`c',
	}
	** kernel
	if "`kernel'"=="linear"|"`kernel'"=="poly"|"`kernel'"=="rbf"|"`kernel'"=="sigmoid"|"`kernel'"=="precomputed" {
		local optstr `optstr' 'kernel':`kernel',
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
		local optstr `optstr' 'gamma':`gamma',
	}
	else {
		local optstr `optstr' 'gamma':'scale',
	}
	** coef0
	if `coef0'>=0 {
		local optstr `optstr' 'coef0':`coef0',
	}
	** shrinking
	if "`noshrinking'"!="" {
		local optstr `optstr' 'shrinking':False,
	}
	else {
		local optstr `optstr' 'shrinking':True,
	}
	** probability estimates
	if "`probability'"!="" {
		local optstr `optstr' 'probability':True,
	}
	else {
		local optstr `optstr' 'probability':False,
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
	if `random_state'>0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':None,
	}
	** return
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	return local optstr `optstr'
end

/*
class sklearn.svm.LinearSVC(penalty='l2', loss='squared_hinge', *, dual=True,
 tol=0.0001, C=1.0, multi_class='ovr', fit_intercept=True, intercept_scaling=1,
  class_weight=None, verbose=0, random_state=None, max_iter=1000)
*/
program define parse_LinearSVC, rclass
	syntax [anything] , [ ///
					penalty(string) ///
					loss(string) ///
					primal /// dual
					tol(real 1e-4) ///
					C(real 1) ///
					NOCONStant /// fit_intercept
					intercept_scaling(real 1) ///
					random_state(integer -1) ///
					max_iter(integer 1000) ///
					]

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
	if `random_state'>0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':None,
	}
	** max iter
	if `max_iter'>0 {
		local optstr `optstr' 'max_iter':`max_iter',
	}
	** return
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	return local optstr `optstr'
end

/*
 class sklearn.neural_network.MLPRegressor(hidden_layer_sizes=100, activation='relu', *, solver='adam', alpha=0.0001,
  batch_size='auto', learning_rate='constant', learning_rate_init=0.001, power_t=0.5, max_iter=200, shuffle=True,
   random_state=None, tol=0.0001, verbose=False, warm_start=False, momentum=0.9, nesterovs_momentum=True, 
   early_stopping=False, validation_fraction=0.1, beta_1=0.9, beta_2=0.999, epsilon=1e-08, n_iter_no_change=10,
   max_fun=15000)[source]
 */
program define parse_MLPReg, rclass
	syntax [anything] , [ ///
						hidden_layer_sizes(numlist >0 integer) ///
						activation(string) ///
						solver(string) ///
						alpha(real -1) ///
						batch_size(integer -1) ///
						learning_rate(string) ///
						learning_rate_init(real -1) ///
						power_t(real -1) ///
						max_iter(integer -1) ///
						NOSHuffle ///
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
					]

	local optstr
	*** hidden layer sizes
	if "`hidden_layer_sizes'"!="" {
		local hidden_layer_sizes 
		foreach i of numlist `hidden_layer_sizes' {
			local hidden_layer_sizes `hidden_layer_sizes',`i'
		}
	} 
	else {
		local hidden_layer_sizes 100
	}
	local optstr `optstr' 'hidden_layer_sizes':(`hidden_layer_sizes',),
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
		local optstr `optstr' 'alpha':'`alpha'',
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
	if "`noshuffle'"!="" {
		local optstr `optstr' 'shuffle':False,
	}
	else {
		local optstr `optstr' 'shuffle':True,
	}
	** random state
	if `random_state'>0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':None,
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
	return local optstr `optstr'
end

/*
 class sklearn.neural_network.MLPClassifier(hidden_layer_sizes=100, activation='relu', *, solver='adam', 
 alpha=0.0001, batch_size='auto', learning_rate='constant', learning_rate_init=0.001, power_t=0.5, 
 max_iter=200, shuffle=True, random_state=None, tol=0.0001, verbose=False, warm_start=False,
  momentum=0.9, nesterovs_momentum=True, early_stopping=False, validation_fraction=0.1, 
  beta_1=0.9, beta_2=0.999, epsilon=1e-08, n_iter_no_change=10, max_fun=15000)[source]¶
 */
program define parse_MLPClass, rclass
	syntax [anything] , [ ///
						hidden_layer_sizes(numlist >0 integer) ///
						activation(string) ///
						solver(string) ///
						alpha(real -1) ///
						batch_size(integer -1) ///
						learning_rate(string) ///
						learning_rate_init(real -1) ///
						double_t(real -1) ///
						max_iter(integer -1) ///
						NOSHuffle ///
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
					]

	local optstr
	*** hidden layer sizes
	if "`hidden_layer_sizes'"!="" {
		local hidden_layer_sizes 
		foreach i of numlist `hidden_layer_sizes' {
			local hidden_layer_sizes `hidden_layer_sizes',`i'
		}
	} 
	else {
		local hidden_layer_sizes 100
	}
	local optstr `optstr' 'hidden_layer_sizes':(`hidden_layer_sizesm',),
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
		local optstr `optstr' 'alpha':'`alpha'',
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
	if `double_t'>0 {
		local optstr `optstr' 'double_t':`double_t',
	}
	else {
		local optstr `optstr' 'double_t':0.5,
	}
	*** max iter
	if `max_iter'>0 {
		local optstr `optstr' 'max_iter':`max_iter',
	}
	else {
		local optstr `optstr' 'max_iter':200,
	}
	*** shuffle
	if "`noshuffle'"!="" {
		local optstr `optstr' 'shuffle':False,
	}
	else {
		local optstr `optstr' 'shuffle':True,
	}
	** random state
	if `random_state'>0 {
		local optstr `optstr' 'random_state':`random_state',
	}
	else {
		local optstr `optstr' 'random_state':None,
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
		local optstr `optstr' 'nmax_fun':15000,						
	}	
	** return
	local optstr {`optstr'}
	local optstr = subinstr("`optstr'",",}","}",.)
	local optstr = subinstr("`optstr'"," ","",.)
	return local optstr `optstr'
end