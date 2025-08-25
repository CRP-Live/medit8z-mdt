// ════════════════════════════════════════════════════════════════════
// MEDIT8Z MDT - UI CONTROLLER
// ════════════════════════════════════════════════════════════════════

let currentTab = 'dashboard';
let playerData = {};
let departmentData = {};
let isOpen = false;

// ════════════════════════════════════════════════════════════════════
// NUI Message Handler
// ════════════════════════════════════════════════════════════════════
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'open':
            openMDT(data);
            break;
        case 'close':
            closeMDT();
            break;
        case 'update':
            updateData(data);
            break;
    }
});

// ════════════════════════════════════════════════════════════════════
// MDT Open/Close Functions
// ════════════════════════════════════════════════════════════════════
function openMDT(data) {
    if (isOpen) return;
    
    isOpen = true;
    playerData = data.playerData || {};
    departmentData = data.config.departments[data.department] || {};
    
    // Update UI with player data
    updatePlayerInfo();
    
    // Show/hide tabs based on department features
    updateAvailableTabs();
    
    // Update department name
    document.getElementById('department-name').textContent = getDepartmentTitle(data.department);
    
    // Show container
    document.getElementById('mdt-container').style.display = 'flex';
    
    // Start time updater
    startTimeUpdater();
    
    // Send loaded callback
    fetch(`https://${GetParentResourceName()}/loaded`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
    
    console.log('[MDT] Opened for department:', data.department);
}

function closeMDT() {
    if (!isOpen) return;
    
    isOpen = false;
    document.getElementById('mdt-container').style.display = 'none';
    
    // Stop time updater
    stopTimeUpdater();
    
    // Reset to dashboard
    switchTab('dashboard');
    
    // Send close to client
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
    
    console.log('[MDT] Closed');
}

// ════════════════════════════════════════════════════════════════════
// UI Update Functions
// ════════════════════════════════════════════════════════════════════
function updatePlayerInfo() {
    // Update header info
    document.getElementById('officer-info').textContent = 
        `${playerData.jobLabel} - ${playerData.rankLabel}`;
    
    // Update dashboard info
    document.getElementById('officer-name-display').textContent = playerData.name || 'Unknown';
    document.getElementById('officer-callsign').textContent = playerData.callsign || 'N/A';
    document.getElementById('officer-rank').textContent = playerData.rankLabel || 'Unknown';
}

function updateAvailableTabs() {
    const tabs = document.querySelectorAll('.nav-tab');
    
    tabs.forEach(tab => {
        const feature = tab.dataset.tab;
        
        // Check if this feature is enabled for the department
        if (departmentData.features && departmentData.features[feature] === false) {
            tab.style.display = 'none';
        } else {
            tab.style.display = 'block';
        }
    });
}

function getDepartmentTitle(department) {
    const titles = {
        'Police': 'Police Mobile Data Terminal',
        'EMS': 'Emergency Medical Services Terminal',
        'DOJ': 'Department of Justice Terminal',
        'Towing': 'Towing Management System'
    };
    
    return titles[department] || 'Mobile Data Terminal';
}

// ════════════════════════════════════════════════════════════════════
// Tab System
// ════════════════════════════════════════════════════════════════════
function switchTab(tabName) {
    // Update nav tabs
    document.querySelectorAll('.nav-tab').forEach(tab => {
        tab.classList.remove('active');
        if (tab.dataset.tab === tabName) {
            tab.classList.add('active');
        }
    });
    
    // Update content
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    
    const targetContent = document.getElementById(tabName);
    if (targetContent) {
        targetContent.classList.add('active');
    }
    
    currentTab = tabName;
    console.log('[MDT] Switched to tab:', tabName);
}

// ════════════════════════════════════════════════════════════════════
// Time Updater
// ════════════════════════════════════════════════════════════════════
let timeInterval = null;

function startTimeUpdater() {
    updateTime();
    timeInterval = setInterval(updateTime, 1000);
}

function stopTimeUpdater() {
    if (timeInterval) {
        clearInterval(timeInterval);
        timeInterval = null;
    }
}

function updateTime() {
    const now = new Date();
    const hours = now.getHours().toString().padStart(2, '0');
    const minutes = now.getMinutes().toString().padStart(2, '0');
    document.getElementById('current-time').textContent = `${hours}:${minutes}`;
}

// ════════════════════════════════════════════════════════════════════
// Event Listeners
// ════════════════════════════════════════════════════════════════════
document.addEventListener('DOMContentLoaded', function() {
    // Tab switching
    document.querySelectorAll('.nav-tab').forEach(tab => {
        tab.addEventListener('click', function() {
            switchTab(this.dataset.tab);
        });
    });
    
    // Search functionality (placeholder for now)
    const searchBtn = document.querySelector('.btn-search');
    if (searchBtn) {
        searchBtn.addEventListener('click', function() {
            const searchValue = document.getElementById('profile-search').value;
            console.log('[MDT] Searching for:', searchValue);
            // Will implement actual search in Phase 3
        });
    }
    
    // Quick action buttons (placeholder for now)
    document.querySelectorAll('.action-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            console.log('[MDT] Quick action clicked:', this.textContent);
            // Will implement in later phases
        });
    });
});

// ════════════════════════════════════════════════════════════════════
// Keyboard Controls
// ════════════════════════════════════════════════════════════════════
document.addEventListener('keyup', function(event) {
    if (event.key === 'Escape' && isOpen) {
        closeMDT();
    }
});

// ════════════════════════════════════════════════════════════════════
// Helper Functions
// ════════════════════════════════════════════════════════════════════
function GetParentResourceName() {
    return window.GetParentResourceName ? window.GetParentResourceName() : 'medit8z-mdt';
}

function updateData(data) {
    // This will be used for real-time updates in later phases
    console.log('[MDT] Data update received:', data);
}

// ════════════════════════════════════════════════════════════════════
// Error Handling
// ════════════════════════════════════════════════════════════════════
window.addEventListener('error', function(event) {
    console.error('[MDT] UI Error:', event.error);
    
    fetch(`https://${GetParentResourceName()}/error`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            error: event.error.toString()
        })
    });
});

console.log('[MDT] UI Loaded Successfully');