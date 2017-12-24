#! /usr/bin/csh

#source ${APL_R_PARM}/wjtftpadd.parm
#source /usr2/APL/debug/WLA/DB/parm/wjftpadd.parm

set JOBID=`basename $0 .csh`
set FTPLOG=${APL_D_LOG}/${JOBID}.tmp

#APLログファイル名設定
set LOGFILE=${APL_D_LOG}/${JOBID}".log"
set FTPBATCH=${APL_D_LOG}/${JOBID}".bat"

set param="${APL_R_PARM}/wjtftpadd2.parm"

if(!($?param))then
    echo "`date '+%Y/%m%d %H:%M:%S'`" "パラメータファイルが存在しません"    >>& $LOGFILE
    goto ABNORMAL_END
endif

foreach lineparam (`cat $param`)
    set paramarray=(`echo "${lineparam}" | awk -F "," '{print $2 " " $3 " " $4 " " $5 " " $6 " " $7 " " $8}'`)
    
    if(${paramarray[7]}=="2") then
        set transmode="binary"
    else
        set transmode="ascii"
    endif
    
    echo "open $paramarray[1]"  >>& $FTPBATCH
    echo "user $paramarray[2] $paramarray[3]"   >>& $FTPBATCH
    echo "${tansmode}"  >>& $FTPBATCH
    echo "cd $paramarray[4]/"   >>& $FTPBATCH
    echo "lcd $paramarray[5]"   >>& $FTPBATCH
    
    if($# > 0) then
        foreach file ($*)
            set filename=`echo ${file} | awk -F "." '{print $1}'`
            echo "put ${filename}.s"    >>& $FTPBATCH
        end
    else
        echo "mput *.s" >>& $FTPBATCH
    endif
    echo "close"    >>& $FTPBATCH
    
    echo "open $paramarray[1]"  >>& $FTPBATCH
    echo "user $paramarray[2] $paramarray[3]"   >>& $FTPBATCH
    echo "${transmode}" >>& $FTPBATCH
    echo "cd $paramarray[4]/"   >>& $FTPBATCH
    echo "lcd $paramarray[5]"   >>& $FTPBATCH
    if($# > 0) then
        foreach file ($*)
            set filename=`echo ${file} | awk -F "." '{print $1}'
            echo "put ${filename}.dat"  >>& $FTPBATCH
        end
    else
        echo "mput *.dat"   >>& $FTPBATCH
    endif
    echo "close"    >>& $FTPBATCH
    
    echo "open $paramarray[1]"  >>& $FTPBATCH
    echo "user $paramarray[2] $paramarray[3]"   >>& $FTPBATCH
    echo "${transmode}" >>& $FTPBATCH
    echo "lcd $paramarray[5]"   >>& $FTPBATCH
    
    if($# > 0) then
        foreach file ($*)
            set filename=`echo ${file} | awk -F "." '{print $1}'    >>& $FTPBATCH
        end
    else
        echo "mput *.e" >>& $FTPBATCH
    endif
    
    echo "close"    >>& $FTPBATCH
end

echo "quit\n"   >>& $FTPBATCH

ftp -n -v < $FTPBATCH   >& $FTPLOG

rm $FTPBATCH
grep "No such file or directory" ${FTPLOG}  >& /dev/null

if(!($status == 0)) then
    echo "[正常終了]FTP結果チェック"  >>& $LOGFILE
else
    echo "[異常終了]FTP結果チェック"  >>& $LOGFILE
    set notfindfile=`awk -F ":" 'match($0,/No such file or directory/) {print $2}' ${FTPLOG}`
    echo "${notfindfile}は存在しません"    >>& $LOGFILE
    goto ABNORMAL_END
endif

exit(0)

ABNORMAL_END:
echo "*------------------------------------------*" >>& $LOGFILE
echo "* " `date '+%Y%m%d %H:%M:%S'` "JOB "${JOBID} ABNORMAL_END *" >>& LOGFILE
echo "*------------------------------------------*" >>& $LOGFILE

exit(1)
        
    