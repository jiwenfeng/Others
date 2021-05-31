#!/bin/sh

###############################################################################

# 以下变量不能为空

CREATE_ROLE_LIMIT="" # 新服导量人数上限


PROJECT_ROOT="" # 服务器根目录


SCRIPT_DIR="" # 脚本执行目录


MONGC_URL="" # MongoDB的地址


DB_NAME="" # 数据库名


REGION="" #所属大区

SII_PATH="" # ServerInfo_Internal所在的目录(此目录需要给执行脚本的用户添加rw权限)

CONFIG_SERVER_PORT="" # 获取ServerInfo_Internal文件的端口
#################################################### 以下不填默认为本机IP
CONFIG_SERVER_IP=
DBD_IP=
JIFEI_IP=
GMTOOL_IP=
ACCOUNT_IP=
NETD_IP=
#战斗录像
VIDEO_IP="54.254.240.39"
###############################################################################

LOG_DIR=
if [ ! -d "$SCRIPT_DIR" ]; then
	LOG_DIR=./log
else
	LOG_DIR=$SCRIPT_DIR/log
fi

if [ ! -d $LOG_DIR ];then
	mkdir $LOG_DIR
fi

LOG_FILE=$LOG_DIR/`date +"%Y%m%d"`.log

function Log()
{
	echo "[`date +"%F %T"`] [$1] $2" >> $LOG_FILE
}

function Error()
{
	Log "Error" $1
}

function Debug()
{
	Log "Debug" $1
}

function Info()
{
	Log "Info" $1
}

if [ "$SCRIPT_DIR" = "" ];then
	Error "变量SCRIPT_DIR不能为空"
	exit 1
fi

if [ ! -d $SCRIPT_DIR ]; then
	echo "变量SCRIPT_DIR[$SCRIPT_DIR]路径不存在"
	exit 1
fi

if [ "$CREATE_ROLE_LIMIT" = "" ];then
	Error "变量CREATE_ROLE_LIMIT不能为空"
	exit 1
fi

if [ "$PROJECT_ROOT" = "" ]; then
	Error "变量PROJECT_ROOT不能为空"
	exit 1
fi

if [ ! -d $PROJECT_ROOT ]; then
	Error "变量PROJECT_ROOT[$PROJECT_ROOT]路径不存在"
	exit 1
fi

if [ "$MONGC_URL" = "" ]; then
	Error "变量MONGC_URL不能为空"
	exit 1
fi

if [ "$DB_NAME" = "" ]; then
	Error "变量DB_NAME不能为空"
	exit 1
fi

if [ "$REGION" = "" ]; then
	Error "变量REGION不能为空"
	exit 1
fi

if [ "$SII_PATH" = "" ]; then
	Error "变量SII_PATH不能为空"
	exit 1
fi


if [ "$SII_PATH" -o ! -d "$SII_PATH" ]; then
	Error "变量SII_PATH[$SII_PATH]路径不存在"
	exit 1
fi

if [ "$CONFIG_SERVER_PORT" = "" ]; then
	Error "变量CONFIG_SERVER_PORT不能为空"
	exit 1
fi

BACKUP_DIR=$SCRIPT_DIR/backup
CONFIG_FILE=$SCRIPT_DIR/config
LAST_SVR_FILE=$SCRIPT_DIR/.last_server
SII_NAME=serverinfo_$REGION
SERVERINFO_FILE=$SII_PATH/$SII_NAME

cd $LOG
find . -name "*.log" -mtime +2 -exec rm -rf {} \;
cd -


function Begin()
{
	if [ ! -d $BACKUP_DIR ]; then
		mkdir $BACKUP_DIR
	fi
	Debug "开始备份$SERVERINFO_FILE"
	cp $SERVERINFO_FILE $BACKUP_DIR
	Debug "开始备份$CONFIG_FILE"
	cp $CONFIG_FILE $BACKUP_DIR
	Debug "开始备份$LAST_SVR_FILE"
	cp $LAST_SVR_FILE $BACKUP_DIR
	Info "备份完成"
}

function Rollback()
{
	Debug "还原备份$SERVERINFO_FILE"
	cp $BACKUP_DIR/$SII_NAME $SII_PATH
	Debug "还原备份config"
	cp $BACKUP_DIR/config $CONFIG_FILE
	Debug "还原备份.last_server"
	cp $BACKUP_DIR/.last_server $LAST_SVR_FILE
	Debug "删除备份"
	rm -rf $BACKUP_DIR
	if [ "$1" != "" ]; then
		Debug "删除新创建的服务器$1"
		rm -rf $1
	fi
	Info "回滚完成"
}

