clear all

cap cd "/Users/kahrens/MyProjects/pystacked/cert"
cap cd "/Users/ecomes/Documents/GitHub/pystacked/cert"

if "`c(username)'"=="kahrens" {
	adopath + "/Users/kahrens/MyProjects/pystacked"
}
else if "`c(username)'"=="ecomes" {
	adopath + "/Users/ecomes/Documents/GitHub/pystacked/cert"
}

local ver `1'

python set exec "/Users/kahrens/python_envs/sk`ver'/bin/python3"

cap log close
log using "log_cs_pystacked_`ver'.txt", text replace

which pystacked 
python: import sklearn
python: sklearn.__version__

do "cs_pystacked_class.do"
do "cs_pystacked_options.do"
do "cs_pystacked_reg.do"

di "############################"
di "all completed"

log close
