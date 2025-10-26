*! pystacked v0.7.9
*! last edited: 26oct2025
*! authors: aa/ms
*! pystacked wrapper - calls pystacked1 (default) or pystacked2 (altpython option)

prog define pystacked
    tokenize `"`0'"', parse(",")
    local beforecomma `1'
	if "`beforecomma'"=="," | "`beforecomma'"=="" {
		// nothing before the comma or no comma, so this is a postestimation call to pystacked
		// get altpython from saved macro
		local altpython = ("`e(altpython)'"=="altpython")
	}
	else {
		// new call to pystacked
		local aftercomma `3'
		local altpython : list posof "altpython" in aftercomma
	}
	if `altpython' {
		pystacked2 `0'
	}
	else {
		pystacked1 `0'
	}
end