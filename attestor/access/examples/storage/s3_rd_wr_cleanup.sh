#!/bin/bash

pod_name=$(kubectl get pods -n internal2cdemo -o=jsonpath='{.items[0].metadata.name}' -l job-name=s3cphello)

# Delete the job
kubectl delete -f s3cphello-job.yaml

# Check if the job is deleted
printf "Checking if the job s3cphello is deleted...\n"
while kubectl get job s3cphello -n internal2cdemo > /dev/null 2>&1; do
  sleep 5
done

# Print the remaining pods
printf "Remaining pods in namespace internal2cdemo:\n"
printf "___________________________________________\n"
kubectl get pods -n internal2cdemo | grep s3cphello

# Ask the attestor to propagate delete to the Control Plane
att_pod_name=$(kubectl get pods -n internal2cdemo -l app=ubyon-workload-attestor -o=jsonpath='{.items[0].metadata.name}')
kubectl exec  -n internal2cdemo $att_pod_name -- /usr/bin/curl -v -XDELETE "http://ubyon-workload-attestor.internal2cdemo.svc.cluster.local:34323/workload-agent/v1/workloads?type=K8S-POD&name=internal2cdemo-$pod_name&namespace=internal2cdemo"
printf "\n\n\n"