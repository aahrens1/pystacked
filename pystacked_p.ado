*! pystacked v0.6.0
*! last edited: 25feb2023
*! authors: aa/ms

program define pystacked_p, rclass
    version 16.0
    syntax namelist(min=1 max=2) [if] [in], [ ///
                                                            pr /// 
                                                            xb /// 
                                                            Resid /// 
                                                            class /// 
                                                            TRANSForm /// legacy option, equivalent to basexb
                                                            BASExb ///
                                                            force ///
                                                            CValid ///
                                                            ]

    qui findfile pystacked_p.py
    cap python script "`r(fn)'", global
    if _rc != 0 {
    noi disp "Error loading Python Script for pystacked. Installation corrupted."
                    error 199
    }
    python: from pystacked_p import *

    if ("`force'"=="") {
        qui datasignature report
        //return list
        if (`r(changed)'!=0) {
            di as err "error: data in memory has changed since last -pystacked- call"
            di as err "you are not allowed to change data in memory between -pystacked- fit and -predict-"
            exit 198
        }
    } 
    
    * legacy option
    if "`transform'"~="" {
        local basexb basexb
        local transform
        di as err "transform option is deprecated; use 'basexb'"
    }

    * only 1 option max
    local optcount : word count `resid' `pr' `xb' `class'
    if `optcount'>1 {
        di as err "only one of options 'pr xb resid class' allowed"
        exit 198
    }

    if "`resid'"!="" & "`basexb'`cvalid'"!="" {
        di as err "resid not allowed with: `basexb' `cvalid'"
        exit 198
    }
    
    if "`cvalid'"~="" & "`basexb'"=="" {
        di as err "error - option cvalid currently supported only with option basexb"
        exit 198
    }

    local command=e(cmd)
    if ("`command'"~="pystacked") {
        di as err "error: -pystacked_p- supports only the -pystacked- command"
        exit 198
    }
    *

    local depvar `e(depvar)'

    tokenize `namelist'
    if "`2'"=="" {                    //  only new varname provided
        local predictvar `1'
    }
    else {                            //  datatype also provided
        local vtype `1'
        local predictvar `2'
    }
    *

    marksample touse, novarlist

    if "`basexb'"=="" {
        qui gen `vtype' `predictvar' = .
    }
    
    * Get predictions
    python: post_prediction("`predictvar'","`basexb'","`cvalid'","`vtype'","`touse'","`pr'`xb'`class'")
    
    if "`resid'"!="" {
        replace `predictvar' = `depvar' - `predictvar' if `touse'
    }
    
end