function Commit()
{
	rm -rf $BACKUP_DIR
	Info "操作完成"
}

function BackupFailedCfg()
{
	if [ ! -d $SCRIPT_DIR/fail ]; then
		mkdir $SCRIPT_DIR/fail
	fi
	if [ ! -d $SCRIPT_DIR/fail/$1 ]; then
		mkdir $SCRIPT_DIR/fail/$1
	fi
	cp $2 $SCRIPT_DIR/fail/$1
	cp $3 $SCRIPT_DIR/fail/$1
	cp $4 $SCRIPT_DIR/fail/$1
	cp $5 $SCRIPT_DIR/fail/$1
	cp $SERVERINFO_FILE $SCRIPT_DIR/fail/$1
}

SERVER_IP=`/sbin/ifconfig|grep "\<inet\>"|grep -v "127"|awk '{print $2}'`
if [ "$SERVER_IP" = "" ]; then
	Error "没有获取到本机IP,脚本执行失败"
	exit 1
fi

if [ "$CONFIG_SERVER_IP" = "" ]; then
	CONFIG_SERVER_IP=$SERVER_IP
fi

if [ "$DBD_IP" = "" ]; then
	DBD_IP=$SERVER_IP
fi

if [ "$JIFEI_IP" = "" ]; then
	JIFEI_IP=$SERVER_IP
fi

if [ "$GMTOOL_IP" = "" ]; then
	GMTOOL_IP=$SERVER_IP
fi

if [ "$ACCOUNT_IP" = "" ]; then
	ACCOUNT_IP=$SERVER_IP
fi

if [ "$NETD_IP" = "" ]; then
	NETD_IP=$SERVER_IP
fi

if [ "$VIDEO_IP" = "" ]; then
	VIDEO_IP=$SERVER_IP
fi

if [ ! -f $SERVERINFO_FILE ]; then
	Error "$SERVERINFO_FILE不存在,脚本执行失败"
	exit 1
fi

if [ ! -w $SII_PATH ]; then
	Error "用户`whoami`没有向$SII_PATH写入的权限,脚本执行失败"
	exit 1
fi

if [ ! -w $SERVERINFO_FILE ]; then
	Error "用户`whoami`没有向$SERVERINFO_FILE写入的权限,脚本执行失败"
	exit 1
fi

if [ ! -w $SCRIPT_DIR ]; then
	Error "用户`whoami`没有向$SCRIPT_DIR写入的权限,脚本执行失败"
	exit 1
fi

Info "开始执行开启新服流程"
if [ ! -f "$CONFIG_FILE" ]; then
	Error "$CONFIG_FILE文件不存在"
	exit 1
fi

CFG_LINE=`cat $CONFIG_FILE|wc -l`
if [ "$CFG_LINE" = "" ]; then
	Error "请在$CONFIG_FILE文件中添加开服配置信息"
	exit 1
fi

LAST_SVR=`cat $LAST_SVR_FILE`
if [ "$LAST_SVR" = "" ]; then
	Error "没有找到新服信息,请将新服ID写入$LAST_SVR_FILE文件中"
	exit 1
fi

Info "当前运行的新服是:$LAST_SVR"

LAST_PROJECT_DIR=$PROJECT_ROOT/$LAST_SVR

if [ ! -d $LAST_PROJECT_DIR ]; then
	Error "服务器$LAST_PROJECT_DIR不存在"
	exit 1
fi

Info "开始检测[$LAST_SVR]的注册人数"
CULF=logic/log/dblog/create_role.log

if [ ! -f $LAST_PROJECT_DIR/$CULF ]; then
	Debug "[$LAST_SVR]注册人数为0,不需要开服"
	exit 0
fi

ROLE_NUM=`cat $LAST_PROJECT_DIR/$CULF|wc -l`


if [ $ROLE_NUM -lt $CREATE_ROLE_LIMIT ]; then
	Debug "[$LAST_SVR]注册人数为$ROLE_NUM,小于$CREATE_ROLE_LIMIT 不需要开新服"
	exit 0
fi

Info "[$LAST_SVR]注册人数为:$ROLE_NUM,注册上限为:$CREATE_ROLE_LIMIT"

