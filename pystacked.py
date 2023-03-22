#! pystacked v0.7
#! last edited: 6mar2023
#! authors: aa/ms

# Import required Python modules
import sfi
import numpy as np
import __main__
import warnings
from sklearn.pipeline import make_pipeline,Pipeline
from sklearn.neural_network import MLPRegressor,MLPClassifier
from sklearn.preprocessing import StandardScaler,PolynomialFeatures,OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer,KNNImputer
from sklearn.linear_model import LassoLarsIC,LassoCV,LogisticRegression,LogisticRegressionCV,LinearRegression
from sklearn.linear_model import RidgeCV,ElasticNetCV
from sklearn.ensemble import StackingRegressor,StackingClassifier
from sklearn.ensemble import VotingRegressor,VotingClassifier
from sklearn.ensemble import RandomForestRegressor,RandomForestClassifier
from sklearn.ensemble import GradientBoostingRegressor,GradientBoostingClassifier
from sklearn.base import TransformerMixin,BaseEstimator
from sklearn.svm import LinearSVR,LinearSVC,SVC,SVR
from sklearn.utils import check_X_y,check_array
from sklearn.utils.validation import check_is_fitted
from scipy.sparse import coo_matrix,csr_matrix,issparse
from scipy.optimize import minimize 
from scipy.optimize import nnls 
from sklearn import __version__ as sklearn_version
from scipy import __version__ as scipy_version
from numpy import __version__ as numpy_version
from sys import version as sys_version
from sklearn.utils import parallel_backend
from sklearn.model_selection import PredefinedSplit,KFold,StratifiedKFold

### Define required Python functions/classes

class SingleBest(BaseEstimator):
    """
    Select base learner with lowest MSE
    """
    _estimator_type="regressor"
    def fit(self, X, y):
        X, y = check_X_y(X, y, accept_sparse=True)
        self.is_fitted_ = True
        ncols = X.shape[1]
        lowest_mse = np.Inf
        for i in range(ncols):
            this_mse=np.mean((y-X[:, i]) ** 2)
            if this_mse < lowest_mse:
                lowest_mse = this_mse
                best = i
        self.best = best
        coef = np.zeros(ncols)
        coef[best] = 1
        self.coef_ = coef
        self.cvalid=X
        return self
    def predict(self, X):
        X = check_array(X, accept_sparse=True)
        check_is_fitted(self, 'is_fitted_')
        return X[:,self.best]

class ConstrLS(BaseEstimator):
    """
    Constrained least squares, weights sum to 1 and optionally >= 0
    """
    _estimator_type="regressor"
    def fit(self, X, y):

        X,y = check_X_y(X,y, accept_sparse=True)
        xdim = X.shape[1]

        #Use nnls to get initial guess
        coef0, rnorm = nnls(X,y)

        #Define minimisation function
        def fn(coef, X, y):
            return np.linalg.norm(X.dot(coef) - y)
        
        #Constraints and bounds
        cons = {'type': 'eq', 'fun': lambda coef: np.sum(coef)-1}
        if self.unit_interval==True:
            bounds = [[0.0,1.0] for i in range(xdim)] 
        else:
            bounds = None

        #Do minimisation
        fit = minimize(fn,coef0,args=(X, y),method='SLSQP',bounds=bounds,constraints=cons)
        self.coef_ = fit.x
        self.is_fitted_ = True
        self.cvalid=X
        return self
        
    def predict(self, X):
        X = check_array(X, accept_sparse=True)
        check_is_fitted(self, 'is_fitted_')
        return np.matmul(X,self.coef_)

    def __init__(self, unit_interval=True):
        self.unit_interval = unit_interval

class ConstrLSClassifier(ConstrLS):
    _estimator_type="classifier"
    def predict_proba(self, X):
        return self.predict(X)

class LinearRegressionClassifier(LinearRegression):
    _estimator_type="classifier"
    def predict_proba(self, X):
        return self.predict(X)

