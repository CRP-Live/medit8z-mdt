// ════════════════════════════════════════════════════════════════════
// PHASE 2: REAL-TIME DASHBOARD SYSTEM
// ════════════════════════════════════════════════════════════════════

// Dashboard state
let dashboardData = {
    activeUnits: [],
    recentCalls: [],
    recentArrests: [],
    probationList: [],
    notifications: []
};

let autoRefreshInterval = null;

// ════════════════════════════════════════════════════════════════════
// Core Dashboard Functions
// ════════════════════════════════════════════════════════════════════
function initializeDashboard() {
    console.log('[Dashboard] Initializing...');
    
    fetchDashboardData();
    startAutoRefresh();
    initializeNotifications();
}

function cleanupDashboard() {
    stopAutoRefresh();
}

function fetchDashboardData() {
    if (!window.GetParentResourceName) return;
    
    console.log('[Dashboard] Fetching data...');
    
    fetch(`https://${window.GetParentResourceName()}/getDashboardData`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    }).then(function(resp) {
        return resp.json();
    }).then(function(data) {
        console.log('[Dashboard] Data received:', data);
        if (data) {
            updateDashboardUI(data);
        }
    }).catch(function(err) {
        console.error('[Dashboard] Error fetching data:', err);
    });
}

function startAutoRefresh() {
    if (autoRefreshInterval) clearInterval(autoRefreshInterval);
    
    autoRefreshInterval = setInterval(function() {
        if (window.MDT && window.MDT.currentTab === 'dashboard') {
            fetchDashboardData();
        }
    }, 5000);
}

function stopAutoRefresh() {
    if (autoRefreshInterval) {
        clearInterval(autoRefreshInterval);
        autoRefreshInterval = null;
    }
}

// ════════════════════════════════════════════════════════════════════
// Dashboard UI Updates
// ════════════════════════════════════════════════════════════════════
function updateDashboardUI(data) {
    dashboardData = data;
    
    updateElement('active-units', data.activeUnits || 0);
    updateElement('recent-calls', data.recentCalls || 0);
    updateElement('active-warrants', data.activeWarrants || 0);
    
    updateUnitsList(data.units || []);
    updateArrestsFeed(data.recentArrests || []);
    updateProbationList(data.probationList || []);
    
    if (data.statistics) {
        updateElement('stat-arrests-today', data.statistics.totalArrests || 0);
        updateElement('stat-citations-today', data.statistics.totalCitations || 0);
        updateElement('stat-reports-today', data.statistics.totalReports || 0);
    }
}

function updateElement(id, value) {
    const element = document.getElementById(id);
    if (element) {
        element.textContent = value;
    }
}

function updateUnitsList(units) {
    const container = document.getElementById('active-units-list');
    if (!container) return;
    
    if (!units || units.length === 0) {
        container.innerHTML = '<p class="no-units">No units on duty</p>';
        return;
    }
    
    let html = '';
    units.forEach(function(unit) {
        html += `
        <div class="unit-card ${getStatusClass(unit.status)}">
            <div class="unit-header">
                <span class="unit-callsign">${unit.callsign || 'N/A'}</span>
                <span class="unit-status">${unit.status || '10-8'}</span>
            </div>
            <div class="unit-name">${unit.name || 'Unknown'}</div>
            <div class="unit-department">${unit.department || 'Unknown'}</div>
        </div>`;
    });
    container.innerHTML = html;
}

function getStatusClass(status) {
    const statusMap = {
        '10-8': 'status-available',
        '10-7': 'status-busy',
        '10-6': 'status-offline',
        '10-97': 'status-enroute',
        '10-23': 'status-arrived'
    };
    return statusMap[status] || 'status-unknown';
}

function updateArrestsFeed(arrests) {
    const container = document.getElementById('recent-arrests-feed');
    if (!container) return;
    
    if (!arrests || arrests.length === 0) {
        container.innerHTML = '<p class="no-arrests">No recent arrests</p>';
        return;
    }
    
    let html = '';
    arrests.forEach(function(arrest) {
        html += `
        <div class="arrest-item">
            <div class="arrest-header">
                <span class="arrest-officer">${arrest.officer || 'Unknown'}</span>
                <span class="arrest-time">${getTimeAgo(arrest.timestamp)}</span>
            </div>
            <div class="arrest-suspect">Suspect: ${arrest.suspect || 'Unknown'}</div>
            <div class="arrest-charges">${arrest.charges ? arrest.charges.join(', ') : 'No charges listed'}</div>
        </div>`;
    });
    container.innerHTML = html;
}

function updateProbationList(probationList) {
    const container = document.getElementById('probation-list');
    if (!container) return;
    
    if (!probationList || probationList.length === 0) {
        container.innerHTML = '<p class="no-probation">No active probation</p>';
        return;
    }
    
    dashboardData.probationList = probationList;
    
    let html = '';
    probationList.forEach(function(person) {
        html += `
        <div class="probation-item">
            <div class="probation-name">${person.citizen_name || 'Unknown'}</div>
            <div class="probation-id">ID: ${person.citizen_id || 'N/A'}</div>
            <div class="probation-end">Ends: ${formatDate(person.end_date)}</div>
        </div>`;
    });
    container.innerHTML = html;
}

