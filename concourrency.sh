#!/bin/bash
    
function rand(){    
    min=$1    
    max=$(($2-$min+1))    
    num=$(date +%s%N)    
    echo $(($num%$max+$min))    
} 


# 每个进程需要执行的更更新
# 可以消耗多个租户的更更新
function update()
{
    rnd=$(rand 1 10)
    sleep $rnd
    echo "${1}------${2}------$rnd" 
}

#没个实例
function instance()
{
    # 每个实例5个进程
    for j in {1..5}
    do
        update $1 $j &  #每个进场可以消耗多个租户
    done
# wait
}

# 多个实例
for i in {a..f}
do
    instance $i &
done
wait


