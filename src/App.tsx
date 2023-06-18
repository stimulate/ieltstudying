import React from 'react'
import MainLayout from './layout'
import './App.css'
import { ConfigProvider } from 'antd'
import { HashRouter, Routes, Route } from 'react-router-dom'
import Home from './pages/home'
import User from './pages/user'
import Role from './pages/role'
import UserDetail from './pages/user/user-detail'
import UserCenter from './pages/user/user-center'

import Login from './pages/login'

import Menu1 from './pages/menu/menu1'
import Menu2 from './pages/menu/menu2'
import Menu3 from './pages/menu/menu3'
import Menu4 from './pages/menu/menu4'
import Menu5 from './pages/menu/menu5'
import Menu6 from './pages/menu/menu6'

function App() {
  return (
    <ConfigProvider
      theme={{
        token: {
          colorPrimary: '#1677ff',
        },
      }}>
      <HashRouter>
        <Routes>
          <Route path="/" element={<MainLayout />}>
            {/* 菜单demo */}
            <Route path="menu1" element={<Menu1 />}></Route>
            <Route path="menu2" element={<Menu2 />}></Route>
            <Route path="menu3" element={<Menu3 />}></Route>
            <Route path="menu4" element={<Menu4 />}></Route>
            <Route path="menu5" element={<Menu5 />}></Route>
            <Route path="menu6" element={<Menu6 />}></Route>
            {/* 首页 */}
            <Route index element={<Home />}></Route>
            {/* 用户路由 */}
            <Route path="/user" element={<User />}></Route>
            <Route path="/user/detail/:id" element={<UserDetail />}></Route>
            <Route path="/user/center" element={<UserCenter />}></Route>
            {/* 角色 */}
            <Route path="/role" element={<Role />}></Route>
          </Route>
          <Route path="/login" element={<Login />}></Route>
        </Routes>
      </HashRouter>
    </ConfigProvider>
  )
}

export default App
