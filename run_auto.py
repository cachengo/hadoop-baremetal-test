#!/usr/bin/python3

import subprocess, os 
import xml.dom.minidom

def log(msg):
   try:
      f = open("log.txt", encoding='utf-8', mode= 'a')
      print(msg)
      f.write(msg)
   finally:
      f.close()


def make_tmpl():
   subprocess.run('./make-tmpl.sh')

#define parameter array
parameters = [
   {'name':'yarn.scheduler.minimum-allocation-mb', 'def':'682', 'min':'100', 'max':'4000', 'file':'yarn-site.xml'} ,
   {'name':'yarn.scheduler.maximum-allocation-mb', 'def':'2500' , 'min':'100','max':'4000' , 'file':'yarn-site.xml'} ,
   {'name':'yarn.nodemanager.resource.memory-mb',  'def':'2500',  'min':'100','max':'4000', 'file':'yarn-site.xml'} ,
   {'name':'yarn.app.mapreduce.am.command-opts',   'def':' -Xmx1091m',  'min':'-Xmx100m','max':'-Xmx3500m', 'file':'yarn-site.xml'} ,
   {'name':'yarn.scheduler.maximum-allocation-vcores','def':'4','min':'1','max':'6', 'file':'yarn-site.xml'} ,

   {'name':'yarn.app.mapreduce.am.resource.mb ','def':'272','min':'50','max':'3500', 'file':'mapred-site.xml'} ,
   {'name':'mapreduce.map.memory.mb','def':'682','min':'100','max':'4000', 'file':'mapred-site.xml'} ,
   {'name':'mapreduce.reduce.memory.mb','def':'1364','min':'100','max':'4000', 'file':'mapred-site.xml'} ,
   {'name':'mapreduce.job.maps','def':'6','min':'1','max':'20', 'file':'mapred-site.xml'} ,
   {'name':'mapreduce.job.reduces','def':'5','min':'1','max':'20', 'file':'mapred-site.xml'} ,
   {'name':'mapreduce.map.java.opts','def':'-Xmx545m','min':'-Xmx100m','max':'-Xmx1500m', 'file':'mapred-site.xml'} ,
   {'name':'mapreduce.reduce.java.opts','def':'-Xmx1091m','min':'-Xmx200m','max':'-Xmx3000m', 'file':'mapred-site.xml'} ,
   {'name':'mapreduce.task.io.sort.mb','def':'2500','min':'100','max':'4000', 'file':'mapred-site.xml'} ,

   {'name':'yarn.app.mapreduce.am.resource.memory-mb', 'def':'2500' ,'min':'100','max':'4000', 'file':'resource-types.xml'} ,
   {'name':'mapreduce.map.resource.vcores','def':'4','min':'1','max':'4', 'file':'resource-types.xml'} ,
   {'name':'mapreduce.reduce.resource.vcores','def':'4','min':'1','max':'4', 'file':'resource-types.xml'} ,
   {'name':'yarn.app.mapreduce.am.resource.vcores','def':'4','min':'1','max':'4', 'file':'resource-types.xml'} ,

   {'name':'yarn.scheduler.capacity.root.a.capacity','def':'100.00','min':'1','max':'100', 'file':'capacity-scheduler.xml'} ,
   {'name':'yarn.scheduler.capacity.root.capacity','def':'100.00','min':'1','max':'100', 'file':'capacity-scheduler.xml'} ,
   {'name':'yarn.scheduler.capacity.root.a.maximum-allocation-mb','def':'2500','min':'100','max':'4000', 'file':'capacity-scheduler.xml'} ,
   {'name':'yarn.scheduler.capacity.root.a.maximum-allocation-vcores','def':'4','min':'1','max':'4', 'file':'capacity-scheduler.xml'} ,
]

def main():

   print('Creating template files')
   try:
      os.remove('log.txt')
   except:
      pass
   minmax = ['min','max']

   for param in parameters:
      for type in minmax:
         log("Running experiment " +type+" on parameter:" + param['name']+'\n')
         make_tmpl()

         #find the tag we need to change for this test
         xmlFile = 'config/'+param['file']
         document = xml.dom.minidom.parse(xmlFile)
         nodelist = document.getElementsByTagName('name')

         for node in nodelist:
            if node.firstChild.nodeValue == param['name']:
               parent = node.parentNode # <property> tag
               for child in parent.childNodes:
                  if child.nodeName == 'value':
                     #print(child.firstChild.nodeValue)
                     child.firstChild.nodeValue = param[type]
                     break
         
         modified_xml = document.toprettyxml()
         f = open(xmlFile,mode="w")
         f.write(modified_xml)
         f.close() 

         try:
            subprocess.run('./start-cluster2.sh')
         except subprocess.SubprocessError as ex:
            print("Exception starting cluster:" + ex)

         output =''
         try:
            output = subprocess.getoutput('./run_dfsio_write.sh')
            try:
               os.mkdir('results')
            except OSError:
               pass

            output_file="./results/"+param['name']+"."+param[type]

            print("Writing command output to file "+output_file)
            f=open(output_file,mode="w")
            f.write(output)
            f.close()

         except subprocess.SubprocessError as ex:
            print('Error running TestDFSIO write')

      

main()   