NEW_SVR_ID=""
NEW_SVR_NAME=""

Debug "开始开服"

Begin

while true
do
	LINE=`cat $CONFIG_FILE | head -n 1`
	if [ "$LINE" = "" ];then
		Error "$CONFIG_FILE没有可用的服务器配置,开服失败"
		Rollback
		exit 1
	fi
	sed -i '1d' $CONFIG_FILE
	NEW_SVR_ID=`echo $LINE | awk '{print $1}'`
	NEW_SVR_NAME=`echo $LINE | awk '{print $2}'`
	if [ "$NEW_SVR_ID" = "" -o "$NEW_SVR_NAME" = "" ]; then
		Error "$LINE格式不正确"
		continue
	fi
	if [ -d $PROJECT_ROOT/server_$NEW_SVR_ID ]; then
		NEW_SVR_ID=""
		NEW_SVR_NAME=""
		continue
	fi
	break
done

if [ "$NEW_SVR_ID" = "" -o "$NEW_SVR_NAME" = "" ]; then
	Error "没有可用的服务器配置,开服失败"
	Rollback
	exit 0
fi

NEW_SVR=server_$NEW_SVR_ID

NEW_PROJECT_DIR=$PROJECT_ROOT/$NEW_SVR

NETD_CFG=$NEW_PROJECT_DIR/logic/etc/config/netd.cfg
USER_CFG=$NEW_PROJECT_DIR/logic/etc/config/user.cfg
GS_FILE=$NEW_PROJECT_DIR/logic/etc/config/gs.cfg


Info "新开的服务器ID为$NEW_SVR,服务器路径在$NEW_PROJECT_DIR"

mkdir $NEW_PROJECT_DIR
Debug "创建$NEW_PROJECT_DIR 成功"
mkdir $NEW_PROJECT_DIR/engine
Debug "创建$NEW_PROJECT_DIR/engine成功"
mkdir $NEW_PROJECT_DIR/logic
Debug "创建$NEW_PROJECT_DIR/logic成功"

