cap cd "/Users/kahrens/MyProjects/pystacked/cert"
cap cd "/Users/ecomes/Documents/GitHub/pystacked/cert"

cap log close
log using "log_cs_pystacked_options.txt", text replace

clear all
 
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
which pystacked 
python: import sklearn
python: sklearn.__version__

clear
insheet using https://web.stanford.edu/~hastie/ElemStatLearn/datasets/prostate.data,  tab clear

global model lpsa lcavol lweight age lbph svi lcp gleason pgg45

*******************************************************************************
*** check options													 		***
*******************************************************************************

pystacked $model, method(lassocv) ///
			cmdopt1( ///
			alphas(0.01 0.1 1 2) ///
			eps(0.01) ///
			n_alphas(20) ///
			nocons ///
			max_iter(500) ///
			tol(0.001) ///
			cv(3) ///
			positive ///
			) showopt showpywarnings // why are no warnings shown
			
pystacked $model, method(lassocv) ///
			cmdopt1( ///
			alphas(0.01 0.1 1 2) ///
			eps(0.01) ///
			n_alphas(20) ///
			nocons ///
			non ///
			max_iter(500) ///
			tol(0.001) ///
			cv(3) ///
			positive ///
			) showopt showpywarnings


pystacked $model, method(gradboost) ///
			cmdopt1( ///
			loss(squared_error) ///
			learning_rate(0.2) ///
			n_estimators(400) ///
			subsample(0.8) ///
			criterion(squared_error) ///
			min_samples_split(5) ///
			min_samples_leaf(0.1) ///
			min_weight_fraction_leaf(.1) ///
			max_depth(3) ///	
			min_impurity_decrease(.1) ///
			max_features(sqrt) ///
			alpha(.8) ///
			max_leaf_nodes(4) /// 
			warm_start ///
			validation_fraction(.15) ///
			) showopt showpywarnings

cap log close
