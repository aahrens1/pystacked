*! pystacked v0.7.8c
*! last edited: 8oct2025
*! authors: aa/ms
*! pystacked_p wrapper - calls pystacked1_p (default) or pystacked2_p (altpython option)

prog define pystacked_p

    qui findfile pystacked_p.py
    cap python script "`r(fn)'", global
    if _rc != 0 {
    noi disp "Error loading Python Script for pystacked. Installation corrupted."
                    error 199
    }
    // branch to pystacked2_p if altpython, otherwise to pystacked1_p
	local altpython = ("`e(altpython)'"~="")
	if `altpython' {
		pystacked2_p `0'
	}
	else {
		pystacked1_p `0'
	}
end