cp $LAST_PROJECT_DIR/engine/*.sh $NEW_PROJECT_DIR/engine/
Debug "拷贝$LAST_PROJECT_DIR/engine/*.sh到$NEW_PROJECT_DIR/engine/完成"

cp $LAST_PROJECT_DIR/engine/engine $NEW_PROJECT_DIR/engine/
Debug "拷贝$LAST_PROJECT_DIR/engine/engine到$NEW_PROJECT_DIR/engine/完成"

cp -R $LAST_PROJECT_DIR/logic $NEW_PROJECT_DIR/
Debug "拷贝$LAST_PROJECT_DIR/logic到$NEW_PROJECT_DIR/完成"

if [ -d $NEW_PROJECT_DIR/logic/log ]; then
	rm -rf $NEW_PROJECT_DIR/logic/log/*
fi

if [ -d $NEW_PROJECT_DIR/logic/dat ]; then
	rm -rf $NEW_PROJECT_DIR/logic/dat/*
fi

# 修改配置文件
function WriteNetdCfg()
{
	echo "#服务器id编号" > $NETD_CFG
	echo "HOST_ID = $1;" >> $NETD_CFG
	echo "" >> $NETD_CFG
	echo "#所属于大区" >> $NETD_CFG
	echo "REGION = \"$REGION\";" >> $NETD_CFG
	echo "" >> $NETD_CFG
	echo "#所属服务器类型" >> $NETD_CFG
	echo "SERVER_TYPE = \"netd\";" >> $NETD_CFG
	echo "" >> $NETD_CFG
	echo "#服务器使用的encoding" >> $NETD_CFG
	echo "ENCODING = \"UTF-8\";" >> $NETD_CFG
	echo "" >> $NETD_CFG
	echo "#时区" >> $NETD_CFG
	echo "TIME_ZONE = 8;" >> $NETD_CFG
	echo "#刷新时间 整点" >> $NETD_CFG
	echo "REFRESH_TIME = 9;" >> $NETD_CFG
	echo "" >> $NETD_CFG
	echo "#netd 内部对game开放的ip, listen ip，需要让gamed连接" >> $NETD_CFG
	echo "NETD_IP = \"$NETD_IP\";" >> $NETD_CFG
	echo "" >> $NETD_CFG
	echo "#netd 内部对game开放的port，listen port，需要防火墙开放内网访问权限" >> $NETD_CFG
	echo "NETD_PORT = "$1"1;" >> $NETD_CFG
	echo "" >> $NETD_CFG
	echo "#netd对client开放的端口，需要防火墙开放公网访问权限" >> $NETD_CFG
	echo "NETD_OUTER_PORT = "$1"0;" >> $NETD_CFG
	echo "" >> $NETD_CFG
	echo "#netd httpd port，需要防火墙开放内网访问权限" >> $NETD_CFG
	echo "NETD_HOST_PORT = "$1"3;" >> $NETD_CFG
	echo "" >> $NETD_CFG
	echo "#账号系统服务器访问配置" >> $NETD_CFG
	echo "ACCOUNT_IP = \"$ACCOUNT_IP\";" >> $NETD_CFG
	echo "ACCOUNT_PORT = 18888;" >> $NETD_CFG
	echo "" >> $NETD_CFG
	echo "#服务器拓扑结构配置服务器访问配置" >> $NETD_CFG
	echo "CONFIG_SERVER_IP = \"$CONFIG_SERVER_IP\";" >> $NETD_CFG
	echo "CONFIG_SERVER_PORT = $CONFIG_SERVER_PORT;" >> $NETD_CFG
}

function WriteUserCfg()
{
	echo "#服务器id编号" > $USER_CFG
	echo "HOST_ID = $1;" >> $USER_CFG
	echo "" >> $USER_CFG
	echo "#所属于大区" >> $USER_CFG
	echo "REGION = \"$REGION\";" >> $USER_CFG
	echo "" >> $USER_CFG
	echo "#所属服务器类型" >> $USER_CFG
	echo "SERVER_TYPE = \"user\";" >> $USER_CFG
	echo "" >> $USER_CFG
	echo "#服务器使用的encoding" >> $USER_CFG
	echo "ENCODING = \"UTF-8\";" >> $USER_CFG
	echo "" >> $USER_CFG
	echo "#最大在线人数" >> $USER_CFG
	echo "MAX_ONLINE = 11000;" >> $USER_CFG
	echo "MAX_LOGIN = 10000;" >> $USER_CFG
	echo "" >> $USER_CFG
	echo "#时区" >> $USER_CFG
	echo "TIME_ZONE = 8;" >> $USER_CFG
	echo "#刷新时间 整点" >> $USER_CFG
	echo "REFRESH_TIME = 0;" >> $USER_CFG
	echo "" >> $USER_CFG
	echo "#netd 内部对game开放的port" >> $USER_CFG
	echo "NETD_PORT = "$1"1;" >> $USER_CFG
	echo "" >> $USER_CFG
	echo "#dbd 内部对game开放的ip port" >> $USER_CFG
	echo "DBD_IP = \"$DBD_IP\";" >> $USER_CFG
	echo "DBD_PORT = "$1"2;" >> $USER_CFG
	echo "" >> $USER_CFG
	echo "#httpd服务器端口，listen port，需要防火墙开放内网访问权限" >> $USER_CFG
	echo "HTTPD_PORT = "$1"5;" >> $USER_CFG
	echo "" >> $USER_CFG
	echo "#账号系统服务器访问配置" >> $USER_CFG
	echo "ACCOUNT_IP = \"$ACCOUNT_IP\";" >> $USER_CFG
	echo "ACCOUNT_PORT = 18888;" >> $USER_CFG
	echo "" >> $USER_CFG
	echo "#gmtool" >> $USER_CFG
	echo "GMTOOL_IP = \"$GMTOOL_IP\";" >> $USER_CFG
	echo "GMTOOL_PORT = 8000;" >> $USER_CFG
	echo "" >> $USER_CFG
	echo "#充值计费" >> $USER_CFG
	echo "JIFEI_IP = \"$JIFEI_IP\";" >> $USER_CFG
	echo "JIFEI_PORT = 9996;" >> $USER_CFG
	echo "APP_ID = \"appq2-official-test\";" >> $USER_CFG
	echo "" >> $USER_CFG
	echo "#战斗录像服务器" >> $USER_CFG
	echo "VIDEO_IP = \"$VIDEO_IP\";" >> $USER_CFG
	echo "VIDEO_PORT = 80;" >> $USER_CFG
	echo "" >> $USER_CFG
	echo "#CDKEY服务器" >> $USER_CFG
	echo "CDKEY_HOST = \"\";" >> $USER_CFG
	echo "CDKEY_PORT = 8888;" >> $USER_CFG
	echo "CDKEY_KEY = \"5450eff8819e44c8ab2b2eae26abb103\";" >> $USER_CFG
	echo "" >> $USER_CFG
	echo "#服务器拓扑结构配置服务器访问配置" >> $USER_CFG
	echo "CONFIG_SERVER_IP = \"$CONFIG_SERVER_IP\";" >> $USER_CFG
	echo "CONFIG_SERVER_PORT = $CONFIG_SERVER_PORT;" >> $USER_CFG
	echo "" >> $USER_CFG
	echo "#数据库" >> $USER_CFG
	echo "MONGOC_URI = \"$MONGC_URL\";" >> $USER_CFG
	echo "MONGOD_DB_NAME = \"$DB_NAME\";" >> $USER_CFG
	echo "#数据库读取、存盘线程数量" >> $USER_CFG
	echo "DB_WORKER_DBO_COUNT=4;" >> $USER_CFG
	echo "#数据库命令执行线程数量" >> $USER_CFG
	echo "DB_WORKER_CMD_COUNT=10;" >> $USER_CFG
	echo "DB_FLUSH_HASH=7;" >> $USER_CFG
	echo "" >> $USER_CFG

	NOW="`date +'%Y-%m-%d'` 00:00:00"
	line=`sed -n /OPEN_TIME/= $USER_CFG | tail -n1`
	if [ "$line" = "" ]; then
		echo "OPEN_TIME = \"${NOW}\";" >> $USER_CFG
	else
		sed "${line}s/.*/OPEN_TIME = \"${NOW}\"/" -i $USER_CFG
	fi
}

