*! pystacked v0.4.9
*! last edited: 27dec2022
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
                        TABLE1                              ///
                        table(string)                       /// rmspe or confusion
                        HOLDOUT1                            /// vanilla option, abbreviates to "holdout"
                        holdout(varname)                    ///
                        CValid                              ///
                        *                                   ///
                    ]
        
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

    qui findfile pystacked.py
    cap python script "`r(fn)'", global
    if _rc != 0 {
    noi disp "Error loading Python Script for pystacked. Installation corrupted."
                    error 199
    }
    python: from pystacked import *

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
    }
    else {
        // classification problem
        
        tempvar stacking_p stacking_c stacking_p_cv stacking_c_cv stacking_r  stacking_r_cv
        qui predict double `stacking_p', pr
        label var `stacking_p' "Predicted Probability: Stacking Regressor"
        qui gen double `stacking_r' = `y' - `stacking_p'
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
            qui gen double `stacking_r`i'' = `y' - `stacking_p'`i'
            qui gen double `stacking_r_cv`i'' = `y' - `stacking_p_cv'`i'
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
    else if "`table'"=="confusion" {
            
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