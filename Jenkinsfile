
pipeline {
    agent any

    triggers {
        // Registers job as a target for incoming GitHub Webhook payloads
        githubPush()
    }

    stages {
        stage('Validate Webhook Trigger') {
            steps {
                echo '=== Instant Webhook Event Received ==='
                sh 'echo "Execution Time: $(date)"'
                sh 'git log -1 --oneline'
            }
        }
    }
}
