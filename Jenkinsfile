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
 
    def CLONE_SERVER_URL = 'http://win-5i6qvujug4j:14145'
    def CLONE_IMAGE_LOCATION = '\\WIN-5I6QVUJUG4J\SQLCloneImages'
 
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
 
    stage ('Deploy to acceptance') {
        powershell(label: 'Use SQL Clone to build acceptance environment from production', script: """
            \$ErrorActionPreference = "Stop"
 
            Connect-SqlClone -ServerUrl ${CLONE_SERVER_URL}
 
            \$ImageName = "${PRODUCTION_DATABASE}-\$(Get-Date -Format yyyyMMddHHmmss)"
 
            \$ProductionSqlServerInstance = Get-SqlCloneSqlServerInstance -MachineName ${PRODUCTION_INSTANCE} -InstanceName ''
            \$ImageDestination = Get-SqlCloneImageLocation -Path ${CLONE_IMAGE_LOCATION}
            New-SqlCloneImage -Name \$ImageName -SqlServerInstance \$ProductionSqlServerInstance -DatabaseName ${PRODUCTION_DATABASE} -Destination \$ImageDestination | Wait-SqlCloneOperation
 
            Get-SqlClone -Name ${ACCEPTANCE_DATABASE} | Remove-SqlClone | Wait-SqlCloneOperation
            \$AcceptanceSqlServerInstance = Get-SqlCloneSqlServerInstance -MachineName ${ACCEPTANCE_INSTANCE} -InstanceName ''
            \$ProductionImage = Get-SqlCloneImage -Name \$ImageName
            New-SqlClone -Name ${ACCEPTANCE_DATABASE} -Location \$AcceptanceSqlServerInstance -Image \$ProductionImage | Wait-SqlCloneOperation
        """)
 
        powershell(label: 'Create release artifact', script: """
            \$ErrorActionPreference = "Stop"
 
            \$buildArtifact = Import-DatabaseBuildArtifact -Path ${BUILD_ARTIFACT_FILE}
            \$acceptanceDatabaseConnection = New-DatabaseConnection -ServerInstance ${ACCEPTANCE_INSTANCE} -Database ${ACCEPTANCE_DATABASE}
            \$releaseArtifact = New-DatabaseReleaseArtifact -Source \$buildArtifact -Target \$acceptanceDatabaseConnection
            Export-DatabaseReleaseArtifact -InputObject \$releaseArtifact -Path ${RELEASE_ARTIFACT_PATH}
        """)
 
        powershell(label: 'Deploy to acceptance', script: """
            \$ErrorActionPreference = "Stop"
 
            \$releaseArtifact = Import-DatabaseReleaseArtifact -Path ${RELEASE_ARTIFACT_PATH}
            \$acceptanceDatabaseConnection = New-DatabaseConnection -ServerInstance ${ACCEPTANCE_INSTANCE} -Database ${ACCEPTANCE_DATABASE}
            Use-DatabaseReleaseArtifact -InputObject \$releaseArtifact -DeployTo \$acceptanceDatabaseConnection
        """)
 
        //archiveArtifacts label: 'Archive release artifact', artifacts: "${RELEASE_ARTIFACT_PATH}\\**"
        archiveArtifacts allowEmptyArchive: true, artifacts:"${RELEASE_ARTIFACT_PATH}\\TargetedDeploymentScript.sql", fingerprint: true
        archiveArtifacts allowEmptyArchive: true, artifacts:"${RELEASE_ARTIFACT_PATH}\\DriftRevertScript.sql", fingerprint: true
        archiveArtifacts allowEmptyArchive: true, artifacts:"${RELEASE_ARTIFACT_PATH}\\Reports\\Changes.html", fingerprint: true
        archiveArtifacts allowEmptyArchive: true, artifacts:"${RELEASE_ARTIFACT_PATH}\\Reports\\Drift.html", fingerprint: true
 
    }
 
    stage ('Approval gate') {
        def message = 'Approve release to production?'
        timeout(time: 30, unit: 'MINUTES') {
            def userInput = input(
                id: 'userInput', message: "$message", parameters: [
                    [$class: 'TextParameterDefinition', defaultValue: 'I approve the deployment', description: 'To proceed, type I approve the deployment', name: 'Review deployment artifacts before proceeding']
                ]
            )
            if (userInput.indexOf('I approve the deployment') == -1) {
                currentBuild.result = 'ABORTED'
                error('Deployment aborted')
            }
        }
    }
 
    stage ('Deploy to production') {
        powershell(label: 'Deploy to production', script: """
            \$ErrorActionPreference = "Stop"
 
            \$releaseArtifact = Import-DatabaseReleaseArtifact -Path ${RELEASE_ARTIFACT_PATH}
            \$productionDatabaseConnection = New-DatabaseConnection -ServerInstance ${PRODUCTION_INSTANCE} -Database ${PRODUCTION_DATABASE}
            Use-DatabaseReleaseArtifact -InputObject \$releaseArtifact -DeployTo \$productionDatabaseConnection
        """)
    }
}
