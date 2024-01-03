#!/bin/bash

# Step 1: Apply the YAML file to create the job
printf "_______________________________________________________________\n"
printf "## Deploy the workload -->  kubectl apply -f rds-hello-job.yaml\n"
kubectl apply -f /home/ubuntu/tln/internal2cdemo/podspecs/srcapp/rds-hello-job.yaml

# Wait for the job to complete
printf "_______________________________________________________________\n"
printf "## Waiting for the job to fetch the credentials with the help of Ubyon's attestor...\n"
#kubectl wait --for=condition=complete --timeout=60s job/rdshello -n internal2cdemo
wo=$(kubectl wait --for=condition=complete --timeout=30s job/rdshello -n internal2cdemo 2>&1)
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
pod_name=$(kubectl get pods -n internal2cdemo -o=jsonpath='{.items[0].metadata.name}' -l job-name=rdshello)

# Step 4: Get the credentials
printf "_______________________________________________________________\n"
printf "## Temporary credentials...\n"
kubectl logs $pod_name -c rds-wlinitcontainer -n internal2cdemo --tail 100 -f > credentials.log &

max_wait_time=15  # Maximum wait time in seconds
start_time=$(date +%s)

# Step 5: Wait for credentials to be fetched
while true; do
    if grep -q "exit" credentials.log ; then
        break
    else
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))

        if [ "$elapsed_time" -ge "$max_wait_time" ]; then
            echo "Maximum wait time reached. exiting."
            break
        fi

        sleep 3
    fi
done

# Step 6: Get the logs from the rdshello pod
printf "_______________________________________________________________\n"
printf "## Output from the workload logs...\n"
kubectl logs $pod_name -c rdshello -n internal2cdemo --tail 100 -f

# Step 7: Clean up
rm credentials.log
kubectl logs $pod_name -c rds-wlinitcontainer -n internal2cdemo > /dev/null 2>&1
