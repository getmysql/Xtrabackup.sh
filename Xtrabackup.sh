#!/bin/bash -x
#By- Alok Kumar Singh @ www.getmysql.info
#Scheduling Daily Full Backup from Production/Backup Server using Xtrabackup without any table lock or any hamper on production during backup.      #Version- 1.2v


HOSTIP="191.168.1.100"
emails="query@getmysql.info alok@getmysql.info" ## add multiple email with space
BACKUP_DIR=/home/alok/DailyFullXtraBackup ##this directory must be created with 777 privileges
DATA_DIR=/var/lib/mysql
BACKUP_LOG=/home/alok/backup.log
USER_ARGS=" --user=user --password=password"
DATETIME=$(date +%y%m%d:"%T.%3N")
BAKFOLDER=$BACKUP_DIR/Backup_$(date +%Y%m%d)
TMPFILE="/tmp/XtraBackup-$(date +%y%m%d"%T").$$.tmp"
MailsubjectFAIL="Error-MySQL:DailyFullXtraBackup job Failed on $HOSTIP"
MailsubjectOK="OK-MySQL:DailyFullXtraBackup job Successful on $HOSTIP"

         echo "$DATETIME :: Full backup requesting" >> $BACKUP_LOG
         echo "$DATETIME :: Checking backup dir" >> $BACKUP_LOG
         date
         if [ ! -d $BACKUP_DIR ]
         then
         echo "$DATETIME :: ERROR: the folder $BACKUP_DIR does not exists" >> $BACKUP_LOG
  ERRMSG="DailyFullXtraBackup Job on server $HOSTIP has been failed."$'\n'""$'\n'"Reason:  ERROR: the folder $BACKUP_DIR does not exists"
  for address in $emails; do
  echo -e $ERRMSG | mail -s "$MailsubjectFAIL" $address
         done
         exit 1
         fi
  if [ -f $BAKFOLDER.tgz ]
         then
         echo "$DATETIME :: ERROR: one backup ($BAKFOLDER) already exist for current day. Rename/delete it before execute new one." >> $BACKUP_LOG
         ERRMSG="DailyFullXtraBackup Job on server $HOSTIP has been failed."$'\n'""$'\n'"Reason: ERROR: one backup ($BAKFOLDER) already exist for current day. Rename/delete it before execute new one."
  for address in $emails; do
  echo -e $ERRMSG | mail -s "$MailsubjectFAIL" $address
         done
  exit 1
  else
  mkdir $BAKFOLDER
         chmod -R 777 $BAKFOLDER
  echo "$DATETIME :: Backup folder created  $BAKFOLDER ..." >> $BACKUP_LOG
         fi
   
        date
        echo "$DATETIME :: Found backup directory $BAKFOLDER" >> $BACKUP_LOG
        echo "$DATETIME :: Starting backup in progress..." >> $BACKUP_LOG
        sudo xtrabackup $USER_ARGS --backup --no-timestamp --target-dir=$BAKFOLDER > $TMPFILE 2>&1
        if [ -z "`tail -1 $TMPFILE | grep 'completed OK!'`" ] ; then
        echo "$DATETIME :: ERROR:Backup Failed in execution time." >> $BACKUP_LOG
    
        ERRMSG="DailyFullXtraBackup Job on server $HOSTIP has been failed."$'\n'""$'\n'"Reason: ERROR:Backup Failed in execution time."
 for address in $emails; do
 echo -e $ERRMSG | mail -s "$MailsubjectFAIL" $address
 done
 cat $TMPFILE
 rm -f $TMPFILE
 exit 1
        fi
        echo "$DATETIME :: Backup done as $BAKFOLDER" >> $BACKUP_LOG
 cat $TMPFILE
        rm -f $TMPFILE
##preparing backup
 echo "$DATETIME :: Backup preparation started..." >> $BACKUP_LOG
 sudo xtrabackup $USER_ARGS --prepare --no-timestamp --target-dir=$BAKFOLDER > $TMPFILE 2>&1
 if [ -z "`tail -1 $TMPFILE | grep 'completed OK!'`" ] ; then
        echo "$DATETIME :: ERROR:Preparation Failed" >> $BACKUP_LOG
        ERRMSG="DailyFullXtraBackup Job on server $HOSTIP has been failed."$'\n'""$'\n'"Reason: ERROR:Backup has been done but Backup Preparation Failed."
 for address in $emails; do
 echo -e $ERRMSG | mail -s "$MailsubjectFAIL" $address
        done
 cat $TMPFILE
        rm -f $TMPFILE
        exit 1
        fi
    
        echo "$DATETIME :: Preparation done as $BAKFOLDER" >> $BACKUP_LOG

## Compress Backup 
        cd $BACKUP_DIR && sudo tar --create --gzip --file=Backup_$(date +%Y%m%d).tgz Backup_$(date +%Y%m%d) --remove-files 
## to Uncompress use  tar -xzvf FILENAME.tgz
        echo "$DATETIME :: Compress Successful as $BAKFOLDER.tgz" >> $BACKUP_LOG
   
        ERRMSG="DailyFullXtraBackup Job on server $HOSTIP has been Successful ."$'\n'""$'\n'"Backup Path: $BAKFOLDER.tgz"
 for address in $emails; do
 echo -e $ERRMSG | mail -s "$MailsubjectOK" $address
        done
        cat $TMPFILE
        rm -f $TMPFILE
    