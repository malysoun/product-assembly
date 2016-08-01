//
// The Jenkins job parameters for this script are:
//    MATURITY          - the image maturity level (e.g. 'unstable', 'testing', 'stable')
//    GIT_CREDENTIAL_ID - the UUID of the GIT credentials used to checkout stuff from github
//
node ('build-ubuntu') {
    PRODUCT_BUILD_NUMBER=env.BUILD_NUMBER
    currentBuild.displayName = "product bld #${PRODUCT_BUILD_NUMBER}"

    stage 'Checkout product-assembly repo'
        // FIXME: parameterize the git credentialsID
        git branch: 'develop', credentialsId: '${GIT_CREDENTIAL_ID}', url: 'https://github.com/zenoss/product-assembly'

        // Record the current git commit id in the variable 'git_sha'
        sh("git rev-parse HEAD >git_sha.id")
        git_sha=readFile('git_sha.id').trim()
        println("Building from git commit='${git_sha}' for MATURITY='${MATURITY}'")

    stage 'Build product-base'
        sh("pwd;cd product-base;MATURITY=${MATURITY} BUILD_NUMBER=${PRODUCT_BUILD_NUMBER} make clean build")

    stage 'Push product-base'
        sh("pwd;cd product-base;MATURITY=${MATURITY} BUILD_NUMBER=${PRODUCT_BUILD_NUMBER} make push")

    stage 'Build all products'
        def branches = [
            'core': {
                println "Starting core-pipeline"
                build job: 'core-pipeline', parameters: [
                    [$class: 'StringParameterValue', name: 'GIT_SHA', value: GIT_SHA],
                    [$class: 'ChoiceParameterValue', name: 'MATURITY', value: MATURITY],
                    [$class: 'StringParameterValue', name: 'PRODUCT_BUILD_NUMBER', value: PRODUCT_BUILD_NUMBER],
                ]
            },
            'resmgr': {
                println "Starting resmgr-pipeline"
                build job: 'resmgr-pipeline', parameters: [
                    [$class: 'StringParameterValue', name: 'GIT_SHA', value: GIT_SHA],
                    [$class: 'ChoiceParameterValue', name: 'MATURITY', value: MATURITY],
                    [$class: 'StringParameterValue', name: 'PRODUCT_BUILD_NUMBER', value: PRODUCT_BUILD_NUMBER],
                ]
            },
        ]

        parallel branches
}
