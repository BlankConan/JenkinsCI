[TOC]

###Mac OS 下的Jenkins环境搭建

1. 安装 [Java JDK](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html) (version:8.0)

	> 查看jdk默认的 `JAVA_HOME` 命令: `/usr/libexec/java_home -V`

2. [安装Jenkins](https://jenkins.io/index.html)，下载完成后执行下面命令: 
	 - 启动
		
	 ```
	 java -jar jenkins.war
	 java -jar jenkins.war --httpPort=8088
	 
	 ```

	- JDK的降级/卸载方法
		
		```
		sudo rm -fr /Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin
		sudo rm -fr /Library/PreferencesPanes/JavaControlPanel.prefPane
		sudo rm -fr ~/Library/Application\ Support/Java
		```
	-  `cd /Library/Java/JavaVirtualMachines/`
	
	> 报错解决：下面的错误是端口被占用
		
		java.io.IOException: Failed to start Jetty
		at winstone.Launcher.<init>(Launcher.java:156)
		at winstone.Launcher.main(Launcher.java:354)
		at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
		at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
		at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
		at java.lang.reflect.Method.invoke(Method.java:498)
		at Main._main(Main.java:312)
		at Main.main(Main.java:136)
		Caused by: java.net.BindException: Address already in use
		at sun.nio.ch.Net.bind0(Native Method)
		at sun.nio.ch.Net.bind(Net.java:433)
		at sun.nio.ch.Net.bind(Net.java:425)
	
3. [关闭、重启jenkins的方法](http://damien.co/general/how-to-start-stop-restart-or-reload-jenkins-mac-osx-8022)
	> http://[jenkins-server]/[command] <br>
	[commond] exit | reload | restart <br>
	exit：shutdown Jenkins <br>
	reload：reload the configuration <br>
	restart：restart jenkins

4. 修改主目录
	> 安装好之后先不要启动Jenkins，通过修改文件`/Library/LaunchDaemons/org.jenkins-ci.plist` 的 `JENKINS_HOME `键	值；</br>
	然后使用下面两个命令： </br>
	
	```
	sudo launchctl load /Library/LaunchDaemons/org.jenkins-ci.plist
	sudo launchctl load /Library/LaunchDaemons/org.jenkins-ci.plist
	```
	
5. 几个必须要的插件

	> `Keychains and Provisioning Profiles Plugin` </br>
	`Xcode Plugin` </br>
	`Github Plugin`  `Gitlab Plugin`可选，根据项目类型这配置
	
6. [Xcode 打包并发布脚本](https://www.jianshu.com/p/1229476fbce4)

7. 用户权限操作失误
	> `<authorizationStrategy class="hudson.security.FullControlOnceLoggedInAuthorizationStrategy"/>`

### Mac 下安装Tomcat
1. 下载安装Tomcat [Apache Timcat下载地址](https://tomcat.apache.org/download-90.cgi)

2. 解压 <br>

	`tar -jxvf FileName.tar.bz/FileName.tar.bz2`
	`tar -xzvf FileName.tar.gz`
	`tar -xvf FileName.tar`
    

3. 运行bin下面的启动和关闭脚本

4. **权限和用户角色**

	> 相关配置文件：webapps/manager/WEB-INF路径下的web.xml <br>
	用户角色配置：tomcat的用户由conf路径下的 tomcat-users.xml <br>
	添加用户角色格式：<br>
	
	```
	<tomcat-users> 
    	<role rolename="manager-gui"/>
    	<user username="admin" password="admin" roles="manager-gui"/> 
	</tomcat-users>	
	```
	- 403 Access Denied 问题
	
		> 首先在conf/tomcat-users.xml文件里面，在</tomcat-users>前面添		加如下代码，改完之后进行重启：
		
		```
		<role rolename="manager-gui"/>
		<role rolename="admin-gui"/>
		<user username="admin" password="admin" roles="manager-gui,admin-gui"/>
		```
		> 重启Tomcat，如果还有问题，那么就是访问的ip地受到了限制，
我们打开/webapps/manager/META-INF/目录下context.xml文件，不是conf/目录下的context.xml文件，一定不要搞错了，添加下面的代码:

		`<Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1|\d+\.\d+\.\d+\.\d+" />`
	
5. 数据源的配置
	- 全局数据源：所有的web应用都可以访问
	- 局部数据源：只能在单个web应用中访问
	
	> 不管配置哪种数据源，都需要提供特定数据库的JDBC驱动，将其复制到Tomcat的lib路径下，然后在	`conf/Catalina/localhost`文件夹下新建任意名字的xml文件—-该文件就是部署Web应用的配置文	件	
	
### Mac 将Jenkins部署到Tomcat下
1. 下载 Tomcat

	`brew install tomcat@8`
	
2. 下载 [jenkins.war](https://updates.jenkins-ci.org/download/war/)
3. 将下载好的 `jenkins.war` 直接放到 `tomcat/webapps/`下面



### Jenkins的一些配置

##### 配置全局的环境变量
1. 打开Jenkins系统设置面板
2. 全局属性添加键值对

##### `Markup Formatter`标记格式器 改为 `Safe HTML`

1. 安装 `OWASP Markup Formatter Plugin`插件
2. 打开 `Configure Global Security`全局安全配置
3. `Markup Formatter`标记格式器进行更改

##### `Jenkins-cli` 相关配置