function WriteGSCfg()
{
	echo "#服务器id编号" > $GS_FILE
	echo "HOST_ID = $1;" >> $GS_FILE
	echo "" >> $GS_FILE
	echo "#所属于大区" >> $GS_FILE
	echo "REGION = \"$REGION\";" >> $GS_FILE
	echo "" >> $GS_FILE
	echo "#所属服务器类型" >> $GS_FILE
	echo "SERVER_TYPE = \"gs\";" >> $GS_FILE
	echo "" >> $GS_FILE
	echo "#服务器使用的encoding" >> $GS_FILE
	echo "ENCODING = \"UTF-8\";" >> $GS_FILE
	echo "" >> $GS_FILE
	echo "#httpd对外端口, 需要防火墙开放内网访问权限" >> $GS_FILE
	echo "HTTPD_PORT = "$1"5;" >> $GS_FILE
	echo "" >> $GS_FILE
	echo "#侦听内部各类服务器连接的端口, 需要防火墙开放内网访问权限" >> $GS_FILE
	echo "GS_SERVER_PORT = "$1"6;" >> $GS_FILE
	echo "" >> $GS_FILE
	echo "#服务器拓扑结构配置服务器访问配置" >> $GS_FILE
	echo "CONFIG_SERVER_IP = \"$CONFIG_SERVER_IP\";" >> $GS_FILE
	echo "CONFIG_SERVER_PORT = $CONFIG_SERVER_PORT;" >> $GS_FILE
	echo "" >> $GS_FILE
	echo "#SENTRY警报key" >> $GS_FILE
	echo "#SENTRY_DSN = \"http://3b8c740049084a1ab83886cf4eb56e48:48752107d17a49859e3adb76510e447c@staging.sentry.platform.qtz/4\";">> $GS_FILE
}

function WriteSII()
{
	key=\"$2\":{
	line=`sed -n /${key}/= $SERVERINFO_FILE |tail -n1`
	if [ "$line" = "" ]; then
		Error "$SERVERINFO_FILE没有找到$2节"
		exit 1
	fi
	line=$((line + 1))
	DATA="$1:{\n\t\t  \"ip\":\"$SERVER_IP\",\n\t\t},"
	sed "$line i${DATA}" -i $SERVERINFO_FILE
}

function WriteSIIGS()
{
	line=`sed -n '/"gs":{/=' $SERVERINFO_FILE |tail -n1`
	if [ "$line" = "" ]; then
		Error "$SERVERINFO_FILE没有找到gs节"
		exit 1
	fi
	DATA="  \"gs\":{\n\t$1:{\n\t\t  \"gs_server_port\":"$1"6,\n\t\t  \"ip\":\"$SERVER_IP\"\n\t  },"
	sed -i "${line}s/.*/${DATA}/" $SERVERINFO_FILE
}

