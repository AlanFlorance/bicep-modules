targetScope = 'resourceGroup'

// Parameters
@description('The api management name')
param apiManagementName string

@description('The app insights name (if in-scope)')
param appInsightsName string = ''

@description('The app insights reference (if out-of-scope)')
param appInsightsRef object

// Resource References
resource apiManagement 'Microsoft.ApiManagement/service@2021-12-01-preview' existing = {
  name: apiManagementName
}

resource appInsightsInScope 'Microsoft.Insights/components@2020-02-02' existing = if (appInsightsName != '') {
  name: appInsightsName
}

resource appInsightsOutOfScope 'Microsoft.Insights/components@2020-02-02' existing = if (appInsightsName == '') {
  name: appInsightsRef.Name
  scope: resourceGroup(appInsightsRef.SubscriptionId, appInsightsRef.ResourceGroupName)
}

// Module Resources
resource apiManagementLogger 'Microsoft.ApiManagement/service/loggers@2021-08-01' = {
  name: appInsightsName != null ? appInsightsInScope.name : appInsightsOutOfScope.name
  parent: apiManagement

  properties: {
    credentials: {
      instrumentationKey: appInsightsName != null
        ? appInsightsInScope.properties.InstrumentationKey
        : appInsightsOutOfScope.properties.InstrumentationKey
    }
    loggerType: 'applicationInsights'
    resourceId: appInsightsName != null ? appInsightsInScope.id : appInsightsOutOfScope.id
  }
}