class SparseTransformer(TransformerMixin):
    def fit(self, X, y=None, **fit_params):
        return self
    def transform(self, X, y=None, **fit_params):
        return csr_matrix(X)

def get_index(lst, w):
    """
    return indexes of where elements in 'w' are stored in 'lst'
    """
    lst = lst.split(" ")
    w = w.split(" ")
    sel = []
    for i in range(len(w)):
        if w[i] in lst:
            ix = lst.index(w[i]) 
            sel.append(ix)
    return(sel)

def build_pipeline(pipes,xvars,xvar_sel):
    #
    #builds the pipeline for each base learner
    #pipes = string with pipes
    #xvars = string with all predictors (expanded original names)
    #xvar_sel = string with to-be-selected predictors
    #
    ll = []
    if xvar_sel!="":
        sel_ix = get_index(xvars,xvar_sel)
        ct = ColumnTransformer([("selector", "passthrough", sel_ix)],remainder="drop")
        ll.append(("selector",ct))
    pipes = pipes.split()
    for p in range(len(pipes)):
        if pipes[p]=="stdscaler":
            ll.append(('stdscaler',StandardScaler()))
        elif pipes[p]=="stdscaler0":
            ll.append(('stdscaler',StandardScaler(with_mean=False)))
        elif pipes[p]=="dense":
            ll.append(('dense',DenseTransformer()))
        elif pipes[p]=="sparse":
            ll.append(('sparse',SparseTransformer()))
        elif pipes[p]=="onehot":
            ll.append(('onehot',OneHotEncoder()))
        elif pipes[p]=="minmaxscaler":
            ll.append(('minmaxscaler',MinMaxScaler()))
        elif pipes[p]=="medianimputer":
            ll.append(('medianimputer',SimpleImputer(strategy='median')))
        elif pipes[p]=="knnimputer":
            ll.append(('knnimputer',KNNImputer()))
        elif pipes[p]=="poly2":
            ll.append(('poly2',PolynomialFeatures(degree=2,include_bias=False)))
        elif pipes[p]=="poly3":
            ll.append(('poly3',PolynomialFeatures(degree=3,include_bias=False)))
        elif pipes[p]=="interact":
            ll.append(('interact',PolynomialFeatures(include_bias=False,interaction_only=True)))
    return ll

