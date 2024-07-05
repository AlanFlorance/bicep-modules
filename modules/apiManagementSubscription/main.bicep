targetScope = 'resourceGroup'

// Parameters
@description('The api management name')
param apiManagementName string

@description('The subscription name')
param subscriptionName string

@description('The api scope')
param apiScope string

@description('The key vault name (if in-scope)')
param keyVaultName string = ''

@description('The key vault reference (if out-of-scope)')
param keyVaultRef object = {}

@description('The tags to apply to the resources.')
param tags object

// Resource References
resource apiManagement 'Microsoft.ApiManagement/service@2021-12-01-preview' existing = {
  name: apiManagementName
}

// Module Resources
resource apiManagementSubscription 'Microsoft.ApiManagement/service/subscriptions@2021-08-01' = {
  name: subscriptionName
  parent: apiManagement

  properties: {
    allowTracing: false
    displayName: subscriptionName
    scope: '/apis/${apiScope}'
  }
}

module keyVaultSecretPrimary './../keyVaultSecret/main.bicep' = {
  name: 'api-key-primary-${uniqueString(subscriptionName)}'
  scope: resourceGroup(
    keyVaultRef != {} ? keyVaultRef.SubscriptionId : subscription().subscriptionId,
    keyVaultRef != {} ? keyVaultRef.ResourceGroupName : resourceGroup().name
  )

  params: {
    parKeyVaultName: keyVaultRef != {} ? keyVaultRef.name : keyVaultName
    parSecretName: '${apiManagementSubscription.name}-api-key-primary'
    parSecretValue: apiManagementSubscription.listSecrets(apiManagementSubscription.apiVersion).primaryKey
    parTags: tags
  }
}

module keyVaultSecretSecondary './../keyVaultSecret/main.bicep' = {
  name: 'api-key-secondary-${uniqueString(subscriptionName)}'
  scope: resourceGroup(
    keyVaultRef != {} ? keyVaultRef.SubscriptionId : subscription().subscriptionId,
    keyVaultRef != {} ? keyVaultRef.ResourceGroupName : resourceGroup().name
  )

  params: {
    parKeyVaultName: keyVaultRef != {} ? keyVaultRef.name : keyVaultName
    parSecretName: '${apiManagementSubscription.name}-api-key-secondary'
    parSecretValue: apiManagementSubscription.listSecrets(apiManagementSubscription.apiVersion).secondaryKey
    parTags: tags
  }
}

// Outputs
output subscriptionName string = apiManagementSubscription.name
