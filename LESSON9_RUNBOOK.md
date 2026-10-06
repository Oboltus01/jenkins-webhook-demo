# Lesson 9 Jenkins Runbook

Полная инструкция для повторного выполнения лабораторной работы в новой Killercoda-сессии.

> Репозиторий: `Oboltus01/jenkins-webhook-demo`

## 1. Быстрый старт Jenkins

В новой Killercoda-сессии выполнить:

```bash
curl -fsSL https://raw.githubusercontent.com/Oboltus01/jenkins-lesson-2/main/killercoda.sh | bash
```

После завершения установить GitHub plugin:

```bash
docker exec jenkins jenkins-plugin-cli --plugins github
docker restart jenkins
sleep 15
```

Проверка:

```bash
docker ps
curl -I http://localhost:8080
```

Jenkins должен отвечать `HTTP/1.1 200 OK`.

---

## 2. Создать jobs Lesson 9

Выполнить весь блок целиком:

```bash
mkdir -p /var/lib/docker/volumes/jenkins_home/_data/jobs/lesson3-github-webhook
mkdir -p /var/lib/docker/volumes/jenkins_home/_data/jobs/lesson3-parameterized-job

cat > /var/lib/docker/volumes/jenkins_home/_data/jobs/lesson3-github-webhook/config.xml <<'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <actions/>
  <description>Lesson 9 - GitHub Webhook Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <triggers>
    <com.cloudbees.jenkins.GitHubPushTrigger plugin="github">
      <spec></spec>
    </com.cloudbees.jenkins.GitHubPushTrigger>
  </triggers>
  <disabled>false</disabled>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps">
    <scm class="hudson.plugins.git.GitSCM" plugin="git">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/Oboltus01/jenkins-webhook-demo.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
</flow-definition>
EOF

cat > /var/lib/docker/volumes/jenkins_home/_data/jobs/lesson3-parameterized-job/config.xml <<'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <actions/>
  <description>Lesson 9 - Parameterized Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.StringParameterDefinition>
          <name>TARGET_ENV</name>
          <description>Deployment target environment</description>
          <defaultValue>staging</defaultValue>
          <trim>false</trim>
        </hudson.model.StringParameterDefinition>
        <hudson.model.StringParameterDefinition>
          <name>RELEASE_TAG</name>
          <description>Container image release tag</description>
          <defaultValue>v1.0.0</defaultValue>
          <trim>false</trim>
        </hudson.model.StringParameterDefinition>
        <hudson.model.BooleanParameterDefinition>
          <name>RUN_TESTS</name>
          <description>Force full integration testing</description>
          <defaultValue>true</defaultValue>
        </hudson.model.BooleanParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps">
    <script><![CDATA[
pipeline {
    agent any

    parameters {
        string(name: 'TARGET_ENV', defaultValue: 'staging', description: 'Deployment target environment')
        string(name: 'RELEASE_TAG', defaultValue: 'v1.0.0', description: 'Container image release tag')
        booleanParam(name: 'RUN_TESTS', defaultValue: true, description: 'Force full integration testing')
    }

    stages {
        stage('Inspect Parameters') {
            steps {
                echo "Deploying Release Tag: ${params.RELEASE_TAG}"
                echo "Target Environment: ${params.TARGET_ENV}"
                echo "Execute Test Suite: ${params.RUN_TESTS}"
            }
        }

        stage('Simulate Deployment') {
            steps {
                sh '''
                    echo "Deploying release ${RELEASE_TAG} to environment ${TARGET_ENV}..."
                    echo "Completed at $(date)"
                '''
            }
        }
    }
}
]]></script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

chown -R 1000:1000 /var/lib/docker/volumes/jenkins_home/_data/jobs/lesson3-github-webhook /var/lib/docker/volumes/jenkins_home/_data/jobs/lesson3-parameterized-job

docker restart jenkins
sleep 15
```

Проверить jobs:

```bash
curl -s 'http://localhost:8080/api/json?tree=jobs%5Bname%5D' | python3 -m json.tool
```

В списке должны быть:

```text
lesson3-github-webhook
lesson3-parameterized-job
```

---

## 3. Проверить parameterized job

Запуск:

```bash
curl -X POST "http://localhost:8080/job/lesson3-parameterized-job/buildWithParameters?RELEASE_TAG=v2.5.1&TARGET_ENV=production&RUN_TESTS=false"
```

Проверка лога:

```bash
curl -s http://localhost:8080/job/lesson3-parameterized-job/lastBuild/consoleText
```

Ожидаемый результат:

```text
Deploying Release Tag: v2.5.1
Target Environment: production
Execute Test Suite: false
Finished: SUCCESS
```

---

## 4. Настроить GitHub webhook

Открыть Jenkins через Killercoda и скопировать текущий публичный URL, например:

```text
https://CURRENT-ID-1-8080.spca.r.killercoda.com/
```

