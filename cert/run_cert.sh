# kahrens@gess-rz-dock-1-a-0367 ~ % which python3
#/usr/local/bin/python3 
#python3 -m venv python_envs/sk121
#kahrens@gess-rz-dock-1-a-0367 ~ % source python_envs/sk121/bin/activate
#(sk121) kahrens@gess-rz-dock-1-a-0367 ~ % python3 -m pip install scikit-learn==1.2.1
#(sk121) kahrens@gess-rz-dock-1-a-0367 ~ % deactivate
export PATH=$PATH:/Applications/Stata\ 17/StataSE.app/Contents/MacOS/
StataSE -b do cs_pystacked_runall.do 024 &
StataSE -b do cs_pystacked_runall.do 102 &
StataSE -b do cs_pystacked_runall.do 113 &
StataSE -b do cs_pystacked_runall.do 121 &
