# geomesa-docker
Set of docker images for running [geomesa](http://www.geomesa.org/)

## Projects

### docker-uber
Single image with all stuff on board. Good for demo and testing purposes

Installation is based on [cloudera.quickstart](https://hub.docker.com/r/cloudera/quickstart/)

#### Useful links 
* Cloudera docker hub [tags](https://hub.docker.com/r/cloudera/quickstart/tags/) 

* Cloudera 5.7 docker [doc](http://www.cloudera.com/documentation/enterprise/5-7-x/topics/quickstart_docker_container.html)

* Cloudera Accumulo [product](https://www.cloudera.com/products/apache-hadoop/apache-accumulo.html)

* Cloudera 5.7 Accumulo [doc](http://www.cloudera.com/documentation/enterprise/5-7-x/topics/cm_props_cdh570_accumulo16.html#concept_5.7.x_accumulo16propertiesincdh570_props)

* [Geomesa 1.0 on CDH 5.3](https://gist.github.com/mikeatlas/0940cfc9a8367459a900)

* [Cloudera Accumulo 1.4.3 install](http://www.cloudera.com/documentation/archive/accumulo/1-4-3/PDF/Apache-Accumulo-Installation-Guide.pdf)

#### Prepare

### Put parcels on image and create Accumulo service 

* pull image `sudo docker pull cloudera/quickstart:5.7.0-0-beta`
* run cloudera image `docker run --hostname=quickstart.cloudera --privileged=true -t -i [OPTIONS] [IMAGE] /usr/bin/docker-quickstart` 
* start docker `sudo docker run --hostname=quickstart.cloudera --privileged=true -t -i -p 7180:7180 geomesa-docker/docker-uber:1.2.5 bash`
* start mysql `/etc/init.d/mysqld start`
* start CM `/home/cloudera/cloudera-manager --enterprise`
* `useradd accumulo`
* download, distribute, activate CDH parcels
* download, distribute Accumulo parcels
* create Accumulo service
* stop cluster
* `/etc/init.d/cloudera-scm-server stop`
* `/etc/init.d/mysqld stop`
* `docker commit 59a9980afa3c  geomesa-docker/docker-uber:1.2.5-01-accumulo`

### Setting up Accumulo

#### Ports to expose
* HDFS UI: 50070
* 

* start image `sudo docker run  -p 7180:7180 geomesa-docker/docker-uber:1.2.5-01-accumulo bash`

* start CM **Wrap it as startup script**
```
/etc/init.d/mysqld restart
/etc/init.d/cloudera-scm-server restart
/etc/init.d/cloudera-scm-agent restart
```
* list geomesa distro
```
ls -la /tmp/geomesa-releases/geomesa-dist-1.2.5/geomesa-1.2.5/
total 28
drwxr-xr-x 4 root  root  4096 Aug 16 21:41 .
drwxr-xr-x 3 root  root  4096 Aug 16 21:41 ..
drwxr-xr-x 8 root  root  4096 Aug 16 21:43 dist
drwxr-xr-x 3 root  root  4096 Aug 16 21:41 docs
-rw-r--r-- 1 10197 8868 10173 Aug 15 04:59 LICENSE.txt
```

* Install extension for Accumulo
`cat /tmp/geomesa-releases/geomesa-dist-1.2.5/geomesa-1.2.5/dist/accumulo/install-geomesa-namespace.sh`

To install the distributed runtime JAR, use the `install-geomesa-namespace.sh` script in the `geomesa-$VERSION/dist/accumul` directory.

* start HDFS, ZK, Accumulo
* run 
```
sudo -u accumulo /tmp/geomesa-releases/geomesa-dist-1.2.5/geomesa-1.2.5/dist/accumulo/install-geomesa-namespace.sh \
-u accumulo \
-n oss_quark \
-d accumulo \
-g /tmp/geomesa-releases/geomesa-dist-1.2.5/geomesa-1.2.5/dist/accumulo/geomesa-accumulo-distributed-runtime-1.2.5.jar 
``` 

```
sudo -u accumulo /tmp/geomesa-releases/geomesa-dist-1.2.5/geomesa-1.2.5/dist/accumulo/run.sh \
-u root \
-p secret \
-n oss_quark \
-d accumulo \
-g /tmp/geomesa-releases/geomesa-dist-1.2.5/geomesa-1.2.5/dist/accumulo/geomesa-accumulo-distributed-runtime-1.2.5.jar 
``` 

System User=accumulo
Trace user=root

* response:
```
createnamespace... 

Shell - Apache Accumulo Interactive Shell
- 
- version: 1.6.0-cdh5.1.4
- instance name: accumulo
- instance id: 379fa751-a841-43e3-8bd1-a480cab4b1f3
- 
- type 'help' for a list of available commands
- 
root@accumulo> createnamespace oss_quark
root@accumulo>  grant NameSpace.CREATE_TABLE -ns oss_quark -u root
root@accumulo>  config -s general.vfs.context.classpath.oss_quark=hdfs://quickstart.cloudera:8020accumulo/oss_quark/.*.jar
root@accumulo>  config -ns oss_quark -s table.classpath.context=oss_quark
root@accumulo> 
root@accumulo> 
Successfully installed GeoMesa distributed runtime JAR.
```
looks like it worked!


#### 
* cloudera-scm-agent reports to localhost, but listener is on the 0.0.0.0 
 
### docker-compose
Multiple images. Good for production installation imitation