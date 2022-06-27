#!/bin/bash
##Assigning the Config file##
. /app/etl/p3/scripts/p3.cfg

p_SUB_AREA_NM=$1

v_USER_ETL=$DB_USER_CTL
v_PSSWD_ETL=$DB_PASSWORD_CTL
v_SRVR=$DB_SERVER
v_PWD=`. $SCRIPT_PATH/decrypt_password.ksh $DECRYPT_PASSPHRASE_CTL $DB_PASSWORD_CTL`
v_LOG_FILE=$LOG_PATH/"$p_INTERFACE"_BATCH_STATUS_CHCK_"$DT".log

v_BATCH_CHCK_EMAIL_CONTENT=$SRC_PATH/p3_batch_status_chck_email_content.csv


##Fetching current status value from the batch details table for the input subject area##
Result=`sqlplus -s $v_USER_ETL/$v_PWD@$v_SRVR << eof
WHENEVER OSERROR EXIT 9;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET SERVEROUTPUT ON;
SET VERIFY OFF;
SET LINESIZE 32760;
SET PAGESIZE 0;
SET ECHO OFF;
SET SPACE 0;
SET TERMOUT OFF;
SET HEADING OFF;
SET UNDERLINE OFF;
SET WRAP OFF;
SET TRIMS ON;
SET TRIMOUT ON;
SET TRIMSPOOL ON;
SET FEEDBACK OFF;
SET SQLNUMBER OFF;
SET ECHO OFF;
SET SQLBLANKLINES OFF;
SET NEWPAGE NONE;
SELECT 'ABC' ||'~'||LOAD_STATUS||'~'|| 'XYZ' from P3_BATCH_DTLS WHERE UPPER(SUB_AREA_NM)=UPPER('$p_SUB_AREA_NM') AND UPPER(LOAD_STATUS)='R';
exit;
eof`
if [[ $? -ne  0 ]]; then
echo "exit status is $? Please verify the query or the parameters passed" >> $v_LOG_FILE
exit 1
else
echo "interface_name and subject area  Select Query was executed successfully." >> $v_LOG_FILE
fi
echo "Result =$Result" >> $v_LOG_FILE
echo "Result =$Result"

v_STATUS=`echo $Result | cut -f2 -d "~"`

if [ "$v_STATUS" = "" ]; then
echo "No current batch in execution" >> "$v_LOG_FILE"
else
cat "$v_BATCH_CHCK_EMAIL_CONTENT" | mailx -i -r "$MAIL_FROM" -s  "Current Batch execution aborted for $p_INTERFACE" "$TEAM_MAIL_LIST"
echo "Previous batch is still running" >> "$v_LOG_FILE"
exit 2
fi
