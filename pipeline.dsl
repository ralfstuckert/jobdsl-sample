def slurper = new ConfigSlurper()
// fix classloader problem using ConfigSlurper in job dsl
slurper.classLoader = this.class.classLoader
def config = slurper.parse(readFileFromWorkspace('microservices.dsl'))

// create job for every microservice
config.microservices.each { name, data ->
  createBuildJob(name,data)
  createITestJob(name,data)
  createDeployJob(name,data)
}


def createBuildJob(name,data) {
  
  freeStyleJob("${name}-build") {
  
    scm {
      git {
        remote {
          url(data.url)
        }
        branch(data.branch)
        createTag(false)
      }
    }
  
    triggers {
       scm('H/15 * * * *')
    }

    steps {
      maven {
        mavenInstallation('3.1.1')
        goals('clean install')
      }
    }

    publishers {
      archiveJunit('/target/surefire-reports/*.xml')

      downstreamParameterized {
        trigger("${name}-itest") {
        }
      }
    }
  }

}

def createITestJob(name,data) {
  freeStyleJob("${name}-itest") {
    publishers {
      downstreamParameterized {
        trigger("${name}-deploy") {
        }
      }
    }
  }
}

def createDeployJob(name,data) {
  freeStyleJob("${name}-deploy") {}
}