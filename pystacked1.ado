*! pystacked v0.7.8e
*! last edited: 23oct2025
*! authors: aa/ms
*! pystacked1 = pystacked with core python code loaded from pystacked.py
*!              using python import in parent program pystacked1

// parent program
program define pystacked1, eclass
    version 16.0

    // exception for printoption which can be called w/o variables
    tokenize `"`0'"', parse(",")
    local beforecomma `1'
    macro shift
    local restargs `*'
    local printopt_on = strpos("`restargs'","print")!=0

    if ~replay() {
        // no replay - must estimate
        
        // load core python code
        python clear
        pystacked_check_python
        qui findfile pystacked.py
        cap python script "`r(fn)'", global
        if _rc != 0 {
            noi disp "Error loading Python Script for pystacked."
            error 199
        }
        python: from pystacked import *
        // end load core python code

        _pystacked `0'
    }
    else if replay() & `printopt_on' {
        // just print options and leave
        _pyparse `0'
        exit
    }
    else {
        // replay - check that pystacked estimation is in memory
        if "`e(cmd)'"~="pystacked" {
            di as err "last estimates not found"
            exit 301
        }
    }

    // save for display results
    tempname weights_mat
    mat `weights_mat'=e(weights)
    local base_est `e(base_est)'
    local nlearners    = e(mcount)

    // parse and check for graph/table options
    // code borrowed from _pstacked below - needed to accommodate syntax #2
    if ~replay() {
        tokenize "`0'", parse(",")
        local beforecomma `1'
        macro shift
        local restargs `*'
        local 0 `beforecomma'
        syntax anything(name=beforeifinweight) [if] [in] [aweight fweight]
        if "`weight'"!="" {
            local ifinweight `if' `in' [`weight' `exp']
        }
        else {
            local ifinweight `if' `in' `weight' `exp'
        }
        tokenize `beforeifinweight', parse("|")
        local mainargs `1'
        local 0 `mainargs' `ifinweight' `restargs'
    }
    syntax [anything]  [if] [in] [aweight fweight] ,    ///
                [                                       ///
                    GRAPH1                              /// vanilla option, abbreviates to "graph"
                    HISTogram                           /// report histogram instead of default ROC
                    graph(string asis)                  /// for passing options to graph combine
                    lgraph(string asis)                 /// for passing options to the graphs of the learners
                    TABLE1                              ///
                    table(string)                       /// rmspe or confusion
                    HOLDOUT1                            /// vanilla option, abbreviates to "holdout"
                    holdout(varname)                    ///
                    CValid                              ///
                    NOESTIMATE                          /// suppress call to run_stacked; no estimates, only parses
                    SHOWCoefs                           ///
                    PRINTopt                            ///
                    cvc                                    /// report cvc test
                    *                                   ///
                ]

    if "`printopt'"!="" local noestimate noestimate
    
    // default reg table = rmspe
    // default class table = confusion
    // table1 = "table" or ""
    // table = rmspe or confusion
    if "`table'"~="" & "`table1'"~="" {
        di as err "error - multiple table options specified"
        exit 198
    }
    if "`table'"~="" & "`table'"~="rmspe" & "`table'"~="confusion" {
        di as err "error - option table(`table') not supported"
        exit 198
    }
    if "`table'"=="confusion" & "`e(type)'"=="reg" {
        di as err "error - confusion table available for classification problems only"
        exit 198
    }
    // if table1 and table both blank, set macro table to default type
    if "`table1'"~="" & "`table'"=="" {
        if "`e(type)'"=="reg" {
            local table rmspe
        }
        else {
            local table confusion
        }           
    }
    // from here, table is the macro indicating table type
    
    // display results
    if `"`graph'`graph1'`lgraph'`histogram'`table'`noestimate'`cvc'"' == "" {

        di
        di as res "Stacking weights:"
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

    // display results
    if "`showcoefs'"!="" & "`noestimate'" == "" {

        forvalues i = 1(1)`e(mcount)' {

            if (`e(has_coefs`i')') {

                // get learner

                local thislearner : word `i' of `e(base_est)'
                // get coefficient matrix
                tempname coefs_mat
                mat `coefs_mat'=e(coefs`i')

                // add constant as a name if it's there
                local thexvars `e(xvars_o`i')'
                if (`e(has_intercept`i')') local thexvars `thexvars' _cons

                // save number of coefficients and number of var names
                local coef_nums = rowsof(`coefs_mat')
                local varname_count : word count `thexvars'

                // get max string length of variables
                local maxstrlen = 17
                foreach i in `thexvars' {
                    local thisstrlen = strlen("`i'")
                    if (`thisstrlen'>`maxstrlen'-2) local maxstrlen = `thisstrlen'+2
                }
                local maxstrlen = `maxstrlen'+2

                // which type of coefficients are shown
                local coeftype Coefficients
                if regexm("rf gradboost","`thislearner'") {
                    local coeftype Variable importance
                }

                // only display if # names = # coefs
                if (`coef_nums' == `varname_count') {
                    di
                    di as res "`coeftype' `thislearner'`i':"
                    di as text "{hline `=`maxstrlen'-1'}{c TT}{hline 21}"
                    di as text "  Predictor  " _c
                    di as text _col(`maxstrlen') "{c |}      Value"
                    di as text "{hline `=`maxstrlen'-1'}{c +}{hline 21}"

                    forvalues j=1/`coef_nums' {
                        local thisxvar : word `j' of `thexvars'
                        di as text "  `thisxvar'" _c
                        di as text _col(`maxstrlen') "{c |}" _c
                        di as res %15.7f el(`coefs_mat',`j',1)
                    }
                }
                if "`e(type)'"=="class" & regexm("lassocv ridgecv elasticcv logit","`thislearner'") {
                    di "" _c
                    di as text "Note: " _c
                    di as text "Coefficients correspond to decision boundary function."
                }
            }
        }   
    }

    // graph/table block
    if `"`graph'`graph1'`lgraph'`histogram'`table'"' ~= "" {
        pystacked_graph_table,                          ///
            `holdout1' holdout(`holdout')               ///
            `cvalid'                                    ///
            `graph1'                                    ///
            `histogram'                                 ///
            goptions(`graph') lgoptions(`lgraph')       ///
            table(`table')
    }
    
    // print RMSPE table if specified
    if "`table'"=="rmspe" {
        tempname m w
        mat `m' = r(m)
        
        di
        di as text "RMSPE: In-Sample, CV, Holdout"
        di as text "{hline 17}{c TT}{hline 47}"
        di as text "  Method" _c
        di as text _col(18) "{c |} Weight   In-Sample        CV         Holdout"
        di as text "{hline 17}{c +}{hline 47}"
        
        di as text "  STACKING" _c
        di as text _col(18) "{c |}" _c
        di as text "    .  " _c
        di as res  _col(30) %7.3f el(`m',1,1) _col(43) %7.3f el(`m',1,2) _col(56) %7.3f el(`m',1,3)
        
        forvalues j=1/`nlearners' {
            local b : word `j' of `base_est'
            di as text "  `b'" _c
            di as text _col(18) "{c |}" _c
            di as res _col(20) %5.3f el(`weights_mat',`j',1) _c
            di as res _col(30) %7.3f el(`m',`j'+1,1) _col(43) %7.3f el(`m',`j'+1,2) _col(56) %7.3f el(`m',`j'+1,3)
        }

        // add to estimation macros
        ereturn mat rmspe = `m'
    }
    
    // print confusion matrix if specified
    if "`table'"=="confusion" {
        tempname m w
        mat `m' = r(m)
        
        di
        di as text "Confusion matrix: In-Sample, CV, Holdout"
        di as text "{hline 17}{c TT}{hline 59}"
        di as text "  Method" _c
        di as text _col(18) "{c |} Weight      In-Sample             CV             Holdout"
        di as text _col(18) "{c |}             0       1         0       1         0       1"
        di as text "{hline 17}{c +}{hline 59}"
        
        di as text "  STACKING" _c
        di as text _col(16) "0 {c |}" _c
        di as text "    .  " _c
        di as res  _col(27) %7.0f el(`m',1,1) _col(35) %7.0f el(`m',1,2) _col(45) %7.0f el(`m',1,3) _col(53) %7.0f el(`m',1,4) _col(63) %7.0f el(`m',1,5) _col(71) %7.0f el(`m',1,6)
        di as text "  STACKING" _c
        di as text _col(16) "1 {c |}" _c
        di as text "    .  " _c
        di as res  _col(27) %7.0f el(`m',2,1) _col(35) %7.0f el(`m',2,2) _col(45) %7.0f el(`m',2,3) _col(53) %7.0f el(`m',2,4) _col(63) %7.0f el(`m',2,5) _col(71) %7.0f el(`m',2,6)
        
        forvalues j=1/`nlearners' {
            local b : word `j' of `base_est'
            di as text "  `b'" _c
            di as text _col(16) "0 {c |}" _c
            di as res  _col(20) %5.3f el(`weights_mat',`j',1) _c
            local r = 2*`j' + 1
            di as res  _col(27) %7.0f el(`m',`r',1) _col(35) %7.0f el(`m',`r',2) _col(45) %7.0f el(`m',`r',3) _col(53) %7.0f el(`m',`r',4) _col(63) %7.0f el(`m',`r',5) _col(71) %7.0f el(`m',`r',6)
            di as text "  `b'" _c
            di as text _col(16) "1 {c |}" _c
            di as res  _col(20) %5.3f el(`weights_mat',`j',1) _c
            local r = 2*`j' + 2
            di as res  _col(27) %7.0f el(`m',`r',1) _col(35) %7.0f el(`m',`r',2) _col(45) %7.0f el(`m',`r',3) _col(53) %7.0f el(`m',`r',4) _col(63) %7.0f el(`m',`r',5) _col(71) %7.0f el(`m',`r',6)
        }
        
        // add to estimation macros
        ereturn mat confusion = `m'
    }
    
    if "`cvc'"~="" {
        // valid only for type=regression
        if "`e(type)'"~="reg" {
            di as err "error - CVC test available only for regression-type models"
            exit 198
        }
        tempvar stub
        predict double `stub', basexb cvalid
        // capture in case cvc isn't installed
        cap cvc `stub'*, yvar(`e(depvar)') foldvar(`e(foldvar)') all
        if _rc==199 {
            di as err "error - must install cvc. See ...."
            exit 199
        }
        else if _rc>0 {
            di as err "internal pystacked error"
            exit _rc
        }
        tempname pmat
        mat `pmat'=r(pmat)
        di
        di as res "CVC test p-values:"
        di as text "{hline 17}{c TT}{hline 21}"
        di as text "  Method" _c
        di as text _col(18) "{c |}      p-value"
        di as text "{hline 17}{c +}{hline 21}"

        forvalues j=1/`nlearners' {
            local b : word `j' of `base_est'
            di as text "  `b'" _c
            di as text _col(18) "{c |}" _c
            di as res %15.7f el(`pmat',1,`j')
        }
        // add to estimation macros
        mat `pmat' = `pmat''
        mat rownames `pmat' = `base_est'
        mat colnames `pmat' = "pval"
        ereturn mat cvc_p = `pmat'
    }
    
end


// main program
program define _pystacked, eclass
version 16.0

    tokenize "`0'", parse(",")
    local beforecomma `1'
    macro shift
    local restargs `*'
    local 0 `beforecomma'
    syntax anything(name=beforeifinweight) [if] [in] [aweight fweight]
            if "`weight'"!="" {
                local ifinweight `if' `in' [`weight' `exp']
            }
            else {
                local ifinweight `if' `in' `weight' `exp'
            }
    tokenize `beforeifinweight', parse("|")
    local mainargs `1'
    local 0 `mainargs' `ifinweight' `restargs'
    local doublebarsyntax = ("`2'"=="|")*("`3'"=="|")
    if `doublebarsyntax'==0 {
        // required to allow for numbered options
        syntax varlist(min=2 fv) [if] [in] [aweight fweight] [, Methods(string) TYpe(string) *]
        // set default
        if ("`type'"=="") {
            local type reg
            local typeopt type(reg)
        }
        if ("`methods'"=="") {
            if (substr("`type'",1,5)=="class") {
                local methods logit lassocv gradboost
            }
            else {
                local methods ols lassocv gradboost
            }
            local methodsopt methods(`methods')
        }
        forv i = 1/`:list sizeof methods' {
            local numopts `numopts' cmdopt`i'(string asis) pipe`i'(string asis) xvars`i'(varlist fv)
        }
    }
    syntax varlist(min=2 fv) [if] [in] [aweight fweight], [*]
    local globalopt `options'
    syntax varlist(min=2 fv) [if] [in] [aweight fweight], ///
                [ ///
                    TYpe(string) /// classification or regression
                    FINALest(string) ///
                    NJobs(int 0) ///
                    CV ///
                    Folds(int 5) ///
                    FOLDVar(varname) ///
                    PREFit ///
                    BFolds(int 5) ///
                    NORANDOM ///
                    NOSHUFFLE ///
                    ///
                    ///
                    PYSeed(integer -1) ///
                    PRINTopt ///
                    NOSAVEPred ///
                    NOSAVETransform /// legacy option
                    NOSAVEBasexb /// equivalent to old NOSAVETransform
                    ///
                    VOTing ///
                    ///
                    VOTEType(string) ///
                    VOTEWeights(numlist >0) ///
                    debug ///
                    Methods(string) ///
                    `numopts' ///
                    ///
                    SHOWPymessages ///
                    backend(string) ///
                    altpython                               /// used for branching to pystacked1 or 2; saved as e(.) macro
                    ///
                    /// options for graphing; ignore here
                    GRAPH1                                  /// vanilla option, abbreviates to "graph"
                    HISTogram                               /// report histogram instead of default ROC
                    graph(string asis)                      /// for passing options to graph combine
                    lgraph(string asis)                     /// for passing options to the graphs of the learners
                    TABle                                   /// 
                    HOLDOUT1                                /// vanilla option, abbreviates to "holdout"
                    holdout(varname)                        ///
                    CValid                                  ///
                    SHOWCoefs                               ///
                    SParse                                  ///
                    SHOWOPTions                             ///
                    NOESTIMATE                              /// suppress call to run_stacked; no estimates, only parses
                ]

    if `"`methods'"'=="" local methods `methods0'
    if "`printopt'"!="" {
        local noestimate noestimate
    }

    if ("`exp'"!="") {
        tempvar wvar
        local wvar_t = subinstr("`exp'","=","",.)
        local wvar_t = subinstr("`wvar_t'"," ","",.)
        gen `wvar'=`wvar_t'
    }

    * set defaults
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
    if ("`methods'"=="") {
        if ("`type'"=="class") {
            local methods logit lassocv gradboost
        }
        else {
            local methods ols lassocv gradboost
        }
        local methodsopt methods(`methods')
    }

    * set the Python seed using randomly drawn number 
    if `pyseed'<0 & "`noestimate'"=="" {
        local pyseed = round(runiform()*10^8)
    }

    * defaults
    if "`finalest'"=="" {
        local finalest nnls1
    }
    * legacy option
    if "`nosavetransform'"~="" {
        local nosavebasexb nosavebasexb
        local nosavetransform
    }

    if "`backend'"=="" local backend threading
    if "`backend'"!="loky"&"`backend'"!="multiprocessing"&"`backend'"!="threading" {
        di as err "backend not supported"
        exit 198
    }
    //local backend threading

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

    // get sklearn version
    python: from sklearn import __version__ as sklearn_version
    python: sfi.Macro.setLocal("sklearn_ver1",format(sklearn_version).split(".")[0])
    python: sfi.Macro.setLocal("sklearn_ver2",format(sklearn_version).split(".")[1])
    cap python: sfi.Macro.setLocal("sklearn_ver3",format(sklearn_version).split(".")[2])
    if ("`sklearn_ver3'"=="") local sklearn_ver3 = 0

    // mark sample 
    marksample touse
    markout `touse' `varlist' `wvar'

    // generate fold var
    cap confirm variable `foldvar'
    if _rc>0 {
        // variable either doesn't exist or wasn't provided, so create tempvar fid
        *** gen folds
        tempvar uni cuni fid
        if "`norandom'"~="" | "`noestimate'"!="" {
            qui gen `uni' = _n
        }
        else {
            qui gen double `uni' = runiform() if `touse'
        }
        qui cumul `uni' if `touse', gen(`cuni')
        qui gen int `fid' = ceil(`folds'*`cuni') if `touse'
    }
    else {
        tempvar fid
        qui gen int `fid'=`foldvar'
        // provided foldvar may have missing values
        markout `touse' `foldvar'
    }

    qui count if `touse'
    local N        = r(N)
    tempvar id 
    gen long `id'=_n
    local shuffle=("`noshuffle'"=="")

    ******** parse options using _pyparse.ado ********************************* 

    if `doublebarsyntax' {
        // Syntax 2
        syntax_parse `beforeifinweight' , type(`type') touse(`touse') sklearn1(`sklearn_ver1') sklearn2(`sklearn_ver2') sklearn3(`sklearn_ver3') `printopt'
        local allmethods `r(allmethods)'
        local allpyopt `r(allpyopt)'
        local mcount : word count `allmethods'
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
        local mcount : word count `allmethods'
        local allpipe (
        forvalues i = 1(1)`mcount' {
            local method : word `i' of `allmethods'
            if "`method'"!="" {
                local mcount = `i'
                _pyparse , `cmdopt`i'' type(`type') method(`method') sklearn1(`sklearn_ver1') sklearn2(`sklearn_ver2') sklearn3(`sklearn_ver3') `printopt'
                if `i'==1 {
                    local allpyopt [`r(optstr)'
                }
                else {
                    local allpyopt `allpyopt' , `r(optstr)'
                }
                local opt`i' `cmdopt`i'' 
                local method`i' `method'
                local pyopt`i' `r(optstr)'
                ** if (no)stdscaler isn't included, add it at the end for linear estimators
                if strpos("`pipe`i''","stdscaler")==0 & strpos("lassoic lassocv ridgecv elasticcv logit","`method'")!=0 {
                    local pipe`i' `pipe`i'' stdscaler
                }
                ** remove 'nostdscaler'
                local pipe`i' = subinstr("`pipe`i''","nostdscaler","",.)
                if "`pipe`i''"=="" local pipe`i' passthrough
                local allpipe `allpipe' '`pipe`i''', 
            }            
        }
        local allpyopt `allpyopt']
        local allpipe `allpipe')
    }

    ******** dealing with varlists ******************************************** 

    * Split varlists called yvar and xvars
    ** xvars is the default predictor set.
    local yvar : word 1 of `varlist' 
    local xvars: list varlist - yvar
    if ("`debug'"!="") {
        forvalues i = 1(1)`mcount' {
            di "xvars`i' = `xvars`i''"
        }
    }

    ** predictors
    local xvars_all  // expanded original vars for each learner (for info only)
    local xvars_all_t // Python list with temp vars for each learner
    local allxvars ( // Python list with expanded original vars for each learner (for info only)
    local allxvars_t (  // Python list with temp vars for each learner
    forvalues i = 1(1)`mcount' {
        ** if xvars() option is empty, use default list
        if "`xvars`i''"=="" {
            local xvars`i' `xvars'
        }
        local xvars_orig`i' `xvars`i''
        ** expand each varlist, and strip out variables with "o" and "b" prefix
        fvstrip `xvars`i'' if `touse', dropomit expand
        local xvars`i' `r(varlist)'
        local allxvars `allxvars' '`xvars`i''',
        local xvars_all `xvars_all' `xvars`i''
        ** create temp vars; loop through one-by-one so no zero vector temps are created
        local tlist
        foreach v in `xvars`i'' {
            fvrevar `v' if `touse'
            local tlist `tlist' `r(varlist)'
        }
        local xvars`i' `tlist'
        ** remove collinear predictors for OLS only
        if "`method`i''"=="ols" { 
            _rmcoll `xvars`i'' if `touse', forcedrop
            local xvars`i'  `r(varlist)'
        }
        local xvars_all_t `xvars_all_t' `xvars`i''
        local allxvars_t `allxvars_t' '`xvars`i''',
    }
    local allxvars `allxvars')
    local allxvars_t `allxvars_t')

    ** xvars_all_t is the unique list of all predictors; this will be passed to Python
    ** we use the union of all vars
    local xvars_all_t : list uniq xvars_all_t
    local xvars_all : list uniq xvars_all

    ** dependent variable (same procedure as above)
    fvstrip `yvar' if `touse', dropomit expand
    local yvar_t `r(varlist)'
    fvrevar `yvar_t' if `touse'
    local yvar_t `r(varlist)'

    if ("`debug'"!="") {
        di "Default predictors = `xvars'"
        di "All predictors = `xvars_all'"
        di "All predictors (temp) = `xvars_all_t'"
        di "Predictors for each learner = `allxvars'"
        di "Predictors for each learner (temp) = `allxvars_t'"
        forvalues i = 1(1)`mcount' {
            di "xvars`i' = `xvars`i''"
        }     
        di "Summarize yvar_t and xvars_all_t:"
        sum `yvar_t' `xvars_all_t' if `touse'
    }

    ******** dealing with varlists END ***************************************** 

    // create esample variable for posting (disappears from memory after posting)
    tempvar esample
    qui gen byte `esample' = `touse'
    ereturn post, depname(`yvar') esample(`esample') obs(`N')

    if "`noestimate'"=="" {
        python: run_stacked( ///
                        "`type'",    ///
                        "`finalest'", ///
                        "`allmethods'", ///
                        "`yvar_t'", ///
                        "`xvars_all_t'", ///
                        "`wvar'", ///
                        "`training_var'", ///
                        ///
                        "`allpyopt'", ///
                        "`allpipe'", ///
                        "`allxvars_t'", ///
                        ///  
                        "`touse'", ///
                        `pyseed', ///
                        "`nosavepred'", ///
                        "`nosavebasexb'", ///
                        "`voting'" , ///
                        "`votetype'", ///
                        "`voteweights'", ///
                        `njobs' , ///
                        "`fid'", ///
                        "`prefit'", ///
                        "`cv'", ///
                        `bfolds', ///
                        `shuffle', ///
                        "`id'", ///
                        "`showpymessages'", ///
                        "`backend'", ///
                        "`sparse'", ///
                        "`showoptions'" ///
                        )
    }
    ereturn local altpython  `altpython'
    ereturn local cmd        pystacked
    ereturn local predict    pystacked_p
    ereturn local depvar    `yvar'
    ereturn local type      `type'
    if "`voting'"~=""        ereturn local finalest voting
    else                    ereturn local finalest `finalest'

    forvalues i = 1(1)`mcount' {
        local opt`i' = stritrim("`opt`i''")
        ereturn local opt`i' `opt`i'' 
        ereturn local method`i' `method`i''
        ereturn local pyopt`i' `pyopt`i''    
        ereturn local pipe`i' `pipe`i''    
        ereturn local xvars`i' `xvars`i''
        ereturn local xvars_o`i' `xvars_orig`i''
    }
    ereturn scalar mcount = `mcount'
    ereturn local globalopt `globalopt'
    
    // if foldvar name was provided and variable exists, save name in e(foldvar)
    // if foldvar name was provided but variable doesn't exist, create it and save name in e(foldvar)
    // if foldvar name was not provided, create it and copy/overwrite to variable _pystacked_foldvar
    if "`foldvar'"=="" {
        // create or overwrite _pystacked_foldvar
        cap drop _pystacked_foldvar
        qui gen int _pystacked_foldvar = `fid'
        local foldvar _pystacked_foldvar
    }
    else {
        qui cap confirm variable `foldvar'
        if _rc>0 {
            // foldvar name provided but doesn't exist
            qui gen int `foldvar' = `fid'
        }
    }
    ereturn local foldvar `foldvar'
    
    // set data signature for pystacked_p
    local allxvars_o
    forvalues i=1/`mcount' {
        local allxvars_o `allxvars_o' `xvars_orig`i''
    }
    // keep only unique items
    local allxvars_o : list uniq allxvars_o
    ereturn local allxvars_o `allxvars_o'
    // get data signature based on depvar, xvars and foldvar
    qui _datasignature `yvar' `allxvars_o' `foldvar'
    ereturn local datasignature `r(datasignature)'
    // set sort info for pystacked_p
    local sortvars : sortedby
    ereturn local sortvars `sortvars'

end

// parses Syntax 2
program define syntax_parse, rclass

    syntax [anything(everything)] , type(string) touse(varname) sklearn1(real) sklearn2(real) sklearn3(real) `printopt'

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
        if strpos("`pipeline'","stdscaler")==0 & strpos("lassoic lassocv ridgecv elasticcv","`method'")!=0 {
            * stdscaler is added by default for linear regularized estimators
            local pipeline `pipeline' stdscaler
        }
        local pipeline = subinstr("`pipeline'","nostdscaler","",.)
        if "`pipeline'"=="" local pipeline passthrough
        _pyparse , `options' type(`type') method(`method') sklearn1(`sklearn1') sklearn2(`sklearn2') `printopt'
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
    syntax ,                                ///
                [                           ///
                    HOLDOUT1                /// vanilla option, abbreviates to "holdout"
                    CValid                  ///
                    holdout(varname)        ///
                    GRAPH1                  /// vanilla option, abbreviates to "graph"
                    HISTogram               /// report histogram instead of default ROC
                    goptions(string asis)   ///
                    lgoptions(string asis)  ///
                    table(string)           ///
                ]

    // any graph options implies graph
    local graphflag = `"`graph1'`histogram'`goptions'`lgoptions'"'~=""
    
    // sample variable, holdout check, graph title
    if "`holdout'`holdout1'"=="" {
        if "`cvalid'"== "" {
            local title In-sample
        }
        else {
            local title In-sample (CV)
           }
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

    local nlearners    = e(mcount)
    local learners    `e(base_est)'
    local y            `e(depvar)'
    // weights
    tempname weights
    mat `weights'    = e(weights)

    if "`e(type)'"=="reg" {
        // regression problem

        // complete graph title
        local title `title' Predictions
            
        tempvar stacking_p stacking_r stacking_p_cv stacking_r_cv stacking_rsq stacking_rsq_cv
        predict double `stacking_p'
        label var `stacking_p' "Prediction: Stacking Regressor"
        qui gen double `stacking_r' = `y' - `stacking_p'
        qui gen double `stacking_rsq' = (`stacking_r')^2
        qui predict double `stacking_p', basexb
        qui predict double `stacking_p_cv', basexb cv
        forvalues i=1/`nlearners' {
            local lname : word `i' of `learners'
            label var `stacking_p'`i' "Prediction: `lname'"
            label var `stacking_p_cv'`i' "Prediction (CV): `lname'"
            tempvar stacking_r`i' stacking_rsq`i'  stacking_r_cv`i' stacking_rsq_cv`i'
            qui gen double `stacking_r`i'' = `y' - `stacking_p'`i'
            qui gen double `stacking_rsq`i'' = (`stacking_r`i'')^2
            qui gen double `stacking_r_cv`i'' = `y' - `stacking_p_cv'`i'
            qui gen double `stacking_rsq_cv`i''=(`stacking_r_cv`i'')^2
        }
        // assemble stacked CV prediction
        qui gen double `stacking_p_cv'=0
        forvalues i=1/`nlearners' {
            qui replace `stacking_p_cv' = `stacking_p_cv' + `stacking_p_cv'`i' * `weights'[`i',1]
        }
        label var `stacking_p_cv' "Prediction (CV): Stacking Regressor"
        qui gen double `stacking_r_cv' = `y' - `stacking_p_cv'
    
        // graph variables
        if "`cvalid'"=="" {
            local xvar stacking_p
        }
        else {
            local xvar stacking_p_cv
        }
        tempname g0
        if `graphflag' {
            twoway (scatter ``xvar'' `y') (line `y' `y') if `touse'         ///
                ,                                                           ///
                legend(off)                                                 ///
                title("STACKING")                                           ///
                `lgoptions'                                                 ///
                nodraw                                                      ///
                name(`g0', replace)
            local glist `g0'
            forvalues i=1/`nlearners' {
                tempname g`i'
                local lname : word `i' of `learners'
                local w : di %5.3f el(`weights',`i',1)
                twoway (scatter `stacking_p'`i' `y') (line `y' `y') if `touse'      ///
                    ,                                                               ///
                    legend(off)                                                     ///
                    title("Learner: `lname'")                                       ///
                    `lgoptions'                                                     ///
                    subtitle("weight = `w'")                                        ///
                    nodraw                                                          ///
                    name(`g`i'', replace)
                local glist `glist' `g`i''
            }
        
            graph combine `glist'                                           ///
                            ,                                               ///
                            title("`title'")                                ///
                            `goptions'
        }
    }
    else {
        // classification problem
        
        tempvar stacking_p stacking_c stacking_p_cv stacking_c_cv stacking_r stacking_r_cv stacking_rsq  stacking_rsq_cv
        qui predict double `stacking_p', pr
        label var `stacking_p' "Predicted Probability: Stacking Regressor"
        qui gen double `stacking_r' = `y' - `stacking_p'
        qui gen double `stacking_rsq' = (`stacking_r')^2
        qui predict double `stacking_c', class
        label var `stacking_c' "Predicted Classification: Stacking Regressor"
        qui predict double `stacking_p', pr basexb
        qui predict double `stacking_c', class basexb
        qui predict double `stacking_p_cv', pr basexb cv
        qui predict double `stacking_c_cv', class basexb cv
 
        forvalues i=1/`nlearners' {
            local lname : word `i' of `learners'
            label var `stacking_p'`i' "Predicted Probability: `lname'"
            label var `stacking_c'`i' "Predicted Classification: `lname'"
            label var `stacking_p_cv'`i' "Predicted Probability (CV): `lname'"
            label var `stacking_c_cv'`i' "Predicted Classification (CV): `lname'"
            tempvar stacking_r`i' stacking_r_cv`i'
            tempvar stacking_rsq`i' stacking_rsq_cv`i'
            qui gen double `stacking_r`i'' = `y' - `stacking_p'`i'
            qui gen double `stacking_r_cv`i'' = `y' - `stacking_p_cv'`i'
            qui gen double `stacking_rsq`i'' = (`stacking_r`i'')^2
            qui gen double `stacking_rsq_cv`i'' = (`stacking_r_cv`i'')^2
       }
        // assemble stacked CV prediction
        qui gen double `stacking_p_cv'=0
        forvalues i=1/`nlearners' {
            qui replace `stacking_p_cv' = `stacking_p_cv' + `stacking_p_cv'`i' * `weights'[`i',1]
        }
        label var `stacking_p_cv' "Predicted Probability (CV): Stacking Regressor"
        qui gen double `stacking_r_cv' = `y' - `stacking_p_cv'
        qui gen byte `stacking_c_cv' = `stacking_p_cv' >= 0.5
        qui replace `stacking_c_cv' = . if `stacking_p_cv'==.
        
        if `graphflag' & "`histogram'"=="" {                            /// default is ROC
            // complete graph title
            local title `title' ROC
        
            // graph variables
            if "`cvalid'"=="" {
                local xvar stacking_p
            }
            else {
                local xvar stacking_p_cv
            }
            tempname g0
            roctab `y' ``xvar'',                                    ///
                graph                                               ///
                title("STACKING")                                   ///
                `lgoptions'                                         ///
                nodraw                                              ///
                name(`g0', replace)
            local glist `g0'
            forvalues i=1/`nlearners' {
                tempname g`i'
                local lname : word `i' of `learners'
                roctab `y' `stacking_p'`i',                         ///
                    graph                                           ///
                    title("Learner: `lname'")                       ///
                    `lgoptions'                                     ///
                    nodraw                                          ///
                    name(`g`i'', replace)
                local glist `glist' `g`i''
            }
            graph combine `glist'                                   ///
                            ,                                       ///
                            title("`title'")                        ///
                            `goptions'
        }
        else if "`histogram'"~="" {                                 /// histogram
            // complete graph title
            local title `title' predicted probabilities

            // user may have specified something other than freq
            local 0 , `lgoptions'
            syntax , [ DENsity FRACtion FREQuency percent * ]
            if "`density'`fraction'`frequency'`percent'"== "" {
                // default is frequency
                local ystyle freq
            }
            
            // graph variables
            if "`cvalid'"=="" {
                local xvar stacking_p
            }
            else {
                local xvar stacking_p_cv
            }
            tempname g0
            qui histogram `stacking_p',                                 ///
                title("STACKING")                                       ///
                `ystyle'                                                ///
                start(0)                                                ///
                `lgoptions'                                             ///
                nodraw                                                  ///
                name(`g0', replace)
            local glist `g0'
            forvalues i=1/`nlearners' {
                tempname g`i'
                local lname : word `i' of `learners'
                qui histogram `stacking_p'`i',                          ///
                    title("Learner: `lname'")                           ///
                    `ystyle'                                            ///
                    start(0)                                            ///
                    `lgoptions'                                         ///
                    nodraw                                              ///
                    name(`g`i'', replace)
                local glist `glist' `g`i''
            }
            graph combine `glist'                                       ///
                            ,                                           ///
                            title("`title'")                            ///
                            `goptions'
        }
    }
    
    // assemble table
    if "`table'"=="rmspe" {
        
        // save in matrix
        tempname m m_in m_cv m_out
        
        // column for in-sample RMSPE
        qui sum `stacking_rsq' if e(sample)
        mat `m_in' = sqrt(r(mean))
        forvalues i=1/`nlearners' {
            qui sum `stacking_rsq`i'' if e(sample)
            mat `m_in' = `m_in' \ (sqrt(r(mean)))
        }
        
        // column for in-sample RMSPE
        // we don't report RMSPE for composite CV prediction
        mat `m_cv' = .
        forvalues i=1/`nlearners' {
            qui sum `stacking_rsq_cv`i'' if e(sample)
            mat `m_cv' = `m_cv' \ (sqrt(r(mean)))
        }
        
        // column for OOS MSPE
        if "`holdout'`holdout1'"~="" {
            // touse is the holdout indicator
            qui sum `stacking_rsq' if `touse'
            mat `m_out' = sqrt(r(mean))
            forvalues i=1/`nlearners' {
                qui sum `stacking_rsq`i'' if `touse'
                mat `m_out' = `m_out' \ (sqrt(r(mean)))
            }
        }
        else {
            mat `m_out' = J(`nlearners'+1,1,.)
        }
        
        mat `m' = `m_in' , `m_cv', `m_out'
        mat colnames `m' = RMSPE_in RMSPE_cv RMSPE_out
        mat rownames `m' = STACKING `learners'
        
        return matrix m = `m'

    }
    else if "`table'"=="confusion" {
            
        // save in matrix
        tempname m mrow
        
        // stacking rows
        forvalues r=0/1 {
            qui count if `y'==0 & `stacking_c'==`r' & e(sample)
            local in_0    = r(N)
            qui count if `y'==1 & `stacking_c'==`r' & e(sample)
            local in_1    = r(N)
            // don't report for composite CV prediction
            // qui count if `y'==0 & `stacking_c_cv'==`r' & e(sample)
            // local cv_0    = r(N)
            // qui count if `y'==1 & `stacking_c_cv'==`r' & e(sample)
            // local cv_1    = r(N)
            local cv_0 = .
            local cv_1 = .
            if "`holdout'`holdout1'"~="" {
                // touse is the holdout indicator
                qui count if `y'==0 & `stacking_c'==`r' & `touse'
                local out_0    = r(N)
                qui count if `y'==1 & `stacking_c'==`r' & `touse'
                local out_1    = r(N)
            }
            else {
                local out_0 = .
                local out_1 = .
            }
            mat `mrow' = `in_0', `in_1', `cv_0', `cv_1', `out_0', `out_1'
            mat `m' = nullmat(`m') \ `mrow'
        }
        
        // base learner rows
        forvalues i=1/`nlearners' {
        
            forvalues r=0/1 {
                qui count if `y'==0 & `stacking_c'`i'==`r' & e(sample)
                local in_0    = r(N)
                qui count if `y'==1 & `stacking_c'`i'==`r' & e(sample)
                local in_1    = r(N)
                qui count if `y'==0 & `stacking_c_cv'`i'==`r' & e(sample)
                local cv_0    = r(N)
                qui count if `y'==1 & `stacking_c_cv'`i'==`r' & e(sample)
                local cv_1    = r(N)
                if "`holdout'`holdout1'"~="" {
                    // touse is the holdout indicator
                    qui count if `y'==0 & `stacking_c'`i'==`r' & `touse'
                    local out_0    = r(N)
                    qui count if `y'==1 & `stacking_c'`i'==`r' & `touse'
                    local out_1    = r(N)
                }
                else {
                    local out_0 = .
                    local out_1 = .
                }
                mat `mrow' = `in_0', `in_1', `cv_0', `cv_1', `out_0', `out_1'
                mat `m' = `m' \ `mrow'
            }
        }
        
        local rnames STACKING_0 STACKING_1
        forvalues i=1/`nlearners' {
            local lname : word `i' of `learners'
            local rnames `rnames' `lname'_0 `lname'_1
        }
        mat rownames `m' = `rnames'
        mat colnames `m' = in_0 cv_1 in_0 cv_1 out_0 out_1
        
        return matrix m = `m'

    }
    
end

// Internal version of matchnames
// Sample syntax:
// matchnames "`varlist'" "`list1'" "`list2'"
// takes list in `varlist', looks up in `list1', returns entries in `list2', called r(names)
program define matchnames, rclass
    version 11.2
    args    varnames namelist1 namelist2

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
    local names    : list clean names
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
    if "`expand'"~="" {                                             //  force call to fvexpand
        if "`onebyone'"=="" {
            fvexpand `anything' `if'                                //  single call to fvexpand
            local anything `r(varlist)'
        }
        else {
            foreach vn of local anything {
                fvexpand `vn' `if'                                  //  call fvexpand on items one-by-one
                local newlist    `newlist' `r(varlist)'
            }
            local anything    : list clean newlist
        }
    }
    foreach vn of local anything {                                  //  loop through varnames
        if "`dropomit'"~="" {                                       //  check & include only if
            _ms_parse_parts `vn'                                    //  not omitted (b. or o.)
            if ~`r(omit)' {
                local unstripped    `unstripped' `vn'               //  add to list only if not omitted
            }
        }
        else {                                                      //  add varname to list even if
            local unstripped        `unstripped' `vn'               //  could be omitted (b. or o.)
        }
    }
// Now create list with b/n/o stripped out
    foreach vn of local unstripped {
        local svn ""                                                //  initialize
        _ms_parse_parts `vn'
        if "`r(type)'"=="variable" & "`r(op)'"=="" {                //  simplest case - no change
            local svn    `vn'
        }
        else if "`r(type)'"=="variable" & "`r(op)'"=="o" {          //  next simplest case - o.varname => varname
            local svn    `r(name)'
        }
        else if "`r(type)'"=="variable" {                           //  has other operators so strip o but leave .
            local op    `r(op)'
            local op    : subinstr local op "o" "", all
            local svn    `op'.`r(name)'
        }
        else if "`r(type)'"=="factor" {                             //  simple factor variable
            local op    `r(op)'
            local op    : subinstr local op "b" "", all
            local op    : subinstr local op "n" "", all
            local op    : subinstr local op "o" "", all
            local svn    `op'.`r(name)'                            //  operator + . + varname
        }
        else if"`r(type)'"=="interaction" {                        //  multiple variables
            forvalues i=1/`r(k_names)' {
                local op    `r(op`i')'
                local op    : subinstr local op "b" "", all
                local op    : subinstr local op "n" "", all
                local op    : subinstr local op "o" "", all
                local opv    `op'.`r(name`i')'                     //  operator + . + varname
                if `i'==1 {
                    local svn    `opv'
                }
                else {
                    local svn    `svn'#`opv'
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
    local stripped    : list retokenize stripped                   //  clean any extra spaces
    
    if "`noisily'"~="" {                                           //  for debugging etc.
di as result "`stripped'"
    }

    return local varlist    `stripped'                             //  return results in r(varlist)
end

cap program drop pystacked_check_python
program define pystacked_check_python
// code adapted from nwxtregress :)
    qui {
        cap python query
        if _rc == 0 {
            cap python which numpy
            local HasNumpy = _rc    

            cap python which scipy
            local HasScipy = _rc

            cap python which sfi
            local HasSfi = _rc

            cap python which sklearn
            local HasSkl = _rc

            if `=`HasNumpy'+`HasSfi'+`HasScipy'+`HasSkl'' > 0 {
                noi disp as smcl "{cmd:pystacked} option {it:python} requires the following Python packages:"
                if `HasNumpy' != 0 noi disp "  numpy"
                if `HasScipy' != 0 noi disp "  scipy"
                if `HasSfi' != 0 noi disp "  sfi"
                if `HasSkl' != 0 noi disp "  sklearn"
                noi disp "Please install them before using the option {it:pystacked}."
            }
        *   exit
        }
        else {
            noi disp as error "Error loading Python."
            error 199
        }
    }   

end
