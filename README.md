Straighforward Dockerfile with Wine for compiling Inno Setup installers in CI

Uses Wine to run ISCC
Inno Setup location: C:\\innosetup

Example of compiling script inside container
`wine "C:\\innosetup\\iscc.exe" setupScript.iss`

Pre-built Docker image can be found in [Docker repo](https://hub.docker.com/r/vrex141/inno_setup)

Documentation for Inno Setup can be found on [website](https://jrsoftware.org/ishelp/)

## Usage
For example, here is how it can be used in Jenkins
```Groovy
    stage('Build Windows installer') {
      agent {
        docker {
          image 'vrex141/inno_setup:latest'
        }
      }
      steps {
        sh 'wine "C:\\innosetup\\iscc.exe" /Qp $(winepath -w ./setupScript.iss)'
      }
    }
```

## Versions
- Ubuntu 18.04

## Credits
- [Inno Setup](https://jrsoftware.org/)
