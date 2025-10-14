---
title: The Pod in Podman
layout: post
---

## What is Podman?

> Podman is an open source container, pod, and container image management engine. Podman makes it easy to find, run, build, and share containers.
>
> -- See [https://podman.io/features](https://podman.io/features)

If you are new to Podman then I recommend watching this [IBM Technology "What is Podman? How is it Different Than Docker?" video](https://www.youtube.com/watch?v=5WML8gX2F1c):

<iframe width="560" height="315" src="https://www.youtube.com/embed/5WML8gX2F1c?si=x9iBeBsxo57q3TnK" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

## Let there be pods!

Just like `docker`, `podman` can build and run containers that live next to the other.

But just like Kubernetes, `podman` can define _pods_ that host _multiple_ containers.

Paraphrasing the [Kubernetes documentation on pods](https://kubernetes.io/docs/concepts/workloads/pods/):

> A Pod (as in a pod of whales or pea pod) is a group of one or more containers, with shared storage and network resources, and a specification for how to run the containers.
> A Pod's contents are always co-located and co-scheduled, and run in a shared context.
> A Pod models an application-specific "logical host": it contains one or more application containers which are relatively tightly coupled.
> In non-cloud contexts, applications executed on the same physical or virtual machine are analogous to cloud applications executed on the same logical host.

Vastly simplifying concepts you can think of a _pod_ as logical unit equivalent to a _machine_ / _host_.

### Example app

Let's use a simple 2-containers application:

- `foo` is a Node app exposing a HTTP endpoint on port 3001
- `bar` does the same, but on port 3000
- `foo` makes a HTTP client request to `bar` and decorates the payload to make a response.

The `bar` app responds as in:

```
$ curl localhost:3000
Hello from bar app%
```

The `foo` app first makes a HTTP request to `bar`, then wraps the response between 2 lines (`---- fetching from bar ----` and `---- done ----`):

```
$ curl localhost:3001
---- fetching from bar ----
Hello from bar app
---- done ----
```

The code of `bar` is:

```javascript
const { createServer } = require('node:http');

const hostname = '0.0.0.0';
const port = 3000;

const server = createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end('Hello from bar app');
});

server.listen(port, hostname, () => {
  console.log(`[bar] Server running at http://${hostname}:${port}/`);
});
```

while the code of `foo` is:

```javascript
const http = require('node:http');

const hostname = '0.0.0.0';
const port = 3001;

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.write('---- fetching from bar ----\n');
  http.get('http://localhost:3000', (resp) => {
    resp.on('data', (chunk) => res.write(chunk));
    resp.on('end', () => res.end('\n---- done ----\n'));
  });
});

