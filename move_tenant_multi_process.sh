#!/bin/bash

WebRoot=/home/www/mt_dev

#redis配置
redisHost='127.0.0.1'
redisPort=16379
redisPassword='&&'

#本地mysql配置
mysqlHost='127.0.0.1'
mysqlPort=3306
mysqlUser='root'
mysqlDatabase='dev'
mysqlPassword=''
mysqlSocket=''

env=$1

if [[ $1 == 'beta_env' ]] ;then
    redisDatabase=7
    #nginx redis配置
    NredisHost='127.0.0.1'
    NredisPort=16379
    NredisDatabase=7
    NredisPassword='iii'
elif [[ $1 == 'prod_env' ]] ;then
    redisDatabase=8
    #nginx redis配置
    NredisHost='127.0.0.1'
    NredisPort=16379
    NredisDatabase=8
    NredisPassword='iiii'
else
    echo 'usage bash ./move-tenant.sh |beta_env|prod_env'
    exit 1
fi
phpDir="/usr/bin/php"



#进程数量
threadNum=5

redisConnect="redis-cli -h $redisHost -p $redisPort -n $redisDatabase -a $redisPassword"
NredisConnect="redis-cli -h $NredisHost -p $NredisPort -n $NredisDatabase -a $NredisPassword"

logfile="${WebRoot}/backend/runtime/logs/move-tenant/${env}-move-tenant.log"

function parseJson()
{
    json=$1
    k=$2
    echo $json|perl -pe "s#.*\"($k)\":\"(.*?)\".*#\2#"
}


log(){
	echo -e "$1" >> "${logfile}"
	# echo  "$1"
}

#单个租户更新
function tenantUpdate()
{
    uniqueName=$1 #租户uniqueName
    scriptNum=$2
	tenantExecCode=0
    for ((s=0;s<$scriptNum;s++))
    do
        sshConnection=`$redisConnect hget upgrade_task:upgrade_script $s`
        sCmd=`echo $sshConnection|sed -r "s#(.*)(\")#\1$uniqueName \2#g"` 
        
        #多进程，就不必判断该命令是否已经是慢更新了
        # if in slow_script_set
        # continue
        #slow=`$phpDir $WebRoot/yii callback/check-slow $env "${sCmd}"`
#       if [[ "$slow" -eq "1" ]]
#        then
#            continue
#        fi

        # 记录命令执行日志
        logId=`$phpDir $WebRoot/yii callback/add-log $uniqueName "${sCmd}" 2 $env 0 2`
        startTime=`date +%s`
        sCmdReturn=`eval $sCmd 2>&1`
        sExeuteCode=$?
        endTime=`date +%s`
#        delta=$((endTime-startTime)) # 不用判断是否为慢更新了
#        hashKey='upgrade_task'
#        timeOut=`$phpDir $WebRoot/yii callback/time-out $env $uniqueName $delta $hashKey "${sCmd}"`
        $phpDir $WebRoot/yii callback/update-log $logId $sExeuteCode  "${sCmdReturn}"  2>&1 >/dev/null
        # 慢更新的规则，3~10秒，3次；大于10秒，1次；
        # TODO 结束执行，毫秒 记日志，统计次数，一个脚本慢了三次，清空队列，触发邮件提示（yii)。
        if [[ $sExeuteCode != 0 ]]; then
            $NredisConnect hdel organization_env $uniqueName g0 2>&1 >/dev/null
            
            log "租户："$uniqueName
            log "命令："$sCmd
            log "错误："$sCmdReturn
            tenantExecCode=$sExeuteCode
            break
        fi
    done

    if [[ $tenantExecCode != 0 ]]; then
        $redisConnect keys upgrade_task*|xargs $redisConnect del 2>&1 >/dev/null
        log $uniqueName" 更新失败" 
        break
    else
        log "租户：${uniqueName} SQL及命令更新成功" 
        # yii回调移动租户
        $phpDir $WebRoot/yii callback/addgrayzero $uniqueName $env 2>&1 >/dev/null
    fi
}

while true; do
	if [[ "`$redisConnect get upgrade_task:locker`" == "locked" ]]; then
		scriptNum=`$redisConnect hkeys upgrade_task:upgrade_script|sed -e '/^$/d'|wc -l`

        $instanceArr=`$redisConnect smembers upgrade_task:instance`
        for instance in $instanceArr
        do
            { #每个实例一个并发
            listKeys=`$redisConnect keys upgrade_task:${$instance}_connections\*`
            for listkey in $listKeys # 这个listKeys应该最多只有5个列表
            do
                while [[ `$redisConnect llen $listKey` > 0 ]];do #这个
                { # 遍历每一个列表
                    data=`$redisConnect rpop $listKey`
                    conn=`parseJson "$data" command`
                    uniqueName=`parseJson "$data" unique_name`
                    $NredisConnect hset organization_env $uniqueName g0 2>&1 >/dev/null
                    tenantUpdate $uniqueName $scriptNum 
                } &
                done
            done
            } &
        done
	else
		sleep 2
	fi

done

