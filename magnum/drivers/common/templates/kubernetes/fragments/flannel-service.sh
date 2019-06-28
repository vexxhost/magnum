#!/bin/sh

. /etc/sysconfig/heat-params

set -x

if [ "$NETWORK_DRIVER" = "flannel" ]; then
    # NOTE(mnaser): Add systemd unit to set iptables to FORWARD.
    #               This is critical to make communication functional.
    cat << EOF > /etc/systemd/system/flannel-iptables-forward-accept.service
[Unit]
After=docker.service
Requires=network.service

[Service]
Type=oneshot
ExecStart=/usr/sbin/iptables -P FORWARD ACCEPT
ExecStartPost=/usr/sbin/iptables -S

[Install]
WantedBy=kubelet.service
EOF

    _prefix=${CONTAINER_INFRA_PREFIX:-quay.io/coreos/}
    FLANNEL_DEPLOY=/srv/magnum/kubernetes/manifests/flannel-deploy.yaml

    [ -f ${FLANNEL_DEPLOY} ] || {
    echo "Writing File: $FLANNEL_DEPLOY"
    mkdir -p "$(dirname ${FLANNEL_DEPLOY})"
    cat << EOF > ${FLANNEL_DEPLOY}
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: flannel
rules:
  - apiGroups:
      - ""
    resources:
      - pods
    verbs:
      - get
  - apiGroups:
      - ""
    resources:
      - nodes
    verbs:
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - nodes/status
    verbs:
      - patch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: flannel
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: flannel
subjects:
- kind: ServiceAccount
  name: flannel
  namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: flannel
  namespace: kube-system
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: kube-flannel-cfg
  namespace: kube-system
  labels:
    tier: node
    app: flannel
data:
  cni-conf.json: |
    {
      "name": "cbr0",
      "plugins": [
        {
          "type": "flannel",
          "delegate": {
            "hairpinMode": true,
            "isDefaultGateway": true
          }
        },
        {
          "type": "portmap",
          "capabilities": {
            "portMappings": true
          }
        }
      ]
    }
  net-conf.json: |
    {
      "Network": "$FLANNEL_NETWORK_CIDR",
      "Subnetlen": $FLANNEL_NETWORK_SUBNETLEN,
      "Backend": {
        "Type": "$FLANNEL_BACKEND"
      }
    }
  magnum-install-cni.sh: |
    #!/bin/sh
    set -e -x;
    if [ -w "/host/opt/cni/bin/" ]; then
      cp /opt/cni/bin/* /host/opt/cni/bin/;
      echo "Wrote CNI binaries to /host/opt/cni/bin/";
    fi;
---
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: kube-flannel-ds-amd64
  namespace: kube-system
  labels:
    tier: node
    app: flannel
spec:
  template:
    metadata:
      labels:
        tier: node
        app: flannel
    spec:
      hostNetwork: true
      nodeSelector:
        beta.kubernetes.io/arch: amd64
      tolerations:
        # Make sure flannel gets scheduled on all nodes.
        - effect: NoSchedule
          operator: Exists
        # Mark the pod as a critical add-on for rescheduling.
        - key: CriticalAddonsOnly
          operator: Exists
        - effect: NoExecute
          operator: Exists
      serviceAccountName: flannel
      initContainers:
      - name: install-cni-plugins
        image: ${_prefix}flannel-cni:${FLANNEL_CNI_TAG}
        command:
        - sh
        args:
        - /etc/kube-flannel/magnum-install-cni.sh
        volumeMounts:
        - name: host-cni-bin
          mountPath: /host/opt/cni/bin/
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
      - name: install-cni
        image: ${_prefix}flannel:${FLANNEL_TAG}
        command:
        - cp
        args:
        - -f
        - /etc/kube-flannel/cni-conf.json
        - /etc/cni/net.d/10-flannel.conflist
        volumeMounts:
        - name: cni
          mountPath: /etc/cni/net.d
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
      containers:
      - name: kube-flannel
        image: ${_prefix}flannel:${FLANNEL_TAG}
        command:
        - /opt/bin/flanneld
        args:
        - --ip-masq
        - --kube-subnet-mgr
        resources:
          requests:
            cpu: "100m"
            memory: "50Mi"
          limits:
            cpu: "100m"
            memory: "50Mi"
        securityContext:
          privileged: true
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        volumeMounts:
        - name: run
          mountPath: /run
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
      volumes:
        - name: host-cni-bin
          hostPath:
            path: /opt/cni/bin
        - name: run
          hostPath:
            path: /run
        - name: cni
          hostPath:
            path: /etc/cni/net.d
        - name: flannel-cfg
          configMap:
            name: kube-flannel-cfg
EOF
    }

    if [ "$MASTER_INDEX" = "0" ]; then

        until  [ "ok" = "$(curl --silent http://127.0.0.1:8080/healthz)" ]
        do
            echo "Waiting for Kubernetes API..."
            sleep 5
        done
    fi

    /usr/bin/kubectl apply -f "${FLANNEL_DEPLOY}" --namespace=kube-system
fi