def run_stacked(type, # regression or classification 
    finalest, # final estimator
    methods, # list of base learners
    yvar, # outcome
    xvars, # predictors (temp names)
    wvar, # weight var
    training, # marks holdout sample
    allopt, # options for each learner
    allpipe, # pipes for each learner
    allxvar_sel, # subset predictors for each learner (expanded var names)
    touse, # sample
    seed, # seed
    nosavepred,nosavebasexb, # store predictions
    voting,votetype,voteweights, # voting
    njobs, # number of cores
    foldvar, # foldvar
    prefit, # don't do CV
    bfolds, #
    shuff, #
    idvar, # id var
    showpywarnings, # show warnings?
    parbackend, # backend
    sparse, # sparse predictor 
    showopt #
    ):
    
    if int(format(sklearn_version).split(".")[1])<24 and int(format(sklearn_version).split(".")[0])<1:
        sfi.SFIToolkit.stata('di as err "pystacked requires sklearn 0.24.0 or higher. Please update sklearn."')
        sfi.SFIToolkit.stata('di as err "See instructions on https://scikit-learn.org/stable/install.html, and in the help file."')
        sfi.SFIToolkit.error(198)

    # Set random seed
    if seed>0:
        rng=np.random.RandomState(seed)
    else: 
        rng=None
    
    if showpywarnings=="":
        warnings.filterwarnings('ignore')
    else:
        warnings.filterwarnings('default')
    
    if njobs==0: 
        nj = None 
    else: 
        nj = njobs 

    ##############################################################
    ### load data                                              ###
    ##############################################################

    y = np.array(sfi.Data.get(yvar,selectvar=touse))
    x = np.array(sfi.Data.get(xvars,selectvar=touse))
    id = np.array(sfi.Data.get(idvar,selectvar=touse))
    if wvar!="":
        weights = np.array(sfi.Data.get(wvar,selectvar=touse))
    else:
        weights =None

    #id = np.reshape(id,(-1,1))
    id.astype(int)
    fid = np.array(sfi.Data.get(foldvar,selectvar=touse))
    # If missings are present, need to specify they are NaNs.
    x_0 = np.array(sfi.Data.get(xvars,missingval=np.nan))
    if x.ndim == 1:
        x=np.reshape(x,(-1,1))
    if x_0.ndim == 1:
        x_0 = np.reshape(x_0,(-1,1))
    if sparse!="":
        x = coo_matrix(x).tocsc()

    shuff = shuff==1
    if shuff: 
        cvrng=rng
    else: 
        cvrng=None

    if prefit!="":
        ccv=prefit
    else:
        ccv=PredefinedSplit(fid)

    ##############################################################
    ### prepare fit                                            ###
    ##############################################################

    # convert strings to python objects
    methods = methods.split()
    if "xgb" in methods:
        import xgboost as xgb
    allopt = eval(allopt)
    allpipe = eval(allpipe)
    allxvar_sel = eval(allxvar_sel)

    # print options:
    if showopt!="":
        sfi.SFIToolkit.displayln("")
        for m in range(len(methods)):
            opt = allopt[m]
            sfi.SFIToolkit.displayln("Base learner: "+methods[m])
            for i in opt:
                subopt_name = opt[i]
                sfi.SFIToolkit.stata('di as text "'+str(i)+' = " _c')
                sfi.SFIToolkit.stata('di as text "'+str(opt[i])+'; " _c')
            sfi.SFIToolkit.displayln("")
            sfi.SFIToolkit.displayln("")

    est_list = []
    for m in range(len(methods)):
        if type=="reg":
            if methods[m]=="ols":
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('ols',LinearRegression(**opt)))
            if methods[m]=="lassoic":
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('lassolarsic',LassoLarsIC(**opt)))
            if methods[m]=="lassocv":
                opt =allopt[m]
                newmethod= build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('lassocv',ElasticNetCV(**opt,cv=KFold(n_splits=bfolds,shuffle=shuff,random_state=cvrng))))
            if methods[m]=="ridgecv":
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('lassocv',ElasticNetCV(**opt,cv=KFold(n_splits=bfolds,shuffle=shuff,random_state=cvrng))))
            if methods[m]=="elasticcv":
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('lassocv',ElasticNetCV(**opt,cv=KFold(n_splits=bfolds,shuffle=shuff,random_state=cvrng))))
            if methods[m]=="rf":
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('rf',RandomForestRegressor(**opt)))
            if methods[m]=="gradboost":
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('gbr',GradientBoostingRegressor(**opt)))
            if methods[m]=="svm":
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('svm', SVR(**opt)))
            if methods[m]=="linsvm":    
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('linsvm',LinearSVR(**opt)))
            if methods[m]=="nnet":    
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('mlp',MLPRegressor(**opt)))
            if methods[m]=="xgb":    
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('mlp',xgb.XGBRegressor(**opt)))
        elif type=="class":
            if methods[m]=="logit":
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('logit',LogisticRegression(**opt)))
            if methods[m]=="lassoic":
                sfi.SFIToolkit.stata("di as err lassoic not supported with type(class)")
                sfi.SFIToolkit.error()
            if methods[m]=="lassocv":
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('lassocv',LogisticRegressionCV(**opt,cv=StratifiedKFold(n_splits=bfolds,shuffle=shuff,random_state=cvrng))))
            if methods[m]=="ridgecv":
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('lassocv',LogisticRegressionCV(**opt,cv=StratifiedKFold(n_splits=bfolds,shuffle=shuff,random_state=cvrng))))
            if methods[m]=="elasticcv":
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('lassocv',LogisticRegressionCV(**opt,cv=StratifiedKFold(n_splits=bfolds,shuffle=shuff,random_state=cvrng))))
            if methods[m]=="rf":
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('rf',RandomForestClassifier(**opt)))
            if methods[m]=="gradboost":
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('gradboost',GradientBoostingClassifier(**opt)))
            if methods[m]=="svm":    
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('svm',SVC(**opt)))
            if methods[m]=="linsvm":
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('linsvm',LinearSVC(**opt)))
            if methods[m]=="nnet":    
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('mlp',MLPClassifier(**opt)))
            if methods[m]=="xgb":    
                opt =allopt[m]
                newmethod = build_pipeline(allpipe[m],xvars,allxvar_sel[m])
                newmethod.append(('mlp',xgb.XGBClassifier(**opt)))
        else: 
            sfi.SFIToolkit.stata('di as err "method not known"') 
            #"
            sfi.SFIToolkit.error()
        if prefit=="":
            est_list.append((methods[m]+str(m),Pipeline(newmethod)))
        else:
            est_list.append((methods[m]+str(m),Pipeline(newmethod).fit(x,y)))

    if finalest == "nnls0" and type == "class": 
        fin_est = LinearRegressionClassifier(fit_intercept=False,positive=True)
    elif finalest == "nnls_sk" and type == "class": 
        fin_est = LinearRegressionClassifier(fit_intercept=False,positive=True)
    elif finalest == "nnls1" and type == "class": 
        fin_est = ConstrLSClassifier()
    elif finalest == "ridge" and type == "class": 
        fin_est = LogisticRegression()
    elif finalest == "nnls0" and type == "reg": 
        fin_est = LinearRegression(fit_intercept=False,positive=True)
    elif finalest == "nnls_sk" and type == "reg": 
        fin_est = LinearRegression(fit_intercept=False,positive=True)
    elif finalest == "nnls1" and type == "reg": 
        fin_est = ConstrLS()
    elif finalest == "ridge" and type == "reg": 
        fin_est = RidgeCV()
    elif finalest == "singlebest" and type == "reg": 
        fin_est = SingleBest()
    elif finalest == "ols" and type == "class": 
        fin_est = LinearRegressionClassifier()    
    elif finalest == "ols" and type == "reg": 
        fin_est = LinearRegression()    
    elif finalest == "ls1" and type == "reg":
        fin_est = ConstrLS(unit_interval=False)    
    elif finalest == "ls1" and type == "class":
        fin_est = ConstrLSClassifier(unit_interval=False)    
    else:
        sfi.SFIToolkit.stata('di as err "specified final estimator not supported"')
        #"
        sfi.SFIToolkit.error(198)

    # if single base learner, use voting with weight = 1
    if len(methods)==1:
        voting="voting"
        voteweights=""
        votetype="soft"
        sfi.SFIToolkit.stata('di as text "Single base learner: no stacking done."')
        #"

    if voting=="" and type=="reg":
        model = StackingRegressor(
                       estimators=est_list,
                       final_estimator=fin_est,
                       n_jobs=nj,
                       cv=ccv
                )
    elif voting=="" and type=="class":
        model = StackingClassifier(
                       estimators=est_list,
                       final_estimator=fin_est,
                       n_jobs=nj,
                       cv=ccv
                )
    elif voting!="":
        if voteweights!="":
            vweights = voteweights.split(" ")
            if len(vweights)!=len(methods)-1:
                sfi.SFIToolkit.stata('di as err "numlist in voteweights should be number of base learners - 1"')
                #"
                sfi.SFIToolkit.error(198)                
            vweights = [float(i) for i in vweights]
            vw_sum = sum(vweights)
            if vw_sum>1:
                sfi.SFIToolkit.stata('di as err "sum of voting weights larger than 1."')
                #"
                sfi.SFIToolkit.error(198)
            vweights.append(1-vw_sum)
        else: 
            vweights=None
        if type=="reg":
            model = VotingRegressor(
                           estimators=est_list,
                           n_jobs=nj,
                           weights=vweights
                    )
        else: 
            model = VotingClassifier(
                           estimators=est_list,
                           n_jobs=nj, 
                           voting=votetype,
                           weights=vweights
                    )

    ##############################################################
    ### fitting; save predictions in __main__                  ###
    ##############################################################

    # Train model on training data
    if type=="class":
        y=y!=0
    with parallel_backend(parbackend):
        model = model.fit(x,y)

    # store weights in e()
    if voting=="":
        w = model.final_estimator_.coef_
        if len(w.shape)==1:
            #w=w/sum(w)
            sfi.Matrix.store("e(weights)",w)
        else:
            sfi.Matrix.store("e(weights)",w[0])
    elif vweights!=None: 
        w = np.array(vweights)
        sfi.Matrix.store("e(weights)",w)
    elif voting!="" and votetype=="hard":
        w = np.repeat(np.nan,len(methods))
    else:
        w = np.array([1/len(methods)]*len(methods))
        sfi.Matrix.store("e(weights)",w)
    
    # save candidate learners
    sfi.Macro.setGlobal("e(base_est)"," ".join(methods))  

    __main__.type = type
    __main__.id = id

    if nosavepred=="" or nosavebasexb=="":
        # Track NaNs
        x0_hasnan = np.isnan(x_0).any(axis=1)
        # Set any NaNs to zeros so that model.predict(.) won't crash
        x_0 = np.nan_to_num(x_0)

    if nosavepred == "" or nosavebasexb == "":
        __main__.model_object = model
        __main__.model_xvars = xvars
        __main__.model_methods = methods

    if nosavepred == "" and type =="class":
        try:
            pred = model.predict_proba(x_0)>0.5
            pred_proba = model.predict_proba(x_0)
        except AttributeError:
            pred = model.predict(x_0)
            pred_proba = np.repeat(np.nan,len(pred))
        # Set any predictions that should be missing to missing (NaN)
        pred_proba=pred_proba.astype(np.float32)
        pred_proba[x0_hasnan] = np.nan
        pred=pred.astype(np.float32)
        pred[x0_hasnan] = np.nan
        __main__.predict = pred
        __main__.predict_proba = pred_proba

    if nosavepred == "" and type =="reg":
        pred = model.predict(x_0)
        # Set any predictions that should be missing to missing (NaN)
        pred=pred.astype(np.float32)
        pred[x0_hasnan] = np.nan
        __main__.predict = pred

    if nosavebasexb == "" and (votetype!="hard" or type=="reg"):
        transf = model.transform(x_0)
        nmethods = len(methods)
        ntransf = transf.shape[1]
        if type=="class" and (2*nmethods==ntransf):
            # only use every second column since predicted values for both 0 and 1 are reported
            ncol = transf.shape[1]
            cols=np.linspace(start=1, stop=ncol-1, num=int(ncol/2)).astype(int)
            transf=transf[:,cols]
        elif type=="class" and (nmethods!=ntransf):
            sfi.SFIToolkit.stata('di as err "Internal error. Failed to save base learner predicted probabilities."')
            #"
            sfi.SFIToolkit.error(198)
        # Set any predictions that should be missing to missing (NaN)
        transf=transf.astype(np.float32)
        transf[x0_hasnan] = np.nan
        __main__.transform = transf
        try:
            __main__.cvalid = model.final_estimator_.cvalid
        except AttributeError:
            # values for cvalid unavailable so return array of correct dimension with all NaNs
            cv0 = x.shape[0]
            cv1 = transf.shape[1]
            __main__.cvalid = np.empty((cv0,cv1))*np.nan

    # save versions of Python and packages
    sfi.Macro.setGlobal("e(sklearn_ver)",format(sklearn_version))
    sfi.Macro.setGlobal("e(numpy_ver)",format(numpy_version))
    sfi.Macro.setGlobal("e(scipy_ver)",format(scipy_version))
    sfi.Macro.setGlobal("e(python_ver)",format(sys_version))