#!/bin/bash

# Step 1: Apply the YAML file to create the job
printf "____________________________________________________________________________________\n"
printf "## Deploy the workload -->  kubectl apply -f s3cphello-job.yaml\n"
kubectl apply -f s3cphello-job.yaml

# Wait for the job to complete
printf "____________________________________________________________________________________\n"
printf "## Waiting for the job to fetch the credentials...\n"
#kubectl wait --for=condition=complete --timeout=60s job/s3cphello -n internal2cdemo
wo=$(kubectl wait --for=condition=complete --timeout=40s job/s3cphello -n internal2cdemo 2>&1)
printf "## %s...\n" "$wo"
if [[ $wo == *"error"* ]]; then
    echo "Unable to get credentials, exiting"
    exit -1
fi

# Step 2: Print the pods
printf "____________________________________________________________________________________\n"
printf "## Get all the pods...\n"
kubectl get pods -n internal2cdemo

# Step 3: Get the pod name
pod_name=$(kubectl get pods -n internal2cdemo -o=jsonpath='{.items[0].metadata.name}' -l job-name=s3cphello)

# Step 4: Get the credentials
printf "____________________________________________________________________________________\n"
printf "## Temporary credentials...\n"
kubectl logs $pod_name -c aws-wlinitcontainer -n internal2cdemo --tail 100 -f > credentials.log &

# Step 5: Wait for credentials to be fetched
while ! grep -q "aws_access_key_id" credentials.log; do
  sleep 5
done

# Step 6: Get the logs from the s3cphello pod
printf "____________________________________________________________________________________\n"
printf "## Output from the workload logs...\n"
kubectl logs $pod_name -c s3cphello -n internal2cdemo --tail 100 -f

# Step 6: Clean up
rm credentials.log
kubectl logs $pod_name -c aws-wlinitcontainer -n internal2cdemo > /dev/null 2>&1