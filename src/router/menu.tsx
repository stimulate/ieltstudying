import React, { useEffect, useState } from 'react'
import { Menu } from 'antd'
import SubMenu from 'antd/es/menu/SubMenu'
import { Link, useLocation } from 'react-router-dom'
import type { MenuProps } from 'antd'
import store from '../redux'
import { AppStateType } from '../redux/state/appState'
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

/**
 * 获取树节点
 */
function getTreePathNodeByPath(tree: IMenuConfig[], path: string) {
  if (!path) {
    return []
  }
  let result: IMenuConfig[] = [] // 记录路径结果
  let traverse = (
    key: string,
    pathNode: IMenuConfig[],
    tree: IMenuConfig[]
  ) => {
    if (tree.length === 0) {
      return
    }
    for (let item of tree) {
      pathNode.push(item)
      if (item.path === path) {
        result = JSON.parse(JSON.stringify(pathNode))
        return
      }
      const children = item?.children || []
      traverse(key, pathNode, children) // 遍历
      pathNode.pop() // 回溯
    }
  }
  traverse(path, [], tree)
  return result
}

/**
 * 生成菜单
 * @param menuConfig 菜单配置
 */
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
  const { pathname } = useLocation()
  const [openKeys, setOpenKeys] = useState<string[]>([])
  const [selectedKeys, setSelectedKeys] = useState<string[]>([])
  const [appStore, setAppStore] = useState<AppStateType>()

  // 初始化时监听store状态,当store的状态更新时更新appStore的值
  useEffect(() => {
    const { app } = store.getState()
    setAppStore(app)

    let unsubscribe = store.subscribe(() => {
      const { app } = store.getState()
      setAppStore(app)
    })
    return () => {
      unsubscribe()
    }
  }, [])

  // 监听路由变化，动态计算openKeys、selectedKeys
  useEffect(() => {
    if (pathname && pathname !== '/') {
      const menuItems = getTreePathNodeByPath(menuList, pathname)
      if (menuItems?.length) {
        const menuKeys = menuItems.map((x) => x.key)
        setOpenKeys(menuKeys)
        setSelectedKeys(menuKeys)
        // 传递select事件，设置面包屑对应数据
        props.onSelect({ key: menuKeys[menuKeys.length - 1] })
      }
    } else {
      setOpenKeys([])
      setSelectedKeys([])
    }
  }, [pathname])

  // 处理菜单选择操作
  const handleSelect = (e: any) => {
    props.onSelect(e)
  }

  // 处理菜单展开收起操作
  const onOpenChange: MenuProps['onOpenChange'] = (keys) => {
    const rootSubmenuKeys = menuList.map((x) => {
      if (x.children?.length) {
        return x.key
      }
    })
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
      theme={appStore?.theme ?? 'dark'}
      selectedKeys={selectedKeys}
      openKeys={openKeys}
      onOpenChange={onOpenChange}
      onSelect={handleSelect}>
      {genMenu(props.menuConfig)}
    </Menu>
  )
}

export default AppMenus
