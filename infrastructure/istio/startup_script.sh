eksctl create cluster --node-type="m5.xlarge" --nodes-min=1 --nodes-max=3 --region=us-east-1 --zones=us-east-1a,us-east-1b
mkdir istio && cd istio

curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.3.0 sh -

export PATH="$PATH:$PWD/istio-1.3.0/bin"

for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply -f $i; done

kubectl apply -f install/kubernetes/istio-demo.yaml