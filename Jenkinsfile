podTemplate(
    label: 'ewallet',
    containers: [
        containerTemplate(name: 'jnlp', image: 'gcr.io/omise-go/jenkins-slave', args: '${computer.jnlpmac} ${computer.name}'),
        containerTemplate(name: 'postgresql', image: 'postgres:9.6'),
        containerTemplate(name: 'rabbitmq', image: 'rabbitmq:3.7'),
    ],
    volumes: [
        hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock'),
        hostPathVolume(mountPath: '/usr/bin/docker', hostPath: '/usr/bin/docker'),
    ]
) {
    node('ewallet') {
        Random random = new Random()
        def tmpDir = pwd(tmp: true)

        def project = 'omise-go'
        def appName = 'ewallet'
        def imageName = "gcr.io/${project}/${appName}"

        def nodeIP = getNodeIP()
        def gitCommit

        stage('Checkout') {
            checkout scm
        }

        stage('Build') {
            gitCommit = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()

            dir(tmpDir) {
                writeFile(
                    file: "ssh_config",
                    text: """
                    Host github.com
                        User git
                        IdentityFile ~/.ssh/key
                        PreferredAuthentications publickey
                        StrictHostKeyChecking no
                        UserKnownHostsFile /dev/null
                    """.stripIndent()
                )
            }

            withCredentials([[$class: 'SSHUserPrivateKeyBinding', credentialsId: 'github', keyFileVariable: 'GIT_SSH_KEY']]) {
                withEnv(["GIT_SSH_CONFIG=${tmpDir}/ssh_config", "IMAGE=${imageName}", "TAG=${gitCommit}"]) {
                    def habitusPort = random.nextInt(1024) + 8080

                    sh(
                        """
                        habitus \
                            --pretty=false \
                            --secrets=true \
                            --binding="${nodeIP}" \
                            --port="${habitusPort}" \
                            --build habitus_port="${habitusPort}" \
                            --build habitus_host="${nodeIP}"
                        """.stripIndent()
                    )
                }
            }
        }

        stage('Test') {
            sh(
                """
                docker run --rm \
                    -e DATABASE_URL="postgresql://postgres@${nodeIP}:5432/ewallet_${gitCommit}_ewallet" \
                    -e LOCAL_LEDGER_DATABASE_URL="postgresql://postgres@${nodeIP}:5432/ewallet_${gitCommit}_local_ledger" \
                    -e MQ_URL="amqp://guest:guest@${nodeIP}" \
                    -e MQ_EXCHANGE="ewallet_${gitCommit}" \
                    ${imageName}:${gitCommit} \
                    sh -c "cd /app && MIX_ENV=test mix do credo, ecto.create, ecto.migrate, test"
                """.stripIndent()
            )
        }
    }
}

String getNodeIP() {
    def rawNodeIP = sh(script: 'ip -4 -o addr show scope global', returnStdout: true).trim()
    def matched = (rawNodeIP =~ /inet (\d+\.\d+\.\d+\.\d+)/)
    return "" + matched[0].getAt(1)
}