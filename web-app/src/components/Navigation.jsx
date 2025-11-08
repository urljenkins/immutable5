import React from 'react'

const Navigation = ({ currentView, onViewChange }) => {
  const navItems = [
    { id: 'prayer-times', label: '🕌 Prayer Times', icon: '⏰' },
    { id: 'qibla', label: 'Qibla', icon: '🧭' },
    { id: 'duas', label: 'Duas', icon: '📿' },
  ]

  return (
    <nav className="navigation">
      {navItems.map(item => (
        <button
          key={item.id}
          className={`nav-button ${currentView === item.id ? 'active' : ''}`}
          onClick={() => onViewChange(item.id)}
        >
          <span className="nav-icon">{item.icon}</span>
          <span className="nav-label">{item.label}</span>
        </button>
      ))}
    </nav>
  )
}

export default Navigation
