#!/bin/bash
user=root
tenant=test_mysql
cluster=allen
port=2883
password=$password
host=10.186.64.161
db=oceanbase

cluster_info="cluster:$cluster|user:$user|tenant:$tenant|port:$port|host:$host"

clear_files(){
if [ ! -d "/tmp/observer_var" ]; then
  mkdir /tmp/observer_var
else
    	cd /tmp/observer_var
    	tmp_file=`ls | grep -E '*.csv|*.txt'`
	if [ $? -eq 0 ]; then
		mkdir observer_bak$(date +%Y-%m-%d_%H:%M:%S)
        	filename=`ls -t |head -n1|awk '{print $0}'`
        	##将旧文件mv到新建的文件夹
    		mv $tmp_file $filename
	else 
		echo "no files need to move or move files failed"
	fi
fi
}


get_parameters(){
if [ $? -eq 0 ]; then

	obclient -h$host -P$port -u$user@$tenant#$cluster -p$password -D$db -t -NBe '
	show variables;\q' > /tmp/observer_var/all_variables.csv
else

    	echo "exit after login OBServer"
	exit 2

fi
}


modify_files(){
if [ $? -eq 0 ]; then

	cd /tmp/observer_var
	new_name=$cluster
	mv all_variables.csv $new_name.csv      

	##下面三个参数包含逗号，会使格式乱掉，独自输出到一个文件
	grep -E 'session_track_system_variables|sql_mode|version_comment' $new_name.csv >> $new_name.additional_var.csv
	sed -i '/session_track_system_variables/d' $new_name.csv
	sed -i '/sql_mode/d' $new_name.csv
	sed -i '/version_comment/d' $new_name.csv
	 
	awk -F'|' '{print $2,$3,$4}' $new_name.csv > $new_name.variables_$(date +%Y-%m-%d_%H:%M:%S).csv
	file_name=`ls | grep variables`
	sed -i "1i $cluster_info" /tmp/observer_var/$file_name
	echo -e "please download /tmp/observer_var/$file_name  and /tmp/observer_var/$new_name.additional_var.csv"
else

        echo "Failed to get OBServer variables, now exit"
        exit 2

fi
}


main() {
	clear_files
	get_parameters
	modify_files
} 

main $@
