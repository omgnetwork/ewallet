def label = "ewallet-${UUID.randomUUID().toString()}"
def yamlSpec = """
spec:
  nodeSelector:
    cloud.google.com/gke-preemptible: "true"
  tolerations:
    - key: dedicated
      operator: Equal
      value: worker
      effect: NoSchedule
"""

podTemplate(
    label: label,
    yaml: yamlSpec,
    containers: [
        containerTemplate(
            name: 'jnlp',
            image: 'gcr.io/omise-go/jenkins-slave',
            args: '${computer.jnlpmac} ${computer.name}',
            resourceRequestCpu: '200m',
            resourceLimitCpu: '500m',
            resourceRequestMemory: '128Mi',
            resourceLimitMemory: '512Mi',
        ),
        containerTemplate(
            name: 'postgresql',
            image: 'postgres:9.6.9-alpine',
            resourceRequestCpu: '300m',
            resourceLimitCpu: '800m',
            resourceRequestMemory: '512Mi',
            resourceLimitMemory: '1024Mi',
        ),
    ],
    volumes: [
        hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock'),
        hostPathVolume(mountPath: '/usr/bin/docker', hostPath: '/usr/bin/docker'),
    ],
) {
    node(label) {
        Random random = new Random()
        def tmpDir = pwd(tmp: true)

        def project = 'omisego'
        def appName = 'ewallet'
        def imageName = "${project}/${appName}"

        def nodeIP = getNodeIP()
        def gitCommit

        stage('Checkout') {
            checkout scm
        }

        stage('Build') {
            gitCommit = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
            sh("docker build --pull . -t ${imageName}:${gitCommit}")
        }

        stage('Test') {
            container('postgresql') {
                sh("pg_isready -t 60 -h localhost -p 5432")
            }

            sh(
                """
                docker run \
                    --rm \
                    --entrypoint /bin/execlineb \
                    -e DATABASE_URL="postgresql://postgres@${nodeIP}:5432/ewallet_${gitCommit}_ewallet" \
                    -e LOCAL_LEDGER_DATABASE_URL="postgresql://postgres@${nodeIP}:5432/ewallet_${gitCommit}_local_ledger" \
                    ${imageName}:${gitCommit} \
                    -P -c " \
                        s6-setuidgid ewallet \
                        s6-env HOME=/tmp/ewallet \
                        s6-env MIX_ENV=test \
                        cd /app \
                        mix do format --check-formatted, credo, ecto.create, ecto.migrate, test \
                    " \
                """.stripIndent()
            )
        }

        if (env.BRANCH_NAME == 'develop') {
            stage('Push') {
                withCredentials([file(credentialsId: 'docker', variable: 'DOCKER_CONFIG')]) {
                    def configDir = sh(script: "dirname ${DOCKER_CONFIG}", returnStdout: true).trim()
                    sh("docker --config=${configDir} tag ${imageName}:${gitCommit} ${imageName}:latest")
                    sh("docker --config=${configDir} push ${imageName}:${gitCommit}")
                    sh("docker --config=${configDir} push ${imageName}:latest")
                }
            }

            stage('Deploy') {
                dir("${tmpDir}/deploy") {
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/master']],
                        userRemoteConfigs: [
                            [
                                url: 'ssh://git@github.com/omisego/kube.git',
                                credentialsId: 'github',
                            ],
                        ]
                    ])

                    sh("sed -i.bak 's#${imageName}:latest#${imageName}:${gitCommit}#' staging/k8s/ewallet/deployment.yaml")
                    sh("kubectl apply -f staging/k8s/ewallet/deployment.yaml")
                    sh("kubectl rollout status --namespace=staging deployment/ewallet")

                    def podID = getPodID('--namespace=staging -l app=ewallet')

                    sh(
                        """
                        kubectl exec ${podID} --namespace=staging -- \
                            /bin/execlineb -P -c " \
                                s6-setuidgid ewallet \
                                s6-env HOME=/tmp/ewallet \
                                mix ecto.migrate \
                            " \
                        """.stripIndent()
                    )
                }
            }
        } else if (env.BRANCH_NAME == 'master') {
            stage('Push') {
                withCredentials([file(credentialsId: 'docker', variable: 'DOCKER_CONFIG')]) {
                    def configDir = sh(script: "dirname ${DOCKER_CONFIG}", returnStdout: true).trim()
                    sh("docker --config=${configDir} tag ${imageName}:${gitCommit} ${imageName}:stable")
                    sh("docker --config=${configDir} push ${imageName}:${gitCommit}")
                    sh("docker --config=${configDir} push ${imageName}:stable")
                }
            }
        }
    }
}

String getNodeIP() {
    def rawNodeIP = sh(script: 'ip -4 -o addr show scope global', returnStdout: true).trim()
    def matched = (rawNodeIP =~ /inet (\d+\.\d+\.\d+\.\d+)/)
    return "" + matched[0].getAt(1)
}

String getPodID(String opts) {
    def pods = sh(script: "kubectl get pods ${opts} -o name", returnStdout: true).trim()
    def matched = (pods.split()[0] =~ /pods\/(.+)/)
    return "" + matched[0].getAt(1)
}
