pipeline {
    agent any

    triggers {
        // Empty pollSCM registers the job for instant GitHub Webhook pushes 
        // without running background polling schedules!
        pollSCM('')
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
