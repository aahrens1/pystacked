clear all
insheet using https://web.stanford.edu/~hastie/ElemStatLearn/datasets/prostate.data,  tab clear
global xvars lcavol-pgg

set seed 124345

// holdout sample 1
cap drop h1
gen h1 = _n>60
// holdout sample 2
cap drop h2
gen h2 = _n>40

// postestimation syntax

/*
// pystacked0 (main version from June 2025)

// full sample
pystacked0 lpsa $xvars, ///
	type(regress) pyseed(243) ///
	methods(ols lassocv rf) ///
	pipe1(poly2) pipe2(poly2)
cap noi pystacked0, table

// with holdout sample
pystacked0 lpsa $xvars if _n<50, ///
	type(regress) pyseed(243) ///
	methods(ols lassocv rf) ///
	pipe1(poly2) pipe2(poly2)
// default holdout - all available obs
cap noi pystacked0, table holdout
*/

********************************************************************************
/*
// pystacked2 directly
pystacked2 lpsa $xvars, ///
	type(regress) pyseed(243) ///
	methods(ols lassocv rf) ///
	pipe1(poly2) pipe2(poly2)
cap noi pystacked2, table

datasignature clear

// with holdout sample
pystacked2 lpsa $xvars if _n<50, ///
	type(regress) pyseed(243) ///
	methods(ols lassocv rf) ///
	pipe1(poly2) pipe2(poly2)
// default holdout - all available obs
cap noi pystacked2, table holdout

// second time with holdout sample
pystacked2 lpsa $xvars if _n<50, ///
	type(regress) pyseed(243) ///
	methods(ols lassocv rf) ///
	pipe1(poly2) pipe2(poly2)
// default holdout - all available obs
cap noi pystacked2, table holdout
*/

********************************************************************************

/*
// pystacked1 directly

pystacked1 lpsa $xvars, ///
	type(regress) pyseed(243) ///
	methods(ols lassocv rf) ///
	pipe1(poly2) pipe2(poly2)
cap noi pystacked1, table

// with holdout sample
pystacked1 lpsa $xvars if _n<50, ///
	type(regress) pyseed(243) ///
	methods(ols lassocv rf) ///
	pipe1(poly2) pipe2(poly2)
// default holdout - all available obs
cap noi pystacked1, table holdout

// second time with holdout sample
pystacked1 lpsa $xvars if _n<50, ///
	type(regress) pyseed(243) ///
	methods(ols lassocv rf) ///
	pipe1(poly2) pipe2(poly2)
// default holdout - all available obs
cap noi pystacked1, table holdout

// third time with holdout sample and changed sort order
pystacked1 lpsa $xvars if _n<50, ///
	type(regress) pyseed(243) ///
	methods(ols lassocv rf) ///
	pipe1(poly2) pipe2(poly2)
// default holdout - all available obs
sort age
cap noi pystacked1, table holdout

// fourth time with holdout sample and changed variable
pystacked1 lpsa $xvars if _n<50, ///
	type(regress) pyseed(243) ///
	methods(ols lassocv rf) ///
	pipe1(poly2) pipe2(poly2)
// default holdout - all available obs
qui replace age = age*12
cap noi pystacked1, table holdout
*/

********************************************************************************

/*
// pystacked wrapper (pystacked1)

pystacked lpsa $xvars, ///
	type(regress) pyseed(243) ///
	methods(ols lassocv rf) ///
	pipe1(poly2) pipe2(poly2)
cap noi pystacked, table

// with holdout sample
pystacked lpsa $xvars if _n<50, ///
	type(regress) pyseed(243) ///
	methods(ols lassocv rf) ///
	pipe1(poly2) pipe2(poly2)
// default holdout - all available obs
cap noi pystacked, table holdout

// second time with holdout sample
pystacked lpsa $xvars if _n<50, ///
	type(regress) pyseed(243) ///
	methods(ols lassocv rf) ///
	pipe1(poly2) pipe2(poly2)
// default holdout - all available obs
cap noi pystacked, table holdout
*/


********************************************************************************

/*
// pystacked wrapper (pystacked2)

pystacked lpsa $xvars, ///
	type(regress) pyseed(243) ///
	methods(ols lassocv rf) ///
	pipe1(poly2) pipe2(poly2) altpython
cap noi pystacked, table

// with holdout sample
pystacked lpsa $xvars if _n<50, ///
	type(regress) pyseed(243) ///
	methods(ols lassocv rf) ///
	pipe1(poly2) pipe2(poly2) altpython
// default holdout - all available obs
cap noi pystacked, table holdout

// second time with holdout sample
pystacked lpsa $xvars if _n<50, ///
	type(regress) pyseed(243) ///
	methods(ols lassocv rf) ///
	pipe1(poly2) pipe2(poly2) altpython
// default holdout - all available obs
cap noi pystacked, table holdout
*/
