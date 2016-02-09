## Usage

This repo contents can be used to build a fedora 23 GCE image by first building a Docker image and then running it.

Building the Docker image is as easy as running `make`.

If your docker host alread has gcloud access you can create an GCE image with the following command:

```
docker run --rm -it -v $HOME/.config/gcloud:/.config/gcloud local/atomic-gce-builder:latest <target-GCE-project>
```

If your docker host doesn't have gcloud access you can create the GCE image with the following command:

```
docker run --rm -it local/atomic-gce-builder:latest <target-GCE-project>
```

Alternatively if you have already downloaded an Fedora Atomic .xz file you can pass it in to the container and it will use it instead of downloading a new copy:
```
docker run --rm -it -v $HOME/.config/gcloud:/.config/gcloud -v <PATH-TO-IMAGES-PARENT_DIR>:/build local/atomic-gce-builder:latest <target-GCE-project>
```
or
```
docker run --rm -it -v <PATH-TO-IMAGES-PARENT_DIR>:/build local/atomic-gce-builder:latest <target-GCE-project>
```

## Know Issues
The scripts clean up after themselves when everything works OK but artifacts (specifically Google Storage Buckets) can be left around on failure.  You can find them and deleteing them in the console by looking for buckes with names like `fedora-atomic-gce-EPOCH_STAMP`
