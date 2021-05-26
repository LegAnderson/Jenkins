node {
    def PROJECT_PATH = 'JenkinsDemo'
 
    def BUILD_ARTIFACT_PACKAGE_ID = 'PKG.DB'
    def BUILD_ARTIFACT_PACKAGE_VERSION = "1.0.${env.BUILD_NUMBER}"
    def BUILD_ARTIFACT_FILE = "${BUILD_ARTIFACT_PACKAGE_ID}.${BUILD_ARTIFACT_PACKAGE_VERSION}.nupkg"
 
    def INTEGRATION_INSTANCE = 'WIN-5I6QVUJUG4J'
    def INTEGRATION_DATABASE = 'Jenkins-2Test'
 
    def ACCEPTANCE_INSTANCE = 'WIN-5I6QVUJUG4J'
    def ACCEPTANCE_DATABASE = 'Jenkins-2QA'
 
    def PRODUCTION_INSTANCE = 'WIN-5I6QVUJUG4J'
    def PRODUCTION_DATABASE = 'Jenkins-1Prod'
 
    def RELEASE_ARTIFACT_PATH = 'Release'
 
    stage ('Build') {
        checkout scm
 
        powershell(label: 'Database build', script: """
            \$ErrorActionPreference = "Stop"
 
            \$validatedProject = Invoke-DatabaseBuild -InputObject ${PROJECT_PATH}
            \$buildArtifact = New-DatabaseBuildArtifact -InputObject \$validatedProject -PackageId ${BUILD_ARTIFACT_PACKAGE_ID} -PackageVersion ${BUILD_ARTIFACT_PACKAGE_VERSION}
            Export-DatabaseBuildArtifact -InputObject \$buildArtifact -Path .
        """)
 
        archiveArtifacts label: 'Archive build artifact', artifacts: "${BUILD_ARTIFACT_FILE}"    }
  
    stage ('Deploy to integration') {
        powershell(label: 'Deploy to integration', script: """
            \$ErrorActionPreference = "Stop"
 
            \$buildArtifact = Import-DatabaseBuildArtifact -Path ${BUILD_ARTIFACT_FILE}
            \$integrationDatabaseConnection = New-DatabaseConnection -ServerInstance ${INTEGRATION_INSTANCE} -Database ${INTEGRATION_DATABASE}
            \$releaseArtifact = New-DatabaseReleaseArtifact -Source \$buildArtifact -Target \$integrationDatabaseConnection
            Use-DatabaseReleaseArtifact -InputObject \$releaseArtifact -DeployTo \$integrationDatabaseConnection
        """)
    }
 
    
 
    stage ('Deploy to production') {
        powershell(label: 'Deploy to production', script: """
            \$ErrorActionPreference = "Stop"
 
            \$buildArtifact = Import-DatabaseBuildArtifact -Path ${BUILD_ARTIFACT_FILE}
            \$productionDatabaseConnection = New-DatabaseConnection -ServerInstance ${PRODUCTION_INSTANCE} -Database ${PRODUCTION_DATABASE}
 
            \$releaseArtifact = New-DatabaseReleaseArtifact -Source \$buildArtifact -Target \$productionDatabaseConnection

            Use-DatabaseReleaseArtifact -InputObject \$releaseArtifact -DeployTo \$productionDatabaseConnection
        """)
    }
}
