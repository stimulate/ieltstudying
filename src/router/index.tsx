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
const router: RouteObject[] = [
  { path: '/login', element: lazyLoad(<Login />) },
  {
    path: '/',
    element: <MainLayout />,
    children: [
      { index: true, element: lazyLoad(<Home />) },
      { path: '/user', element: lazyLoad(<User />) },
      { path: '/user/detail/:id', element: lazyLoad(<UserDetail />) },
      { path: '/user/center', element: lazyLoad(<UserCenter />) },
      { path: '/role', element: lazyLoad(<Role />) },
      { path: 'menu1', element: lazyLoad(<Menu1 />) },
      { path: 'menu2', element: lazyLoad(<Menu2 />) },
      { path: 'menu3', element: lazyLoad(<Menu3 />) },
      { path: 'menu4', element: lazyLoad(<Menu4 />) },
      { path: 'menu5', element: lazyLoad(<Menu5 />) },
      { path: 'menu6', element: lazyLoad(<Menu6 />) },
    ],
  },
]
export default router
