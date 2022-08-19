*! pystacked v0.4.3
*! last edited: 18Aug2022
*! authors: aa/ms

program define pystacked_p, rclass
	version 16.0
	syntax namelist(min=1 max=2) [if] [in], [ ///
															pr /// 
															xb /// 
															Resid /// 
															class /// 
															TRANSForm ///
															force ///
															]
	
	if ("`force'"=="") {
		qui datasignature report
		//return list
		if (`r(changed)'!=0) {
			di as err "error: data in memory has changed since last -pystacked- call"
			di as err "you are not allowed to change data in memory between -pystacked- fit and -predict-"
			exit 198
		}
	} 

	if ("`resid'"!="") local xb xb

	local command=e(cmd)
	if ("`command'"~="pystacked") {
		di as err "error: -pystacked_p- supports only the -pystacked- command"
		exit 198
	}
	*

	local depvar `e(depvar)'

	tokenize `namelist'
	if "`2'"=="" {					//  only new varname provided
		local predictvar `1'
	}
	else {							//  datatype also provided
		local vtype `1'
		local predictvar `2'
	}
	*

	marksample touse, novarlist

	if "`transform'"=="" {
		qui gen `vtype' `predictvar' = .
	}
	
	* Get predictions
	python: post_prediction("`predictvar'","`transform'","`vtype'","`touse'","`pr'`xb'`class'")
	
	if "`resid'"!="" {
		replace `predictvar' = `depvar' - `predictvar' if `touse'
	}
	
end

python:

# Import SFI, always with stata 16
from sfi import Data,Matrix,Scalar,Macro
from sfi import SFIToolkit
import numpy as np

def post_prediction(pred_var,transform,var_type,touse,pred_type):

	# Start with a working flag
	Scalar.setValue("r(import_success)", 1, vtype='visible')

	# Import model from Python namespace
	try:
		from __main__ import model_object as model
		from __main__ import model_xvars as xvars
		from __main__ import model_methods as methods
		from __main__ import type as type
	except ImportError:
		print("Error: Could not find pystacked estimation results.")
		Scalar.setValue("r(import_success)", 0, vtype='visible')
		return

	touse = np.array(Data.get(touse))

	if type=="class" and pred_type=="":
		pred_type="pr"
	elif type=="class" and pred_type=="xb":
		SFIToolkit.stata('di as err "xb/resid not supported with classification"')
		#"
		SFIToolkit.error(198)

	if transform=="":
		if type=="class" and pred_type == "pr":
			from __main__ import predict_proba as pred
			if pred.ndim>1:
				pred=pred[:,1]
		elif type=="class" and (pred_type == "" or pred_type == "class"):
			from __main__ import predict as pred
			if pred.ndim>1:
				pred=pred[:,1]
		else: 
			from __main__ import predict as pred
		pred[touse==0] = np.nan
		Data.store(var=pred_var,val=pred,obs=None)
	else:
		from __main__ import transform as transf
		ncol = transf.shape[1]
		for j in range(ncol):
			if var_type == "double":
				Data.addVarDouble(pred_var+str(j+1))
			else: 
				Data.addVarFloat(pred_var+str(j+1))
			transf[touse==0,j]=np.nan
			Data.setVarLabel(pred_var+str(j+1),"Prediction"+" "+methods[j])
			if pred_type=="class":
				Data.store(var=pred_var+str(j+1),val=transf[:,j]>0.5,obs=None)
			else: 
				Data.store(var=pred_var+str(j+1),val=transf[:,j],obs=None)

end