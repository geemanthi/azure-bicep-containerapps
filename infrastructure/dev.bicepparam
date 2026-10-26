using './main.bicep'

param appName = 'nginx-dev'
param image = 'docker.io/nginx:stable'
param minReplicas = 0          // scale to zero when idle, so no cost overnight
param maxReplicas = 3          // cap it, dev doesn't need 10
param concurrentRequests = '20' // scales out sooner, so it's easier to test
