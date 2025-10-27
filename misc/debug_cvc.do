clear all

global qui qui

// low and high regularization macros for pystacked gradboost
global gradlow max_depth(20) n_estimators(800) learning_rate(0.1) validation_fraction(0.2) n_iter_no_change(10) tol(0.01)
global gradhigh max_depth(4) n_estimators(800) learning_rate(0.1) validation_fraction(0.2) n_iter_no_change(10) tol(0.01)

// Mata DGP program; dataset returned in Stata matrices along with R-sqs
mata:

void iv_dgp(							///
				real scalar n,			///
				real scalar p,			///
				real scalar rho_ev,		///
				real scalar rho_x,		///
				real scalar theta0,		///
				real scalar c			///
				)
{

	Sx = (1-rho_x)*I(p) + rho_x*J(p,p,1)
	Sev = (1 , rho_ev) \ (rho_ev , 1)

	beta0 = 0.1*(J(5,1,1) \ J(p-5,1,0))
	
	U_1 = rnormal(n,2,0,1)
	U_2 = matpowersym(Sev,0.5)
	U = U_1*U_2

	Z_1 = rnormal(n,p,0,1)
	Z_2 = matpowersym(Sx,0.5)
	Z = Z_1*Z_2

	glin = Z*beta0
	gnl_1 = (abs(c*glin) :< pi()/2)
	gnl_2 = cos(c*glin)
	gnl = gnl_1 :* gnl_2

	xlin = glin + U[.,2]
	xnl = gnl + U[.,2]

	ylin = theta0*xlin + U[.,1]
	ynl = theta0*xnl + U[.,1]

	elin = xlin - glin*svsolve(glin,xlin)
	enl = xnl - gnl*svsolve(gnl,xnl)

	r2_lin = 1-(elin'*elin)/((xlin:-mean(xlin))'*(xlin:-mean(xlin)))
	r2_nl = 1-(enl'*enl)/((xnl:-mean(xnl))'*(xnl:-mean(xnl)))
	
	st_numscalar("r(r2_lin)",r2_lin)
	st_numscalar("r(r2_nl)",r2_nl)
	
	st_matrix("r(ylin)",ylin)
	st_matrix("r(ynl)",ynl)
	st_matrix("r(xlin)",xlin)
	st_matrix("r(xnl)",xnl)
	st_matrix("r(glin)",glin)
	st_matrix("r(gnl)",gnl)
	st_matrix("r(Z)",Z)
	
}

end

mata: iv_dgp(1000,200,0.6,0.6,0,4.3)

// convert Stata matrices to Stata data; convenient for var naming
qui svmat double r(ylin), names(ylin_)
qui svmat double r(ynl), names(ynl_)
qui svmat double r(xlin), names(xlin_)
qui svmat double r(xnl), names(xnl_)
qui svmat double r(glin), names(glin_)
qui svmat double r(gnl), names(gnl_)
qui svmat double r(Z), names(Z_)

pystacked xlin_1 Z*, type(reg)											///
	method(gradboost gradboost ridgecv lassocv rf)						///
	cmdopt1($gradhigh) cmdopt2($gradlow)
predict double yhat_lin, basexb cv

cvc yhat_lin*, yvar(xlin_1) foldvar(_pystacked_foldvar) all

pystacked xnl_1 Z*, type(reg)											///
	method(gradboost gradboost ridgecv lassocv rf)						///
	cmdopt1($gradhigh) cmdopt2($gradlow)
predict double yhat_nl, basexb cv

cvc yhat_nl*, yvar(xnl_1) foldvar(_pystacked_foldvar) all
