{smcl}
{* *! version 30nov2022}{...}
{hline}
{cmd:help pystacked}{right: v0.4.8}
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
Stacking is a way of combining multiple supervised
machine learners (the "base" or "level-0" learners) into
a meta learner.
The currently supported base learners are linear regression, 
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
a Python installation and scikit-learn (0.24 or higher). {opt pystacked}
has been tested with scikit-learn 0.24, 1.0, 1.1.0, 1.1.1 and 1.1.2.
See {helpb python:here} and {browse "https://blog.stata.com/2020/08/18/stata-python-integration-part-1-setting-up-stata-to-use-python/":here} 
for how to set up Python for Stata on your system.

{marker methodopts}{...}
{title:Contents}

	{helpb pystacked##syntax_overview:Syntax overview}
	{helpb pystacked##syntax1:Syntax 1}
	{helpb pystacked##syntax2:Syntax 2}
	{helpb pystacked##otheropts:Other options}
	{helpb pystacked##postestimation:Postestimation and prediction options}
	{helpb pystacked##section_stacking:Stacking}
	{helpb pystacked##base_learners:Supported base learners}
	{helpb pystacked##base_learners_opt:Base learners: Options}
	{helpb pystacked##pipelines:Pipelines}
	{helpb pystacked##predictors:Learner-specific predictors}
	{helpb pystacked##example_boston:Example Stacking Regression}
	{helpb pystacked##example_spam:Example Stacking Classification}
	{helpb pystacked##installation:Installation}
	{helpb pystacked##misc:Misc (references, contact, etc.)}

{marker syntax_overview}{...}
{title:Syntax overview}

{pstd}
There are two alternative syntaxes. The {ul:first syntax} is:

{p 8 14 2}
{cmd:pystacked}
{it:depvar} {it:predictors} 
[{cmd:if} {it:exp}] [{cmd:in} {it:range}]
{bind:[{cmd:,}}
{opt methods(string)}
{opt cmdopt1(string)} 
{opt cmdopt2(string)} 
{opt ...}
{opt pipe1(string)} 
{opt pipe2(string)} 
{opt ...}
{opt xvars1(varlist)} 
{opt xvars2(varlist)} 
{opt ...}
{helpb pystacked##otheropts:{it:otheropts}}
]

{pstd}
The {ul:second syntax} is:

{p 8 14 2}
{cmd:pystacked}
{it:depvar} {it:predictors} 
|| {opt m:ethod(string)}
{opt opt(string)} 
{opt pipe:line(string)} 
{opt xvars(varlist)} 
|| {opt m:ethod(string)}
{opt opt(string)} 
{opt pipe:line(string)} 
{opt xvars(varlist)} 
||
{opt ...}
||
[{cmd:if} {it:exp}] [{cmd:in} {it:range}]
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
Furthermore, {opt xvars*(varlist)} allows to specify a learner-specific varlist of predictors.

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
a list of base learners, defaults to "{it:ols lassocv gradboost}" for regression
and "{it:logit lassocv gradboost}" for classification;
see {helpb pystacked##base_learners:Base learners}.
{p_end}
{synopt:{opt cmdopt*(string)}}
options passed to the base learners, see {helpb pystacked##base_learners_opt:Command options}.
{p_end}
{synopt:{opt pipe*(string)}}
pipelines passed to the base learners, see {helpb pystacked##pipelines:Pipelines}.
Regularized linear learners use the {it:stdscaler} pipeline by default, which
standardizes the predictors. To suppress this, use {it:nostdscaler}.
For other learners, there is no default pipeline.
{p_end}
{synopt:{opt xvars*(varlist)}}
overwrites the default list of predictors.
That is, 
you can specify learner-specific lists of predictors.
See {helpb pystacked##predictors:here}.
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
pipelines passed to the base learners, see {helpb pystacked##pipelines:Pipelines}.
Regularized linear learners use the {it:stdscaler} pipeline by default, which
standardizes the predictors. To suppress this, use {it:nostdscaler}.
For other learners, there is no default pipeline.
{p_end}
{synopt:{opt xvars(varlist)}}
overwrites the default list of predictors.
That is, 
you can specify learner-specific lists of predictors.
See {helpb pystacked##predictors:here}.
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
The default is regression.
{p_end}
{synopt:{opt final:est(string)}}
final estimator used to combine base learners. 
The default is non-negative least squares without an intercept 
and the additional constraint that weights sum to 1 ({it:nnls1}). 
Alternatives are {it:nnls0} (non-negative least squares without intercept 
without the sum-to-one constraint), 
{it:singlebest} (use base learner with minimum MSE),
{it:ols} (ordinary least squares) or
{it:ridge} for (logistic) ridge, which is the
sklearn default. For more information, 
see {helpb pystacked##section_stacking:here}.
{p_end}
{synopt:{opt nosavep:red}} do not save predicted values
(do not use if {cmd:predict} is used after estimation)
{p_end}
{synopt:{opt nosaveb:asexb}} do not save predicted values
of each base learner 
(do not use if {cmd:predict} with {opt base:xb} is used after estimation)
{p_end}
{synopt:{opt njobs(int)}} 
number of jobs for parallel computing. The default is 0 (no parallelization), 
-1 uses all available CPUs, -2 uses all CPUs minus 1. 
{p_end}
{synopt:{opt backend(string)}} 
joblib backend used for parallelization; the default is 'loky' under Linux/MacOS
and 'threading' under Windows. 
See {browse "https://scikit-learn.org/stable/modules/generated/sklearn.utils.parallel_backend.html":here} for more information.
{p_end}
{synopt:{opt folds(int)}} 
number of folds used for cross-validation (not relevant for voting); 
default is 5. Ignored if {opt foldvar(varname)} if specified.
{p_end}
{synopt:{opt foldvar(varname)}} 
integer fold variable for cross-validation.
{p_end}
{synopt:{opt bfolds(int)}} 
number of folds used for {it:base learners} that use 
cross-validation (e.g. {it:lassocv}); 
default is 5.  
{p_end}
{synopt:{opt norandom}} 
folds are created using the ordering of the data. 
{p_end}
{synopt:{opt noshuffle}} 
cross-validation folds for {it:base learners} that use 
cross-validation (e.g. {it:lassocv}) are based on 
ordering of the data. 
{p_end}
{synopt:{opt sparse}} 
converts predictor matrix to a sparse matrix. This will only lead to speed improvements
if the predictor matrix is sufficiently sparse. Not all learners support sparse matrices
and not all learners will benefit from sparse matrices in the same way. You can also 
use the sparse pipeline to use sparse matrices for some learners, but not for others.
{p_end}
{synopt:{opt pyseed(int)}} 
set the Python seed. Note that since {cmd:pystacked} uses
Python, we also need to set the Python seed to ensure replicability.
Three options: 1) {opt pyseed(-1)} draws a number 
between 0 and 10^8 in Stata which is then used as a Python seed.
This way, you only need to deal with the Stata seed. For example, {opt set seed 42} is
sufficient, as the Python seed is generated automatically. 2) Setting {opt pyseed(x)} 
with any positive integer {it:x} allows to control the Python seed 
directly. 3) {opt pyseed(0)} sets the seed to None in Python.
The default is {opt pyseed(-1)}.
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

{marker postestimation}{...}
{title:Postestimation and prediction options}

{pstd}
{ul:Postestimation tables}

{pstd}
After estimation, {opt pystacked} can report a table of in-sample
(both cross-validated and full-sample-refitted)
and, optionally, out-of-sample (holdout sample) performance
for both the stacking regression and the base learners.
For regression problems, the table reports the root MSPE (mean squared prediction error);
for classification problems, a confusion matrix is reported.
The default holdout sample used for out-of-sample performance with the {opt holdout} option
is all observations not included in the estimation.
Alternatively, the user can specify the holdout sample explicitly
using the syntax {opt holdout(varname)}.
The table can be requested postestimation as below,
or as part of the {opt pystacked} estimation command.

{pstd}
Table syntax:

{p 8 14 2}
{cmd:pystacked} {bind:[{cmd:,}}
{opt tab:le}
{opt holdout}[{cmd:(}{it:varname}{cmd:)}]
]

{pstd}
{ul:Postestimation graphs}

{pstd}
{opt pystacked} can also report graphs of in-sample
and, optionally, out-of-sample (holdout sample) performance
for both the stacking regression and the base learners.
For regression problems, the graphs compare predicted vs actual values of {it:depvar}.
For classification problems, the default is to report ROC curves;
optionally, histograms of predicted probabilities are reported.
As with the {opt table} option, the default holdout sample used for out-of-sample performance
is all observations not included in the estimation,
but the user can instead specify the holdout sample explicitly.
The table can be requested postestimation as below,
or as part of the {opt pystacked} estimation command.

{pstd}
The {opt graph} option on its own reports the graphs using {opt pystacked}'s default settings.
Because graphs are produced using Stata's {helpb twoway}, {helpb roctab} and {helpb histogram} commands,
the user can control either the combined graph ({opt graph(options)})
or the individual learner graphs ({opt lgraph(options)}) appear by passing options to these commands.

{pstd}
Graph syntax:

{p 8 14 2}
{cmd:pystacked} {bind:[{cmd:,}}
{opt graph}[{cmd:(}{it:options}{cmd:)}]
{opt lgraph}[{cmd:(}{it:options}{cmd:)}]
{opt hist:ogram}
{opt holdout}[{cmd:(}{it:varname}{cmd:)}]
]

{pstd}
{ul:Prediction}

{pstd}
To get stacking predicted values:

{p 8 14 2}
{cmd:predict}
{it:type} {it:newname} 
[{cmd:if} {it:exp}] [{cmd:in} {it:range}]
{bind:[{cmd:,}}
{opt pr}
{opt class}
{opt xb}
{opt resid}
]

{pstd}
To get fitted values for each base learner:

{p 8 14 2}
{cmd:predict}
{it:type} {it:stub} 
[{cmd:if} {it:exp}] [{cmd:in} {it:range}]
{bind:[{cmd:,}}
{opt base:xb}
{opt cv:alid}
]

{synoptset 20}{...}
{synopthdr:Option}
{synoptline}
{synopt:{opt xb}}
predicted value; the default for regression
{p_end}
{synopt:{opt pr}}
predicted probability; the default for classification
{p_end}
{synopt:{opt class}}
predicted class
{p_end}
{synopt:{opt resid}}
residuals
{p_end}
{synopt:{opt base:xb}}
predicted values for each base learner (default = use base learners re-fitted on full estimation sample)
{p_end}
{synopt:{opt cv:alid}}
cross-validated predicted values. Currently only supported if combined with {opt base:xb}.
{p_end}
{synoptline}

{pstd}
{it:Note:} Predicted values (in and out-sample)
are calculated and stored in Python memory
when {cmd:pystacked} is run. {cmd:predict} pulls the
predicted values from Python memory and saves them in 
Stata memory. This means that no changes on the data
in Stata memory should be made {it:between} {cmd:pystacked} call
and {cmd:predict} call. If changes to the data set are made, 
{cmd:predict} will return an error. 

{marker section_stacking}{...}
{title:Stacking}

{pstd}
Stacking is a way of combining cross-validated 
predictions from multiple base ("level-0") learners into
a final prediction. A final estimator ("level-1") is used to combine the base predictions. 

{pstd}
The default final predictor for stacking
regession is non-negative
least squares (NNLS) without an intercept and with the constraint
that weights sum to one.
Note that in this respect we deviate from 
the scikit-learn default and follow the 
recommendation in Breiman (1996)
and Hastie et al. ({helpb pystacked##Hastie2009:2009}, p. 290).
The scikit-learn defaults for the final estimator
are ridge regression 
for stacking regression and logistic ridge
for classification tasks. 
To use the scikit-learn default, 
use {opt final:est(ridge)}. 
{cmd:pystacked} also supports ordinary (unconstrained)
least squares as the final estimator ({opt final:est(ols)}). 
Finally, {it:singlebest} uses the single base learner that 
exhibits the smallest cross-validated mean squared error. 

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
{opt methods(lassocv gradboost nnet)}  
(Syntax 1) or {opt m:ethod(string)}
options (Syntax 2).

{pstd}
Please see links in the next section for more information on each method.

{marker base_learners_opt}{...}
{title:Base learners: Options}

{pstd}
Options can be passed to the base learners via {opt cmdopt*(string)} 
(Syntax 1) or {opt opt(string)} (Syntax 2).
The defaults are adopted from scikit-learn.

{pstd}
To see the default options of each base learners, simply click on 
the "Show options" links below. To see which alternative
settings are allowed, please see the scikit-learn 
documentations linked below.
We {it:strongly recommend} that you read the scikit-learn 
documentation carefully.

{pstd}
The option {opt showopt:ions} shows the options passed on to Python. 
We recommend to verify that options have been passed to Python as intended. 

{pstd}
{ul:Linear regression} {break}
Methods {it:ols} {break}
{it:Type:} {it:reg} {break}
{it:Documentation:} {browse "https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LinearRegression.html":linear_model.LinearRegression}

{pstd}
{stata "_pyparse, type(reg) method(ols) print":Show options}

{pstd}
{ul:Logistic regression} {break}
Methods: {it:logit} {break}
Type: {it:class} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LogisticRegression.html":linear_model.LogisticRegression}

{pstd}
{stata "_pyparse, type(class) method(logit) print":Show options}

{pstd}
{ul:Penalized regression with information criteria} {break}
Methods {it:lassoic} {break}
Type: {it:reg} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LassoLarsIC.html":linear_model.LassoLarsIC}

{pstd}
{stata "_pyparse, type(reg) method(lassoic) print":Show options}

{pstd}
{ul:Penalized regression with cross-validation} 

{p 6 6 2}
Methods: {it:lassocv}, {it:ridgecv} and {it:elasticv} {break} 
Type: {it:regress} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.ElasticNetCV.html":linear_model.ElasticNetCV}  

{pstd}
{stata "_pyparse, type(reg) method(lassocv) print":Show lasso options} {break}
{stata "_pyparse, type(reg) method(ridgecv) print":Show ridge options} {break}
{stata "_pyparse, type(reg) method(elasticcv) print":Show elastic net options}

{pstd}
{ul:Penalized logistic regression with cross-validation} {break}
Methods: {it:lassocv}, {it:ridgecv} and {it:elasticv} {break} 
Type: {it:class} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LogisticRegressionCV.html":linear_model.LogisticRegressionCV}

{pstd}
{stata "_pyparse, type(class) method(lassocv) print":Show lasso options} {break}
{stata "_pyparse, type(class) method(ridgecv) print":Show ridge options} {break}
{stata "_pyparse, type(class) method(elasticcv) print":Show elastic options}

{pstd}
{ul:Random forest classifier} {break}
Method: {it:rf} {break}
Type: {it:class} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.RandomForestClassifier.html":ensemble.RandomForestClassifier}

{pstd}
{stata "_pyparse, type(class) method(rf) print":Show options}

{pstd}
{ul:Random forest regressor} {break}
Method: {it:rf} {break}
Type: {it:reg} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.RandomForestRegressor.html":ensemble.RandomForestRegressor}

{pstd}
{stata "_pyparse, type(reg) method(rf) print":Show options}

{pstd}
{ul:Gradient boosted regression trees} {break}
Method: {it:gradboost} {break}
Type: {it:reg} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.GradientBoostingRegressor.html":ensemble.GradientBoostingRegressor}

{pstd}
{stata "_pyparse, type(reg) method(gradboost) print":Show options}

{pstd}
{ul:Linear SVM (SVR)} {break}
Method: {it:linsvm} {break}
Type: {it:reg} {break} 
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.svm.LinearSVR.html":svm.LinearSVR}

{pstd}
{stata "_pyparse, type(reg) method(linsvm) print":Show options}

{pstd}
{ul:SVM (SVR)} {break}
Method: {it:svm} {break}
Type: {it:class} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.svm.SVR.html":svm.SVR}

{pstd}
{stata "_pyparse, type(reg) method(svm) print":Show options}

{pstd}
{ul:SVM (SVC)} {break}
Method: {it:svm} {break}
Type: {it:reg} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.svm.SVC.html":svm.SVC}

{pstd}
{stata "_pyparse, type(class) method(svm) print":Show options}

{pstd}
{ul:Neural net classifier (Multi-layer Perceptron)} {break}
Method: {it:nnet} {break}
Type: {it:class} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.neural_network.MLPClassifier.html":sklearn.neural_network.MLPClassifier}

{pstd}
{stata "_pyparse, type(class) method(nnet) print":Show options}

{pstd}
{ul:Neural net regressor (Multi-layer Perceptron)} {break}
Method: {it:nnet} {break}
Type: {it:reg} {break}
Documentation: {browse "https://scikit-learn.org/stable/modules/generated/sklearn.neural_network.MLPRegressor.html":sklearn.neural_network.MLPRegressor}

{pstd}
{stata "_pyparse, type(reg) method(nnet) print":Show options}

{marker predictors}{...}
{title:Learner-specific predictors}

{pstd}
By default, {cmd:pystacked} uses the same set of predictors for all base learners. This is often not 
desirable. For example, when using linear machine learners such as the lasso, 
it is recommended to create interactions. There are two methods to allow for learner-specific
sets of predictors: 

{pstd}
1) Pipelines, discussed in the next section, can be used to create polynomials on the fly. 

{pstd}
2) The {opt xvars*(varlist)} option allows to specify predictors for a specific learner. 
If {opt xvars*(varlist)} is missing for a specific learner, 
the default predictor list is used. 

{marker pipelines}{...}
{title:Pipelines}

{pstd}
Scikit-learn uses pipelines to pre-preprocess input data on the fly. 
Pipelines can be used to impute missing observations or 
create transformation of predictors such as interactions and polynomials.

{pstd}
The following pipelines are currently supported: 

{synoptset 10 tabbed}{...}
{p2col 5 29 23 2:Pipelines}{p_end}
{p2col 7 29 23 2:{it:stdscaler}}{browse "https://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.StandardScaler.html":StandardScaler()}{p_end}
{p2col 7 29 23 2:{it:stdscaler0}}{browse "https://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.StandardScaler.html":StandardScaler(with_mean=False)}{p_end}
{p2col 7 29 23 2:{it:sparse}}{browse "https://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.SparseTransformer.html":SparseTransformer()}{p_end}
{p2col 7 29 23 2:{it:onehot}}{browse "https://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.OneHotEncoder.html":OneHotEncoder()()}{p_end}
{p2col 7 29 23 2:{it:minmaxscaler}}{browse "https://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.MinMaxScaler.html":MinMaxScaler()}{p_end}
{p2col 7 29 23 2:{it:medianimputer}}{browse "https://scikit-learn.org/stable/modules/generated/sklearn.impute.SimpleImputer.html":SimpleImputer(strategy='median')}{p_end}
{p2col 7 29 23 2:{it:knnimputer}}{browse "https://scikit-learn.org/stable/modules/generated/sklearn.impute.KNNImputer.html":KNNImputer()}{p_end}
{p2col 7 29 23 2:{it:poly2}}{browse "https://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.PolynomialFeatures.html":PolynomialFeatures(degree=2)}{p_end}
{p2col 7 29 23 2:{it:poly3}}{browse "https://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.PolynomialFeatures.html":PolynomialFeatures(degree=3)}{p_end}

{pstd}
Pipelines can be passed to the base learners via {opt pipe*(string)} 
(Syntax 1) or {opt pipe:line(string)} (Syntax 2).

{pstd}
{it:stdscaler0} is intended for sparse matrices, since {it:stdscaler} will make a sparse matrix dense.

{marker example_boston}{...}
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
Stacking regression with lasso, random forest and gradient boosting.
{p_end}
{phang2}. {stata "pystacked medv crim-lstat, type(regress) pyseed(123) methods(lassocv rf gradboost)"}{p_end}

{pstd}
The weights determine how much each base learner contributes
to the final stacking prediction.{p_end}

{pstd}
Request the root MSPE table (in-sample only):{p_end}
{phang2}. {stata "pystacked, table"}{p_end}

{pstd}
Re-estimate using the first 400 observations, and
request the root MSPE table.
RMSPEs for both in-sample (both refitted and cross-validated)
and the default holdout sample (all unused observations) are reported.:{p_end}
{phang2}. {stata "pystacked medv crim-lstat if _n<=400, type(regress) pyseed(123) methods(lassocv rf gradboost)"}{p_end}
{phang2}. {stata "pystacked, table holdout"}{p_end}

{pstd}
Graph predicted vs actual for the holdout sample:{p_end}
{phang2}. {stata "pystacked, graph holdout"}{p_end}

{pstd}
Storing the predicted values:{p_end}
{phang2}. {stata "predict double yhat, xb"}{p_end}

{pstd}
Storing the cross-validated predicted values:{p_end}
{phang2}. {stata "predict double yhat_cv, xb cvalid"}{p_end}

{pstd}
We can also save the predicted values of each base learner:{p_end}
{phang2}. {stata "predict double yhat, basexb"}{p_end}

{pstd}
{ul:Learner-specific predictors (Syntax 1)}

{pstd}
{cmd:pystacked} allows the use of different sets of predictors 
for each base learners. For example, 
linear estimators might perform better if interactions are 
provided as inputs. Here, we use interactions and 2nd-order polynomials
for the lasso, but not for the other base learners. 
{p_end}
{phang2}. {stata "pystacked medv crim-lstat, type(regress) pyseed(123) methods(ols lassocv rf) xvars2(c.(crim-lstat)# #c.(crim-lstat))"}{p_end}

{pstd}
The same can be achieved using pipelines which create polynomials on-the-fly in Python. 
{p_end}
{phang2}. {stata "pystacked medv crim-lstat, type(regress) pyseed(123) methods(ols lassocv rf) pipe2(poly2)"}{p_end}

{pstd}
{ul:Learner-specific predictors (Syntax 2)}

{pstd}
We demonstrate the same using the alternative syntax, which is often more handy:

{phang2}. {stata "pystacked medv crim-lstat || m(ols) || m(lassocv) xvars(c.(crim-lstat)# #c.(crim-lstat)) || m(rf) || , type(regress) pyseed(123)"}{p_end}
{phang2}. {stata "pystacked medv crim-lstat || m(ols) || m(lassocv) pipe(poly2) || m(rf) || , type(regress) pyseed(123)"}{p_end}

{pstd}
{ul:Options of base learners (Syntax 1)}

{pstd}
We can pass options to the base learners using {opt cmdopt*(string)}. In this example, 
we change the maximum tree depth for the random forest. Since random forest is
the third base learner, we use {opt cmdopt3(max_depth(3))}.
{p_end}

{phang2}. {stata "pystacked medv crim-lstat, type(regress) pyseed(123) methods(ols lassocv rf) pipe1(poly2) pipe2(poly2) cmdopt3(max_depth(3))"}{p_end}

{pstd}
You can verify that the option has been passed to Python correctly:
{p_end}
{phang2}. {stata "di e(pyopt3)"}{p_end}

{pstd}
{ul:Options of base learners (Syntax 2)}

{pstd}
The same results as above can be achieved using the alternative syntax, which 
imposes no limit on the number of base learners.
{p_end}

{phang2}. {stata "pystacked medv crim-lstat || m(ols) pipe(poly2) || m(lassocv) pipe(poly2) || m(rf) opt(max_depth(3)) , type(regress) pyseed(123)"}{p_end}

{pstd}
{ul:Single base learners}

{pstd}
You can use {cmd:pystacked} with a single base learner. 
In this example, we are using a conventional random forest:
{p_end}

{phang2}. {stata "pystacked medv crim-lstat, type(regress) pyseed(123) methods(rf)"}{p_end}

{pstd}
{ul:Voting}

{pstd}
You can also use pre-defined weights. Here, we assign weights of 0.5 to OLS, 
.1 to the lasso and, implicitly, .4 to the random foreset.
{p_end}
{phang2}. {stata "pystacked medv crim-lstat, type(regress) pyseed(123) methods(ols lassocv rf) pipe1(poly2) pipe2(poly2) voting voteweights(.5 .1)"}{p_end}

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

{pstd}
Throughout this example, we add the option {opt njobs(4)}, which enables 
parallelization with 4 cores. 

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

{pstd}Confusion matrix, just in-sample and both in- and out-of-sample.{p_end}
{phang2}. {stata "pystacked, table"}{p_end}
{phang2}. {stata "pystacked, table holdout"}{p_end}

{pstd}Confusion matrix for a specified holdout sample.{p_end}
{phang2}. {stata "gen h = _n>3000"}{p_end}
{phang2}. {stata "pystacked, table holdout(h)"}{p_end}

{pstd}ROC curves for the default holdout sample. Specify a subtitle for the combined graph.{p_end}
{phang2}. {stata "pystacked, graph(subtitle(Spam data)) holdout"}{p_end}

{pstd}Predicted probabilites ({opt hist} option) for the default holdout sample.
Specify number of bins for the individual learner graphs.{p_end}
{phang2}. {stata "pystacked, graph hist lgraph(bin(20)) holdout"}{p_end}


{marker installation}{title:Installation}

{pstd}
{opt pystacked} requires at least Stata 16 (or higher),  
a Python installation and scikit-learn (0.24 or higher).
See 
{helpb python:this help file}, {browse "https://blog.stata.com/2020/08/18/stata-python-integration-part-1-setting-up-stata-to-use-python/":this Stata blog entry}
and 
{browse "https://www.youtube.com/watch?v=4WxMAGNhcuE":this Youtube video}
for how to set up
Python on your system.
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
which implements other scikit-learn programs for Stata.
Thanks to Jan Ditzen for testing an early version 
of the program. We also thank Brigham Frandsen and 
Marco Alfano for feedback. 
All remaining errors are our own. 

{title:Citation}

{pstd}
Please also cite scikit-learn; see {browse "https://scikit-learn.org/stable/about.html"}.

{title:Authors}

{pstd}
Achim Ahrens, Public Policy Group, ETH Zurich, Switzerland {break}
achim.ahrens@gess.ethz.ch

{pstd}
Christian B. Hansen, University of Chicago, USA {break}
Christian.Hansen@chicagobooth.edu

{pstd}
Mark E Schaffer, Heriot-Watt University, UK {break}
m.e.schaffer@hw.ac.uk	
