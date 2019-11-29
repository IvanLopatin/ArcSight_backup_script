
#!/bin/bash
#run via cron every week at friday in 23:00
echo `date` started
#set arrays
echo "set arrays and Variables"

tables=(user_sequences arc_event_annotation arc_event_annotation_p arc_event_path_info arc_event_payload arc_event_payload_p)
files=(/home/arcsight/.bash_profile /etc/hosts /opt/arcsight/manager/config/server.properties /opt/arcsight/manager/config/database.properties /opt/arcsight/manager/config/server.wrapper.conf /opt/arcsight/manager/config/jetty /opt/arcsight/manager/jre/lib/security/cacerts /opt/arcsight/manager/user/manager/license/arcsight.lic /opt/arcsight/logger/current/arcsight/logger/user/logger/logger.properties /opt/arcsight/logger/data/mysql/my.cnf)
services=(aps execprocsvc logger_httpd logger_servers logger_web manager mysqld postgresql)
services2=(logger_servers manager)

# opredeleinie peremennih
login="arcsight"
corre_password=""
curr_date=`date +"%Y%m%d"`
status=
arcstatus=`/etc/init.d/arcsight_services status`
export_dir=/opt/arcsight/manager/tmp/
exp_sql="arcsight_dump_system_tables.sql"
exp_param="export_system_tables.param"
backup_dir=/backup/

