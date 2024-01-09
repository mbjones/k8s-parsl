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

### Creating a PVC for use in a parsl app

The easiest way to create a volume for testing is with [dynamically allocated cephfs volumes](https://github.com/DataONEorg/k8s-cluster/blob/main/storage/Ceph/Ceph-CSI-CephFS.md#provisioning-dynamic-cephfs-volumes). However, to control volume names you may want to create static volumes, which are described here.

To create a static PVC, one needs to create a Persistent Volume and its associated secret, and then use that in a Persistent Volume Claim. At NCEAS and DataONE, these should be named following our [volume and volume claim naming conventions](https://github.com/DataONEorg/k8s-cluster/blob/main/storage/storage.md#dataone-volume-naming-conventions). 

As a prerequisite, ask a system admin to create a  CephFS static volume of the approroate size, and they will provide the metadata needed below for the configuration files here. 

First, create a secret object that contains the `userId` and `userKey` for the Ceph volume. In the Ceph client file configurations, the userid will likely contain a prefix that should be removed -- for example, change `client.k8s-dev-pdg-subvol-user` to `k8s-dev-pdg-subvol-user`. In addition, in the Ceph user configuration files, the `userKey` is already base64 encoded, so it will appear as such. Put the Ceph-provided base64 string in the `stringData.userKey` field, which upon creation will be base64-encoded again. If you decide to base64-encode these values yourself, be sure to 1) not accidentally include newlines or other extraneous whitespace (e.g. use `echo -n` when passing the value to be encoded), and 2) use the yaml `data` key rather than `stringData` to indicate that the values have already been encoded.

Note that in the examples below I have changed the keys to not use the real keys, so this example will not work verbatim.

```bash
❯ cat pdg-secret.yaml
apiVersion: v1
kind: Secret
type: Opaque
metadata:
apiVersion: v1
  name: csi-cephfs-pdgrun-secret
apiVersion: v1
  namespace: ceph-csi-cephfs
apiVersion: v1
stringData:
  userID: k8s-dev-pdg-subvol-user
  userKey: ODk3Mjk5OTg3Nzc3Nwo=
❯ kubectl -n ceph-csi-cephfs apply -f pdg-secret.yaml
secret/csi-cephfs-pdgrun-secret created
```

Next, create a Persistent Volume using that secret to link to the underlying Ceph volume that was created. Note the other Ceph metadata is in this yaml configuration file. For example:

```bash
❯ cat pdg-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: cephfs-pdgrun-dev
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 10Gi
  csi:
    driver: cephfs.csi.ceph.com
    nodeStageSecretRef:
      # node stage secret name
      name: csi-cephfs-pdgrun-secret
      # node stage secret namespace where above secret is created
      namespace: ceph-csi-cephfs
    volumeAttributes:
      # Required options from storageclass parameters need to be added in volumeAttributes
      "clusterID": "8aa3d4a0-b577-a1ba-dba5-ddc787bfc812"
      "fsName": "cephfs"
      "staticVolume": "true"
      "rootPath": /volumes/k8s-dev-pdg-subvol-group/k8s-dev-pdg-subvol/674cdd70-2571-1fff-8a4e-e6cf1d945d7a
    # volumeHandle can be anything, need not to be same
    # as PV name or volume name. keeping same for brevity
    volumeHandle: cephfs-pdgrun-dev
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
❯ kubectl apply -f pdg-pv.yaml
persistentvolume/cephfs-pdgrun-dev created
```

Finally, create the volume claim to be used in your kubernetes application by binding to the volume you created:

```bash
❯ cat pdg-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pdgrun-dev-0
  namespace: pdgrun
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  volumeMode: Filesystem
  # volumeName should be same as PV name
  volumeName: cephfs-pdgrun-dev
❯ kubectl -n pdgrun apply -f pdg-pvc.yaml
persistentvolumeclaim/pdgrun-dev-0 created
❯ kubectl -n pdgrun get pvc -o wide
NAME           STATUS   VOLUME              CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
pdgrun-dev-0   Bound    cephfs-pdgrun-dev   10Gi       RWX                           62s   Filesystem
```
