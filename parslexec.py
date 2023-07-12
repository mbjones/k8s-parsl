from parsl.config import Config
from parsl.executors import HighThroughputExecutor
from parsl.providers import KubernetesProvider
from parsl.addresses import address_by_route

htex_kube = Config(
    executors=[
        HighThroughputExecutor(
            label='kube-htex',
            cores_per_worker=1,
            max_workers=2,
            worker_logdir_root='/',
            # Address for the pod worker to connect back
            address=address_by_route(),
            #address='192.168.0.103',
            #address_probe_timeout=3600,
            worker_debug=True,
            provider=KubernetesProvider(

                # Namespace in K8S to use for the run
                namespace="pdgrun",

                # Docker image url to use for pods
                image='ghcr.io/mbjones/k8sparsl:0.3',

                # Command to be run upon pod start, such as:
                # 'module load Anaconda; source activate parsl_env'.
                # or 'pip install parsl'
                #worker_init='echo "Worker started..."; lf=`find . -name \'manager.log\'` tail -n+1 -f ${lf}',
                worker_init='echo "Worker started..."',

                # The secret key to download the image
                #secret="YOUR_KUBE_SECRET",

                # Should follow the Kubernetes naming rules
                pod_name='parsl-worker',

                nodes_per_block=1,
                init_blocks=2,
                min_blocks=1,
                # Maximum number of pods to scale up
                max_blocks=4,
            ),
        ),
    ]
)