ta=${#tables[@]}
fa=${#files[@]}

SQL="SET group_concat_max_len = 10240; SELECT GROUP_CONCAT(table_name separator ' ') FROM information_schema.tables WHERE table_schema='arcsight' AND (table_name like 'arc_trend%');"
trends=($(/opt/arcsight/logger/current/arcsight/bin/mysql -u$login -p$corre_password arcsight -Bse "$SQL"))
tr_a=${#trends[@]}
srv=${#services[@]}
srv2=srv=${#services2[@]}

echo $login
echo $corre_password
echo $curr_date
echo $status
echo $export_dir
echo $exp_sql
echo $exp_param
echo $backup_dir
echo $ta
echo $fa
echo $SQL
echo $tr_a
echo $srv
echo ${tables[@]}
echo ${files[@]}
echo ${services[@]}
echo ${trends[@]}
echo "$arcstatus"
echo "variables Ok"
echo "set arrays and Variables - ok"



# proverka servisov (exept manager)
#aps service is available
#arcsight_web service is available
#execprocsvc service is available
#logger_httpd service is available
#logger_servers service is available
#logger_web service is available
#manager service is available
#mysqld service is available
#postgresql service is available



for (( sv=0; sv!=$srv; sv++ ))
 do
 status=`echo -e  "$arcstatus" |grep ${services[$sv]}`
  if [ "$status" = "${services[$sv]} service is available" ]
  then echo "service" ${services[$sv]}" started"
  else exit 1
  fi
 done;
unset status

echo "service status Ok"
# ustanovka sostoyaniya  Arcsight Manager
status=`/etc/init.d/arcsight_services status  |grep manager`
echo "manager status" $status
# proverka i ostanovka manager
if [ "$status" = "manager service is initializing" ]; then  while [ "$status" = "manager service is initializing" ]
 do
 unset status
 status=`/etc/init.d/arcsight_services status |grep manager`
 echo $status
 sleep 30
 done
else :
fi
echo "manager not in initializing"

if [ "$status" = "manager service is available_and_initializing" ]; then  while [ "$status" = "manager service is available_and_initializing" ]
 do
 unset status
 status=`/etc/init.d/arcsight_services status |grep manager`
 echo $status
 sleep 30
 done
else :
fi
echo "manager service is not in available_and_initializing"

if [ "$status" = "manager service is available" ]; then /etc/init.d/arcsight_services stop logger_servers 
else :
fi
echo "logger_servers,manager,execprocsvc,logger_web stop"

#udalenie starih failov esli oni est'

for loop in `ls $export_dir`
do
if [ "$loop" = "$exp_sql" ]; then rm -rf $export_dir$exp_sql
 elif [ "$loop" = "$exp_param" ]; then rm -rf $export_dir$exp_param
 else :
fi
done

echo "files removed"

# backup
echo "step 1 - create dir and wait a minute"
#step 1 make dir
mkdir $backup_dir$curr_date
echo "step 1 - done "$date
status=`/etc/init.d/arcsight_services status  |grep logger_servers`
if [ "$status" != "logger_servers service is unavailable" ]; then  while [ "$status" != "logger_servers service is unavailable" ]
 do
  unset status
 status=`/etc/init.d/arcsight_services status  |grep logger_servers`
 #status=`/etc/init.d/arcsight_services status |grep manager`
 echo $status
 sleep 30
 echo "wait 30 sec"
 done
else :
fi

#step 2 create config backup

if [ "$status" = "logger_servers service is unavailable" ]; then /opt/arcsight/logger/current/arcsight/logger/bin/arcsight configbackup
  else logger -i "CEF:0|ArcSight|Logger|1|archive:122|Backup failed|6|msg=Arcsight manager service must be stopped before export system tables cat=/Monitor/Archive/Archival/Failure"  && exit 6
fi
echo "step 2 (config) - done "$date

mkdir $backup_dir$curr_date/config
sleep 5
cp -rp /opt/arcsight/logger/current/arcsight/logger/tmp/configs/configs.tar.gz $backup_dir$curr_date/config
echo "step 2 - done $date"

#step 3 copy files
echo "copy files"
for (( fc=0; fc!=$fa; fc++ ))
 do
 mkdir $backup_dir$curr_date/$fc
 echo "$backup_dir$curr_date/$fc - created"
 cp -rp ${files[$fc]} $backup_dir$curr_date/$fc
 echo "${files[$fc]} - copied to $backup_dir$curr_date/$fc - created"
done;

echo "step 3 - done $date"

#step 4 backup mysql
unset status
status=`/etc/init.d/arcsight_services status |grep manager`
if [ "$status" = "manager service is unavailable" ]; then /opt/arcsight/manager/bin/arcsight export_system_tables $login $corre_password arcsight 
else logger -i "CEF:0|ArcSight|Logger|1|archive:122|Backup failed|6|msg=Arcsight manager service must be stopped before export system tables cat=/Monitor/Archive/Archival/Failure"  && exit 6
fi

#echo "step 4(config) - done " $date
#/opt/arcsight/logger/current/arcsight/bin/mysqldump user_sequences $login $corre_password arcsight gzip > $backup_dir$curr_date/user_sequences.sql.gz

for (( tc=0; tc!=$ta; tc++ ))
 do
 /opt/arcsight/logger/current/arcsight/bin/mysqldump -u$login -p$corre_password arcsight ${tables[$tc]} |gzip > $backup_dir$curr_date/${tables[$tc]}.sql.gz 
echo "step 4 backup table" ${tables[$tc]} "done" 
done;
#echo "step 4 - done " $date
#step 5  export trends

for (( tr_c=0; tr_c!=$tr_a; tr_c++ ))
 do
 /opt/arcsight/logger/current/arcsight/bin/mysqldump -u$login -p$corre_password arcsight ${trends[$tr_c]} |gzip > $backup_dir$curr_date/${trends[$tr_c]}.sql.gz
echo "step 5 backup table" ${trends[$tr_c]} "done" 
done;
echo "step 5 - done "$date
#step 6 backup index (pgsql)

/opt/arcsight/logger/current/arcsight/bin/pg_dump -d rwdb -c -n data -U web | gzip -9 -v > $backup_dir$curr_date/postgres_data.sql.gz
echo "step 6 - done $date"

# kopirovanie v papku
#mkdir $backup_dir$curr_date
cp -rp $export_dir$exp_sql $backup_dir$curr_date
cp -rp $export_dir$exp_param $backup_dir$curr_date
echo "copy done" $date

#proverka nalichiya kopiy
if [ -f "$backup_dir$curr_date/$exp_sql" ] && [ -f "$backup_dir$curr_date/$exp_param" ]
then cd $backup_dir && tar -czf $HOSTNAME.$curr_date.tgz $curr_date
 else logger -i "CEF:0|ArcSight|Logger|1|archive:122|Backup archive failed|6|msg=File $exp_sql or $exp_param  not copied in $backup_dir$curr_date/ folder  cat=/Monitor/Archive/Archival/Failure" && exit 7
fi
echo "archived" $date
if [ -f "$backup_dir$HOSTNAME.$curr_date.tgz" ]
then logger -i "CEF:0|ArcSight|Logger|1|archive:120|Backup archived|1|msg=Arcsight backup finished cat=/Monitor/Archive/Archival/Success" && cd $backup_dir && rm -rf $curr_date
else logger -i "CEF:0|ArcSight|Logger|1|archive:122|Backup archive failed|6|msg=Archive not completed folder  cat=/Monitor/Archive/Archival/Failure" && exit 8
fi

# zapusk manager
unset status
status=`/etc/init.d/arcsight_services status |grep manager`
if [ "$status" = "manager service is unavailable" ]; then /etc/init.d/arcsight_services start && sleep 30
else :
fi
#echo "manager started" $date
unset status
status=`/etc/init.d/arcsight_services status |grep manager`
if [ "$status" != "manager service is available_and_initializing" ]
then while [ "$status" != "manager service is available" ]
 do
 unset status
 status=`/etc/init.d/arcsight_services status |grep manager`
 echo $status
 sleep 30
 done
else :
fi

#unset all varialbes
unset login
unset corre_password
unset curr_date
unset status
unset export_dir
unset exp_sql
unset exp_param
unset backup_dir
unset ta
unset fa
unset SQL
unset tr_a
unset srv
unset tables
unset files
unset services
unset trends

echo `date` "unset all. Exit"
#logger -i "CEF:0|ArcSight|Logger|1|archive:100|Backup success|1|msg=Arcsight backup finished cat=/Monitor/Archive/Archival/Success"
exit 0
