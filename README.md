# k8s-parsl

Run a parsl example program on a K8S cluster.

## Building the image

Build and publish an image to be run to an appropropriate network-accessible image repository.
Here we use ghcr.io as an example.

```
docker build -t ghcr.io/mbjones/k8sparsl:0.3 .
echo $GITHUB_PAT | docker login ghcr.io -u mbjones --password-stdin
docker push ghcr.io/mbjones/k8sparsl:0.3
```

## Configuring k8s cluster access

To access the k8s cluster, you must have access to credentials for a service account that
has appropriate access to the kubernetes API. For the purposes of this example, 
we created a namespace `pdgrun` with associated service account `pdgrun` on the cluster. You
can set up your local kubernetes environment by copying a kubectl config file to `~/.kube/config`
on a server with access to the cluster. This file contains the cluster details, and a context with
configured access credentials. In our case, the credentials are:

```
$ kubectl config get-contexts
CURRENT   NAME               CLUSTER           AUTHINFO           NAMESPACE
*         prod-pdgrun        prod-dataone      prod-pdgrun        pdgrun
```

Once this file is in place, you can use the parsl kubernetes provider to connect.

## Set up a virtualenv on the server

This example uses python3.10. You must use the same minor python version to launch the job and in the
Docker image supporting job execution.

Be sure you have the software needed to run parsl:

```
$ pip install -r requirements.txt
```

## Launching the parsl job

The parsl job is configured using a `parsl.config.Config` object as set up in the `parslexec.py` file 
in this repository. That file is then imported by the `example-parsl.py` script that runs a parsl job. 
This simple job emulates a long operation by sleeping for 5 seconds before returning the product of 
its two inputs. Run the example job with:

```
$ python example-parsl.py
```

## Persistent data volumes

While this example does not require external data, most real applications will. For that, they
generally would require mounting one or more persistent volumes in the pods running the job. The
`parslexec.py` configuration file shows how to provide a list of tuples of pvc-name and mount-point 
for each volume to be mounted in the pods.  Because multiple pods will be mounting the same volumes,
be sure to not allow for resource conflicts between pods running in parallel.
