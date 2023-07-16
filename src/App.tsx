import React, { Suspense } from 'react'
import MainLayout from './layout'
import './App.css'
import { ConfigProvider } from 'antd'
import { HashRouter, useRoutes } from 'react-router-dom'
import router from './router'
import { Provider } from 'react-redux'
import store from './store'

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