SERVER_NUM=`ls -lt $PROJECT_ROOT|grep server|wc -l`

SVR_RELEATE_ID=0

if [ "$SERVER_NUM" = "" ]; then
	SVR_RELEATE_ID=0
else
	SVR_RELEATE_ID=$((SERVER_NUM / 3))
fi
SVR_RELEATE_ID=$((SVR_RELEATE_ID + 1))

Debug "新开的服务器组ID为:$SVR_RELEATE_ID"

#Debug "开始创建netd.cfg"
#WriteNetdCfg $NEW_SVR_ID $NEW_SVR_NAME $SVR_RELEATE_ID
#Debug "创建netd.cfg成功"
Debug "开始创建userd.cfg"
WriteUserCfg $NEW_SVR_ID $NEW_SVR_NAME $SVR_RELEATE_ID
Debug "创建userd.cfg成功"
#Debug "开始创建gs.cfg"
#WriteGSCfg $NEW_SVR_ID $NEW_SVR_NAME $SVR_RELEATE_ID
#Debug "创建gs.cfg成功"
Debug "向ServerInternal文件中添加user服信息"
WriteSII $NEW_SVR_ID "user"
Debug "添加user服信息成功"
#Debug "向ServerInternal文件中添加netd服信息"
#WriteSII $NEW_SVR_ID "netd"
#Debug "添加netd服信息成功"
#Debug "向ServerInternal文件中添加gs服信息"
#WriteSIIGS $NEW_SVR_ID
#Debug "添加gs服信息成功"
cd $NEW_PROJECT_DIR/engine/
#Debug "开始启动gs服务器"
#./start_gs.sh
#Debug "启动gs服务器成功"
Debug "开始启动服务器"
./start_user.sh
#sleep 5

#NETD_PID=`cat netd_ls.pid`
#if [ "$NETD_PID" = "" ]; then
#	BackupFailedCfg $NEW_SVR_ID $NEW_PROJECT_DIR/engine/netd_ls.log $NEW_PROJECT_DIR/engine/gamed_user.log $NETD_CFG $USER_CFG
#	Error "[$NEW_SVR]netd启动失败,脚本开始回滚"
#	./stop.sh
#	Rollback $NEW_PROJECT_DIR
#	exit 1
#fi
#
#NETD_INFO=`ps aux|grep $NETD_PID|grep -v "grep"`
#if [ "$NETD_INFO" = "" ]; then
#	BackupFailedCfg $NEW_SVR_ID $NEW_PROJECT_DIR/engine/netd_ls.log $NEW_PROJECT_DIR/engine/gamed_user.log $NETD_CFG $USER_CFG
#	Error "[$NEW_SVR]netd启动失败,脚本开始回滚"
#	./stop.sh
#	Rollback $NEW_PROJECT_DIR
#	exit 1
#fi

GAMED_PID=`cat gamed_user.pid`
if [ "$GAMED_PID" = "" ]; then
	BackupFailedCfg $NEW_SVR_ID $NEW_PROJECT_DIR/engine/netd_ls.log $NEW_PROJECT_DIR/engine/gamed_user.log $NETD_CFG $USER_CFG
	Error "[$NEW_SVR]gamed启动失败,脚本开始回滚"
	./stop_user.sh
	Rollback $NEW_PROJECT_DIR
	exit 1
fi

GAMED_INFO=`ps aux|grep $GAMED_PID|grep -v "grep"`
if [ "$GAMED_INFO" = "" ]; then
	BackupFailedCfg $NEW_SVR_ID $NEW_PROJECT_DIR/engine/netd_ls.log $NEW_PROJECT_DIR/engine/gamed_user.log $NETD_CFG $USER_CFG
	Error "[$NEW_SVR]gamed启动失败,脚本开始回滚"
	./stop_user.sh
	Rollback $NEW_PROJECT_DIR
	exit 1
fi

echo $NEW_SVR > $LAST_SVR_FILE
Info "新服开启成功，当前最新服务器是:$NEW_SVR"
Commit

python $SCRIPT_DIR/dingtalk.py $NEW_SVR $LAST_SVR $ROLE_NUM >> $SCRIPT_DIR/log & 2>&1

