import { RouteObject } from 'react-router-dom'
import { Suspense, lazy, ReactNode } from 'react'
import MainLayout from '../layout'
const Login = lazy(() => import('../pages/login'))
const Home = lazy(() => import('../pages/home'))
const Role = lazy(() => import('../pages/role'))
const User = lazy(() => import('../pages/user'))
const UserDetail = lazy(() => import('../pages/user/user-detail'))
const UserCenter = lazy(() => import('../pages/user/user-center'))
const Menu1 = lazy(() => import('../pages/menu/menu1'))
const Menu2 = lazy(() => import('../pages/menu/menu2'))
const Menu3 = lazy(() => import('../pages/menu/menu3'))
const Menu4 = lazy(() => import('../pages/menu/menu4'))
const Menu5 = lazy(() => import('../pages/menu/menu5'))
const Menu6 = lazy(() => import('../pages/menu/menu6'))
const lazyLoad = (children: ReactNode): ReactNode => {
  return <Suspense fallback={<>loading</>}>{children}</Suspense>
}

// const router: RouteObject[] = [
//   { path: '/login', element: lazyLoad(<Login />) },
//   {
//     path: '/',
//     element: <MainLayout />,
//     children: [
//       { index: true, element: lazyLoad(<Home />) },
//       { path: '/user', element: lazyLoad(<User />) },
//       { path: '/user/detail/:id', element: lazyLoad(<UserDetail />) },
//       { path: '/user/center', element: lazyLoad(<UserCenter />) },
//       { path: '/role', element: lazyLoad(<Role />) },
//       { path: 'menu1', element: lazyLoad(<Menu1 />) },
//       { path: 'menu2', element: lazyLoad(<Menu2 />) },
//       { path: 'menu3', element: lazyLoad(<Menu3 />) },
//       { path: 'menu4', element: lazyLoad(<Menu4 />) },
//       { path: 'menu5', element: lazyLoad(<Menu5 />) },
//       { path: 'menu6', element: lazyLoad(<Menu6 />) },
//     ],
//   },
// ]
const routeList: RouteObject[] = [
  { path: '/login', element: './login/index.tsx' },
  {
    path: '/',
    element: 'MainLayout',
    children: [
      { index: true, element: './home/index.tsx' },
      { path: '/user', element: './user/index.tsx' },
      { path: '/user/detail/:id', element: './user/user-detail.tsx' },
      { path: '/user/center', element: './user/user-center.tsx' },
      { path: '/role', element: './role/index.tsx' },

      { path: 'menu1', element: './menu/menu1.tsx' },
      { path: 'menu2', element: './menu/menu2.tsx' },
      { path: 'menu3', element: './menu/menu3.tsx' },
      { path: 'menu4', element: './menu/menu4.tsx' },
      { path: 'menu5', element: './menu/menu5.tsx' },
      { path: 'menu6', element: './menu/menu6.tsx' },
    ],
  },
]
/**
 *  扫描路由取得全部路由文件
 */
const context = require.context('../pages/', true, /\.(tsx|jsx|js)$/, 'lazy')

/**
 * 懒加载组件
 * @param key
 */
const lazyLoadComponent = (key: string) => {
  const PageComponent = lazy(() => {
    return context(key)
  })
  return (
    <Suspense
      fallback={
        <div>
          <h1>页面正在加载,请稍后 ......</h1>
        </div>
      }>
      <PageComponent />
    </Suspense>
  )
}

function genRoute(list: RouteObject[]): RouteObject[] {
  let result: RouteObject[] = []
  list.forEach((item) => {
    if (item.element === 'MainLayout') {
      result.push({
        path: item.path,
        element: <MainLayout />,
        children: [...genRoute(item.children || [])],
      })
    } else {
      if (item.children && item.children.length) {
        result.push({
          ...item,
          element: lazyLoadComponent(item.element as string),
          children: [...genRoute(item.children)],
        })
      } else {
        result.push({
          ...item,
          element: lazyLoadComponent(item.element as string),
        })
      }
    }
  })
  return result
}

// const router = genRoute(routeList)
export default genRoute(routeList)
