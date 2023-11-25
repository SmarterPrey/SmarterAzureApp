@minLength(3)
@maxLength(11)
param storagePrefix string

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param storageSKU string = 'Standard_LRS'

param location string = resourceGroup().location

var uniqueStorageName = '${storagePrefix}${uniqueString(resourceGroup().id)}'

// create a storage account
resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: uniqueStorageName
  location: location
  sku: {
    name: storageSKU
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
}

output storageEndpoint object = stg.properties.primaryEndpoints

// create a container
resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  resource blobStorage 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' = {
    parent: stg
    name: 'default'
  }

//Create blob storage
resource blobStorage 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' = {
  parent: stg
  name: 'default'
  properties: {
    cors: {
      corsRules: [
        {
          allowedHeaders: [
            '*'
          ]
          allowedMethods: [
            'GET'
            'POST'
            'PUT'
            'DELETE'
            'HEAD'
          ]
          allowedOrigins: [
            '*'
          ]
          exposedHeaders: [
            '*'
          ]
          maxAgeInSeconds: 86400
        }
      ]
    }
  }
}

// create an app service plan
resource appServicePlan 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: 'myappserviceplan'
  location: location
  sku: {
    name: 'S1'
    tier: 'Dynamic'
  }
}

// create an app service with appservice authentication
resource appService 'Microsoft.Web/sites@2021-01-15' = {
  name: 'SmarterPreyWebApp'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: stg.blob
        }
      ]
    }
  }
  dependsOn: [

  ]
}
}
