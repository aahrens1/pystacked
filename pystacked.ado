*! pystacked v0.3
*! last edited: 22Jan2022
*! authors: aa/ms

// parent program
program define pystacked, eclass
	version 16.0

	// no replay - must estimate
	if ~replay() {
		_pystacked `0'
	}

	// save for display results
	tempname weights_mat
	mat `weights_mat'=e(weights)
	local base_est `e(base_est)'
	local nlearners	= e(mcount)

	// parse and check for graph/table options
	// code borrowed from _pstacked below - needed to accommodate syntax #2
	if ~replay() {
		tokenize "`0'", parse(",")
		local beforecomma `1'
		macro shift
		local restargs `*'
		tokenize `beforecomma', parse("|")
		local mainargs `1'
		local 0 "`mainargs' `restargs'"
	}
	syntax [anything]  [if] [in] [aweight fweight] , 	///
				[										///
					GRAPH1								/// vanilla option, abbreviates to "graph"
					HISTogram							/// report histogram instead of default ROC
					graph(string asis)					/// for passing options to graph combine
					lgraph(string asis)					/// for passing options to the graphs of the learners
					TABle								/// 
					HOLDOUT1							/// vanilla option, abbreviates to "holdout"
					holdout(varname)					///
					*									///
				]
	
	// display results
	if `"`graph'`graph1'`lgraph'`histogram'`table'"' == "" {

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
	}

	// graph/table block
	if `"`graph'`graph1'`lgraph'`histogram'`table'"' ~= "" {
		pystacked_graph_table,							///
			`holdout1' holdout(`holdout')				///
			`graph1'									///
			`histogram'									///
			goptions(`graph') lgoptions(`lgraph')		///
			`table'
	}
	
	// print MSPE table for regression problem
	if "`table'" ~= "" & "`e(type)'"=="reg" {
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
			di as res _col(30) %7.3f el(`m',`j'+1,1) _col(44) %7.3f el(`m',`j'+1,2)
		}

		// add to estimation macros
		ereturn mat mspe = `m'
	}
	
	// print confusion matrix for classification problem
	if "`table'" ~= "" & "`e(type)'"=="class" {
		tempname m w
		mat `m' = r(m)
		
		di
		di as text "Confusion matrix: In-Sample and Out-of-Sample"
		di as text "{hline 17}{c TT}{hline 42}"
		di as text "  Method" _c
		di as text _col(18) "{c |} Weight      In-Sample       Out-of-Sample"
		di as text _col(18) "{c |}             0       1         0       1  "
		di as text "{hline 17}{c +}{hline 42}"
		
		// di as text "  STACKING" _c
		// di as text _col(16) "0 {c |}" _c
		// di as text "    .  " _c
		// di as res  _col(27) %7.0f 1234567 _col(35) %7.0f 1234567 _col(45) %7.0f 1234567 _col(53) %7.0f 1234567
		di as text "  STACKING" _c
		di as text _col(16) "0 {c |}" _c
		di as text "    .  " _c
		di as res  _col(27) %7.0f el(`m',1,1) _col(35) %7.0f el(`m',1,2) _col(45) %7.0f el(`m',1,3) _col(53) %7.0f el(`m',1,4)
		di as text "  STACKING" _c
		di as text _col(16) "1 {c |}" _c
		di as text "    .  " _c
		di as res  _col(27) %7.0f el(`m',2,1) _col(35) %7.0f el(`m',2,2) _col(45) %7.0f el(`m',2,3) _col(53) %7.0f el(`m',2,4)
		
		forvalues j=1/`nlearners' {
			local b : word `j' of `base_est'
			di as text "  `b'" _c
			di as text _col(16) "0 {c |}" _c
			di as res  _col(20) %5.3f el(`weights_mat',`j',1) _c
			local r = 2*`j' + 1
			di as res  _col(27) %7.0f el(`m',`r',1) _col(35) %7.0f el(`m',`r',2) _col(45) %7.0f el(`m',`r',3) _col(53) %7.0f el(`m',`r',4)
			di as text "  `b'" _c
			di as text _col(16) "1 {c |}" _c
			di as res  _col(20) %5.3f el(`weights_mat',`j',1) _c
			local r = 2*`j' + 2
			di as res  _col(27) %7.0f el(`m',`r',1) _col(35) %7.0f el(`m',`r',2) _col(45) %7.0f el(`m',`r',3) _col(53) %7.0f el(`m',`r',4)
		}
		
		// add to estimation macros
		ereturn mat confusion = `m'
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
					xvars1(varlist fv) ///
					xvars2(varlist fv) ///
					xvars3(varlist fv) ///
					xvars4(varlist fv) ///
					xvars5(varlist fv) ///
					xvars6(varlist fv) ///
					xvars7(varlist fv) ///
					xvars8(varlist fv) ///
					xvars9(varlist fv) ///
					xvars10(varlist fv) ///
					///
					showpywarnings ///
					backend(string) ///
					///
					/// options for graphing; ignore here
					GRAPH1								/// vanilla option, abbreviates to "graph"
					HISTogram							/// report histogram instead of default ROC
					graph(string asis)					/// for passing options to graph combine
					lgraph(string asis)					/// for passing options to the graphs of the learners
					table								/// 
					HOLDOUT1							/// vanilla option, abbreviates to "holdout"
					holdout(varname)					///
					SParse								///
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

	* set the Python seed using randomly drawn number 
	if `pyseed'<0 {
		local pyseed = round(runiform()*10^8)
	}

	* defaults
	if "`finalest'"=="" {
		local finalest nnls
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

	if "`votetype'"!="" {
		local voting voting
	}
	if "`voteweights'"!="" {
		local voting voting
	}
	if "`voting'"!="" {
		if "`votetype'"=="" {
			local votetype hard
		}
		else if "`votetype'"!="hard"&"`votetype'"!="soft" {
			di as error "votetype(`votetype') not allowed"
			error 198
		}
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

	// mark sample 
	marksample touse
	markout `touse' `varlist'
	qui count if `touse'
	local N		= r(N)

	******** parse options using _pyparse.ado ********************************* 

	if `doublebarsyntax' {
		// Syntax 2
		syntax_parse `beforecomma' , type(`type') touse(`touse')
		local allmethods `r(allmethods)'
		local allpyopt `r(allpyopt)'
		local mcount = `r(mcount)'
		local allpipe (
		forvalues i = 1(1)`mcount' {
			local opt`i' `r(opt`i')'
			local method`i' `r(method`i')'
			local pyopt`i' `r(pyopt`i')'
			local pipe`i' `r(pipe`i')'
			local xvars`i' `r(xvars`i')'
			local allpipe `allpipe' '`pipe`i''', 
		}
		local allpipe `allpipe')
	} 
	else {
		// Syntax 1
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

	* Split varlists called yvar and xvars
	** xvars is the default predictor set.
	local yvar : word 1 of `varlist' 
	local xvars: list varlist - yvar

		forvalues i = 1(1)`mcount' {
			di "xvars`i' = `xvars`i''"
		} 	

	** predictors
	local xvars_all  // expanded original vars for each learner (for info only)
	local xvars_all_t // Python list with temp vars for each learner
	local allxvars // Python list with expanded original vars for each learner (for info only)
	local allxvars_t (  // Python list with temp vars for each learner
	forvalues i = 1(1)`mcount' {
		** if xvars() option is empty, use default list
		if "`xvars`i''"=="" {
			local xvars`i' `xvars'
		}
		** expand each varlist
		fvexpand `xvars`i'' if `touse'
		local xvars`i' `r(varlist)'
		** strip out variables with "o" and "b" prefix
		fvstrip `xvars`i'', dropomit
		local xvars`i' `r(varlist)'
		local allxvars `allxvars' '`xvars`i''',
		local xvars_all `xvars_all' `xvars`i''
		** create temp vars
		fvrevar `xvars`i''
		local xvars`i' `r(varlist)'
		** remove collinear predictors for OLS only
		if "`method`i''"=="ols" { 
			_rmcoll `xvars`i''
			local xvars`i'  `r(varlist)'
		}
		local xvars_all_t `xvars_all_t' `xvars`i''
		local allxvars_t `allxvars_t' '`xvars`i''',
	}
	local allxvars `allxvars']
	local allxvars_t `allxvars_t')

	** xvars_all_t is the unique list of all predictors; this will be passed to Python
	** we use the union of all vars
	local xvars_all_t : list uniq xvars_all_t
	local xvars_all : list uniq xvars_all

	** dependent variable (same procedure as above)
	fvexpand `yvar' if `touse'
	local yvar_t `r(varlist)'
	fvstrip `yvar_t', dropomit
	local yvar_t `r(varlist)'
	fvrevar `yvar_t'
	local yvar_t `r(varlist)'

	if ("`debug'"!="") {
		di "Default predictors = `xvars'"
		di "All predictors = `xvars_all'"
		di "All predictors (temp) = `xvars_all_t'"
		di "Predictors for each learners = `allxvars'"
		di "Predictors for each learners (temp) = `allxvars_t'"
		forvalues i = 1(1)`mcount' {
			di "xvars`i' = `xvars`i''"
		} 	
	}

	// create esample variable for posting (disappears from memory after posting)
	tempvar esample
	qui gen byte `esample' = `touse'
	ereturn post, depname(`yvar') esample(`esample') obs(`N')

	python: run_stacked(	///
					"`type'",	///
					"`finalest'", ///
					"`allmethods'", ///
					"`yvar_t'", ///
					"`xvars_all_t'",	///
					"`training_var'", ///
					///
					"`allpyopt'", ///
					"`allpipe'", ///
					"`allxvars_t'", ///
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
					"`showpywarnings'", ///
					"`backend'", ///
					"`sparse'" ///
					)

	ereturn local cmd		pystacked
	ereturn local predict	pystacked_p
	ereturn local depvar	`yvar'
	ereturn local type		`type'

	forvalues i = 1(1)`mcount' {
		ereturn local opt`i' `opt`i'' 
		ereturn local method`i' `method`i''
		ereturn local pyopt`i' `pyopt`i''	
		ereturn local pipe`i' `pipe`i''	
		ereturn local xvars`i' `xvars`i''
	}
	ereturn scalar mcount = `mcount'

end

// parses Syntax 2
program define syntax_parse, rclass

	syntax [anything(everything)] , type(string) touse(varname)

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
		syntax , [Method(string asis) OPTions(string asis) PIPEline(string asis) XVARs(varlist fv) ]
		local allmethods `allmethods' `method'
		return local method`i' `method'
		return local opt`i' `options'
		if "`pipeline'"=="" local pipeline passthrough
		_pyparse , `options' type(`type') method(`method') 
		return local pyopt`i' `r(optstr)'
		return local pipe`i' `pipeline'
		return local xvars`i' `xvars'
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

// graph and/or table
program define pystacked_graph_table, rclass
	version 16.0
	syntax ,								///
				[							///
					HOLDOUT1				/// vanilla option, abbreviates to "holdout"
					holdout(varname)		///
					GRAPH1					/// vanilla option, abbreviates to "graph"
					HISTogram				/// report histogram instead of default ROC
					goptions(string asis)	///
					lgoptions(string asis)	///
					table					/// 
				]

	// any graph options implies graph
	local graphflag = `"`graph1'`histogram'`goptions'`lgoptions'"'~=""
	
	if "`holdout'`holdout1'"=="" {
		local title In-sample
		tempvar touse
		qui gen `touse' = e(sample)
	}
	else {
		local title Out-of-sample
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
			di as text "Number of holdout observations:" as res %5.0f r(N)
		}
		else {
			// check that holdout variable doesn't overlap with e(sample)
			qui count if e(sample) & `holdout' > 0
			if r(N) > 0 {
				di as err "error - holdout and estimation samples overlap"
				exit 198
			}
			qui count if `holdout' > 0 & `holdout' < .
			if r(N) == 0 {
				di as err "error - no observations in holdout sample"
				exit 198
			}
			di as text "Number of holdout observations:" as res %5.0f r(N)
			local touse `holdout'
		}
	}

	local nlearners	= e(mcount)
	local learners	`e(base_est)'
	local y			`e(depvar)'
	// weights
	tempname weights
	mat `weights'	= e(weights)

	if "`e(type)'"=="reg" {
		// regression problem

		// complete graph title
		local title `title' Predictions
			
		tempvar stacking_p stacking_r
		predict double `stacking_p'
		label var `stacking_p' "Prediction: Stacking Regressor"
		qui gen double `stacking_r' = `y' - `stacking_p'
		qui predict double `stacking_p', transform
		forvalues i=1/`nlearners' {
			local lname : word `i' of `learners'
			label var `stacking_p'`i' "Prediction: `lname'"
			tempvar stacking_r`i'
			qui gen double `stacking_r`i'' = `y' - `stacking_p'`i'
		}
	
		tempname g0
		if `graphflag' {
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
	}
	else {
		// classification problem
		
		tempvar stacking_p stacking_c
		predict double `stacking_p', pr
		label var `stacking_p' "Predicted Probability: Stacking Regressor"
		predict double `stacking_c', class
		label var `stacking_c' "Predicted Classification: Stacking Regressor"
		qui predict double `stacking_p', pr transform
		qui predict double `stacking_c', class transform

		forvalues i=1/`nlearners' {
			local lname : word `i' of `learners'
			label var `stacking_p'`i' "Predicted Probability: `lname'"
			label var `stacking_c'`i' "Predicted Classification: `lname'"
		}
		
		if `graphflag' & "`histogram'"=="" {							/// default is ROC
			// complete graph title
			local title `title' ROC
		
			tempname g0
			roctab `y' `stacking_p',									///
				graph													///
				title("STACKING")										///
				`lgoptions'												///
				nodraw													///
				name(`g0', replace)
			local glist `g0'
			forvalues i=1/`nlearners' {
				tempname g`i'
				local lname : word `i' of `learners'
				roctab `y' `stacking_p'`i',								///
					graph												///
					title("Learner: `lname'")							///
					`lgoptions'											///
					nodraw												///
					name(`g`i'', replace)
				local glist `glist' `g`i''
			}
			graph combine `glist'										///
							,											///
							title("`title'")							///
							`goptions'
		}
		else if "`histogram'"~="" {										/// histogram
			// complete graph title
			local title `title' predicted probabilities

			// user may have specified something other than freq
			local 0 , `lgoptions'
			syntax , [ DENsity FRACtion FREQuency percent * ]
			if "`density'`fraction'`frequency'`percent'"== "" {
				// default is frequency
				local ystyle freq
			}
			
			tempname g0
			qui histogram `stacking_p',									///
				title("STACKING")										///
				`ystyle'												///
				start(0)												///
				`lgoptions'												///
				nodraw													///
				name(`g0', replace)
			local glist `g0'
			forvalues i=1/`nlearners' {
				tempname g`i'
				local lname : word `i' of `learners'
				qui histogram `stacking_p'`i',							///
					title("Learner: `lname'")							///
					`ystyle'											///
					start(0)											///
					`lgoptions'											///
					nodraw												///
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
			tempname m mrow
			
			// stacking rows
			forvalues r=0/1 {
				qui count if `y'==`r' & `stacking_c'==0 & e(sample)
				local in_0	= r(N)
				qui count if `y'==`r' & `stacking_c'==1 & e(sample)
				local in_1	= r(N)
				if "`holdout'`holdout1'"~="" {
					// touse is the holdout indicator
					qui count if `y'==`r' & `stacking_c'==0 & `touse'
					local out_0	= r(N)
					qui count if `y'==`r' & `stacking_c'==1 & `touse'
					local out_1	= r(N)
				}
				else {
					local out_0 = .
					local out_1 = .
				}
				mat `mrow' = `in_0', `in_1', `out_0', `out_1'
				mat `m' = nullmat(`m') \ `mrow'
			}
			
			// base learner rows
			forvalues i=1/`nlearners' {
			
				forvalues r=0/1 {
					qui count if `y'==`r' & `stacking_c'`i'==0 & e(sample)
					local in_0	= r(N)
					qui count if `y'==`r' & `stacking_c'`i'==1 & e(sample)
					local in_1	= r(N)
					if "`holdout'`holdout1'"~="" {
						// touse is the holdout indicator
						qui count if `y'==`r' & `stacking_c'`i'==0 & `touse'
						local out_0	= r(N)
						qui count if `y'==`r' & `stacking_c'`i'==1 & `touse'
						local out_1	= r(N)
					}
					else {
						local out_0 = .
						local out_1 = .
					}
					mat `mrow' = `in_0', `in_1', `out_0', `out_1'
					mat `m' = `m' \ `mrow'
				}
			}
			
			local rnames STACKING_0 STACKING_1
			forvalues i=1/`nlearners' {
				local lname : word `i' of `learners'
				local rnames `rnames' `lname'_0 `lname'_1
			}
			mat rownames `m' = `rnames'
			mat colnames `m' = in_0 in_1 out_0 out_1
			
			return matrix m = `m'
	
		}
	}
	
end


// Internal version of matchnames
// Sample syntax:
// matchnames "`varlist'" "`list1'" "`list2'"
// takes list in `varlist', looks up in `list1', returns entries in `list2', called r(names)
program define matchnames, rclass
	version 11.2
	args	varnames namelist1 namelist2

	local k1 : word count `namelist1'
	local k2 : word count `namelist2'

	if `k1' ~= `k2' {
		di as err "namelist error"
		exit 198
	}
	foreach vn in `varnames' {
		local i : list posof `"`vn'"' in namelist1
		if `i' > 0 {
			local newname : word `i' of `namelist2'
		}
		else {
* Keep old name if not found in list
			local newname "`vn'"
		}
		local names "`names' `newname'"
	}
	local names	: list clean names
	return local names "`names'"
end

// internal version of fvstrip 1.01 ms 24march2015
// takes varlist with possible FVs and strips out b/n/o notation
// returns results in r(varnames)
// optionally also omits omittable FVs
// expand calls fvexpand either on full varlist
// or (with onebyone option) on elements of varlist
program define fvstrip, rclass
	version 11.2
	syntax [anything] [if] , [ dropomit expand onebyone NOIsily ]
	if "`expand'"~="" {												//  force call to fvexpand
		if "`onebyone'"=="" {
			fvexpand `anything' `if'								//  single call to fvexpand
			local anything `r(varlist)'
		}
		else {
			foreach vn of local anything {
				fvexpand `vn' `if'									//  call fvexpand on items one-by-one
				local newlist	`newlist' `r(varlist)'
			}
			local anything	: list clean newlist
		}
	}
	foreach vn of local anything {									//  loop through varnames
		if "`dropomit'"~="" {										//  check & include only if
			_ms_parse_parts `vn'									//  not omitted (b. or o.)
			if ~`r(omit)' {
				local unstripped	`unstripped' `vn'				//  add to list only if not omitted
			}
		}
		else {														//  add varname to list even if
			local unstripped		`unstripped' `vn'				//  could be omitted (b. or o.)
		}
	}
// Now create list with b/n/o stripped out
	foreach vn of local unstripped {
		local svn ""											//  initialize
		_ms_parse_parts `vn'
		if "`r(type)'"=="variable" & "`r(op)'"=="" {			//  simplest case - no change
			local svn	`vn'
		}
		else if "`r(type)'"=="variable" & "`r(op)'"=="o" {		//  next simplest case - o.varname => varname
			local svn	`r(name)'
		}
		else if "`r(type)'"=="variable" {						//  has other operators so strip o but leave .
			local op	`r(op)'
			local op	: subinstr local op "o" "", all
			local svn	`op'.`r(name)'
		}
		else if "`r(type)'"=="factor" {							//  simple factor variable
			local op	`r(op)'
			local op	: subinstr local op "b" "", all
			local op	: subinstr local op "n" "", all
			local op	: subinstr local op "o" "", all
			local svn	`op'.`r(name)'							//  operator + . + varname
		}
		else if"`r(type)'"=="interaction" {						//  multiple variables
			forvalues i=1/`r(k_names)' {
				local op	`r(op`i')'
				local op	: subinstr local op "b" "", all
				local op	: subinstr local op "n" "", all
				local op	: subinstr local op "o" "", all
				local opv	`op'.`r(name`i')'					//  operator + . + varname
				if `i'==1 {
					local svn	`opv'
				}
				else {
					local svn	`svn'#`opv'
				}
			}
		}
		else if "`r(type)'"=="product" {
			di as err "fvstrip error - type=product for `vn'"
			exit 198
		}
		else if "`r(type)'"=="error" {
			di as err "fvstrip error - type=error for `vn'"
			exit 198
		}
		else {
			di as err "fvstrip error - unknown type for `vn'"
			exit 198
		}
		local stripped `stripped' `svn'
	}
	local stripped	: list retokenize stripped						//  clean any extra spaces
	
	if "`noisily'"~="" {											//  for debugging etc.
di as result "`stripped'"
	}

	return local varlist	`stripped'								//  return results in r(varlist)
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
from sklearn.preprocessing import StandardScaler,PolynomialFeatures,OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer,KNNImputer
from sklearn.linear_model import LassoLarsIC,LassoCV,LogisticRegression,LogisticRegressionCV,LinearRegression
from sklearn.linear_model import RidgeCV,ElasticNetCV
from sklearn.ensemble import StackingRegressor,StackingClassifier
from sklearn.ensemble import VotingRegressor,VotingClassifier
from sklearn.ensemble import RandomForestRegressor,RandomForestClassifier
from sklearn.ensemble import GradientBoostingRegressor,GradientBoostingClassifier
from sklearn.base import TransformerMixin
from sklearn.svm import LinearSVR,LinearSVC,SVC,SVR
from scipy.sparse import coo_matrix,csr_matrix,issparse
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

class SparseTransformer(TransformerMixin):
	def fit(self, X, y=None, **fit_params):
		return self
	def transform(self, X, y=None, **fit_params):
		return csr_matrix(X)

def get_index(lst, w):
	#
	#return indexes of where elements in 'w' are stored in 'lst'
	#
	lst = lst.split(" ")
	w = w.split(" ")
	sel = []
	for i in range(len(w)):
		if w[i] in lst:
			ix = lst.index(w[i]) 
			sel.append(ix)
	return(sel)

def build_pipeline(pipes,xvars,xvar_sel):
	#
	#builds the pipeline for each base learner
	#pipes = string with pipes
	#xvars = string with all predictors (expanded original names)
	#xvar_sel = string with to-be-selected predictors
	#
	ll = []
	if xvar_sel!="":
		sel_ix = get_index(xvars,xvar_sel)
		ct = ColumnTransformer([("selector", "passthrough", sel_ix)],remainder="drop")
		#print(xvars.split(" "))
		#print(xvar_sel)
		#print(sel_ix)
		#print([xvars.split(" ")[i] for i in sel_ix])
		ll.append(("selector",ct))
	pipes = pipes.split()
	for p in range(len(pipes)):
		if pipes[p]=="stdscaler":
			ll.append(('stdscaler',StandardScaler()))
		elif pipes[p]=="stdscaler0":
			ll.append(('stdscaler',StandardScaler(with_mean=False)))
		elif pipes[p]=="dense":
			ll.append(('dense',DenseTransformer()))
		elif pipes[p]=="sparse":
			ll.append(('sparse',SparseTransformer()))
		elif pipes[p]=="onehot":
			ll.append(('onehot',OneHotEncoder()))
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

def run_stacked(type, # regression or classification 
	finalest, # final estimator
	methods, # list of base learners
	yvar, # outcome
	xvars, # predictors (temp names)
	training, # marks holdout sample
	allopt, # options for each learner
	allpipe, # pipes for each learner
	allxvar_sel, # subset predictors for each learner (expanded var names)
	touse, # sample
	seed, # seed
	nosavepred,nosavetransform, # store predictions
	voting,votetype,voteweights, # voting
	njobs, # number of jobs
	nfolds, # number of folds
	showpywarnings, # show warnings?
	parbackend, # backend
	sparse # sparse predictor matrix
	):
	
	if int(format(sklearn.__version__).split(".")[1])<24 and int(format(sklearn.__version__).split(".")[0])<1:
		sfi.SFIToolkit.stata('di as err "pystacked requires sklearn 0.24.0 or higher. Please update sklearn."')
		sfi.SFIToolkit.stata('di as err "See instructions on https://scikit-learn.org/stable/install.html, and in the help file."')
		sfi.SFIToolkit.error(198)

	# Set random seed
	if seed>0:
		rng=np.random.RandomState(seed)
	else: 
		rng=None

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

	y = np.array(sfi.Data.get(yvar,selectvar=touse))
	x = np.array(sfi.Data.get(xvars,selectvar=touse))
	# If missings are present, need to specify they are NaNs.
	x_0 = np.array(sfi.Data.get(xvars,missingval=np.nan))

	if sparse!="":
		x = coo_matrix(x).tocsc()

	##############################################################
	### prepare fit											   ###
	##############################################################

	# convert strings to python objects
	methods = methods.split()
	allopt = eval(allopt)
	allpipe = eval(allpipe)
	allxvar_sel = eval(allxvar_sel)

	est_list = []
	for m in range(len(methods)):
		if type=="reg":
			if methods[m]=="ols":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
				newmethod.append(('ols',LinearRegression(**opt)))
			if methods[m]=="lassoic":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
				newmethod.append(('lassolarsic',LassoLarsIC(**opt)))
			if methods[m]=="lassocv":
				opt =allopt[m]
				newmethod= build_pipeline(allpipe[m],xvars,allxvar_sel[m])
				newmethod.append(('lassocv',ElasticNetCV(**opt)))
			if methods[m]=="ridgecv":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
				newmethod.append(('lassocv',ElasticNetCV(**opt)))
			if methods[m]=="elasticcv":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
				newmethod.append(('lassocv',ElasticNetCV(**opt)))
			if methods[m]=="rf":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
				newmethod.append(('rf',RandomForestRegressor(**opt)))
			if methods[m]=="gradboost":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
				newmethod.append(('gbr',GradientBoostingRegressor(**opt)))
			if methods[m]=="svm":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
				newmethod.append(('svm', SVR(**opt)))
			if methods[m]=="linsvm":	
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
				newmethod.append(('linsvm',LinearSVR(**opt)))
			if methods[m]=="nnet":	
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
				newmethod.append(('mlp',MLPRegressor(**opt)))
		elif type=="class":
			if methods[m]=="logit":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
				newmethod.append(('lassocv',LogisticRegression(**opt)))
			if methods[m]=="lassoic":
				sfi.SFIToolkit.stata("di as err lassoic not supported with type(class)")
				sfi.SFIToolkit.error()
			if methods[m]=="lassocv":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
				newmethod.append(('lassocv',LogisticRegressionCV(**opt)))
			if methods[m]=="ridgecv":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
				newmethod.append(('lassocv',LogisticRegressionCV(**opt)))
			if methods[m]=="elasticcv":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
				newmethod.append(('lassocv',LogisticRegressionCV(**opt)))
			if methods[m]=="rf":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
				newmethod.append(('rf',RandomForestClassifier(**opt)))
			if methods[m]=="gradboost":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
				newmethod.append(('gradboost',GradientBoostingClassifier(**opt)))
			if methods[m]=="svm":	
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
				newmethod.append(('svm',SVC(**opt)))
			if methods[m]=="linsvm":
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
				newmethod.append(('linsvm',LinearSVC(**opt)))
			if methods[m]=="nnet":	
				opt =allopt[m]
				newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
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
		votetype="soft"
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

	if nosavepred == "" and type =="class" and votetype!="hard":
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