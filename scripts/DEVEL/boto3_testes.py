#!/usr/bin/python

import sys

(theother) = (sys.argv[1])
import boto3

e = boto3.client('ec2').describe_instances()
possible = {}

for r in e['Reservations']:
  for i in r['Instances']:
    if 'PrivateIpAddress' in i:
     p = i['PrivateIpAddress']
     if 'NetworkInterfaces' in i:
        for n in i['NetworkInterfaces']:
          if 'Association' in n and 'PublicIp' in n['Association']:
            u = n['Association']['PublicIp']
            if u == theother or p == theother:
              print("found")
              possible['id'] = i['InstanceId']
              possible['public'] = u
              possible['private'] = p
              break

print(possible)
