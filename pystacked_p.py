#! pystacked v0.7
#! last edited: 6mar2023
#! authors: aa/ms


# Import SFI, always with stata 16
from sfi import Data,Matrix,Scalar,Macro
from sfi import SFIToolkit
import numpy as np

def post_prediction(pred_var,basexb,cvalid,var_type,touse,pred_type):

	# Start with a working flag
	Scalar.setValue("r(import_success)", 1, vtype='visible')

	# Import model from Python namespace
	try:
		from __main__ import model_object as model
		from __main__ import model_xvars as xvars
		from __main__ import model_methods as methods
		from __main__ import id as id
		from __main__ import type as type
	except ImportError:
		print("Error: Could not find pystacked estimation results.")
		Scalar.setValue("r(import_success)", 0, vtype='visible')
		return

	touse = np.array(Data.get(touse))

	if type=="class" and pred_type=="":
		pred_type="pr"
	elif type=="reg" and pred_type=="":
		pred_type="xb"
	elif type=="class" and pred_type=="xb":
		SFIToolkit.stata('di as err "xb/resid not supported with classification"')
		#"
		SFIToolkit.error(198)
	elif type=="reg" and pred_type=="class":
		SFIToolkit.stata('di as err "class not supported with regression"')
		#"
		SFIToolkit.error(198)		
	elif type=="reg" and pred_type=="pr":
		SFIToolkit.stata('di as err "pr not supported with regression"')
		#"
		SFIToolkit.error(198)	

	if basexb=="" and cvalid=="":
		# stacked prediction
		if type=="class" and pred_type == "pr":
			from __main__ import predict_proba as pred
			if pred.ndim>1:
				pred=pred[:,1]
		elif type=="class" and pred_type == "class":
			from __main__ import predict as pred
			if pred.ndim>1:
				pred=pred[:,1]
		else: 
			from __main__ import predict as pred
		pred[touse==0] = np.nan
		Data.store(var=pred_var,val=pred,obs=None)

	elif basexb!="" and cvalid=="":
		# learner predictions
		from __main__ import transform as transf
		if len(methods)==1:
			SFIToolkit.stata('di as err "basexp not supported with only one learner"')
			#"
			SFIToolkit.error(198)
		ncol = transf.shape[1]
		for j in range(ncol):
			if var_type == "double":
				Data.addVarDouble(pred_var+str(j+1))
			else: 
				Data.addVarFloat(pred_var+str(j+1))
			pred=transf[:,j]
			predna =np.isnan(pred)
			if pred_type=="class":
				pred=(pred>0.5)*1 
				pred=pred.astype(float)
				pred[predna]=np.nan
				Data.setVarLabel(pred_var+str(j+1),"Predicted class "+" "+methods[j])
			elif type=="class":
				Data.setVarLabel(pred_var+str(j+1),"Predicted probability "+" "+methods[j])
			else:
				Data.setVarLabel(pred_var+str(j+1),"Predicted value"+" "+methods[j])
			Data.store(var=pred_var+str(j+1),val=pred,obs=None)

	elif basexb!="" and cvalid!="":
		if len(methods)==1:
			SFIToolkit.stata('di as err "cvalid not supported with only one learner"')
			#"
			SFIToolkit.error(198)
		# learner cross-validated predictions
		try:  
			from __main__ import cvalid as transf
			if np.isnan(transf).all():
				SFIToolkit.stata('di as res "Warning: cvalid option not available with selected final estimator;"')
				SFIToolkit.stata('di as res "         cross-validated predicted values are set to missing"')
		except ImportError:
			SFIToolkit.stata('di as err "Error: Could not find cross-validated predicted values."')
			#"
			SFIToolkit.error(198)
			return
		id = id -1
		id = id.tolist()
		ncol = transf.shape[1]
		for j in range(ncol):
			if var_type == "double":
				Data.addVarDouble(pred_var+str(j+1))
			else: 
				Data.addVarFloat(pred_var+str(j+1))
			pred=transf[:,j]
			predna =np.isnan(pred)
			Data.setVarLabel(pred_var+str(j+1),"Predicted value"+" "+methods[j])
			Data.store(var=pred_var+str(j+1),val=pred,obs=id)