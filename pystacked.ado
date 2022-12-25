*! pystacked v0.4.8
*! last edited: 30nov2022
*! authors: aa/ms

// parent program
program define pystacked, eclass
    version 16.0

    // only print options
    tokenize `"`0'"', parse(",")
    local beforecomma `1'
    macro shift
    local restargs `*'
    if (strpos("`restargs'","print"))==0 {

        if ~replay() {
            // no replay - must estimate
            _pystacked `0'
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
            local ifinweight `if' `in' `weight' `exp'
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
                        TABle                               /// 
                        HOLDOUT1                            /// vanilla option, abbreviates to "holdout"
                        holdout(varname)                    ///
                        CValid                              ///
                        *                                   ///
                    ]
        
        // display results
        if `"`graph'`graph1'`lgraph'`histogram'`table'"' == "" {

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

        // graph/table block
        if `"`graph'`graph1'`lgraph'`histogram'`table'"' ~= "" {
            pystacked_graph_table,                          ///
                `holdout1' holdout(`holdout')               ///
                `cvalid'                                    ///
                `graph1'                                    ///
                `histogram'                                 ///
                goptions(`graph') lgoptions(`lgraph')       ///
                `table'
        }
        
        // print RMSPE table for regression problem
        if "`table'" ~= "" & "`e(type)'"=="reg" {
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
        
        // print confusion matrix for classification problem
        if "`table'" ~= "" & "`e(type)'"=="class" {
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
    }
    else {
        _pyparse `0'
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
    local ifinweight `if' `in' `weight' `exp'
    tokenize `beforeifinweight', parse("|")
    local mainargs `1'
    local 0 `mainargs' `ifinweight' `restargs'
    local doublebarsyntax = ("`2'"=="|")*("`3'"=="|")
    syntax varlist(min=2 fv) [if] [in] [aweight fweight], ///
                [ ///
                    type(string) /// classification or regression
                    FINALest(string) ///
                    njobs(int 0) ///
                    folds(int 5) ///
                    foldvar(varname) ///
                    bfolds(int 5) ///
                    NORANDOM ///
                    NOSHUFFLE ///
                    ///
                    ///
                    pyseed(integer -1) ///
                    PRINTopt ///
                    NOSAVEPred ///
                    NOSAVETransform /// legacy option
                    NOSAVEBasexb /// equivalent to old NOSAVETransform
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
                    SHOWPywarnings ///
                    backend(string) ///
                    ///
                    /// options for graphing; ignore here
                    GRAPH1                                  /// vanilla option, abbreviates to "graph"
                    HISTogram                               /// report histogram instead of default ROC
                    graph(string asis)                      /// for passing options to graph combine
                    lgraph(string asis)                     /// for passing options to the graphs of the learners
                    table                                   /// 
                    HOLDOUT1                                /// vanilla option, abbreviates to "holdout"
                    holdout(varname)                        ///
                    CValid                                  ///
                    SParse                                  ///
                    SHOWOPTions                             ///
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
        local finalest nnls1
    }
    * legacy option
    if "`nosavetransform'"~="" {
        local nosavebasexb nosavebasexb
        local nosavetransform
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
            local methods ols lassocv gradboost
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

    python clear

    // get sklearn version
    python: from sklearn import __version__ as sklearn_version
    python: sfi.Macro.setLocal("sklearn_ver1",format(sklearn_version).split(".")[0])
    python: sfi.Macro.setLocal("sklearn_ver2",format(sklearn_version).split(".")[1])
    cap python: sfi.Macro.setLocal("sklearn_ver3",format(sklearn_version).split(".")[2])
    if (`sklearn_ver2'<24 & `sklearn_ver1'<1) {
        di as err "pystacked requires sklearn 0.24.0 or higher. Please update sklearn."
        di as err "See instructions on https://scikit-learn.org/stable/install.html, and in the help file."
        exit 198
    }
    if ("`sklearn_ver3'"=="") local sklearn_ver3 = 0

    // mark sample 
    marksample touse
    markout `touse' `varlist'
    qui count if `touse'
    local N        = r(N)

    // generate fold var
    if "`foldvar'"=="" {
        *** gen folds
        tempvar uni cuni fid
        if "`norandom'"~="" {
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
        gen int `fid'=`foldvar'
    }

    tempvar id 
    gen int `id'=_n
    local shuffle=("`noshuffle'"=="")

    ******** parse options using _pyparse.ado ********************************* 

    if `doublebarsyntax' {
        // Syntax 2
        syntax_parse `beforeifinweight' , type(`type') touse(`touse') sklearn1(`sklearn_ver1') sklearn2(`sklearn_ver2') sklearn3(`sklearn_ver3')
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
                _pyparse , `cmdopt`i'' type(`type') method(`method') sklearn1(`sklearn_ver1') sklearn2(`sklearn_ver2') sklearn3(`sklearn_ver3')
                if `i'==1 {
                    local allpyopt [`r(optstr)'
                }
                else {
                    local allpyopt `allpyopt' , `r(optstr)'
                }
                local opt`i' `cmdopt`i'' 
                local method`i' `method'
                local pyopt`i' `r(optstr)'
                if strpos("`pipe`i''","stdscaler")==0 & strpos("lassoic lassocv ridgecv elasticcv","`method'")!=0 {
                    * stdscaler is added by default for linear regularized estimators
                    local pipe`i' `pipe`i'' stdscaler
                }
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

    python: run_stacked(    ///
                    "`type'",    ///
                    "`finalest'", ///
                    "`allmethods'", ///
                    "`yvar_t'", ///
                    "`xvars_all_t'",    ///
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
                    `bfolds', ///
                    `shuffle', ///
                    "`id'", ///
                    "`showpywarnings'", ///
                    "`backend'", ///
                    "`sparse'", ///
                    "`showoptions'" ///
                    )

    ereturn local cmd        pystacked
    ereturn local predict    pystacked_p
    ereturn local depvar    `yvar'
    ereturn local type        `type'

    forvalues i = 1(1)`mcount' {
        local opt`i' = stritrim("`opt`i''")
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

    syntax [anything(everything)] , type(string) touse(varname) sklearn1(real) sklearn2(real) sklearn3(real)

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
        _pyparse , `options' type(`type') method(`method') sklearn1(`sklearn1') sklearn2(`sklearn2')
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
                    table                   /// 
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
            
        tempvar stacking_p stacking_r stacking_p_cv stacking_r_cv
        predict double `stacking_p'
        label var `stacking_p' "Prediction: Stacking Regressor"
        qui gen double `stacking_r' = `y' - `stacking_p'
        qui predict double `stacking_p', basexb
        qui predict double `stacking_p_cv', basexb cv
        forvalues i=1/`nlearners' {
            local lname : word `i' of `learners'
            label var `stacking_p'`i' "Prediction: `lname'"
            label var `stacking_p_cv'`i' "Prediction (CV): `lname'"
            tempvar stacking_r`i' stacking_r_cv`i'
            qui gen double `stacking_r`i'' = `y' - `stacking_p'`i'
            qui gen double `stacking_r_cv`i'' = `y' - `stacking_p_cv'`i'
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
        
        if "`table'"~="" {
            
            // save in matrix
            tempname m m_in m_cv m_out
            
            // column for in-sample RMSPE
            qui sum `stacking_r' if e(sample)
            mat `m_in' = r(sd) * sqrt( (r(N)-1)/r(N) )
            forvalues i=1/`nlearners' {
                qui sum `stacking_r`i'' if e(sample)
                mat `m_in' = `m_in' \ (r(sd) * sqrt( (r(N)-1)/r(N) ))
            }
            
            // column for in-sample RMSPE
            qui sum `stacking_r_cv' if e(sample)
            mat `m_cv' = r(sd) * sqrt( (r(N)-1)/r(N) )
            forvalues i=1/`nlearners' {
                qui sum `stacking_r_cv`i'' if e(sample)
                mat `m_cv' = `m_cv' \ (r(sd) * sqrt( (r(N)-1)/r(N) ))
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
            
            mat `m' = `m_in' , `m_cv', `m_out'
            mat colnames `m' = RMSPE_in RMSPE_cv RMSPE_out
            mat rownames `m' = STACKING `learners'
            
            return matrix m = `m'
    
        }
    }
    else {
        // classification problem
        
        tempvar stacking_p stacking_c stacking_p_cv stacking_c_cv
        qui predict double `stacking_p', pr
        label var `stacking_p' "Predicted Probability: Stacking Regressor"
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
        }
        // assemble stacked CV prediction
        qui gen double `stacking_p_cv'=0
        forvalues i=1/`nlearners' {
            qui replace `stacking_p_cv' = `stacking_p_cv' + `stacking_p_cv'`i' * `weights'[`i',1]
        }
        label var `stacking_p_cv' "Predicted Probability (CV): Stacking Regressor"
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

        if "`table'"~="" {
            
            // save in matrix
            tempname m mrow
            
            // stacking rows
            forvalues r=0/1 {
                qui count if `y'==0 & `stacking_c'==`r' & e(sample)
                local in_0    = r(N)
                qui count if `y'==1 & `stacking_c'==`r' & e(sample)
                local in_1    = r(N)
                qui count if `y'==0 & `stacking_c_cv'==`r' & e(sample)
                local cv_0    = r(N)
                qui count if `y'==1 & `stacking_c_cv'==`r' & e(sample)
                local cv_1    = r(N)
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


*===============================================================================
* Python helper function
*===============================================================================

version 16.0
python:

# Import required Python modules
import sfi
import numpy as np
import __main__
import warnings
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
from sklearn.base import TransformerMixin,BaseEstimator
from sklearn.svm import LinearSVR,LinearSVC,SVC,SVR
from sklearn.utils import check_X_y,check_array
from sklearn.utils.validation import check_is_fitted
from scipy.sparse import coo_matrix,csr_matrix,issparse
from scipy.optimize import minimize 
from scipy.optimize import nnls 
from sklearn import __version__ as sklearn_version
from scipy import __version__ as scipy_version
from numpy import __version__ as numpy_version
from sys import version as sys_version
from sklearn.utils import parallel_backend
from sklearn.model_selection import PredefinedSplit,KFold,StratifiedKFold

### Define required Python functions/classes

class SingleBest(BaseEstimator):
    _estimator_type="regressor"
    def fit(self, X, y):
        X, y = check_X_y(X, y, accept_sparse=True)
        self.is_fitted_ = True
        ncols = X.shape[1]
        lowest_mse = np.Inf
        for i in range(ncols):
            this_mse=np.mean((y-X[:, i]) ** 2)
            if this_mse < lowest_mse:
                lowest_mse = this_mse
                best = i
        self.best = best
        coef = np.zeros(ncols)
        coef[best] = 1
        self.coef_ = coef
        self.cvalid=X
        return self
    def predict(self, X):
        X = check_array(X, accept_sparse=True)
        check_is_fitted(self, 'is_fitted_')
        return X[:,self.best]

class ConstrLS(BaseEstimator):
    _estimator_type="regressor"
    def fit(self, X, y):

        X,y = check_X_y(X,y, accept_sparse=True)
        xdim = X.shape[1]

        #Use nnls to get initial guess
        coef0, rnorm = nnls(X,y)

        #Define minimisation function
        def fn(coef, X, y):
            return np.linalg.norm(X.dot(coef) - y)
        
        #Constraints and bounds
        cons = {'type': 'eq', 'fun': lambda coef: np.sum(coef)-1}
        bounds = [[0.0,1.0] for i in range(xdim)] 

        #Do minimisation
        fit = minimize(fn,coef0,args=(X, y),method='SLSQP',bounds=bounds,constraints=cons)
        self.coef_ = fit.x
        self.is_fitted_ = True
        self.cvalid=X
        return self
        
    def predict(self, X):
        X = check_array(X, accept_sparse=True)
        check_is_fitted(self, 'is_fitted_')
        return np.matmul(X,self.coef_)

class ConstrLSClassifier(ConstrLS):
    _estimator_type="classifier"
    def predict_proba(self, X):
        return self.predict(X)

class LinearRegressionClassifier(LinearRegression):
    _estimator_type="classifier"
    def predict_proba(self, X):
        return self.predict(X)

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
    nosavepred,nosavebasexb, # store predictions
    voting,votetype,voteweights, # voting
    njobs, # number of cores
    foldvar, # foldvar
    bfolds, #
    shuff, #
    idvar, # id var
    showpywarnings, # show warnings?
    parbackend, # backend
    sparse, # sparse predictor 
    showopt #
    ):
    
    if int(format(sklearn_version).split(".")[1])<24 and int(format(sklearn_version).split(".")[0])<1:
        sfi.SFIToolkit.stata('di as err "pystacked requires sklearn 0.24.0 or higher. Please update sklearn."')
        sfi.SFIToolkit.stata('di as err "See instructions on https://scikit-learn.org/stable/install.html, and in the help file."')
        sfi.SFIToolkit.error(198)

    # Set random seed
    if seed>0:
        rng=np.random.RandomState(seed)
    else: 
        rng=None
    
    if showpywarnings=="":
        warnings.filterwarnings('ignore')
    
    if njobs==0: 
        nj = None 
    else: 
        nj = njobs
        
    ##############################################################
    ### load data                                                 ###
    ##############################################################    

    y = np.array(sfi.Data.get(yvar,selectvar=touse))
    x = np.array(sfi.Data.get(xvars,selectvar=touse))
    id = np.array(sfi.Data.get(idvar,selectvar=touse))
    #id = np.reshape(id,(-1,1))
    id.astype(int)
    fid = np.array(sfi.Data.get(foldvar,selectvar=touse))
    # If missings are present, need to specify they are NaNs.
    x_0 = np.array(sfi.Data.get(xvars,missingval=np.nan))
    if x.ndim == 1:
        x=np.reshape(x,(-1,1))
    if x_0.ndim == 1:
        x_0 = np.reshape(x_0,(-1,1))
    if sparse!="":
        x = coo_matrix(x).tocsc()

    shuff = shuff==1
    if shuff: 
        cvrng=rng
    else: 
        cvrng=None

    ##############################################################
    ### prepare fit                                            ###
    ##############################################################

    # convert strings to python objects
    methods = methods.split()
    if "xgb" in methods:
        import xgboost as xgb
    allopt = eval(allopt)
    allpipe = eval(allpipe)
    allxvar_sel = eval(allxvar_sel)

    # print options:
    if showopt!="":
        sfi.SFIToolkit.displayln("")
        for m in range(len(methods)):
            opt = allopt[m]
            sfi.SFIToolkit.displayln("Base learner: "+methods[m])
            for i in opt:
                subopt_name = opt[i]
                sfi.SFIToolkit.stata('di as text "'+str(i)+' = " _c')
                sfi.SFIToolkit.stata('di as text "'+str(opt[i])+'; " _c')
            sfi.SFIToolkit.displayln("")
            sfi.SFIToolkit.displayln("")

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
                newmethod.append(('lassocv',ElasticNetCV(**opt,cv=KFold(n_splits=bfolds,shuffle=shuff,random_state=cvrng))))
            if methods[m]=="ridgecv":
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('lassocv',ElasticNetCV(**opt,cv=KFold(n_splits=bfolds,shuffle=shuff,random_state=cvrng))))
            if methods[m]=="elasticcv":
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('lassocv',ElasticNetCV(**opt,cv=KFold(n_splits=bfolds,shuffle=shuff,random_state=cvrng))))
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
            if methods[m]=="xgb":    
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('mlp',xgb.XGBRegressor(**opt)))
        elif type=="class":
            if methods[m]=="logit":
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('logit',LogisticRegression(**opt)))
            if methods[m]=="lassoic":
                sfi.SFIToolkit.stata("di as err lassoic not supported with type(class)")
                sfi.SFIToolkit.error()
            if methods[m]=="lassocv":
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('lassocv',LogisticRegressionCV(**opt,cv=StratifiedKFold(n_splits=bfolds,shuffle=shuff,random_state=cvrng))))
            if methods[m]=="ridgecv":
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('lassocv',LogisticRegressionCV(**opt,cv=StratifiedKFold(n_splits=bfolds,shuffle=shuff,random_state=cvrng))))
            if methods[m]=="elasticcv":
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('lassocv',LogisticRegressionCV(**opt,cv=StratifiedKFold(n_splits=bfolds,shuffle=shuff,random_state=cvrng))))
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
            if methods[m]=="xgb":    
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('mlp',xgb.XGBClassifier(**opt)))
        else: 
            sfi.SFIToolkit.stata('di as err "method not known"') 
            #"
            sfi.SFIToolkit.error()
        est_list.append((methods[m]+str(m),Pipeline(newmethod)))

    if finalest == "nnls0" and type == "class": 
        fin_est = LinearRegressionClassifier(fit_intercept=False,positive=True)
    elif finalest == "nnls_sk" and type == "class": 
        fin_est = LinearRegressionClassifier(fit_intercept=False,positive=True)
    elif finalest == "nnls1" and type == "class": 
        fin_est = ConstrLSClassifier()
    elif finalest == "ridge" and type == "class": 
        fin_est = LogisticRegression()
    elif finalest == "nnls0" and type == "reg": 
        fin_est = LinearRegression(fit_intercept=False,positive=True)
    elif finalest == "nnls_sk" and type == "reg": 
        fin_est = LinearRegression(fit_intercept=False,positive=True)
    elif finalest == "nnls1" and type == "reg": 
        fin_est = ConstrLS()
    elif finalest == "ridge" and type == "reg": 
        fin_est = RidgeCV()
    elif finalest == "singlebest" and type == "reg": 
        fin_est = SingleBest()
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
                       cv=PredefinedSplit(fid)
                )
    elif voting=="" and type=="class":
        model = StackingClassifier(
                       estimators=est_list,
                       final_estimator=fin_est,
                       n_jobs=nj,
                       cv=PredefinedSplit(fid)
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
    ### fitting; save predictions in __main__                  ###
    ##############################################################

    # Train model on training data
    if type=="class":
        y=y!=0
    with parallel_backend(parbackend):
        model = model.fit(x,y)

    # store weights in e()
    if voting=="":
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
    __main__.id = id

    if nosavepred=="" or nosavebasexb=="":
        # Track NaNs
        x0_hasnan = np.isnan(x_0).any(axis=1)
        # Set any NaNs to zeros so that model.predict(.) won't crash
        x_0 = np.nan_to_num(x_0)

    if nosavepred == "" or nosavebasexb == "":
        __main__.model_object = model
        __main__.model_xvars = xvars
        __main__.model_methods = methods

    if nosavepred == "":
        if type=="class" and finalest[0:4]=="nnls":
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

    if nosavebasexb == "":
        transf = model.transform(x_0)
        # Set any predictions that should be missing to missing (NaN)
        transf[x0_hasnan] = np.nan
        __main__.transform = transf
        if voting=="" and (finalest == "nnls1" or finalest == "singlebest"):
            __main__.cvalid = model.final_estimator_.cvalid
        else:
            # values for cvalid unavailable so return array of correct with with all NaNs
            cv0 = np.shape(x)[0]
            cv1 = np.shape(transf)[1]
            __main__.cvalid = np.empty((cv0,cv1))*np.nan

    # save versions of Python and packages
    sfi.Macro.setGlobal("e(sklearn_ver)",format(sklearn_version))
    sfi.Macro.setGlobal("e(numpy_ver)",format(numpy_version))
    sfi.Macro.setGlobal("e(scipy_ver)",format(scipy_version))
    sfi.Macro.setGlobal("e(python_ver)",format(sys_version))

end