// ════════════════════════════════════════════════════════════════════
// Global Search
// ════════════════════════════════════════════════════════════════════
function performGlobalSearch() {
    const searchInput = document.getElementById('global-search');
    if (!searchInput) return;
    
    const query = searchInput.value.trim();
    
    if (query.length < 2) {
        showNotification({
            type: 'error',
            title: 'Search Error',
            message: 'Please enter at least 2 characters'
        });
        return;
    }
    
    const container = document.getElementById('global-search-results');
    if (container) {
        container.innerHTML = '<div class="search-loading">Searching...</div>';
        container.style.display = 'block'; // Make sure it's visible
    }
    
    // Fix: Use the correct resource name function
    const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'medit8z-mdt';
    
    fetch(`https://${resourceName}/globalSearch`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({query: query})
    }).then(function(resp) {
        return resp.json();
    }).then(function(results) {
        displayGlobalSearchResults(results);
    }).catch(function(err) {
        console.error('[Dashboard] Search error:', err);
        if (container) {
            container.innerHTML = '<div class="search-results"><p>Search error occurred</p></div>';
        }
    });
}

function displayGlobalSearchResults(results) {
    const container = document.getElementById('global-search-results');
    if (!container) return;
    
    if (!results || Object.keys(results).length === 0) {
        container.innerHTML = '<div class="search-results"><p>No results found</p></div>';
        return;
    }
    
    let html = '<div class="search-results">';
    
    if (results.profiles && results.profiles.length > 0) {
        html += '<div class="search-category"><h4>Profiles</h4>';
        results.profiles.forEach(function(profile) {
            html += `<div class="search-item" onclick="openProfile('${profile.citizen_id}')">
                ${profile.first_name} ${profile.last_name} - ${profile.phone || 'No phone'}
            </div>`;
        });
        html += '</div>';
    }
    
    if (results.vehicles && results.vehicles.length > 0) {
        html += '<div class="search-category"><h4>Vehicles</h4>';
        results.vehicles.forEach(function(vehicle) {
            html += `<div class="search-item" onclick="openVehicle('${vehicle.plate}')">
                ${vehicle.plate} - ${vehicle.make || ''} ${vehicle.model || ''} (${vehicle.owner_name})
            </div>`;
        });
        html += '</div>';
    }
    
    if (results.incidents && results.incidents.length > 0) {
        html += '<div class="search-category"><h4>Incidents</h4>';
        results.incidents.forEach(function(incident) {
            html += `<div class="search-item" onclick="openIncident('${incident.incident_number}')">
                #${incident.incident_number} - ${incident.title}
            </div>`;
        });
        html += '</div>';
    }
    
    html += '</div>';
    container.innerHTML = html;
}

// ════════════════════════════════════════════════════════════════════
// Notifications
// ════════════════════════════════════════════════════════════════════
function initializeNotifications() {
    if (!document.getElementById('notification-container')) {
        const container = document.createElement('div');
        container.id = 'notification-container';
        container.className = 'notification-container';
        document.body.appendChild(container);
    }
}

function showNotification(notification) {
    const container = document.getElementById('notification-container');
    if (!container) {
        initializeNotifications();
        return showNotification(notification);
    }
    
    const notifElement = document.createElement('div');
    notifElement.className = `notification notification-${notification.type || 'info'}`;
    
    let html = `
        <div class="notification-header">
            <span class="notification-title">${notification.title}</span>
            <button class="notification-close" onclick="this.closest('.notification').remove()">×</button>
        </div>
        <div class="notification-message">${notification.message}</div>`;
    
    notifElement.innerHTML = html;
    container.appendChild(notifElement);
    
    if (notification.type !== 'emergency') {
        setTimeout(function() {
            if (notifElement.parentNode) {
                notifElement.remove();
            }
        }, 5000);
    }
}

// ════════════════════════════════════════════════════════════════════
// Utility Functions
// ════════════════════════════════════════════════════════════════════
function getTimeAgo(timestamp) {
    const seconds = Math.floor(Date.now() / 1000 - timestamp);
    
    if (seconds < 60) return `${seconds}s ago`;
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
    if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
    return `${Math.floor(seconds / 86400)}d ago`;
}

function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString();
}

// ════════════════════════════════════════════════════════════════════
// Navigation Handlers
// ════════════════════════════════════════════════════════════════════
function openProfile(citizenId) {
    console.log('Opening profile:', citizenId);
    showNotification({
        type: 'info',
        title: 'Coming Soon',
        message: 'Profile view will be available in the next update'
    });
}

function openVehicle(plate) {
    console.log('Opening vehicle:', plate);
    showNotification({
        type: 'info',
        title: 'Coming Soon',
        message: 'Vehicle records will be available in a future update'
    });
}

function openIncident(incidentNumber) {
    console.log('Opening incident:', incidentNumber);
    showNotification({
        type: 'info',
        title: 'Coming Soon',
        message: 'Incident reports will be available in the next update'
    });
}

// ════════════════════════════════════════════════════════════════════
// Global Exports (No circular references)
// ════════════════════════════════════════════════════════════════════
window.globalSearch = performGlobalSearch;

console.log('[MDT] Dashboard functions loaded');