import { useState } from 'react'
import img from '../../style/imgs/404.png'
import { Button } from 'antd'
import { useNavigate } from 'react-router-dom'

function NotFound() {
  const navigate = useNavigate()
  const [animated, setAnimated] = useState('')
  return (
    <div
      style={{
        minHeight: '100vh',
        background: '#ececec',
        overflow: 'hidden',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
      }}>
      <div>
        <img
          src={img}
          alt="404"
          className={`animated swing ${animated}`}
          onMouseEnter={() => setAnimated('hinge')}
        />
        <Button
          onClick={() => {
            navigate(-1)
          }}
          style={{
            display: 'block',
            margin: '30px auto',
          }}>
          返回上一页
        </Button>
      </div>
    </div>
  )
}
export default NotFound
