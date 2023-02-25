clear all

cap cd "/Users/kahrens/MyProjects/pystacked/cert"
cap cd "/Users/ecomes/Documents/GitHub/pystacked/cert"

if "`c(username)'"=="kahrens" {
	adopath + "/Users/kahrens/MyProjects/pystacked"
}
else if "`c(username)'"=="ecomes" {
	adopath + "/Users/ecomes/Documents/GitHub/pystacked/cert"
}
else {
	net install pystacked, ///
		from(https://raw.githubusercontent.com/aahrens1/pystacked/main) replace
}

local ver `0'

python set exec "/Users/kahrens/python_envs/sk`ver'/bin/python3"

cap log close
log using "log_cs_pystacked_`ver'.txt", text replace

do "cs_pystacked_class.do"
do "cs_pystacked_options.do"
do "cs_pystacked_reg.do"

log close