server.listen(port, hostname, () => {
  console.log(`[foo] Server running at http://${hostname}:${port}/`);
});
```

### Let's have containers!

Creating container images in Podman is not very different from what you might be used to with Docker.

Let's have a `Containerfile` for `foo` (you can repeat the process for `bar` by changing exposed port to 3000):


```dockerfile
FROM docker.io/library/node
WORKDIR /app
COPY app.js ./
EXPOSE 3001
CMD [ "node", "app.js" ]
```

You can build the container image with `podman build`:

```
$ podman build . --tag foo-app
STEP 1/5: FROM docker.io/library/node
STEP 2/5: WORKDIR /app
--> Using cache cb6cce87d57c1e551af3a542dbc16f46e3845d89914041293b086cc87422cd7a
--> cb6cce87d57c
STEP 3/5: COPY app.js ./
--> Using cache e290cd9a99acb46233462ce4d1f72b996e91f58fec7250207454780ff0206c88
--> e290cd9a99ac
STEP 4/5: EXPOSE 3001
--> Using cache 390ba14a42564fa4ad01d77368d7b839a96f8fd4fe3ff845fc1ac4761c86233a
--> 390ba14a4256
STEP 5/5: CMD [ "node", "app.js" ]
--> Using cache 6ccf2a3dd8b14b50404ba786d160646c081152ef84354e6b90923121cd4c6d1f
COMMIT foo-app
--> 6ccf2a3dd8b1
Successfully tagged localhost/foo-app:latest
6ccf2a3dd8b14b50404ba786d160646c081152ef84354e6b90923121cd4c6d1f
```

### Let's have pods!

Now that we have `foo-app` and `bar-app` container images, let's create a pod:

```
$ podman pod create --name node-apps -p 3001:3001
20b79d10cba251f5ac89ebaac92fc89de6d4761fcbd19c62da08e02109329655
```

This creates a pod named `node-apps`.
You can also see a familiar port mapping where the host port 3001 is exposed externally on port 3001.

This means that once containers for `foo` and `bar` have been attached, only `foo` will be reachable from the outside world.
The `bar` container will only be available from within the pod, so when `foo` makes a HTTP client request to `localhost:3000` it will work (remember that containers on a pod are on the same "host").

Here's how to deploy containers to the pod:

```
$ podman run -dt --pod node-apps bar-app:latest
42cd68be34f1ac824eec0e9efb4b1ccaff07b443601a72e1bb73a4a012c7109d
$ podman run -dt --pod node-apps foo-app:latest
f058a9ff57a71b5a2d149a227db7c47616d3ca28459cb237bb535c05630b398c
```

We can check that everything is working:

```
$ podman ps -a --pod
CONTAINER ID  IMAGE                                                  COMMAND      CREATED         STATUS         PORTS                   NAMES               POD ID        PODNAME
1dd231d291bf  localhost/podman-pause:5.0.0-dev-8a643c243-1710720000               11 minutes ago  Up 55 seconds  0.0.0.0:3001->3001/tcp  20b79d10cba2-infra  20b79d10cba2  node-apps
42cd68be34f1  localhost/bar-app:latest                               node app.js  55 seconds ago  Up 55 seconds  0.0.0.0:3001->3001/tcp  keen_yalow          20b79d10cba2  node-apps
f058a9ff57a7  localhost/foo-app:latest                               node app.js  51 seconds ago  Up 51 seconds  0.0.0.0:3001->3001/tcp  pensive_swanson     20b79d10cba2  node-apps
```

We can check that the `bar` container is not reachable:

```
$ curl localhost:3000
curl: (7) Failed to connect to localhost port 3000 after 0 ms: Couldn't connect to server
```

while the `foo` container is reachable:

```
$ curl localhost:3001
---- fetching from bar ----
Hello from bar app
---- done ----
```

Last but not least, since a pod is a logical unit, we can turn everything down all at once:

```
$ podman pod kill node-apps
20b79d10cba251f5ac89ebaac92fc89de6d4761fcbd19c62da08e02109329655
$ podman pod rm node-apps
20b79d10cba251f5ac89ebaac92fc89de6d4761fcbd19c62da08e02109329655
```

💡 Note that pods can also be very useful in development settings.
There are indeed a few instances where I have replaced _Docker Compose_ with plain Kubernetes pod descriptors, typically to run middleware such as PostgreSQL, Apache Kafka, etc.

## What if we could get... Kubernetes pods?

This is where things get even more interesting: Podman can work with Kubernetes containers, pods and volumes.

### Generating Kubernetes descriptors from Podman

Podman can generate Kubernetes descriptors for containers, pods and volumes it manages.

Back to the `node-apps` pod we had manually created before, we can ask Podman to generate us the following YAML payload:

```
$ podman kube generate node-apps
# Save the output of this file and use kubectl create -f to import
# it into Kubernetes.
#
# Created with podman-5.0.0-dev-8a643c243
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: "2024-04-30T21:03:42Z"
  labels:
    app: node-apps
  name: node-apps
spec:
  containers:
  - args:
    - node
    - app.js
    env:
    - name: TERM
      value: xterm
    image: localhost/bar-app:latest
    name: determinedhermann
    ports:
    - containerPort: 3001
      hostPort: 3001
    tty: true
  - args:
    - node
    - app.js
    env:
    - name: TERM
      value: xterm
    image: localhost/foo-app:latest
    name: amazingdriscoll
    tty: true
```

With a little cleanup and polishing, this pod definition can be simplified as:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: node-apps 
  name: node-apps
spec:
  containers:
    - name: bar
      image: bar-app:latest
    - name: foo
      image: foo-app:latest
      ports:
        - containerPort: 3001
          hostPort: 3001
```

### Podman can consume Kubernetes resources

Podman can directly consume the pod definition above:

```
$ podman kube play --replace pod.yaml
Pods stopped:
b236ec4ebc3a584fd4fff502f3ea547f258671ff4eee59da5d440aeb5c78643a
Pods removed:
b236ec4ebc3a584fd4fff502f3ea547f258671ff4eee59da5d440aeb5c78643a
Secrets removed:
Volumes removed:
Pod:
77d8e61fe855a85fd9e388b6ba783add3b81f2481b79feb63d961ecfb19c0b1a
Containers:
7075333e4fe277f9524da64290991b62d2fbaa85f3d5e5958552dca0ded748d5
aa227002f0d076a624025ba9d9c4761340779fa7a63536b2d68e304317853bfc
```

You can feed Podman with more than pod Kubernetes definitions.
At the time of this writing, `podman kube play` supports _Pods_, _Deployments_, _DaemonSets_ and _PersistentVolumeClaims_ resources!

## Conclusion

Podman is fun, but people often forget that there is... well... "Pod" in "Podman" 😄

I personaly find it quite compelling in development settings.
How about you? 
Have you found some interesting patterns? 
I'd be interested to hear about it! _(check my social networks and ping me)_
