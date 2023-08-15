#!/bin/bash
user=root
tenant=sys
cluster=allen
port=2883
password=$password
host=10.186.64.161
db=oceanbase

cluster_info="cluster:$cluster|user:$user|tenant:$tenant|port:$port|host:$host|db:$db"

clear_files(){
if [ ! -d "/tmp/observer_parameters" ]; then
  mkdir /tmp/observer_parameters
else
    	cd /tmp/observer_parameters
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

    obclient -h$host -P$port -u$user@$tenant#$cluster -p$password -D$db -vvv -NBe '
	select concat(cluster_name, "_",cluster_id) from oceanbase.v$ob_cluster;
	show parameters;' > /tmp/observer_parameters/all_parameters.csv
else

    	echo "exit after login OBServer"
	exit 2

fi
}


modify_files(){
if [ $? -eq 0 ]; then

	cd /tmp/observer_parameters
	##获取集群名和id用于文件命名
	sed -n 6p all_parameters.csv > name_middle.txt
	sed 's/|//g'  name_middle.txt > no_line.txt
	sed 's/ //g' no_line.txt > no_space.txt
	new_name=`cat no_space.txt`

	##以集群名和ID进行文件命名
	mv all_parameters.csv $new_name.csv
	sed -i '1,14d' $new_name.csv
	awk -F'|' '{print $2,$4,$5,$6,$8}' $new_name.csv > $new_name.modified_$(date +%Y-%m-%d_%H:%M:%S).csv
	file_name=`ls | grep modified`
	sed -i "1i $cluster_info" /tmp/observer_parameters/$file_name
	echo -e "please download /tmp/observer_parameters/$file_name"
else

        echo "Failed to get OBServer parameters, now exit"
        exit 2

fi
}


main() {
	clear_files
	get_parameters
	modify_files
} 

main $@
