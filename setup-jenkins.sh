#!/usr/bin/env bash
set -euo pipefail

JENKINS_CONTAINER="jenkins"
JENKINS_IMAGE="jenkins/jenkins:lts-jdk17"
JENKINS_VOLUME="jenkins_home"

echo "==> Checking Docker..."
docker version >/dev/null

echo "==> Removing old Jenkins container if it exists..."
docker rm -f "${JENKINS_CONTAINER}" >/dev/null 2>&1 || true

echo "==> Creating Jenkins volume..."
docker volume create "${JENKINS_VOLUME}" >/dev/null

echo "==> Starting Jenkins..."
docker run -d \
  --name "${JENKINS_CONTAINER}" \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 50000:50000 \
  -e JAVA_OPTS="-Djenkins.install.runSetupWizard=false" \
  -v "${JENKINS_VOLUME}:/var/jenkins_home" \
  "${JENKINS_IMAGE}" >/dev/null

echo "==> Waiting for Jenkins to start..."
for i in {1..60}; do
  if curl -fsS http://localhost:8080/login >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

if ! curl -fsS http://localhost:8080/login >/dev/null 2>&1; then
  echo "ERROR: Jenkins did not start in time."
  docker logs "${JENKINS_CONTAINER}" --tail 80
  exit 1
fi

echo "==> Installing git inside Jenkins container..."
docker exec -u root "${JENKINS_CONTAINER}" bash -lc '
  apt-get update >/dev/null &&
  DEBIAN_FRONTEND=noninteractive apt-get install -y git >/dev/null &&
  rm -rf /var/lib/apt/lists/*
'

echo "==> Installing Jenkins plugins..."
docker exec -u root "${JENKINS_CONTAINER}" jenkins-plugin-cli --plugins \
  workflow-aggregator \
  git \
  github

echo "==> Enabling proxy-compatible CSRF crumbs for Killercoda..."
docker exec -u root "${JENKINS_CONTAINER}" bash -lc 'mkdir -p /var/jenkins_home/init.groovy.d && cat > /var/jenkins_home/init.groovy.d/killercoda-proxy-crumb.groovy <<'"'"'GROOVY'"'"'
import jenkins.model.Jenkins
import hudson.security.csrf.DefaultCrumbIssuer

def j = Jenkins.get()
j.setCrumbIssuer(new DefaultCrumbIssuer(true))
j.save()
println("Configured proxy-compatible CSRF crumb issuer")
GROOVY'

echo "==> Restarting Jenkins..."
docker restart "${JENKINS_CONTAINER}" >/dev/null

echo "==> Waiting for Jenkins after restart..."
for i in {1..60}; do
  if curl -fsS http://localhost:8080/login >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

echo
echo "=============================================="
echo "Jenkins is ready."
echo "Local check: http://localhost:8080"
echo
echo "For Lesson 3 create the Pipeline job:"
echo "  Name: lesson3-github-webhook"
echo "  Definition: Pipeline script from SCM"
echo "  SCM: Git"
echo "  Repository: https://github.com/Oboltus01/jenkins-webhook-demo.git"
echo "  Branch: */main"
echo "  Script Path: Jenkinsfile"
echo "  Trigger: GitHub hook trigger for GITScm polling"
echo
echo "GitHub webhook URL:"
echo "  <YOUR-KILLERCODA-JENKINS-URL>/github-webhook/"
echo "  Content type: application/json"
echo "  Event: Just the push event"
echo "=============================================="
