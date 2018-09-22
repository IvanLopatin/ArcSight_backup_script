#!/bin/bash
#ArcSight ESM 6.11 FULL Backup
BASE_PATH="/opt/arcsight"
ARCSIGHT_MANAGER_BIN="/opt/arcsight/manager/bin"
ARCSIGHT_MANAGER_TMP="/opt/arcsight/manager/tmp"
BACKUP_DIR="/opt/arcsight/logger/data/archives/backups/ArcSight_Backup"
HOST=$(hostname)
# FAILED_MSG="ArcSight Express ($HOSTNAME) System Table Export Failed!" # Used as                                                                                                                                                            the subject of the email sent to the recipients if the script fails.
# SUCCESSFUL_MSG="ArcSight Express ($HOSTNAME) System Tables Export Completed Succ                                                                                                                                                           essfully" # Used as the subject of the email sent to the recipients if the script                                                                                                                                                            succeeds.
# RECIPIENTS="(EMAIL OR ALERT HERE)" # email recipients. Use a space when specifyi                                                                                                                                                           ng multiple email addresses.
SCRIPT_TIME=`date +%m-%d-%Y-%H.%M`
SCRIPT_TIME_CEF=`date '+%b %d %H:%M:%S'`
BACKUP_FILENAME="$BACKUP_DIR/arcsight_system_tables_${HOST}_$SCRIPT_TIME.tar.gz"
BACKUP_SINGLE_FILENAME="${BACKUP_DIR}_${HOST}_$SCRIPT_TIME.tar"
EXPORT_LOG='/opt/arcsight/manager/logs/default/backup.log' # Log file that contain                                                                                                                                                           s the results of this script
MYSQL_PASS=""

  # paragraph 3 (Technical Note: CORR-Engine Backup and Recovery)
function backup_specialfiles {
  FILELIST="/home/arcsight/.bash_profile $BASE_PATH/logger/data/mysql/my.cnf /etc/                                                                                                                                                           hosts $BASE_PATH/manager/config/server.properties $BASE_PATH/manager/config/databa                                                                                                                                                           se.properties $BASE_PATH/logger/current/arcsight/logger/user/logger/logger.propert                                                                                                                                                           ies $BASE_PATH/manager/config/server.wrapper.conf $BASE_PATH/manager/config/jetty                                                                                                                                                            $BASE_PATH/manager/jre/lib/security/cacerts $BASE_PATH/manager/user/manager/licens                                                                                                                                                           e/arcsight.lic $BASE_PATH/manager/config/keystore* $BASE_PATH/manager/config/notif                                                                                                                                                           ication $BASE_PATH/manager/i18n $BASE_PATH/manager/config/caseui.xml /etc/sysctl.d                                                                                                                                                           /*.conf"
  tar -Pjcf $BACKUP_DIR/specialfiles.tar.bz2 $FILELIST
}

  # paragraph 5 (Technical Note: CORR-Engine Backup and Recovery)
function backup_specialtables {
for TABLE in user_sequences arc_event_annotation arc_event_annotation_p arc_event_                                                                                                                                                           payload arc_event_payload_p arc_event_p arc_event_path_info
do
$BASE_PATH/logger/current/arcsight/bin/mysqldump --single-transaction -uarcsight -                                                                                                                                                           p${MYSQL_PASS} arcsight ${TABLE} | gzip > $BACKUP_DIR/${TABLE}.sql.gz
done
}

# paragraph 7 (Technical Note: CORR-Engine Backup and Recovery)
function backup_logger_configuration {
#sed -i 's/DATABASEPASSWORD=arcsight/DATABASEPASSWORD=ebTmSqCQSd' $BASE_PATH/logge                                                                                                                                                           r/current/arcsight/logger/bin/scripts/configbackup.sh
$BASE_PATH/logger/current/arcsight/logger/bin/arcsight configbackup
mv /opt/arcsight/logger/current/arcsight/logger/tmp/configs/configs.tar.gz $BACKUP                                                                                                                                                           _DIR
}

  # paragraph 6 (Technical Note: CORR-Engine Backup and Recovery)
function backup_trends {
  SQL="SET group_concat_max_len = 10240; SELECT GROUP_CONCAT(table_name separator                                                                                                                                                            ' ') FROM information_schema.tables WHERE table_schema='arcsight' AND (table_name                                                                                                                                                            like 'arc_trend%');"
  TBLIST=`$BASE_PATH/logger/current/arcsight/bin/mysql -u arcsight -p${MYSQL_PASS}                                                                                                                                                            -AN -e "${SQL}"`
  $BASE_PATH/logger/current/arcsight/bin/mysqldump --single-transaction -u arcsigh                                                                                                                                                           t -p${MYSQL_PASS} arcsight ${TBLIST} > $BACKUP_DIR/arcsight_trends.sql
  gzip $BACKUP_DIR/arcsight_trends.sql
}

