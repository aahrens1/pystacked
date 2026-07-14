# kahrens@gess-rz-dock-1-a-0367 ~ % which python3
#/usr/local/bin/python3 
#python3 -m venv python_envs/sk121
#kahrens@gess-rz-dock-1-a-0367 ~ % source python_envs/sk121/bin/activate
#(sk121) kahrens@gess-rz-dock-1-a-0367 ~ % python3 -m pip install scikit-learn==1.2.1
#(sk121) kahrens@gess-rz-dock-1-a-0367 ~ % deactivate
export PATH=$PATH:/Applications/StataNow/StataSE.app/Contents/MacOS/
stata-se -b do cs_pystacked_runall.do 130 & 
stata-se -b do cs_pystacked_runall.do 140 & 
#stata-se -b do cs_pystacked_runall.do 152 &
#stata-se -b do cs_pystacked_runall.do 160 &
#stata-se -b do cs_pystacked_runall.do 170 &
#stata-se -b do cs_pystacked_runall.do 172 &
#stata-se -b do cs_pystacked_runall.do 180 &
#stata-se -b do cs_pystacked_runall.do 190 &
wait
