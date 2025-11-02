import reactLogo from './assets/react.svg'
import viteLogo from '/vite.svg'
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
        <h4>Tech stack</h4>
        <ul>
          <li>Vite</li>
          <li>React</li>
          <li>TypeScript</li>
          <li>Jenkins</li>
          <li>AWS</li>
          <li>Terraform</li>
          <li>Nginx</li>
        </ul>
      </div>
    </>
  )
}

export default App