function backup_systemparameters {
  # paragraph 7 (Technical Note: CORR-Engine Backup and Recovery)
  # Make a note of the following: which must match exactly on the machine to which                                                                                                                                                            you restore:
  # Operating system and version; Hostname; File system type; Path to the archive                                                                                                                                                            locations for each storage group; ESM version; MySQL password
  TEXTFILE="$BACKUP_DIR/sysparams.txt"
  echo "" > $TEXTFILE
  echo "==========================================================================                                                                                                                                                           ================================================================================="                                                                                                                                                            >>$TEXTFILE
  echo "=============================================================== Operating                                                                                                                                                            system and version =============================================================="                                                                                                                                                            >>$TEXTFILE
  echo "==========================================================================                                                                                                                                                           ================================================================================="                                                                                                                                                            >>$TEXTFILE
  uname -a >> $TEXTFILE
  cat /etc/redhat-release >> $TEXTFILE
  echo "==========================================================================                                                                                                                                                           ================================================================================="                                                                                                                                                            >>$TEXTFILE
  echo "============================================================ Computer doma                                                                                                                                                           in name and hostname ============================================================"                                                                                                                                                            >>$TEXTFILE
  echo "==========================================================================                                                                                                                                                           ================================================================================="                                                                                                                                                            >>$TEXTFILE
  echo $HOST >> $TEXTFILE
  echo "==========================================================================                                                                                                                                                           ================================================================================="                                                                                                                                                            >>$TEXTFILE
  echo "======================================== File system type and Path to the                                                                                                                                                            archive locations for each storage group ========================================"                                                                                                                                                            >>$TEXTFILE
  echo "==========================================================================                                                                                                                                                           ================================================================================="                                                                                                                                                            >>$TEXTFILE
  cat /proc/mounts >> $TEXTFILE
  echo "==========================================================================                                                                                                                                                           ================================================================================="                                                                                                                                                            >>$TEXTFILE
  echo "======================================================================= ES                                                                                                                                                           M version ======================================================================="                                                                                                                                                            >>$TEXTFILE
  echo "==========================================================================                                                                                                                                                           ================================================================================="                                                                                                                                                            >>$TEXTFILE
  $BASE_PATH/manager/bin/arcsight version >> $TEXTFILE
  echo "==========================================================================                                                                                                                                                           ================================================================================="                                                                                                                                                            >>$TEXTFILE
  echo "===================================================================== MySQ                                                                                                                                                           L password ======================================================================"                                                                                                                                                            >>$TEXTFILE
  echo "==========================================================================                                                                                                                                                           ================================================================================="                                                                                                                                                            >>$TEXTFILE
  echo "$MYSQL_PASS" >> $TEXTFILE
  echo "==========================================================================                                                                                                                                                           ================================================================================="                                                                                                                                                            >>$TEXTFILE
  echo "================================================================ Timezone                                                                                                                                                            of the machine =================================================================="                                                                                                                                                            >>$TEXTFILE
  echo "==========================================================================                                                                                                                                                           ================================================================================="                                                                                                                                                            >>$TEXTFILE
  date +'%:z %Z' >> $TEXTFILE
  echo "=========================================================================                                                                                                                                                            END ============================================================================="                                                                                                                                                            >>$TEXTFILE
}

# function backup_eventarchives {
  # paragraph 8 (Technical Note: CORR-Engine Backup and Recovery)
        # mkdir $NETWORK_DIR/archives
        #cp -R $BASE_PATH/logger/data/archives/* $NETWORK_DIR/archives/
  # If you cannot afford to lose events that occurred since midnight, when the las                                                                                                                                                           t archive was
  # created, back up $BASE_PATH/logger/data/logger. However, in addition to the un                                                                                                                                                           -archived
  # data since midnight, you also get events from each day from yesterday to the b                                                                                                                                                           eginning of your
  # retention period, which are also in the archives.
  # $BASE_PATH/logger/current/arcsight/bin/pg_dump -d rwdb -c -n data -U web |gzip                                                                                                                                                            -9 -v > /tmp/postgres_data.sql.gz
# }

function create_single_file {
  # No need to zip it again, since everything that can be zipped is already zipped
  echo "Tar single file:" | tee -a $EXPORT_LOG | logger
  tar -vPcf $BACKUP_SINGLE_FILENAME $BACKUP_DIR | tee -a $EXPORT_LOG
  rm -rf $BACKUP_DIR
}
##################################################################################                                                                                                                                                           ##########

# Creates the script log file
echo "============================== `date` ==================================" >                                                                                                                                                            $EXPORT_LOG

# Checks if backup directory exists, if not, the directory is created.
if [ ! -d $BACKUP_DIR ]
then
echo "$BACKUP_DIR directory does not exist, creating..." | tee -a $EXPORT_LOG
mkdir -p $BACKUP_DIR
fi

