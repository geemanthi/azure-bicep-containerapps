using './main.bicep'

param appName = 'nginx-dev'
param image = readEnvironmentVariable('IMAGE', 'docker.io/nginx:stable')
param deployApp = bool(readEnvironmentVariable('DEPLOY_APP', 'true'))
param minReplicas = 0
param maxReplicas = 2
param concurrentRequests = '20'
