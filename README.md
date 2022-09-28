# Deploy k3s backed by Flux

This repository and README replicate the following work: https://github.com/onedr0p/flux-cluster-template

This home lab consists of:

- ⛵ [k3s](https://k3s.io) cluster installed using [Ansible](https://www.ansible.com).
- 🔹 GitOps setup using [Flux](https://fluxcd.io) for cluster management.
- ☁️ DNS zone and root record created in Cloudflare using [Terraform](https://www.terraform.io).
- 🔁 Dynamic DNS service managed by [Cloudflare DDNS](https://github.com/timothymiller/cloudflare-ddns) running in the cluster.
- 🌐 DNS record updates managed by [ExternalDNS](https://github.com/kubernetes-sigs/external-dns).
- 🔐 All secrets in the repo are encrypted with an [Age](https://github.com/FiloSottile/age) key via [SOPS](https://toolkit.fluxcd.io/guides/mozilla-sops/) integrations.

## Overview

- [Introduction](https://github.com/alekssro/home-lab#-introduction)
- [Systems](https://github.com/alekssro/home-lab#-systems)
- [Prerequisites](https://github.com/alekssro/home-lab#-prerequisites)
- [Repository structure](https://github.com/alekssro/home-lab#-repository-structure)
- [Lets go!](https://github.com/alekssro/home-lab#-lets-go)
- [Post installation](https://github.com/alekssro/home-lab#-post-installation)
- [Troubleshooting](https://github.com/alekssro/home-lab#-troubleshooting)
- [What's next](https://github.com/alekssro/home-lab#-whats-next)
- [Thanks](https://github.com/alekssro/home-lab#-thanks)

## 👋 Introduction

The following components are installed in the [k3s](https://k3s.io/) cluster. Most are only included to get a minimum viable cluster up and running.

- [flux](https://toolkit.fluxcd.io/) - GitOps operator for managing Kubernetes clusters from a Git repository
- [kube-vip](https://kube-vip.io/) - Load balancer for the Kubernetes control plane nodes
- [metallb](https://metallb.universe.tf/) - Load balancer for Kubernetes services
- [cert-manager](https://cert-manager.io/) - Operator to request SSL certificates and store them as Kubernetes resources
- [calico](https://www.tigera.io/project-calico/) - Container networking interface for inter pod and service networking
- [external-dns](https://github.com/kubernetes-sigs/external-dns) - Operator to publish DNS records to Cloudflare (and other providers) based on Kubernetes ingresses
- [k8s_gateway](https://github.com/ori-edge/k8s_gateway) - DNS resolver that provides local DNS to your Kubernetes ingresses
- [traefik](https://traefik.io) - Kubernetes ingress controller used for a HTTP reverse proxy of Kubernetes ingresses
- [local-path-provisioner](https://github.com/rancher/local-path-provisioner) - provision persistent local storage with Kubernetes
- [longhorn](https://longhorn.io/) - distributed block storage system for Kubernetes

_Additional applications include [filerun](https://filerun.com/), [heimdall](https://github.com/linuxserver/Heimdall), [error-pages](https://github.com/tarampampam/error-pages), [echo-server](https://github.com/Ealenn/Echo-Server), [system-upgrade-controller](https://github.com/rancher/system-upgrade-controller), [reflector](https://github.com/emberstack/kubernetes-reflector), and [reloader](https://github.com/stakater/Reloader)_

For provisioning, the following tools are used:

- [Ubuntu](https://ubuntu.com/download/server) - Universal operating system that supports running all kinds of home related workloads in Kubernetes
- [Ansible](https://www.ansible.com) - Provision the Ubuntu OS and install k3s
- [Terraform](https://www.terraform.io) - Provision an already existing Cloudflare domain and certain DNS records to be used with your k3s cluster

## 💻 Systems

The home lab consists of the follwing hardware:

- [Intel NUC7PJYHN](https://ark.intel.com/content/www/us/en/ark/products/130394/intel-nuc-kit-nuc7pjyhn.html) - 4 core, 8 thread, 8GB RAM, 256GB SSD (Ubuntu 22.04 LTS) - Master node
- [Raspberry Pi 4B](https://www.raspberrypi.org/products/raspberry-pi-4-model-b/) - 4 core, 4 thread, 4GB RAM, 128GB SD card (Ubuntu Server 22.04 LTS) - Worker node
- [Raspberry Pi 3B+](https://www.raspberrypi.org/products/raspberry-pi-3-model-b-plus/) - 4 core, 4 thread, 1GB RAM, 64GB SD card (Ubuntu Server 22.04 LTS) - Worker node

As you can see, there are two different architectures (ARM64/AMD64) involved, which means a large number of ~~headaches~~ opportunities for learning.

## 📦 Prerequisites

### 🔧 Workstation Tools

1. Install the **most recent versions** of the following CLI tools on your workstation, if you are using [Homebrew](https://brew.sh/) on MacOS or Linux skip to steps 3 and 4.

    * Required: [age](https://github.com/FiloSottile/age), [ansible](https://www.ansible.com), [flux](https://toolkit.fluxcd.io/), [gitleaks](https://github.com/zricethezav/gitleaks), [go-task](https://github.com/go-task/task), [ipcalc](http://jodies.de/ipcalc), [jq](https://stedolan.github.io/jq/), [kubectl](https://kubernetes.io/docs/tasks/tools/), [pre-commit](https://github.com/pre-commit/pre-commit), [sops](https://github.com/mozilla/sops), [terraform](https://www.terraform.io), [yq](https://github.com/mikefarah/yq)

    * Recommended: [direnv](https://github.com/direnv/direnv), [helm](https://helm.sh/), [kustomize](https://github.com/kubernetes-sigs/kustomize), [prettier](https://github.com/prettier/prettier), [stern](https://github.com/stern/stern), [yamllint](https://github.com/adrienverge/yamllint)

2. This guide heavily relies on [go-task](https://github.com/go-task/task) as a framework for setting things up. It is advised to learn and understand the commands it is running under the hood.

3. Install [go-task](https://github.com/go-task/task) via Brew

    ```sh
    brew install go-task/tap/go-task
    ```

4. Install workstation dependencies via Brew

    ```sh
    task init
    ```

### ⚠️ pre-commit

It is advisable to install [pre-commit](https://pre-commit.com/) and the pre-commit hooks that come with this repository.
[sops-pre-commit](https://github.com/k8s-at-home/sops-pre-commit) and [gitleaks](https://github.com/zricethezav/gitleaks) will check to make sure you are not by accident committing un-encrypted secrets.

1. Enable Pre-Commit

    ```sh
    task precommit:init
    ```

2. Update Pre-Commit, though it will occasionally make mistakes, so verify its results.

    ```sh
    task precommit:update
    ```

## 📂 Repository structure

The Git repository contains the following directories under `cluster` and are ordered below by how Flux will apply them.

```
📁 cluster      # k8s cluster defined as code
├─📁 base       # the entrypoint to flux, gitops operator, loaded before everything
├─📁 crds       # custom resources, loaded before 📁 core and 📁 apps
├─📁 core       # crucial apps, namespaced dir tree, loaded before 📁 apps
└─📁 apps       # regular apps, namespaced dir tree, loaded last
```

## 🚀 Lets go


📍 **All of the below commands** are run on your **local** workstation, **not** on any of your cluster nodes.

### 🔐 Setting up Age

📍 Here we will create a Age Private and Public key. Using [SOPS](https://github.com/mozilla/sops) with [Age](https://github.com/FiloSottile/age) allows us to encrypt secrets and use them in Ansible, Terraform and Flux.

1. Create a Age Private / Public Key

    ```sh
    age-keygen -o age.agekey
    ```

2. Set up the directory for the Age key and move the Age file to it

    ```sh
    mkdir -p ~/.config/sops/age
    mv age.agekey ~/.config/sops/age/keys.txt
    ```

3. Export the `SOPS_AGE_KEY_FILE` variable in your `bashrc`, `zshrc` or `config.fish` and source it, e.g.

    ```sh
    export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
    source ~/.bashrc
    ```

4. Keep the Age public key to fill out the [`.config.env`](https://github.com/alekssro/home-lab#-configuration) under `BOOTSTRAP_AGE_PUBLIC_KEY`, **note** the public key should start with `age`...

### ☁️ Global Cloudflare API Key

In order to use Terraform, `cloudflare-ddns` and `cert-manager` with the Cloudflare DNS challenge you will need to create an API key.

1. Log in into your Cloudflare account and create an API [here](https://dash.cloudflare.com/profile/api-tokens).

2. Under the `API Keys` section, create a global API Key.

3. Use the API Key in the configuration section below.

📍 You may wish to update this later on to a Cloudflare **API Token** which can be scoped to certain resources. For more information see the [Cloudflare docs on API Keys and Tokens](https://developers.cloudflare.com/api/).

### 📄 Configuration

📍 The `.config.env` file contains configuration that is needed by Ansible, Terraform and Flux.

1. Copy the `.config.sample.env` to `.config.env` and start filling out all the environment variables.

    **All are required** unless otherwise noted in the comments.

    ```sh
    cp .config.sample.env .config.env
    ```

2. Once that is done, verify the configuration is correct by running:

    ```sh
    task verify
    ```

3. If you do not encounter any errors run start having the script wire up the templated files and place them where they need to be.

    ```sh
    task configure
    ```

### ⚡ Preparing Ubuntu with Ansible

📍 Here we will be running an Ansible Playbook to prepare Ubuntu for running a Kubernetes cluster.

📍 Nodes are not security hardened by default, you can do this with [dev-sec/ansible-collection-hardening](https://github.com/dev-sec/ansible-collection-hardening) or similar if it supports Ubuntu 22.04.

1. Ensure you are able to SSH into your nodes from your workstation using a private SSH key **without a passphrase**. This is how Ansible is able to connect to your remote nodes.

   [How to configure SSH key-based authentication](https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server)

2. Install the Ansible deps

    ```sh
    task ansible:init
    ```

3. Verify Ansible can view your config

    ```sh
    task ansible:list
    ```

4. Verify Ansible can ping your nodes

    ```sh
    task ansible:ping
    ```

5. Run the Ubuntu Prepare Ansible playbook

    ```sh
    task ansible:prepare
    ```

6. Reboot the nodes

    ```sh
    task ansible:reboot
    ```

### ⛵ Installing k3s with Ansible

📍 Here we will be running an Ansible Playbook to install [k3s](https://k3s.io/) with [this](https://galaxy.ansible.com/xanmanning/k3s) wonderful k3s Ansible galaxy role. After completion, Ansible will drop a `kubeconfig` in `./provision/kubeconfig` for interacting with your cluster via `kubectl`.

☢️ If you run into problems, you can run `task ansible:nuke` to destroy the k3s cluster and start over.

1. Verify Ansible can view your config

    ```sh
    task ansible:list
    ```

2. Verify Ansible can ping your nodes

    ```sh
    task ansible:ping
    ```

3. Install k3s with Ansible

    ```sh
    task ansible:install
    ```

4. Verify the nodes are online

    ```sh
    task cluster:nodes
    # NAME           STATUS   ROLES                       AGE     VERSION
    # k8s-0          Ready    control-plane,master      4d20h   v1.21.5+k3s1
    # k8s-1          Ready    worker                    4d20h   v1.21.5+k3s1
    # k8s-2          Ready    worker                    4d20h   v1.21.5+k3s1
    ```

### ☁️ Configuring Cloudflare DNS with Terraform

📍 Review the Terraform scripts under `./provision/terraform/cloudflare/` and make sure you understand what it's doing (no really, review it).

If your domain already has existing DNS records **be sure to export those DNS settings before you continue**.

1. Pull in the Terraform deps

    ```sh
    task terraform:init
    ```

2. Review the changes Terraform will make to your Cloudflare domain

    ```sh
    task terraform:plan
    ```

3. Have Terraform apply your Cloudflare settings

    ```sh
    task terraform:apply
    ```

If Terraform was ran successfully you can log into Cloudflare and validate the DNS records are present.

The cluster application [external-dns](https://github.com/kubernetes-sigs/external-dns) will be managing the rest of the DNS records you will need.

### 🔹 GitOps with Flux

📍 Here we will be installing [flux](https://toolkit.fluxcd.io/) after some quick bootstrap steps.

1. Verify Flux can be installed

    ```sh
    task cluster:flux:verify
    # ► checking prerequisites
    # ✔ kubectl 1.21.5 >=1.18.0-0
    # ✔ Kubernetes 1.21.5+k3s1 >=1.16.0-0
    # ✔ prerequisites checks passed
    ```

2. Create the `flux-system` namespace

    ```sh
    task cluster:flux:namespace
    ```

3. Add the Age key to your cluster as a secret in-order for Flux to decrypt SOPS secrets

    ```sh
    task cluster:flux:secret
    ```

    📍 Variables defined in `./cluster/base/cluster-secrets.sops.yaml` and `./cluster/base/cluster-settings.yaml` will be usable anywhere in your YAML manifests under `./cluster` except `./cluster/base`

4. Push you changes to git

    📍 **Verify** all the `*.sops.yaml` and `*.sops.yml` files under the `./cluster` and `./provision` folders are **encrypted** with SOPS

    ```sh
    git add -A
    git commit -m "initial commit"
    git push
    ```

5. Install Flux

    📍 Due to race conditions with the Flux CRDs you will have to run the below command twice. There should be no errors on this second run.

    ```sh
    task cluster:flux:install
    # namespace/flux-system configured
    # customresourcedefinition.apiextensions.k8s.io/alerts.notification.toolkit.fluxcd.io created
    # ...
    # unable to recognize "./cluster/base/flux-system": no matches for kind "HelmRepository" in version "source.toolkit.fluxcd.io/v1beta1"
    ```

6. Verify Flux components are running in the cluster

    ```sh
    task cluster:pods -- -n flux-system
    # NAME                                       READY   STATUS    RESTARTS   AGE
    # helm-controller-5bbd94c75-89sb4            1/1     Running   0          1h
    # kustomize-controller-7b67b6b77d-nqc67      1/1     Running   0          1h
    # notification-controller-7c46575844-k4bvr   1/1     Running   0          1h
    # source-controller-7d6875bcb4-zqw9f         1/1     Running   0          1h
    ```

### 🎤 Verification Steps

_Mic check, 1, 2_ - In a few moments applications should be lighting up like a Christmas tree 🎄

You are able to run all the commands below with one task

```sh
task cluster:resources
```

1. View the Flux Git Repositories

    ```sh
    task cluster:gitrepositories
    ```

2. View the Flux kustomizations

    ```sh
    task cluster:kustomizations
    ```

3. View all the Flux Helm Releases

    ```sh
    task cluster:helmreleases
    ```

4. View all the Flux Helm Repositories

    ```sh
    task cluster:helmrepositories
    ```

5. View all the Pods

    ```sh
    task cluster:pods
    ```

6. View all the certificates and certificate requests

    ```sh
    task cluster:certificates
    ```

🏆 **Congratulations** if all goes smooth you'll have a Kubernetes cluster managed by Flux, your Git repository is driving the state of your cluster.

☢️ If you run into problems, you can run `task ansible:nuke` to destroy the k3s cluster and start over.

🧠 Now it's time to pause and go get some coffee ☕ because next is describing how DNS is handled.

## 📣 Post installation

### 🌐 DNS

📍 The [external-dns](https://github.com/kubernetes-sigs/external-dns) application created in the `networking` namespace will handle creating public DNS records. By default, `echo-server` is the only public domain exposed on your Cloudflare domain. In order to make additional applications public you must set an ingress annotation like in the `HelmRelease` for `echo-server`. You do not need to use Terraform to create additional DNS records unless you need a record outside the purposes of your Kubernetes cluster (e.g. setting up MX records).

[k8s_gateway](https://github.com/ori-edge/k8s_gateway) is deployed on the IP choosen for `${BOOTSTRAP_METALLB_K8S_GATEWAY_ADDR}`. Inorder to test DNS you can point your clients DNS to the `${BOOTSTRAP_METALLB_K8S_GATEWAY_ADDR}` IP address and load `https://hajimari.${BOOTSTRAP_CLOUDFLARE_DOMAIN}` in your browser.

You can also try debugging with the command `dig`, e.g. `dig @${BOOTSTRAP_METALLB_K8S_GATEWAY_ADDR} hajimari.${BOOTSTRAP_CLOUDFLARE_DOMAIN}` and you should get a valid answer containing your `${BOOTSTRAP_METALLB_TRAEFIK_ADDR}` IP address.

If your router (or Pi-Hole, Adguard Home or whatever) supports conditional DNS forwarding (also know as split-horizon DNS) you may have DNS requests for `${SECRET_DOMAIN}` only point to the  `${BOOTSTRAP_METALLB_K8S_GATEWAY_ADDR}` IP address. This will ensure only DNS requests for `${SECRET_DOMAIN}` will only get routed to your [k8s_gateway](https://github.com/ori-edge/k8s_gateway) service thus providing DNS resolution to your cluster applications/ingresses.

To access services from the outside world port forwarded `80` and `443` in your router to the `${BOOTSTRAP_METALLB_TRAEFIK_ADDR}` IP, in a few moments head over to your browser and you _should_ be able to access `https://echo-server.${BOOTSTRAP_CLOUDFLARE_DOMAIN}` from a device outside your LAN.

Now if nothing is working, that is expected. This is DNS after all!

### 🔐 SSL

SSL certificates are managed by [cert-manager](https://cert-manager.io/docs/). When testing new configuration, you may use the [Let's Encrypt Staging Environment](https://letsencrypt.org/docs/staging-environment/). This will hopefully reduce issues from ACME on requesting certificates until you are ready to use this in "Production".

Once you have confirmed there are no issues requesting your certificates replace `letsencrypt-staging` with `letsencrypt-production` in your ingress annotations for `cert-manager.io/cluster-issuer`

### 🤖 Renovatebot

[Renovatebot](https://www.whitesourcesoftware.com/free-developer-tools/renovate/) will scan your repository and offer PRs when it finds dependencies out of date. Common dependencies it will discover and update are Flux, Ansible Galaxy Roles, Terraform Providers, Kubernetes Helm Charts, Kubernetes Container Images, Pre-commit hooks updates, and more!

The base Renovate configuration provided in your repository can be view at [.github/renovate.json5](https://github.com/k8s-at-home/template-cluster-k3s/blob/main/.github/renovate.json5). If you notice this only runs on weekends and you can [change the schedule to anything you want](https://docs.renovatebot.com/presets-schedule/) or simply remove it.

To enable Renovate on your repository, click the 'Configure' button over at their [Github app page](https://github.com/apps/renovate) and choose your repository. Over time Renovate will create PRs for out-of-date dependencies it finds. Any merged PRs that are in the cluster directory Flux will deploy.

### 🪝 Github Webhook

Flux is pull-based by design meaning it will periodically check your git repository for changes, using a webhook you can enable Flux to update your cluster on `git push`. In order to configure Github to send `push` events from your repository to the Flux webhook receiver you will need two things:

1. Webhook URL - Your webhook receiver will be deployed on `https://flux-receiver.${BOOTSTRAP_CLOUDFLARE_DOMAIN}/hook/:hookId`. In order to find out your hook id you can run the following command:

    ```sh
    kubectl -n flux-system get receiver/github-receiver --kubeconfig=./provision/kubeconfig
    # NAME              AGE    READY   STATUS
    # github-receiver   6h8m   True    Receiver initialized with URL: /hook/12ebd1e363c641dc3c2e430ecf3cee2b3c7a5ac9e1234506f6f5f3ce1230e123
    ```

    So if my domain was `k8s-at-home.com` the full url would look like this:

    ```text
    https://flux-receiver.k8s-at-home.com/hook/12ebd1e363c641dc3c2e430ecf3cee2b3c7a5ac9e1234506f6f5f3ce1230e123
    ```

2. Webhook secret - Your webhook secret can be found by decrypting the `secret.sops.yaml` using the following command:

    ```sh
    sops -d ./cluster/apps/flux-system/webhooks/github/secret.sops.yaml | yq .stringData.token
    ```

    **Note:** Don't forget to update the `BOOTSTRAP_FLUX_GITHUB_WEBHOOK_SECRET` variable in your `.config.env` file so it matches the generated secret if applicable

Now that you have the webhook url and secret, it's time to set everything up on the Github repository side. Navigate to the settings of your repository on Github, under "Settings/Webhooks" press the "Add webhook" button. Fill in the webhook url and your secret.

### 💾 Storage

Rancher's `local-path-provisioner` is a great start for storage but soon you might find you need more features like replicated block storage, or to connect to a NFS/SMB/iSCSI server. Check out the projects below to read up more on some storage solutions that might work for you.

- [rook-ceph](https://github.com/rook/rook)
- [longhorn](https://github.com/longhorn/longhorn)
- [openebs](https://github.com/openebs/openebs)
- [nfs-subdir-external-provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner)
- [democratic-csi](https://github.com/democratic-csi/democratic-csi)
- [csi-driver-nfs](https://github.com/kubernetes-csi/csi-driver-nfs)
- [synology-csi](https://github.com/SynologyOpenSource/synology-csi)

### 🔏 Authenticate Flux over SSH

Authenticating Flux to your git repository has a couple benefits like using a private git repository and/or using the Flux [Image Automation Controllers](https://fluxcd.io/docs/components/image/).

By default this template only works on a public GitHub repository, it is advised to keep your repository public.

The benefits of a public repository include:

* Debugging or asking for help, you can provide a link to a resource you are having issues with.
* Adding a topic to your repository of `k8s-at-home` to be included in the [k8s-at-home-search](https://whazor.github.io/k8s-at-home-search/). This search helps people discover different configurations of Helm charts across others Flux based repositories.

<details>
  <summary>Expand to read guide on adding Flux SSH authentication</summary>

  1. Generate new SSH key:
      ```sh
      ssh-keygen -t ecdsa -b 521 -C "github-deploy-key" -f ./cluster/github-deploy-key -q -P ""
      ```
  2. Paste public key in the deploy keys section of your repository settings
  3. Create sops secret in `cluster/base/flux-system/github-deploy-key.sops.yaml` with the contents of:
      ```yaml
      # yamllint disable
      apiVersion: v1
      kind: Secret
      metadata:
          name: github-deploy-key
          namespace: flux-system
      stringData:
          # 3a. Contents of github-deploy-key
          identity: |
              -----BEGIN OPENSSH PRIVATE KEY-----
                  ...
              -----END OPENSSH PRIVATE KEY-----
          # 3b. Output of curl --silent https://api.github.com/meta | jq --raw-output '"github.com "+.ssh_keys[]'
          known_hosts: |
              github.com ssh-ed25519 ...
              github.com ecdsa-sha2-nistp256 ...
              github.com ssh-rsa ...
      ```
  4. Encrypt secret:
      ```sh
      sops --encrypt --in-place ./cluster/base/flux-system/github-deploy-key.sops.yaml
      ```
  5. Apply secret to cluster:
      ```sh
      sops --decrypt cluster/base/flux-system/github-deploy-key.sops.yaml | kubectl apply -f -
      ```
  6.  Update `cluster/base/flux-system/gotk-sync.yaml`:
      ```yaml
      ---
      apiVersion: source.toolkit.fluxcd.io/v1beta2
      kind: GitRepository
      metadata:
        name: flux-system
        namespace: flux-system
      spec:
        interval: 5m0s
        # 6a: Change this to your user and repo names
        url: ssh://git@github.com/$user/$repo
        ref:
          branch: main
        secretRef:
          name: github-deploy-key
      ```
  7. Commit and push changes
  8. Force flux to reconcile your changes
     ```sh
     task cluster:reconcile
     ```
  9. Verify git repository is now using SSH:
      ```sh
      task cluster:gitrepositories
      ```
  10. Optionally set your repository to Private in your repository settings.
</details>

## 👉 Troubleshooting

The k8s-at-home [wiki](https://github.com/k8s-at-home/template-cluster-k3s/wiki) (WIP, contributions welcome) is a good place to start troubleshooting issues.

## ❔ What's next

The world is your cluster!

## 🤝 Thanks

Big shout out to all the authors and contributors to the projects that we are using in this repository.

Community member @Whazor created [this website](https://whazor.github.io/k8s-at-home-search/) as a creative way to search Helm Releases across GitHub. You may use it as a means to get ideas on how to configure an applications' Helm values.

Many people have shared their awesome repositories over at [awesome-home-kubernetes](https://github.com/k8s-at-home/awesome-home-kubernetes).
