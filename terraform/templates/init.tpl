#!/bin/bash

yum -y update
sudo -y amazon-linux-extras install epel
yum -y install python-pip
pip install boto3
pip install requests
echo -e "import requests\nimport json\nimport boto3\nimport uuid\nimport time\nimport random\nclient = boto3.client('kinesis', region_name='eu-central-1')\npartition_key = str(uuid.uuid4())\nwhile True:\n\tr = requests.get('https://randomuser.me/api/?exc=login')\n\tdata = json.dumps(r.json())\n\tresponse = client.put_record(StreamName='my-data-stream', Data=data, PartitionKey=partition_key)\n\ttime.sleep(random.uniform(0, 1))\n\n" > put-request.py
chmod +x put-request.py
python put-request.py