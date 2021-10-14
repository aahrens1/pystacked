{smcl}
{* *! version 8oct2020}{...}
{hline}
{cmd:help pystacked}{right: v0.1}
{hline}

{title:Title}

{p2colset 5 19 21 2}{...}
{p2col:{hi: pystacked} {hline 2}}Stata program for Stacking Regression{p_end}
{p2colreset}{...}

{title:Overview}

{pstd}
{opt pystacked} implements stacking regression ({helpb pystacked##Wolpert1992:Wolpert, 1992}) via 
{browse "https://scikit-learn.org/stable/index.html":scikit-learn}'s 
{browse "https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.StackingRegressor.html":sklearn.ensemble.StackingRegressor} and 
{browse "https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.StackingClassifier.html":sklearn.ensemble.StackingClassifier}. 
Stacking is a way of combining predictions from multiple supervised
machine learners (the "base learners") into
a final prediction to improve performance.
The currently-supported base learners are linear regression, 
logit, lasso, ridge, elastic net, (linear) support
vector machines, gradient 
boosting, and neural nets (MLP).

{pstd}
{opt pystacked} can also be used with a single
base learner and, thus, provides an easy-to-use 
API for scikit-learn's machine learning
algorithms. 

{pstd}
{opt pystacked} requires at least Stata 16 (or higher),  
a Python installation and scikit-learn (0.24 or higher).
See {helpb python:here} and {browse "https://blog.stata.com/2020/08/18/stata-python-integration-part-1-setting-up-stata-to-use-python/":here} 
for how to set up Python for Stata on your system.

{marker methodopts}{...}
{title:Contents}

	{helpb pystacked##syntax_overview:Syntax overview}
	{helpb pystacked##syntax1:Syntax 1}
	{helpb pystacked##syntax2:Syntax 2}
	{helpb pystacked##syntax2:Other options}
	{helpb pystacked##otheropts:Predictions}
	{helpb pystacked##section_stacking:Stacking}
	{helpb pystacked##base_learners:Supported base learners}
	{helpb pystacked##base_learners_opt:Base learners: Options}
	{helpb pystacked##pipelines:Pipelines}
	{helpb pystacked##example_prostate:Example Stacking Regression}
	{helpb pystacked##example_spam:Example Stacking Classification}
	{helpb pystacked##installation:Installation}
	{helpb pystacked##misc:Misc (references, contact, etc.)}

{marker syntax_overview}{...}
{title:Syntax overview}

{pstd}
There are two alternative syntaxes. The {ul:first syntax} is:

{p 8 14 2}
{cmd:pystacked}
{it:depvar} {it:regressors} 
[{cmd:if} {it:exp}] [{cmd:in} {it:range}]
{bind:[{cmd:,}}
{opt methods(string)}
{opt cmdopt1(string)} 
{opt cmdopt2(string)} 
{opt ...}
{opt pipe1(string)} 
{opt pipe2(string)} 
{opt ...}
{helpb pystacked##otheropts:{it:otheropts}}
]

{pstd}
The {ul:second syntax} is:

{p 8 14 2}
{cmd:pystacked}
{it:depvar} {it:regressors} 
[{cmd:if} {it:exp}] [{cmd:in} {it:range}]
|| {opt m:ethod(string)}
{opt opt(string)} 
{opt pipe:line(string)} 
|| {opt m:ethod(string)}
{opt opt(string)} 
{opt pipe:line(string)} 
||
{opt ...}
{bind:[{cmd:,}}
{helpb pystacked##otheropts:{it:otheropts}}
]

{pstd}
The first syntax uses {opt methods(string)} to select base learners, where
{it:string} is a list of base learners.
Options are passed on to base learners via {opt cmdopt1(string)}, 
{opt cmdopt2(string)} to {opt cmdopt10(string)}. 
That is, up to 
10 base learners can be specified and options are passed on in the order in which
they appear in {opt methods(string)} (see {helpb pystacked##base_learners_opt:Command options}).
Likewise, the {opt pipe*(string)} option can be used 
for pre-processing predictors within Python on the fly (see {helpb pystacked##pipelines:Pipelines}).

{pstd}
The second syntax imposes no limit on the number of base learners (aside from the increasing
computational complexity). Base learners are added before the comma 
using {opt method(string)} together with {opt opt(string)} and separated by
"||". 

{marker syntax1}{...}
{title:Syntax 1}

{synoptset 20}{...}
{synopthdr:Option}
{synoptline}
{synopt:{opt methods(string)}}
a list of base learners, defaults to "{it:ols lassoic gradboost}" for regression
and "{it:logit lassocv gradboost}" for classification;
see {helpb pystacked##base_learners:Base learners}.
{p_end}
{synopt:{opt cmdopt*(string)}}
options passed to the base learners, see {helpb pystacked##base_learners_opt:Command options}.
{p_end}
{synopt:{opt pipe*(string)}}
pipelines passed to the base learners, see {helpb pystacked##pipelines:Pipelines}.
{p_end}
{synoptline}
{pstd}
{it:Note:} {opt *} is replaced
with 1 to 10. The number refers to the order given 
in {opt methods(string)}.

{marker syntax2}{...}
{title:Syntax 2}

{synoptset 20}{...}
{synopthdr:Option}
{synoptline}
{synopt:{opt m:ethod(string)}}
a base learner, see {helpb pystacked##base_learners:Base learners}.
{p_end}
{synopt:{opt opt(string)}}
options, see {helpb pystacked##base_learners_opt:Command options}.
{p_end}
{synopt:{opt pipe:line(string)}}
pipelines applied to the predictors, see {helpb pystacked##pipelines:Pipelines}.
{p_end}
{synoptline}

{marker otheropts}{...}
{title:Other options}

{synoptset 20}{...}
{synopthdr:Option}
{synoptline}
{synopt:{opt type(string)}}
{it:reg(ress)} for regression problems 
or {it:class(ify)} for classification problems. 
{p_end}
{synopt:{opt final:est(string)}}
final estimator used to combine base learners. 
This can be
{it:nnls} (non-negative least squares, the default),
{it:ols} (ordinary least squares) or
{it:ridge} for (logistic) ridge, which is the
sklearn default. For more information, 
see {helpb pystacked##section_stacking:here}.
{p_end}
{synopt:{opt nosavep:red}} do not save predicted values
(do not use if {cmd:predict} is used after estimation)
{p_end}
{synopt:{opt nosavet:ransform}} do not save predicted values
of each base learner 
(do not use if {cmd:predict} with {opt transf:orm} is used after estimation)
{p_end}
{synopt:{opt njobs(int)}} 
number of jobs for parallel computing. The default is 1 (no parallelization), 
-1 uses all available CPUs, -2 uses all CPUs minus 1. 
{p_end}
{synopt:{opt backend(string)}} 
joblib backend used for parallelization; the default is 'loky' under Linux/MacOS
and 'threading' under Windows. 
See {browse "https://scikit-learn.org/stable/modules/generated/sklearn.utils.parallel_backend.html":here} for more information.
{p_end}
{synopt:{opt folds(int)}} 
number of folds used for cross-validation (not relevant for voting); 
default is 5
{p_end}
{synopt:{opt pyseed(int)}} 
set the Python seed. Note that, since {cmd:pystacked} uses
Python, using {helpb "set seed"} won't be sufficient
for replication. 
{p_end}
{synoptline}

{synoptset 20}{...}
{synopthdr:Voting}
{synoptline}
{synopt:{opt voting}} use voting regressor 
({browse "https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.VotingRegressor.html":ensemble.VotingRegressor})
or voting classifier
({browse "https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.VotingClassifier.html":ensemble.VotingClassifier}); 
see {helpb pystacked##section_stacking:here} for a brief 
explanation.
{p_end}
{synopt:{opt votet:ype(string)}} type of voting classifier:
{it:hard} (default) or {it:soft}
{p_end}
{synopt:{opt votew:eights(numlist)}} positive weights used
for voting regression/classification. 
The length of {it:numlist} should be the number of 
base learners - 1. The last weight is calculated to 
ensure that sum(weights)=1.
{p_end}
{synoptline}

{marker prediction}{...}
{title:Prediction}

{pstd}
To get predicted values:

{p 8 14 2}
{cmd:predict}
{it:type} {it:newname} 
[{cmd:if} {it:exp}] [{cmd:in} {it:range}]
{bind:[{cmd:,}}
{opt pr}
{opt xb}
]

{pstd}
To get fitted values for each base learner:

{p 8 14 2}
{cmd:predict}
{it:type} {it:stub} 
[{cmd:if} {it:exp}] [{cmd:in} {it:range}]
{bind:[{cmd:,}}
{opt transf:orm}
]

{synoptset 20}{...}
{synopthdr:Option}
{synoptline}
{synopt:{opt pr}}
predicted probability (classification only)
{p_end}
{synopt:{opt xb}}
the default; predicted value (regression) or predicted class (classification)
{p_end}
{synopt:{opt transf:orm}}
predicted values for each base learner
{p_end}
{synoptline}

{pstd}
{it:Note:} Predicted values (in and out-sample)
are calculated when {cmd:pystacked}
is run and stored in Python memory. {cmd:predict} pulls the
predicted values from Python memory and saves them in 
Stata memory. This means that no changes on the data
in Stata memory should be made {it:between} {cmd:pystacked} call
and {cmd:predict} call. If changes to the data set are made, 
{cmd:predict} will return an error. 

{marker section_stacking}{...}
{title:Stacking}

{pstd}
Stacking is a way of combining cross-validated 
predictions from multiple base learners into
a final prediction. A final estimator is used to combine the base predictions. 

{pstd}
The default final predictor for stacking
regession is non-negative
least squares (NNLS) without an intercept. 
The NNLS coefficients are standardized to sum to one.
Note that in this respect we deviate from 
the scikit-learn default and follow the 
recommendation in Hastie et al. ({helpb pystacked##Hastie2009:2009}, p. 290).
The scikit-learn defaults for the final estimator
are {browse "https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.RidgeCV.html#sklearn.linear_model.RidgeCV":ridge regression} 
for stacking regression and 
{browse: "https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LogisticRegression.html#sklearn.linear_model.LogisticRegression":logistic ridge}
for classification tasks. 
To use the scikit-learn default, 
use {opt final:est(ridge)}. 
{cmd:pystacked} also supports ordinary (unconstrained)
least squares as the final estimator ({opt final:est(ols)}).

{pstd}
An alternative to stacking is voting. Voting regression uses the weighted 
average of base learners to form predictions. By default, 
the unweighted average is used, but the user can specify weights using 
{opt votew:eights(numlist)}. Voting classifier uses a
majority rule by default (hard voting). An alternative is soft
voting where the (weighted) probabilities are used to 
form the final prediction.

{marker base_learners}{...}
{title:Supported base learners}

{pstd}
The following base learners are supported:

{synoptset 10 tabbed}{...}
{p2col 5 29 23 2:Base learners}{p_end}
{p2col 7 29 23 2:{it:ols}}Linear regression {it:(regression only)}{p_end}
{p2col 7 29 23 2:{it:logit}}Logistic regression {it:(classification only)}{p_end}
{p2col 7 29 23 2:{it:lassoic}}Lasso with penalty chosen by AIC/BIC {it:(regression only)}{p_end}
{p2col 7 29 23 2:{it:lassocv}}Lasso with cross-validated penalty{p_end}
{p2col 7 29 23 2:{it:ridgecv}}Ridge with cross-validated penalty{p_end}
{p2col 7 29 23 2:{it:elasticcv}}Elastic net with cross-validated penalty{p_end}
{p2col 7 29 23 2:{it:svm}}Support vector machines{p_end}
{p2col 7 29 23 2:{it:gradboost}}Gradient boosting{p_end}
{p2col 7 29 23 2:{it:rf}}Random forest{p_end}
{p2col 7 29 23 2:{it:linsvm}}Linear SVM{p_end}
{p2col 7 29 23 2:{it:nnet}}Neural net{p_end}

{pstd}
The base learners can be chosen using the  
{opt methods(lassoic gradboost nnet)}  
(Syntax 1) or {opt m:ethod(string)}
options (Syntax 2).

{pstd}
Please see links in the next section for more information on each method.

{marker base_learners_opt}{...}
{title:Base learners: Options}

{pstd}
This section lists the options of each base learners supported by {cmd:pystacked}.
Options can be passed to the base learners via {opt cmdopt*(string)} 
(Syntax 1) or {opt opt(string)} (Syntax 2).
The defaults are adopted from scikit-learn, with some 
modifications highlighted below.

{pstd}
For the sake of brevity, the base learners options are
not discussed here in detail.
Please see the scikit-learn documentations linked below.
We {it:strongly recommend} that you read the scikit-learn 
documentation carefully.

{pstd}
{ul:Linear regression} {break}
Methods {it:ols} {break}
{it:Type:} {it:reg} {break}
{it:Documentation:} {browse "https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LinearRegression.html":linear_model.LinearRegression}

{p 8 8 2}
{opt nocons:tant}
{opt non:ormalize}
{opt pos:itive}

{pstd}
{ul:Logistic regression} {break}
Methods: {it:logit} {break}
Type: {it:class} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LogisticRegression.html":linear_model.LogisticRegression}

{p 8 8 2}
{opt nocons:tant}

{pstd}
{ul:Penalized regression with information criteria} {break}
Methods {it:lassoic} {break}
Type: {it:reg} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LassoLarsIC.html":linear_model.LassoLarsIC}

{p 8 8 2}
{opt criterion(aic|bic)}
{opt nocons:tant}
{opt max_iter(int 500)}
{opt eps(real)}
{opt positive}

{pstd}
{ul:Penalized regression with cross-validation} 

{p 6 6 2}
Methods: {it:lassocv}, {it:ridgecv} and {it:elasticv} {break} 
Type: {it:regress} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.ElasticNetCV.html":linear_model.ElasticNetCV}  

{p 8 8 2}
{opt l1_ratio(real 0.5)}
{opt eps(real 1e-3)}
{opt n_alphas(integer 100)}
{opt alphas(numlist)}
{opt nocons:tant}
{opt non:ormalize}
{opt max_iter(integer 1000)}
{opt tol(real 1e-4)}
{opt cv(integer 5)}
{opt n_jobs(integer 1)}
{opt positive}
{opt random_state(integer)}
{opt selection(cyclic|random)}

{pstd}
Note: {it:lassocv} uses {opt l1_ratio(1)}, {it:ridgecv} uses {opt l1_ratio(0)},
{it:elasticcv} uses {opt l1_ratio(.5)};  
other options are the same.

{pstd}
{ul:Penalized logistic regression with cross-validation} {break}
Methods: {it:lassocv}, {it:ridgecv} and {it:elasticv} {break} 
Type: {it:class} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LogisticRegressionCV.html":linear_model.LogisticRegressionCV}

{p 8 8 2}
{opt l1_ratios(numlist)}
{opt c:s(integer 10)}
{opt nocons:tant}
{opt cv(integer 5)}
{opt penalty(l1|l2|elasticnet)}
{opt solver(string)}
{opt tol(real 1e-4)}
{opt max_iter(integer 100)}
{opt n_jobs(integer 1)}
{opt norefit}
{opt intercept_scaling(real 1)}
{opt random_state(integer)}

{pstd}
Note: {it:lassocv} uses {opt penalty(l1)}, {it:ridgecv} uses {opt penalty(l2)},
{it:elasticcv} uses {opt penalty(elasticnet) l1_ratios(0 .5 1)};
other options are the same.

{pstd}
{ul:Random forest classifier} {break}
Method: {it:rf} {break}
Type: {it:class} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.RandomForestClassifier.html":ensemble.RandomForestClassifier}

{p 8 8 2}
{opt n_estimators(int 100)}
{opt criterion(string)}
{opt max_depth(int)}  
{opt min_samples_split(integer 2)}
{opt min_samples_leaf(integer 1)}
{opt min_weight_fraction_leaf(real 0)}
{opt max_features(string)}
{opt max_leaf_nodes(int)}
{opt min_impurity_decrease(real 0)}
{opt noboots:trap}
{opt oob_score}
{opt n_jobs(int)}
{opt random_state(integer)}
{opt warm_start}
{opt ccp_alpha(real 0)}
{opt max_samples(integer)}

{pstd}
{ul:Random forest regressor} {break}
Method: {it:rf} {break}
Type: {it:reg} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.RandomForestRegressor.html":ensemble.RandomForestRegressor}

{p 8 8 2}
{opt n_estimators(int 100)}
{opt criterion(string)}
{opt max_depth(int)} 
{opt min_samples_split(integer)}
{opt min_samples_leaf(integer)}
{opt min_weight_fraction_leaf(real 0)}
{opt max_features(string)}
{opt max_leaf_nodes(integer)}
{opt min_impurity_decrease(real 0)}
{opt noboots:trap}
{opt oob_score}
{opt n_jobs(integer 1)}
{opt random_state(integer)}
{opt warm_start}
{opt ccp_alpha(real 0)}
{opt max_samples(integer)} 

{pstd}
{ul:Gradient boosted classification trees} {break}
Method: {it:gradboost} {break}
Type: {it:class} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.GradientBoostingClassifier.html":ensemble.GradientBoostingClassifier}

{p 8 8 2}
{opt loss(deviance|exponential)}
{opt learning_rate(real 0.1)}
{opt n_estimators(integer 100)}
{opt subsample(real 1)}
{opt criterion(string)}
{opt min_samples_split(integer 2)}
{opt min_samples_leaf(integer 1)}
{opt min_weight_fraction_leaf(real 0)}
{opt max_depth(integer 3)}
{opt min_impurity_decrease(real 0)}
{opt init(string)}
{opt random_state(integer)}
{opt max_features(auto|sqrt|log2)}
{opt max_leaf_nodes(integer)}
{opt warm_start}
{opt validation_fraction(real 0.1)}
{opt n_iter_no_change(integer)}
{opt tol(real 1e-4)}
{opt ccp_alpha(real 0)}

{pstd}
{ul:Gradient boosted regression trees} {break}
Method: {it:gradboost} {break}
Type: {it:reg} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.GradientBoostingRegressor.html":ensemble.GradientBoostingRegressor}

{p 8 8 2}
{opt loss(string)}
{opt learning_rate(real 0.1)}
{opt n_estimators(integer 100)}
{opt subsample(real 1)}
{opt criterion(string)}
{opt min_samples_split(integer 2)}
{opt min_samples_leaf(integer 1)}
{opt min_weight_fraction_leaf(real 0)}
{opt max_depth(integer 3)}  
{opt min_impurity_decrease(real 0)}
{opt init(string)}
{opt random_state(integer)}
{opt max_features(string)}
{opt alpha(real 0.9)}
{opt max_leaf_nodes(integer)}
{opt warm_start}
{opt validation_fraction(real 0.1)}
{opt n_iter_no_change(integer)}
{opt tol(real 1e-4)}
{opt ccp_alpha(real 0)}

{pstd}
{ul:Linear SVM (SVC)} {break}
Method: {it:linsvm} {break}
Type: {it:class} {break} 
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.svm.LinearSVC.html":svm.LinearSVC}

{p 8 8 2}
{opt penalty(string)}
{opt loss(string)}
{opt primal}
{opt tol(real 1e-4)}
{opt c(real 1)}
{opt nocons:tant}
{opt intercept_scaling(real 1)}
{opt random_state(integer -1)}
{opt max_iter(integer 1000)}

{pstd}
{ul:Linear SVM (SVR)} {break}
Method: {it:linsvm} {break}
Type: {it:reg} {break} 
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.svm.LinearSVR.html":svm.LinearSVR}

{p 8 8 2}
{opt epsilon(real 0)}
{opt tol(real 1e-4)} 
{opt c(real 1)} 
{opt loss(string)}
{opt nocons:tant}
{opt intercept_scaling(real 1)}
{opt primal}
{opt random_state(integer -1)}
{opt max_iter(integer 1000)}

{pstd}
{ul:SVM (SVR)} {break}
Method: {it:svm} {break}
Type: {it:class} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.svm.SVR.html":svm.SVR}

{p 8 8 2}
{opt ker:nel(linear|poly|rbf|sigmoid)}
{opt degree(integer 3)}
{opt gam:ma(scale|auto)}
{opt coef0(real 0)}
{opt tol(real 1e-3)}
{opt c(real 1)}
{opt epsilon(real 0.1)}
{opt noshr:inking}
{opt cache_size(real 200)}
{opt max_iter(integer -1)}

{pstd}
{ul:SVM (SVC)} {break}
Method: {it:svm} {break}
Type: {it:reg} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.svm.SVC.html":svm.SVC}

{p 8 8 2}
{opt c(real 1)}
{opt ker:nel(linear|poly|rbf|sigmoid)}
{opt degree(integer 3)}
{opt gam:ma(scale|auto)}
{opt coef0(real 0)}
{opt probability}
{opt tol(real 1e-3)}
{opt epsilon(real 0.1)}
{opt noshr:inking}
{opt cache_size(real 200)}
{opt max_iter(integer -1)}
{opt decision_function_shape(ovr|ovo)}
{opt break_ties}
{opt random_state(integer -1)}

{pstd}
{ul:Neural net classifier (Multi-layer Perceptron)} {break}
Method: {it:nnet} {break}
Type: {it:class} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.neural_network.MLPClassifier.html":sklearn.neural_network.MLPClassifier}

{p 8 8 2}
{opt hidden_layer_sizes(numlist >0 integer)}
{opt activation(identity|logistic|tanh|relu)}
{opt solver(lbfgs|sgd|adam)}
{opt alpha(real 0.0001)}
{opt batch_size(integer)}
{opt learning_rate(constant|invscaling|adaptive)}
{opt learning_rate_init(real -1)}
{opt power_t(real .5)}
{opt max_iter(integer 200)}
{opt nosh:uffle}
{opt random_state(integer)}
{opt tol(real 1e-4)}
{opt verbose}
{opt warm_start}
{opt momentum(real .9)}
{opt nonest:erovs_momentum}
{opt early_stopping}
{opt validation_fraction(real .1)}
{opt beta_1(real .9)}
{opt beta_2(real .999)}
{opt epsilon(real 1e-8)}
{opt n_iter_no_change(integer 10)}
{opt max_fun(integer 15000)}

{pstd}
{ul:Neural net regressor (Multi-layer Perceptron)} {break}
Method: {it:nnet} {break}
Type: {it:reg} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.neural_network.MLPRegressor.html":sklearn.neural_network.MLPRegressor}

{p 8 8 2}
{opt hidden_layer_sizes(numlist >0 integer)}
{opt activation(identity|logistic|tanh|relu)}
{opt solver(lbfgs|sgd|adam)}
{opt alpha(real 0.0001)}
{opt batch_size(integer)}
{opt learning_rate(constant|invscaling|adaptive)}
{opt learning_rate_init(real 0.001)}
{opt power_t(real .5)}
{opt max_iter(integer 200)}
{opt nosh:uffle}
{opt random_state(integer)}
{opt tol(real 1e-4)}
{opt verbose}
{opt warm_start}
{opt momentum(real .9)}
{opt NONESTerovs_momentum}
{opt early_stopping}
{opt validation_fraction(real .1)}
{opt beta_1(real .9)}
{opt beta_2(real .999)}
{opt epsilon(real 1e-8)}
{opt n_iter_no_change(integer 10)}
{opt max_fun(integer 15000)}

{marker pipelines}{...}
{title:Pipelines}

{pstd}
Scikit-learn uses pipelines to pre-preprocess input data on the fly. 
Pipelines can be used to impute missing observations or 
create transformation of predictors such as interactions and polynomials.
For example, when using linear machine learners such as the lasso, 
it is recommended to create interactions. This can be done on the fly in 
Python. 

{pstd}
The following pipelines are currently supported: 

{synoptset 10 tabbed}{...}
{p2col 5 29 23 2:Pipelines}{p_end}
{p2col 7 29 23 2:{it:stdscaler}}{browse "https://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.StandardScaler.html":StandardScaler()}{p_end}
{p2col 7 29 23 2:{it:minmaxscaler}}{browse "https://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.MinMaxScaler.html":MinMaxScaler()}{p_end}
{p2col 7 29 23 2:{it:medianimputer}}{browse "https://scikit-learn.org/stable/modules/generated/sklearn.impute.SimpleImputer.html":SimpleImputer(strategy='median')}{p_end}
{p2col 7 29 23 2:{it:knnimputer}}{browse "https://scikit-learn.org/stable/modules/generated/sklearn.impute.KNNImputer.html":KNNImputer()}{p_end}
{p2col 7 29 23 2:{it:poly2}}{browse "https://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.PolynomialFeatures.html":PolynomialFeatures(degree=2)}{p_end}
{p2col 7 29 23 2:{it:poly3}}{browse "https://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.PolynomialFeatures.html":PolynomialFeatures(degree=3)}{p_end}

{pstd}
Pipelines can be passed to the base learners via {opt pipe*(string)} 
(Syntax 1) or {opt pipe:line(string)} (Syntax 2).

{pstd}
NB: Users should take care when employing pipelines
that they don't accidentally introduce data leakage.
For example, a pipeline that transforms the data
prior to passing the data to a base learner that uses cross-validation
could do this if the data transformation (e.g., standardizing predictors)
uses information from the entire dataset.

{marker example_prostate}{...}
{title:Example using Boston Housing data (Harrison et al., {helpb pystacked##Harrison1978:1978})}

{marker examples_data}{...}
{pstd}
{ul:Data set}

{pstd}
The data set is available from the {browse "https://archive.ics.uci.edu/ml/machine-learning-databases/housing/":UCI Machine Learning Repository}. 
The following variables are included in the data set of 506
observations:

{synoptset 10 tabbed}{...}
{p2col 5 19 23 2: Predictors}{p_end}
{synopt:CRIM}per capita crime rate by town{p_end}
{synopt:ZN}proportion of residential land zoned for lots over 
25,000 sq.ft.{p_end}
{synopt:INDUS}proportion of non-retail business acres per town{p_end}
{synopt:CHAS}Charles River dummy variable (= 1 if tract bounds 
river; 0 otherwise){p_end}
{synopt:NOX}nitric oxides concentration (parts per 10 million){p_end}
{synopt:RM}average number of rooms per dwelling{p_end}
{synopt:AGE}proportion of owner-occupied units built prior to 1940{p_end}
{synopt:DIS}weighted distances to five Boston employment centres{p_end}
{synopt:RAD}index of accessibility to radial highways{p_end}
{synopt:TAX}full-value property-tax rate per $10,000{p_end}
{synopt:PTRATIO}pupil-teacher ratio by town{p_end}
{synopt:B}1000(Bk - 0.63)^2 where Bk is the proportion Black 
by town{p_end}
{synopt:LSTAT}% lower status of the population{p_end}

{synoptset 10 tabbed}{...}
{p2col 5 19 23 2: Outcome}{p_end}
{synopt:MEDV}Median value of owner-occupied homes in $1000's{p_end}

{pstd}
{ul:Getting started}

{pstd}Load housing data.{p_end}
{phang2}. {stata "insheet using https://statalasso.github.io/dta/housing.csv, clear"}

{pstd}
Define a global for the model:
{p_end}
{phang2}. {stata "global model medv crim-lstat"}{p_end}

{pstd}
Stacking regression with lasso, random forest and gradient boosting.
{p_end}
{phang2}. {stata "pystacked $model, type(regress) pyseed(123) methods(lassoic rf gradboost)"}{p_end}

{pstd}
The weights determine how much each base learner contributes
to the final stacking prediction. In this example, 
random forest receives a weight of zero.{p_end}

{pstd}
Getting the predicted values:{p_end}
{phang2}. {stata "predict double yhat, xb"}{p_end}

{pstd}
We can also save the predicted values of each base learner:{p_end}
{phang2}. {stata "predict double yhat, transform"}{p_end}

{pstd}
{ul:Using pipelines (Syntax 1)}

{pstd}
Pipelines allow pre-processing predictors on the fly. For example, 
linear estimators might perform better if interactions are 
provided as inputs. Here, we use interactions and 2nd-order polynomials
for ols and lasso, but not for the random forest. Note that the base inputs
in Stata are only provided in levels. 
{p_end}
{phang2}. {stata "pystacked $model, type(regress) pyseed(123) methods(ols lassoic rf) pipe1(poly2) pipe2(poly2)"}{p_end}
{phang2}. {stata "predict a, transf"}{p_end}

{pstd}
You can verify that you get the same ols and lasso predicted values when 
creating the polynomials in Stata:
{p_end}
{phang2}. {stata "pystacked medv c.(crim-lstat)# #c.(crim-lstat), type(regress) pyseed(123) methods(ols lassoic rf)"}{p_end}
{phang2}. {stata "predict b, transf"}{p_end}
{phang2}. {stata "list a1 b1 a2 b2"}{p_end}

{pstd}
Note that the stacking weights are different in the second estimation. 
This is because we also include 2nd-order polynomials as inputs for the random forest.
{p_end}

{pstd}
You can also use the same base learner more than once with different pipelines and/or
different options.
{p_end}
{phang2}. {stata "pystacked $model, type(regress) pyseed(123) methods(lassoic lassoic lassoic) pipe2(poly2) pipe3(poly3)"}{p_end}

{pstd}
{ul:Options of base learners (Syntax 1)}

{pstd}
We can pass options to the base learners using {cmdopt*(string)}. In this example, 
we change the maximum tree depth for the random forest. Since random forest is
the third base learner, we use {cmdopt3(max_depth(3))}.
{p_end}
{phang2}. {stata "pystacked $model, type(regress) pyseed(123) methods(ols lassoic rf) pipe1(poly2) pipe2(poly2) cmdopt3(max_depth(3))"}{p_end}

{pstd}
You can verify that the option has been passed to Python correctly:
{p_end}
{phang2}. {stata "di e(pyopt3)"}{p_end}

{pstd}
{ul:Using the alternative syntax (Syntax 2)}

{pstd}
The same results as above can be achieved using the alternative syntax, which 
imposes no limit on the number of base learners.
{p_end}
{phang2}. {stata "pystacked $model || m(ols) pipe(poly2) || m(lassoic) pipe(poly2) || m(rf) opt(max_depth(3)) , type(regress) pyseed(123)"}{p_end}

{pstd}
{ul:Single base learners}

{pstd}
You can use {cmd:pystacked} with a single base learner. 
In this example, we are using a conventional random forest:
{p_end}
{phang2}. {stata "pystacked $model, type(regress) pyseed(123) methods(rf)"}{p_end}

{pstd}
{ul:Voting}

{pstd}
You can also use pre-defined weights. Here, we assign weights of 0.5 to OLS, 
.1 to the lasso and, implicitly, .4 to the random foreset.
{p_end}
{phang2}. {stata "pystacked $model, type(regress) pyseed(123) methods(ols lassoic rf) pipe1(poly2) pipe2(poly2) voting voteweights(.5 .1)"}{p_end}

{marker example_spam}{...}
{title:Classification Example using Spam data}

{pstd}
{ul:Data set}

{pstd}
For demonstration we consider the Spambase Data Set 
from the {browse "https://archive.ics.uci.edu/ml/datasets/spambase":UCI Machine Learning Repository}. 
The data includes 4,601 observations and 57 variables.
The aim is to predict whether an email is spam 
(i.e., unsolicited commercial e-mail) or not.
Each observation corresponds to one email.

{synoptset 10 tabbed}{...}
{p2col 5 19 23 2: Predictors}{p_end}
{synopt:v1-v48}percentage of words in the e-mail that match a specific {it:word},
i.e. 100 * (number of times the word appears in the e-mail) divided by
total number of words in e-mail. 
To see which word each predictor corresponds to, see link below. {p_end}
{synopt:v49-v54}percentage of characters in the e-mail that match a specific {it:character},
i.e. 100 * (number of times the character appears in the e-mail) divided by
total number of characters in e-mail. 
To see which character each predictor corresponds to, see link below.{p_end}
{synopt:v55}average length of uninterrupted sequences of capital letters{p_end}
{synopt:v56}length of longest uninterrupted sequence of capital letters{p_end}
{synopt:v57}total number of capital letters in the e-mail{p_end}

{synoptset 10 tabbed}{...}
{p2col 5 19 23 2: Outcome}{p_end}
{synopt:v58}denotes whether the e-mail was considered spam (1)
 or not (0). {p_end}

{pstd}
For more information
about the data 
see {browse "https://archive.ics.uci.edu/ml/datasets/spambase"}.

{pstd}Load spam data.{p_end}
{phang2}. {stata "insheet using https://archive.ics.uci.edu/ml/machine-learning-databases/spambase/spambase.data, clear comma"}{p_end}

{pstd}We consider three base learners: logit, random forest and gradient boosting:{p_end}
{phang2}. {stata "pystacked v58 v1-v57, type(class) pyseed(123) methods(logit rf gradboost) njobs(4) pipe1(poly2)"}{p_end}

{pstd}{ul:Out-of-sample classification.} 

{pstd}As the data is ordered by outcome, we first shuffle the data randomly.{p_end}
{phang2}. {stata "set seed 42"}{p_end}
{phang2}. {stata "gen u = runiform()"}{p_end}
{phang2}. {stata "sort u"}{p_end}

{pstd}Estimation on the first 2000 observations.{p_end}
{phang2}. {stata "pystacked v58 v1-v57 if _n<=2000, type(class) pyseed(123) methods(logit rf gradboost) njobs(4) pipe1(poly2)"}{p_end}

{pstd}We can get both the predicted probabilities or the predicted class:{p_end}
{phang2}. {stata "predict spam, class"}{p_end}
{phang2}. {stata "predict spam_p, pr"}{p_end}

{pstd}Confusion matrix.{p_end}
{phang2}. {stata "tab spam v58 if _n<=2000, cell"}{p_end}
{phang2}. {stata "tab spam v58 if _n>2000, cell"}{p_end}

{marker installation}{title:Installation}

{pstd}
{opt pystacked} requires at least Stata 16 (or higher),  
a Python installation and scikit-learn (0.24 or higher).
See {helpb python:help python} and {browse "https://blog.stata.com/2020/08/18/stata-python-integration-part-1-setting-up-stata-to-use-python/":the Stata blog} 
for how to set up Python on your system.
Installing {browse "https://www.anaconda.com/":Anaconda} is 
in most cases the easiest way of installing Python including
all required packages.

{pstd}
You can check your scikit-learn version using:{p_end}
{phang2}. {stata "python: import sklearn"}{p_end}
{phang2}. {stata "python: sklearn.__version__"}{p_end}

{pstd}
{it:Updating scikit-learn:}
If you use Anaconda, update scikit-learn through your
Anaconda Python distribution. Make sure that you have 
linked Stata with the correct Python installation using 
{stata "python query"}.

{pstd}
If you use pip, you can update scikit-learn by
typing "<Python path> -m pip install -U scikit-learn"
into the {it:terminal}, or directly in Stata:{p_end}
{phang2}. {stata "shell <Python path> -m pip install -U scikit-learn"}{p_end}

{pstd}
Note that you might need to restart Stata for
changes to your Python installation to take effect.

{pstd}
For further information, see
{browse "https://scikit-learn.org/stable/install.html"}.

{pstd}
To install/update {cmd:pystacked}, type {p_end}
{phang2}. {stata "net install pystacked, from(https://raw.githubusercontent.com/aahrens1/pystacked/main) replace"}{p_end}

{marker misc}{title:References}
{marker Harrison1978}{...}

{pstd}
Harrison, D. and Rubinfeld, D.L (1978). Hedonic prices and the 
demand for clean air. {it:J. Environ. Economics & Management},
vol.5, 81-102, 1978.

{marker Hastie2009}{...}
{pstd}
Hastie, T., Tibshirani, R., & Friedman, J. (2009). 
The elements of statistical learning: data mining, inference,
and prediction. Springer Science & Business Media.

{marker Wolpert1992}{...}
{pstd}
Wolpert, David H. Stacked generalization. {it:Neural networks} 5.2 (1992): 241-259.
{browse "https://doi.org/10.1016/S0893-6080(05)80023-1"}

{title:Contact}

{pstd}
If you encounter an error, contact us via email. If you have a question, you 
can also post on Statalist (please tag @Achim Ahrens). 

{title:Acknowledgements}

{pstd}
{cmd:pystacked} took some inspiration from Michael Droste's 
{browse "https://github.com/mdroste/stata-pylearn":pylearn}, 
which implements other Sklearn programs for Stata.
Thanks to Jan Ditzen for testing an early version 
of the program. All remaining errors are our own. 

{title:Citation}

{pstd}
Please also cite scikit-learn; see {browse "https://scikit-learn.org/stable/about.html"}.

{title:Authors}

	Achim Ahrens, Public Policy Group, ETH Zurich, Switzerland
	achim.ahrens@gess.ethz.ch

	Christian B. Hansen, University of Chicago, USA

	Mark E. Schaffer, Heriot-Watt University, UK
