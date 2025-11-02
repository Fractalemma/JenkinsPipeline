import reactLogo from './assets/react.svg'
import viteLogo from '/vite.svg'
import pipelineDiagram from './assets/jenkins-pipeline-diagram.svg'
import './App.css'

function App() {

  return (
    <>
      <div>
        <a href="https://vite.dev" target="_blank">
          <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
      </div>
      <h1>Vite + React</h1>
      <h3>By Emmanuel Romero</h3>
      <div className="card">
        <h4>Pipeline features</h4>
        <ul>
          <li>AWS Infra is provisioned via Terraform</li>
          <li>CI/CD pipeline is managed by Jenkins</li>
          <li>Application is served by Nginx</li>
          <li>Automated builds and deployments on push</li>
        </ul>
      </div>
      <div className="pipeline-diagram" style={{ width: '100%', maxWidth: '1400px', margin: '2rem auto' }}>
        <h2>Jenkins Pipeline Architecture Diagram</h2>
        <img 
          src={pipelineDiagram} 
          alt="Jenkins Pipeline Diagram" 
          style={{ width: '100%', height: 'auto', border: '1px solid #FFF', borderRadius: '8px', padding: '2rem', backgroundColor: '#121212' }}
        />
      </div>
    </>
  )
}

export default App
