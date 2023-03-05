 
which pystacked 
python: import sklearn
python: sklearn.__version__

global model lpsa lcavol lweight age lbph svi lcp gleason pgg45

*******************************************************************************
*** check options classification									 		***
*******************************************************************************

clear
insheet using https://web.stanford.edu/~hastie/ElemStatLearn/datasets/prostate.data,  tab clear

sum lpsa, meanonly
replace lpsa = lpsa > `r(mean)'

pystacked $model, method(rf) type(class) ///
			cmdopt1( ///
			n_estimators(400) ///
			criterion(entropy) ///
			min_samples_split(5) ///
			min_samples_leaf(0.1) ///
			min_weight_fraction_leaf(.1) ///
			max_depth(3) ///	
			min_impurity_decrease(.1) ///
			max_features(sqrt) ///
			bootstrap(True) ///
			n_jobs(3) ///
			max_samples(10) ///
			) showopt 

pystacked $model, method(gradboost) type(class) ///
			cmdopt1( ///
			loss(exponential) ///
			learning_rate(0.2) ///
			n_estimators(400) ///
			subsample(0.8) ///
			min_samples_split(5) ///
			min_samples_leaf(0.1) ///
			min_weight_fraction_leaf(.1) ///
			max_depth(3) ///	
			min_impurity_decrease(.1) ///
			max_features(sqrt) ///
			max_leaf_nodes(4) /// 
			validation_fraction(.15) ///
			) showopt  

pystacked $model, method(elasticcv) type(class) ///
			cmdopt1( ///
			c(9) ///
			nocons ///
			tol(0.001) ///
			max_iter(90) ///
			n_jobs(2) ///
			intercept_scaling(1.1) ///
			l1_ratios(0 0.1 1) ///
			) showopt  bfolds(4)  

pystacked $model, method(lassocv) type(class) ///
			cmdopt1( ///
			c(9) ///
			nocons ///
			tol(0.001) ///
			max_iter(90) ///
			n_jobs(2) ///
			intercept_scaling(1.1) ///
			) showopt bfolds(4) 

pystacked $model, method(ridgecv) type(class) ///
			cmdopt1( ///
			c(9) ///
			nocons ///
			tol(0.001) ///
			max_iter(90) ///
			n_jobs(2) ///
			intercept_scaling(1.1) ///
			) showopt bfolds(4) 	

pystacked $model, method(nnet) type(class) ///
			cmdopt1( ///
			hidden_layer_sizes(5 5) ///
			activation(logistic) ///
			alpha(0.0002) ///
			learning_rate(adaptive) ///
			learning_rate_init(0.01) ///
			max_iter(100) ///
			power_t(0.4) ///
			shuffle(False) ///
			momentum(0.8) ///
			validation_fraction(0.15) ///
			beta_1(0.91) ///
			beta_2(0.991) ///
			epsilon(1e-7) ///
			n_iter_no_change(9) ///
			max_fun(14000) ///
			) showopt 			

pystacked $model, method(svm) type(class) ///
			cmdopt1( ///
			c(0.1) ///
			kernel(poly) ///
			degree(2) ///
			gamma(auto) ///
			coef0(0.01) ///
			shrinking(False) ///
			tol(1e-2) ///
			cache_size(150) ///
			max_iter(10) ///
			) showopt 
			
			
			
*******************************************************************************
*** check options regression										 		***
*******************************************************************************

clear
insheet using https://web.stanford.edu/~hastie/ElemStatLearn/datasets/prostate.data,  tab clear

pystacked $model, method(linsvm) ///
			cmdopt1( ///
			epsilon(0.01) ///
			tol(1e-3) ///
			c(1.1) ///
			loss(squared_epsilon_insensitive) ///
			nocons ///
			intercept_scaling(1.1) ///
			dual(False) ///
			max_iter(900) ///
			) showopt 	

pystacked $model, method(svm) ///
			cmdopt1( ///
			kernel(poly) ///
			degree(2) ///
			gamma(auto) ///
			coef0(0.1) ///
			tol(1e-2) ///
			c(1.1) ///
			epsilon(0.14) ///
			shrinking(False) ///
			max_iter(10) ///
			) showopt 	

pystacked $model, method(nnet) ///
			cmdopt1( ///
			hidden_layer_sizes(5 5) ///
			activation(logistic) ///
			alpha(0.0002) ///
			learning_rate(adaptive) ///
			learning_rate_init(0.01) ///
			max_iter(100) ///
			shuffle(False) ///
			momentum(0.8) ///
			validation_fraction(0.15) ///
			beta_1(0.91) ///
			beta_2(0.991) ///
			epsilon(1e-7) ///
			n_iter_no_change(9) ///
			max_fun(14000) ///
			) showopt 			

pystacked $model, method(lassocv) ///
			cmdopt1( ///
			alphas(0.01 0.1 1 2) ///
			eps(0.1) ///
			n_alphas(20) ///
			nocons ///
			max_iter(500) ///
			tol(0.001) ///
			positive ///
			) showopt bfolds(3) 

pystacked $model, method(ridgecv) ///
			cmdopt1( ///
			alphas(0.01 0.1 1 2) ///
			eps(0.01) ///
			n_alphas(20) ///
			nocons ///
			max_iter(500) ///
			tol(0.001) ///
			positive ///
			) showopt  bfolds(3)  	
			
pystacked $model, method(gradboost) ///
			cmdopt1( ///
			learning_rate(0.2) ///
			n_estimators(400) ///
			subsample(0.8) ///
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
			) showopt  

pystacked $model, method(rf) ///
			cmdopt1( ///
			n_estimators(400) ///
			min_samples_split(5) ///
			min_samples_leaf(0.1) ///
			min_weight_fraction_leaf(.1) ///
			max_depth(3) ///	
			min_impurity_decrease(.1) ///
			max_features(sqrt) ///
			max_leaf_nodes(4) /// 
			warm_start ///
			) showopt 
 