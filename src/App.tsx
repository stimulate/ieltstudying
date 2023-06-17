import React from 'react'
import MainLayout from './layout'
import './App.css'
import { ConfigProvider } from 'antd'
import { BrowserRouter, Routes, Route } from 'react-router-dom'

function App() {
  return (
    <ConfigProvider
      theme={{
        token: {
          colorPrimary: '#1677ff',
        },
      }}>
      {/* <MainLayout/> */}
      <BrowserRouter>
        {/* <Routes>
          <Route path="/" element={MainLayout}></Route>
        </Routes> */}
      </BrowserRouter>
    </ConfigProvider>
  )
}

export default App