# Exports mysql system tables and replaces the username and password used in the s                                                                                                                                                           cript with a hyphen so that it doesnt show in the logs.
$ARCSIGHT_MANAGER_BIN/arcsight export_system_tables arcsight $MYSQL_PASS arcsight                                                                                                                                                            -s | tee -a $EXPORT_LOG
# | sed -r 's/mysql\_(password|username): [a-zA-Z0-9\S]+?/-/g' | tee -a $EXPORT_LO                                                                                                                                                           G

#EXPORT_FAILED=`grep -o FAILED $EXPORT_LOG`

# Checks if the word "failed" exists in the script's log, if it does, script sends                                                                                                                                                            a notification email to the recipients and exits with an exit status of 321.
#if [ "$EXPORT_FAILED" == "FAILED" ]
#then
#echo "ArcSight System Tables export FAILED" | tee -a $EXPORT_LOG
# mail -s "$FAILED_MSG" $RECIPIENTS < $EXPORT_LOG
#exit 321
#fi

echo "Moving System Tables to `echo $BACKUP_FILENAME`" | tee -a $EXPORT_LOG
# Compresses and moves the export files from /opt/arcsight/manager/tmp to /opt/arc                                                                                                                                                           sight/logger/data/archives/arcsight_system_tables.
mv $ARCSIGHT_MANAGER_TMP/arcsight_dump_system_tables.sql $ARCSIGHT_MANAGER_TMP/arc                                                                                                                                                           sight_dump_system_tables_$SCRIPT_TIME.sql
mv $ARCSIGHT_MANAGER_TMP/export_system_tables.param $ARCSIGHT_MANAGER_TMP/export_s                                                                                                                                                           ystem_tables_$SCRIPT_TIME.param
tar --remove-files -zcf $BACKUP_FILENAME -C $ARCSIGHT_MANAGER_TMP ./{arcsight_dump                                                                                                                                                           _system_tables_$SCRIPT_TIME.sql,export_system_tables_$SCRIPT_TIME.param}

# Verifies that there are two files in the tar file, if it fails, script sends a n                                                                                                                                                           otification email to the recipients and exits with an exit status of 322.
BACKUP_FILE_COUNT=`tar -tf $BACKUP_FILENAME | wc -l`
if [ "$BACKUP_FILE_COUNT" -eq 2 ]
then
echo "ArcSight System Tables export DONE" | tee -a $EXPORT_LOG
else
echo "ArcSight System Tables export FAILED" | tee -a $EXPORT_LOG
# mail -s "$FAILED_MSG" $RECIPIENTS < $EXPORT_LOG
exit 322
fi

backup_specialfiles
backup_specialtables
backup_trends
backup_systemparameters
backup_logger_configuration
# backup_eventarchives
create_single_file

#### Check if tar exist and contains 13 files#####
BACKUP_FILE_COUNT2=`tar -Ptf $BACKUP_SINGLE_FILENAME | wc -l`
if [ -e $BACKUP_SINGLE_FILENAME ] && [ "$BACKUP_FILE_COUNT2" -eq 13 ]
then
    echo "Backup DONE at `echo $SCRIPT_TIME path $BACKUP_SINGLE_FILENAME`" | tee -                                                                                                                                                           a $EXPORT_LOG
    echo "`echo $SCRIPT_TIME_CEF $HOST` CEF:0|ArcSight|Logger|1|archive:100|Backup                                                                                                                                                            success|1|msg=Arcsight backup finished in folder `echo $BACKUP_SINGLE_FILENAME`"                                                                                                                                                            | tee -a /opt/elk/log/archives/archive_status.log
    echo "CEF:0|ArcSight|Logger|1|archive:100|Backup success|1|msg=Arcsight backup                                                                                                                                                            finished in folder `echo $BACKUP_SINGLE_FILENAME`" | logger
else
    echo "Backup FAILED at `echo $SCRIPT_TIME path $BACKUP_SINGLE_FILENAME`" | tee                                                                                                                                                            -a $EXPORT_LOG
    echo "`echo $SCRIPT_TIME_CEF $HOST` CEF:0|ArcSight|Logger|1|archive:122|Backup                                                                                                                                                            archive failed|6|msg=Archive not completed in folder `echo $BACKUP_SINGLE_FILENAM                                                                                                                                                           E`" | tee -a /opt/elk/log/archives/archive_status.log
    echo "CEF:0|ArcSight|Logger|1|archive:122|Backup archive failed|6|msg=Archive                                                                                                                                                            not completed in folder `echo $BACKUP_SINGLE_FILENAME`" | logger
    exit 8
fi

# Sends notification email to recipients upon completion
# mail -s "$SUCCESSFUL_MSG" $RECIPIENTS < $EXPORT_LOG

######### Mount n Move ##########
#if mount | grep /mnt/<host> > /dev/null; then
#    cp $BACKUP_SINGLE_FILENAME /mnt/<host1>/
#else
#    mount -t nfs host:/opt/backup /mnt/<host1>
#    cp $BACKUP_SINGLE_FILENAME /mnt/<host1>/
#fi

