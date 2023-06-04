screen_name="speederv2_amd64"                
screen -dmS $screen_name
cmd="/root/udpspeeder/speederv2_amd64 -s -l0.0.0.0:28900 -r127.0.0.1:7777 -f2:4 -k "passwd" --mode 0 -q1 &"            
screen -x -S $screen_name -p 0 -X stuff "$cmd"    
screen -x -S $screen_name -p 0 -X stuff $'\n' 
