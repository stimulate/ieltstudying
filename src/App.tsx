import React, { Suspense } from 'react'
import MainLayout from './layout'
import './App.css'
import './style/animate.css'
import { ConfigProvider } from 'antd'
import { HashRouter, useRoutes } from 'react-router-dom'
import router from './router'

function AppRouter() {
  return useRoutes(router)
}

function App() {
  return (
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
  )
}

export default App
