@description('Azure region. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Base name used for all resources, e.g. nginx-dev')
param appName string

@description('Container image to run')
param image string = 'docker.io/nginx:stable'

@description('Minimum replicas. Use 0 in dev to scale to zero when idle.')
@minValue(0)
@maxValue(4)
param minReplicas int = 1

@description('Maximum replicas')
@minValue(1)
@maxValue(4)
param maxReplicas int = 4

@description('Concurrent HTTP requests per replica before scaling out (passed as a string)')
param concurrentRequests string = '50'

@description('vCPU per replica')
param cpu string = '0.25'

@description('Memory per replica')
param memory string = '0.5Gi'

@description('Log Analytics retention in days')
@minValue(30)
@maxValue(90)
param logRetentionDays int = 30

resource logs 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${appName}-logs'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: logRetentionDays
  }
}

resource env 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: '${appName}-env'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logs.properties.customerId
        sharedKey: logs.listKeys().primarySharedKey
      }
    }
  }
}

resource nginx 'Microsoft.App/containerApps@2024-03-01' = {
  name: appName
  location: location
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        transport: 'auto'
      }
    }
    template: {
      containers: [
        {
          name: 'nginx'
          image: image
          resources: {
            cpu: json(cpu)
            memory: memory
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'http-scaler'
            http: {
              metadata: {
                concurrentRequests: concurrentRequests
              }
            }
          }
        ]
      }
    }
  }
}

output url string = 'https://${nginx.properties.configuration.ingress.fqdn}'
output appName string = nginx.name
