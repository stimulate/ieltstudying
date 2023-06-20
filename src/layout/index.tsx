import React, { useEffect, useState } from 'react'
import AppMenus, { menuList } from '../router/menu'
import {
  DesktopOutlined,
  FileOutlined,
  PieChartOutlined,
  TeamOutlined,
  UserOutlined,
  MenuUnfoldOutlined,
  MenuFoldOutlined,
  DownOutlined,
} from '@ant-design/icons'
import type { MenuProps } from 'antd'
import {
  Breadcrumb,
  Layout,
  Menu,
  theme,
  Button,
  Badge,
  Avatar,
  Dropdown,
  Space,
} from 'antd'
import { Outlet } from 'react-router-dom'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import SubMenu from 'antd/es/menu/SubMenu'

const { Header, Content, Footer, Sider } = Layout

type MenuItem = Required<MenuProps>['items'][number]
type DropdownItem = Required<MenuProps>['items'][number]

function getItem(
  label: React.ReactNode,
  key: React.Key,
  icon?: React.ReactNode,
  children?: MenuItem[]
): MenuItem {
  return {
    key,
    icon,
    children,
    label,
  } as MenuItem
}

const items: MenuItem[] = [
  getItem('Option 1', '1', <PieChartOutlined />),
  getItem('Option 2', '2', <DesktopOutlined />),
  getItem('User', 'sub1', <UserOutlined />, [
    getItem('Tom', '3'),
    getItem('Bill', '4'),
    getItem('Alex', '5'),
  ]),
  getItem('Team', 'sub2', <TeamOutlined />, [
    getItem('Team 1', '6'),
    getItem('Team 2', '8'),
  ]),
  getItem('Files', '9', <FileOutlined />),
]
const UserList = ['Lucy', 'Tom', 'Edward']
const ColorList = ['#7265e6', '#ffbf00', '#00a2ae']
const userDropdownItems: MenuProps['items'] = [
  {
    label: '个人中心',
    key: '1',
  },
  {
    label: '退出',
    key: '2',
  },
]

const MainLayout: React.FC = () => {
  const navigate = useNavigate()
  const { pathname } = useLocation()
  const [collapsed, setCollapsed] = useState(false)
  const [user, setUser] = useState(UserList[0])
  const [color, setColor] = useState(ColorList[0])
  const {
    token: { colorBgContainer },
  } = theme.useToken()

  useEffect(() => {
    const aa = pathname
  }, [pathname])

  const handleMenuClick: MenuProps['onClick'] = (e) => {
    if (e.key === '2') {
      navigate('/login')
    }
    if (e.key === '1') {
      navigate('/user/center')
    }
  }

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Sider
        collapsible
        collapsed={collapsed}
        onCollapse={(value) => setCollapsed(value)}>
        <div className="demo-logo-vertical">
          {collapsed ? '英语' : '英语学习系统'}
        </div>
        <AppMenus menuConfig={menuList} />
      </Sider>
      <Layout>
        <Header style={{ padding: 0, background: colorBgContainer }}>
          <Button
            type="text"
            icon={collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
            onClick={() => setCollapsed(!collapsed)}
            style={{
              fontSize: '16px',
              width: 64,
              height: 64,
            }}
          />
          <Dropdown
            menu={{ items: userDropdownItems, onClick: handleMenuClick }}
            trigger={['click']}>
            <Badge>
              <Space>
                <Avatar
                  style={{ backgroundColor: color, verticalAlign: 'middle' }}
                  size="large">
                  {user}
                </Avatar>
                <DownOutlined />
              </Space>
            </Badge>
          </Dropdown>
        </Header>
        <Content style={{ margin: '0 16px' }}>
          <Breadcrumb style={{ margin: '16px 0' }}>
            <Breadcrumb.Item>User</Breadcrumb.Item>
            <Breadcrumb.Item>Bill</Breadcrumb.Item>
          </Breadcrumb>
          <div
            style={{
              padding: 24,
              minHeight: 360,
              background: colorBgContainer,
            }}>
            <Outlet />
          </div>
        </Content>
        <Footer style={{ textAlign: 'center' }}>
          Ant Design ©2023 Created by Ant UED
        </Footer>
      </Layout>
    </Layout>
  )
}

export default MainLayout
