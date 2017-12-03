        $tempInstanceArr = [];
        foreach($tenantList as $k => $v) {
            //判断租户是否在gray_zore表中
            $where = [
                'unique_name' => $v['unique_name'],
            ];
            $info = $this->grayModel->getTenantInfo($where);

            if ( $info ) { // 在G0仓库中
                continue;
            } else {
                // 将连接信息 push到队列
                $dsnArr = $this->parseDbString($v['connection_string']);
                $cmd    = $this->getCmd($dsnArr);
                $unique = $v['unique_name'];
                $arr    = ['command'=>$cmd,'unique_name' => $unique];
                $this->redis->lpush($version.':connections', json_encode($arr));
                $instance = $v['Instance']; // 实例
                $tempInstanceArr[$v['Instance']][] = $v['id'];
                $this->redis->sadd($version.':instance',$instance);
                $num = count($tempInstanceArr[$v['Instance']]);
                $mod = ($num  % 5); // todo 写成配置
                $instanceHash = $version.':'.$instance.'_connectioins'.$mod;
                $this->redis->lpush($instanceHash, json_encode($arr));
                //$v['create_time'] = time(); unset($v['connection_string']); $this->grayModel->addToCrayZero($v); // 保存到G0库
            }
        }
