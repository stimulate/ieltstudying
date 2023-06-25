import React, { useState } from 'react'
import { Menu } from 'antd'
import SubMenu from 'antd/es/menu/SubMenu'
import { Link } from 'react-router-dom'
import type { MenuProps } from 'antd'

export const menuList: IMenuConfig[] = [
  {
    key: 'user-manage',
    title: '用户管理',
    icon: 'TeamOutlined',
    children: [
      {
        key: 'user',
        title: '用户列表',
        path: '/user',
        icon: 'UserOutlined',
      },
    ],
  },
  {
    key: 'role-manage',
    title: '角色管理',
    icon: 'PieChartOutlined',
    children: [
      {
        key: 'role',
        title: '角色列表',
        path: '/role',
        icon: 'UserOutlined',
      },
    ],
  },
  {
    key: 'menu1',
    title: '模块一',
    path: '/menu1',
    icon: 'DesktopOutlined',
  },
  {
    key: 'menu2',
    title: '模块二',
    path: '/menu2',
    icon: 'DesktopOutlined',
  },
  {
    key: 'menu3-manage', // 唯一的id
    title: '模块三', // 菜单名称
    icon: 'DesktopOutlined',
    children: [
      // 子菜单
      {
        key: 'menu3-1',
        title: '模块3-1',
        path: '/menu3',
        icon: 'DesktopOutlined',
      },
      {
        key: 'menu3-2',
        title: '多级菜单',
        path: '/menu3/2',
        icon: 'DesktopOutlined',
        children: [
          {
            key: 'menu3-2-1',
            title: '模块3-2-1',
            path: '/menu4',
            icon: 'DesktopOutlined',
          },
        ],
      },
    ],
  },
]

export interface IMenuConfig {
  key: string
  title: string
  path?: string
  auth?: number // 是否需要鉴权 [user]
  icon?: string
  hidden?: boolean // 是否显示在菜单上, 默认要显示。加该参数主要是隐藏用于重定向的菜单
  children?: IMenuConfig[]
}

function genMenu(menuConfig: IMenuConfig[]) {
  return menuConfig.map((menuItem) => {
    const itemIcon = menuItem?.icon
      ? React.createElement(require('@ant-design/icons')[menuItem?.icon])
      : null

    if (menuItem.children && menuItem.children.length) {
      return (
        <SubMenu key={menuItem.key} title={menuItem.title} icon={itemIcon}>
          {genMenu(menuItem.children)}
        </SubMenu>
      )
    } else {
      return (
        <Menu.Item key={menuItem.key} icon={itemIcon}>
          <Link to={menuItem?.path || ''}>{menuItem.title}</Link>
        </Menu.Item>
      )
    }
  })
}

function AppMenus(props: { menuConfig: IMenuConfig[]; onSelect: Function }) {
  const handleSelect = (e: any) => {
    props.onSelect(e)
  }
  const [openKeys, setOpenKeys] = useState(['user'])
  const rootSubmenuKeys = ['user-manage', 'role-manage', 'menu3-manage']

  const onOpenChange: MenuProps['onOpenChange'] = (keys) => {
    const latestOpenKey = keys.find((key) => openKeys.indexOf(key) === -1)
    if (rootSubmenuKeys.indexOf(latestOpenKey!) === -1) {
      setOpenKeys(keys)
    } else {
      setOpenKeys(latestOpenKey ? [latestOpenKey] : [])
    }
  }

  return (
    <Menu
      mode="inline"
      theme="dark"
      openKeys={openKeys}
      onOpenChange={onOpenChange}
      onSelect={handleSelect}>
      {genMenu(props.menuConfig)}
    </Menu>
  )
}

export default AppMenus