В GitHub открыть:

```text
jenkins-webhook-demo
Settings
Webhooks
Add webhook
```

Payload URL:

```text
https://CURRENT-ID-1-8080.spca.r.killercoda.com/github-webhook/
```

Настройки:

```text
Content type: application/json
SSL verification: Enable SSL verification
Events: Just the push event
```

Важно: завершающий `/` после `github-webhook/` обязателен.

В `Recent Deliveries` у события `ping` должна появиться зелёная галочка.

---

## 5. Проверить автоматический запуск webhook

Клонировать репозиторий:

```bash
cd ~
git clone https://github.com/Oboltus01/jenkins-webhook-demo.git
cd jenkins-webhook-demo
```

Настроить Git identity для новой Killercoda-сессии:

```bash
git config --global user.name "Oboltus01"
git config --global user.email "Oboltus01@users.noreply.github.com"
```

Создать тестовый commit:

```bash
echo "Webhook test $(date)" >> README.md
git add README.md
git commit -m "Test Jenkins webhook trigger"
git log -1 --oneline
```

Отправить:

```bash
git push origin main
```

При HTTPS-аутентификации:

```text
Username: Oboltus01
Password: GitHub Personal Access Token
```

Не использовать обычный пароль GitHub.

После push ничего вручную в Jenkins не запускать. Подождать несколько секунд и проверить:

```bash
curl -s http://localhost:8080/job/lesson3-github-webhook/lastBuild/consoleText
```

Ожидается:

```text
=== Instant Webhook Event Received ===
<новый commit> Test Jenkins webhook trigger
Finished: SUCCESS
```

---

## 6. Создать Jenkins user для API

Выполнить:

```bash
docker exec -u 0 jenkins bash -c 'mkdir -p /var/jenkins_home/init.groovy.d && cat > /var/jenkins_home/init.groovy.d/create-admin.groovy << "EOF"
import jenkins.model.*
import hudson.security.*

def instance = Jenkins.get()

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
def user = hudsonRealm.createAccount("admin", "JenkinsLab2026!")
user.save()

instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

instance.save()

println "--> SUCCESS: User admin created successfully."
EOF

chown -R 1000:1000 /var/jenkins_home/init.groovy.d'
```

Перезапустить:

```bash
docker restart jenkins
sleep 15
docker logs jenkins --tail 40
```

После успешного создания удалить startup-скрипт:

```bash
docker exec -u 0 jenkins rm -f /var/jenkins_home/init.groovy.d/create-admin.groovy
```

Проверить пользователя:

```bash
curl -u admin:'JenkinsLab2026!' http://localhost:8080/me/api/json
```

---

## 7. Создать Jenkins API token

Создать token:

```bash
docker exec jenkins bash -c 'curl -s -u "admin:JenkinsLab2026!" -X POST "http://localhost:8080/me/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken?newTokenName=remote-trigger-token"'
```

Из ответа сохранить только значение:

```text
tokenValue
```

Не добавлять API token в Git и не сохранять его в README.

---

## 8. Удалённый запуск job через Jenkins API

Подставить свой `tokenValue`:

```bash
curl -X POST -i -u "admin:YOUR_JENKINS_API_TOKEN" "http://localhost:8080/job/lesson3-parameterized-job/buildWithParameters?TARGET_ENV=production&RELEASE_TAG=v3.0.0&RUN_TESTS=true"
```

Успешный запрос:

```text
HTTP/1.1 201 Created
```

После включения Jenkins security чтение лога тоже требует авторизации:

```bash
curl -s -u "admin:YOUR_JENKINS_API_TOKEN" http://localhost:8080/job/lesson3-parameterized-job/lastBuild/consoleText
```

Короткая проверка:

```bash
curl -s -u "admin:YOUR_JENKINS_API_TOKEN" http://localhost:8080/job/lesson3-parameterized-job/lastBuild/consoleText | grep -E "Deploying Release Tag|Target Environment|Execute Test Suite|Finished:"
```

Ожидается:

```text
Deploying Release Tag: v3.0.0
Target Environment: production
Execute Test Suite: true
Finished: SUCCESS
```

---

## Итоговая схема

```text
GitHub push
    |
    v
GitHub Webhook
    |
    v
lesson3-github-webhook
    |
    v
Jenkins Pipeline
    |
    +--> Parameterized build
    |
    +--> Remote API trigger with token
    |
    v
SUCCESS
```

## Что меняется после сброса Killercoda

После каждой новой Killercoda-сессии нужно заново:

1. Запустить Jenkins.
2. Установить GitHub plugin.
3. Восстановить jobs.
4. Обновить Payload URL в GitHub webhook на новый Killercoda URL.
5. При необходимости заново настроить Git identity.
6. Если Jenkins volume новый — заново создать Jenkins user/API token.

Сам GitHub-репозиторий и Jenkinsfile сохраняются между сессиями.
