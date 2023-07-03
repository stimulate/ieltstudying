import './App.css'
import './style/animate.css'
import { ConfigProvider } from 'antd'
import { HashRouter, useRoutes } from 'react-router-dom'
import router from './router'
import store from './store'
import { Provider } from 'react-redux'
function AppRouter() {
  return useRoutes(router)
}

function App() {
  return (
    <Provider store={store}>
      <ConfigProvider
        theme={{
          token: {
            colorPrimary: '#1677ff',
          },
        }}>
        <HashRouter>
          <AppRouter />
        </HashRouter>
      </ConfigProvider>
    </Provider>
  )
}

export default App
