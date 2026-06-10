import React from 'react';
import { 
  MdDashboard, MdAgriculture, MdPeople, 
  MdInventory, MdWbSunny, MdYard 
} from 'react-icons/md';
import { GiPlantRoots, GiLeafSwirl } from 'react-icons/gi';

// list of all navigation items
const navItems = [
  { id: 'dashboard',  label: 'Dashboard',       icon: MdDashboard },
  { id: 'farms',      label: 'Farms',            icon: MdAgriculture },
  { id: 'plots',      label: 'Plots',            icon: MdYard },
  { id: 'crops',      label: 'Crop Management',  icon: GiPlantRoots },
  { id: 'inventory',  label: 'Inventory',        icon: MdInventory },
  { id: 'employees',  label: 'Employees',        icon: MdPeople },
  { id: 'weather',    label: 'Weather',          icon: MdWbSunny },
  { id: 'leaf',       label: 'Leaf Detection',   icon: GiLeafSwirl },
];

function Sidebar({ currentPage, setCurrentPage }) {
  return (
    <aside className="w-64 bg-green-800 text-white flex flex-col">

      {/* logo */}
      <div className="px-6 py-5 border-b border-green-700">
        <h1 className="text-xl font-bold">🌱 Farm OS</h1>
        <p className="text-green-300 text-xs mt-1">Farm Management System</p>
      </div>

      {/* nav links */}
      <nav className="flex-1 px-3 py-4 space-y-1">
        {navItems.map(item => {
          const Icon = item.icon;
          const isActive = currentPage === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setCurrentPage(item.id)}
              className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                isActive 
                  ? 'bg-green-600 text-white' 
                  : 'text-green-200 hover:bg-green-700'
              }`}
            >
              <Icon size={18} />
              {item.label}
            </button>
          );
        })}
      </nav>

      {/* bottom */}
      <div className="px-6 py-4 border-t border-green-700">
        <p className="text-green-400 text-xs">Farm OS v1.0 MVP</p>
      </div>
    </aside>
  );
}

export default Sidebar;