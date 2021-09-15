{smcl}
{* *! version 18sep2020}{...}
{hline}
{cmd:help pystacked}{right: v0.1}
{hline}

{title:Title}

{p2colset 5 19 21 2}{...}
{p2col:{hi: pystacked} {hline 2}}Stata program for Stacking Regression{p_end}
{p2colreset}{...}

{pstd}
{opt pystacked} implements stacking regression ({helpb pystacked##Wolpert1992:Wolpert, 1992}) via 
{browse "https://scikit-learn.org/stable/index.html":scikit-learn}'s 
{browse "https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.StackingRegressor.html":sklearn.ensemble.StackingRegressor} and 
{browse "https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.StackingClassifier.html":sklearn.ensemble.StackingClassifier}. 
{opt pystacked} requires at least Stata 16 (or higher),  
a Python installation and scikit-learn (0.24 or higher).
See {helpb python:here} for how to set up Python on your system.

{pstd}
There are two alternative syntax options. The first syntax is:

{p 8 14 2}
{cmd:pystacked}
{it:depvar} {it:regressors} 
[{cmd:if} {it:exp}] [{cmd:in} {it:range}]
{bind:[{cmd:,}}
{opt type(string)}
{opt methods(string)}
{opt cmdopt1(string)} 
{opt cmdopt2(string)} 
{opt ...}
{opt cmdopt10(string)}
{opt final:est(string)}
{opt nosavep:red}
{opt nosavet:ansform}
{opt njobs(int)}
{opt folds(int)}
{opt pyseed(int)}
{opt voting}
{opt votet:ype(string)}
{opt votew:eights(numlist)}
]

{pstd}
The second syntax is:

{p 8 14 2}
{cmd:pystacked}
{it:depvar} {it:regressors} 
[{cmd:if} {it:exp}] [{cmd:in} {it:range}]
|| {opt method(string)}
{opt opt(string)} 
|| {opt method(string)}
{opt opt(string)} 
||
{opt ...}
{bind:[{cmd:,}}
{opt type(string)}
{opt final:est(string)}
{opt nosavep:red}
{opt nosavet:ansform}
{opt njobs(int)}
{opt folds(int)}
{opt pyseed(int)}
{opt voting}
{opt votet:ype(string)}
{opt votew:eights(numlist)}
]

{pstd}
The first syntax uses {opt methods(string)} to select base learners, where
{it:string} is a list of base learners.
Options are passed on to base learners via {opt cmdopt1(string)} to {opt cmdopt10(string)}. That is, up to 
10 base learners can be specified and options are passed on in the order in which
they appear in {opt methods(string)}.

{pstd}
The second syntax imposes no limit on the number of base learners (aside from the increasing
computational complexity). Base learners are added before the comma 
using {opt method(string)} together with {opt opt(string)} and separated by
"||". 

{marker syntax}{...}
{title:Options}

{synoptset 20}{...}
{synopthdr:Option}
{synoptline}
{synopt:{opt type(string)}}
{it:reg(ress)} for regression problems 
or {it:class(ify)} for classification problems. 
{p_end}
{synopt:{opt methods(string)}}
Syntax 1: list of ML algorithms in any order separated by spaces;
allowed are {it:lassoic} (lasso with penalization selected by 
information criteria), 
{it:lassocv} (linear lasso or logistic lasso with CV),
{it:elasticcv} (elastic net with CV),  
{it:rf} (random forest), {it:gradboost} (gradient boosting),
{it:linsvm} (linear support vector machine)
and {it:svm} (support vector machines). {it:lassoic} is
only available for regression.
{it:_all} is a short-hand for all available base learners.
{p_end}
{synopt:{opt method(string)}}
Syntax 2: single base learner
{p_end}
{synopt:{opt final:est(string)}}
final estimator used to combine base learners. 
This can be
{it:nnls} (non-negative least squares; the default) or
(logistic)
{it:ridge} (the sklearn default).
{p_end}
{synopt:{opt nosavep:red}} do not save predicted values
(do not use if {cmd:predict} is used after estimation)
{p_end}
{synopt:{opt nosavet:ransform}} do not save predicted values
of each base learner 
(do not use if {cmd:predict} with {opt transf:orm} is used after estimation)
{p_end}
{synopt:{opt njobs(int)}} 
number of jobs for parallel computing; default is 1 (no parallel)
{p_end}
{synopt:{opt folds(int)}} 
number of folds used for cross-validation (not relevant for voting); 
default is 5
{p_end}
{synopt:{opt pyseed(int)}} 
set the Python seed. Note that, since {cmd:pystacked} uses
Python, it's not enough to set the Stata seed. 
{p_end}
{synopt:{opt cmdopt*(string)}}
Syntax 1: options passed on the base learners. {*} is replaced
with 1 to 10.
{p_end}
{synopt:{opt opt(string)}}
Syntax 2: options passed on the base learners. 
{p_end}

{synoptset 20}{...}
{synopthdr:Voting}
{synoptline}
{synopt:{opt voting}} use voting regressor 
({browse "https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.VotingRegressor.html":ensemble.VotingRegressor})
or voting classifier
({browse "https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.VotingClassifier.html":ensemble.VotingClassifier}).
{p_end}
{synopt:{opt votet:ype(string)}} type of voting classifier:
{it:hard} (default) or {it:soft}
{p_end}
{synopt:{opt votew:eights(numlist)}} weights used
for voting regression/classification. Each weight corresponds
to one base learner; thus, length of {it:numlist}
should be equal to number of base learners in {opt methods(string)}.
{p_end}


{marker syntax}{...}
{title:Prediction}

{p 8 14 2}
{cmd:predict}
{it:type} {it:newname} 
[{cmd:if} {it:exp}] [{cmd:in} {it:range}]
{bind:[{cmd:,}}
{opt pr}
{opt xb}
]

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

{pstd}
{it:Note:} Predicted values (in and out-sample)
are calculated when {cmd:pystacked}
is run and stored in Python memory. {cmd:predict} pulls the
predicted values from Python memory and saves them in 
Stata memory. This means that no changed on the data
in Stata memory should be made {it:between} {cmd:pystacked} fit
and {cmd:predict} call. If changes to the data set are made, 
{cmd:predict} will return an error. 

{marker section_stacking}{...}
{title:Stacking}

{pstd}
Stacking is a way of combining predictions from multiple base learners into
a final prediction. A final estimator is used to combine the base predictions; 
see {helpb pystacked##final_estimator:here}. 

{pstd}
The default final predictor for stacking
regession is non-negative
least squares (NNLS) without an intercept. 
The NNLS coefficients are standardized to sum to one.
Note that in this respect we deviate from 
the scikit-learn default and follow the 
recommendation in {helpb pystacked##Hastie2009:2009}, p. 290).
The scikit-lerarn defaults are ridge regression 
for stacking regression and logistic ridge for 
classification tasks. 
To use the scikit-learn default, 
use {opt final:est(ridge)}. 

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
This section lists the base learners that can be chosen via {opt methods(string)}
in combination with {opt type(string)}.
For example, to use lasso with CV and random forest regression, use 
{opt methods(lassocv rf)} with {opt type(reg)}.

{pstd}
Options can be passed to the base learners via {opt ***opt(string)}, 
where {opt ***} is one of the methods, e.g. {opt lassocvopt(string)}.
The defaults are adopted from scikit-learn, with some 
modifications highlighted below.
For a full documentation of the 
options, please see the scikit-learn documentations linked below.

{pstd}
{ul:Penalized regression with information criteria} {break}
Methods {it:lassoic} {break}
{it:Type:} {it:reg} {break}
{it:Doc:} {browse "https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LassoLarsIC.html":linear_model.LassoLarsIC}

{p 8 8 2}
{opt criterion(string)}
{opt nocons:tant}
{opt normalize}
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
{opt nocons:tant}
{opt normalize}
{opt max_iter(integer 1000)}
{opt tol(real 1e-4)}
{opt cv(integer 5)}
{opt n_jobs(integer 1)}
{opt positive}
{opt random_state(integer)}
{opt selection(string)}

{p 6 6 2}
Note: {it:lassocv} uses {l1_ratio(1)}, {it:ridgecv} uses {l1_ratio(0)}; 
other options are the same.

{pstd}
{ul:Logistic regression} Method: {it:elasticcv}, {ul:Type:} {it:class}, {ul:Doc:} {browse "https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LogisticRegression.html":linear_model.LogisticRegression}

{p 8 8 2}
{opt l1_ratio(real)}
{opt c:s(integer 10)}
{opt nocons:tant}
{opt integer(integer 5)}
{opt penalty(string)}
{opt solver(string)}
{opt tol(real 1e-4)}
{opt max_iter(integer 100)}
{opt n_jobs(integer 1)}
{opt norefit}
{opt intercept_scaling(real 1)}
{opt random_state(integer)}

{pstd}
{ul:Method:} {it:rf}, {ul:Type:} {it:class}, {ul:Doc:} {browse "https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.RandomForestClassifier.html":ensemble.RandomForestClassifier}

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
{ul:Method:} {it:rf}, {ul:Type:} {it:reg}, {ul:Doc:} {browse "https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.RandomForestRegressor.html":ensemble.RandomForestRegressor}

{p 8 8 2}
{opt n_estimators(int 100)}
{opt criterion(string)}
{opt max_depth(int)} 
{opt min_samples_split(integer)}
{opt min_samples_leaf(integer)}
{opt min_weight_fraction_leaf(real 0)}
{opt max_features(string)}
{opt max_leaf_nodes(int -1)}
{opt min_impurity_decrease(real 0)}
{opt noboots:trap}
{opt oob_score}
{opt n_jobs(int 1)}
{opt random_state(integer)}
{opt warm_start}
{opt ccp_alpha(real 0)}
{opt max_samples(integer)} 

{pstd}
{ul:Method:} {it:gradboost}, {ul:Type:} {it:class}, {ul:Doc:} {browse "https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.GradientBoostingClassifier.html":ensemble.GradientBoostingClassifier}

{p 8 8 2}
{opt loss(string)}
{opt learning_rate(real 0.1)}
{opt n_estimators(integer 100)}
{opt subsample(real 1)}
{opt min_samples_split(integer 2)}
{opt min_samples_leaf(integer 1)}
{opt min_weight_fraction_leaf(real 0)}
{opt max_depth(integer 3)}
{opt min_impurity_decrease(real 0)}
{opt init(string)}
{opt random_state(integer -1)}
{opt max_features(string)}
{opt max_leaf_nodes(integer -1)}
{opt warm_start}
{opt validation_fraction(real 0.1)}
{opt n_iter_no_change(integer -1)}
{opt tol(real 1e-4)}
{opt ccp_alpha(real 0)}

{pstd}
{ul:Method:} {it:gradboost}, {ul:Type:} {it:reg}, {ul:Doc:} {browse "https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.GradientBoostingRegressor.html":ensemble.GradientBoostingRegressor}

{p 8 8 2}
{opt loss(string)}
{opt learning_rate(real 0.1)}
{opt n_estimators(integer 100)}
{opt subsample(real 1)}
{opt min_samples_split(integer 2)}
{opt min_samples_leaf(integer 1)}
{opt min_weight_fraction_leaf(real 0)}
{opt max_depth(integer 3)}  
{opt min_impurity_decrease(real 0)}
{opt init(string)}
{opt random_state(integer -1)}
{opt max_features(string)}
{opt alpha(real 0.9)}
{opt max_leaf_nodes(integer -1)}
{opt warm_start}
{opt validation_fraction(real 0.1)}
{opt n_iter_no_change(integer -1)}
{opt tol(real 1e-4)}
{opt ccp_alpha(real 0)}

{pstd}
{ul:Method:} {it:linsvm}, {ul:Type:} {it:class}, {ul:Doc:} {browse "https://scikit-learn.org/stable/modules/generated/sklearn.svm.LinearSVC.html":svm.LinearSVC}

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
{ul:Method:} {it:linsvm}, {ul:Type:} {it:reg}, {ul:Doc:} {browse "https://scikit-learn.org/stable/modules/generated/sklearn.svm.LinearSVR.html":svm.LinearSVR}

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
{ul:Method:} {it:svm}, {ul:Type:} {it:class}, {ul:Doc:} {browse "https://scikit-learn.org/stable/modules/generated/sklearn.svm.SVR.html":svm.SVR}

{p 8 8 2}
{opt ker:nel(string)}
{opt degree(integer 3)}
{opt gam:ma(string)}
{opt coef0(real 0)}
{opt tol(real 1e-3)}
{opt c(real 1)}
{opt epsilon(real 0.1)}
{opt noshr:inking}
{opt cache_size(real 200)}
{opt max_iter(integer -1)}

{pstd}
{ul:Method:} {it:svm}, {ul:Type:} {it:reg}, {ul:Doc:} {browse "https://scikit-learn.org/stable/modules/generated/sklearn.svm.SVC.html":svm.SVC}

{p 8 8 2}
{opt c(real 1)}
{opt ker:nel(string)}
{opt degree(integer 3)}
{opt gam:ma(string)}
{opt coef0(real 0)}
{opt probability}
{opt tol(real 1e-3)}
{opt epsilon(real 0.1)}
{opt noshr:inking}
{opt cache_size(real 200)}
{opt max_iter(integer -1)}
{opt decision_function_shape(string)}
{opt break_ties}
{opt random_state(integer -1)}

{marker example_prostate}{...}
{title:Example using prostate cancer data (Stamey et al., {helpb pystacked##Stamey1989:1989})}

{marker examples_data}{...}
{pstd}
{ul:Data set}

{pstd}
The data set is available through Hastie et al. ({helpb pystacked##Hastie2009:2009}) on the {browse "https://web.stanford.edu/~hastie/ElemStatLearn/":authors' website}. 
The following variables are included in the data set of 97 men:

{synoptset 10 tabbed}{...}
{p2col 5 19 23 2: Predictors}{p_end}
{synopt:lcavol}log(cancer volume){p_end}
{synopt:lweight}log(prostate weight){p_end}
{synopt:age}patient age{p_end}
{synopt:lbph}log(benign prostatic hyperplasia amount){p_end}
{synopt:svi}seminal vesicle invasion{p_end}
{synopt:lcp}log(capsular penetration){p_end}
{synopt:gleason}Gleason score{p_end}
{synopt:pgg45}percentage Gleason scores 4 or 5{p_end}

{synoptset 10 tabbed}{...}
{p2col 5 19 23 2: Outcome}{p_end}
{synopt:lpsa}log(prostate specific antigen){p_end}

{pstd}Load prostate cancer data.{p_end}
{phang2}. {stata "insheet using https://web.stanford.edu/~hastie/ElemStatLearn/datasets/prostate.data, clear tab"}{p_end}

{pstd}
Stacking regression with default base learners.
{p_end}
{phang2}. {stata "pystacked lpsa lcavol lweight age lbph svi lcp gleason pgg45, type(regress) pyseed(123)"}{p_end}

{pstd}
The weights indicate that lasso with CV received a weight of 1, while
random forest and gradient boosting get zero weights. 
Hence, in this example, stacking regression chooses
to exclusively use the lasso with cross-validated penalisation.{p_end}

{pstd}
Getting the predicted values:{p_end}
{phang2}. {stata "predict double l, xb"}{p_end}

{pstd}
We can also save the predicted values of each base learner:{p_end}
{phang2}. {stata "predict double l, transform"}{p_end}

{marker example}{...}
{title:Classification Example using Spam data}

{marker example_data}{...}
{pstd}
{ul:Data set}

{pstd}
For demonstration we consider the Spambase Data Set 
from the Machine Learning Repository. 
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

{marker references}{title:References}

{marker Hastie2009}{...}
{pstd}
Hastie, T., Tibshirani, R., & Friedman, J. (2009). 
The elements of statistical learning: data mining, inference,
and prediction. Springer Science & Business Media.

{marker Stamey1989}{...}
{pstd}
Stamey, T. A., Kabalin, J. N., Mcneal, J. E., Johnstone,
I. M., Freiha, F., Redwine, E. A., & Yang, N. (1989). 
Prostate Specific Antigen in the Diagnosis and Treatment
 of Adenocarcinoma of the Prostate. II. Radical Prostatectomy Treated Patients.
{it:The Journal of Urology} 141(5), 1076–1083. 
{browse "https://doi.org/10.1016/S0022-5347(17)41175-X"}
{p_end}

{marker Wolpert1992}{...}
{pstd}
Wolpert, David H. Stacked generalization. {it:Neural networks} 5.2 (1992): 241-259.
{browse "https://doi.org/10.1016/S0893-6080(05)80023-1"}

{marker installation}{title:Installation}

{title:Authors}

	Achim Ahrens, Public Policy Group, ETH Zurich, Switzerland
	achim.ahrens@gess.ethz.ch

	Mark E. Schaffer, Heriot-Watt University, UK
	m.e.schaffer@hw.ac.uk