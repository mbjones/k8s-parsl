# k8s-parsl

Run a parsl example program on a K8S cluster.

## Building the image

Build and publish an image to be run to an appropropriate network-accessible image repository.
Here we use ghcr.io as an example.

```
docker build -t ghcr.io/mbjones/k8sparsl:0.2 .
echo $GITHUB_PAT | docker login ghcr.io -u mbjones --password-stdin
docker push ghcr.io/mbjones/k8sparsl:0.2
```
